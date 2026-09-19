# als.nu — alias finder for Nushell
#
# Two capabilities, both driven off `scope aliases` at runtime:
#   1. lookup  — find an alias by name, or find aliases for a command you typed
#   2. hint    — a pre_execution hook that shows the shorter alias you could have used
#
# Public API
#   als                       list every alias
#   als <name>                forward lookup by alias name
#   als <command> [args...]   reverse lookup: exact-prefix matches + related aliases
#   als stats [--json]        keystrokes saved / missed, from shell history
#   als stats --fleet         same, aggregated across ssh hosts
#   als hint <line>           render the hint box for a line (hook entry point)
#   als reindex               rebuild the cached alias index
#
# Configuration — all optional, all via $env, so nothing here is host-specific:
#   $env.ALS_HINT       bool         enable the hint box            (default true)
#   $env.ALS_MIN_SAVED  int          minimum keystrokes to hint on  (default 1)
#   $env.ALS_IGNORE     list<string> alias names never hinted       (default [])
#   $env.ALS_FLEET      list<record> {name, target, remote?, enabled?} for --fleet
#
# Portability: this file is written to work both inlined into config.nu (how the
# dotfiles consume it) and as a standalone module via `use als.nu *`.

const ALS_SP = " "
const ALS_DASH = "─"
const ALS_STATS_SCHEMA = "als/stats/1"
const ALS_FLEET_SCHEMA = "als/fleet/1"

# ─── helpers ────────────────────────────────────────────────────────────────

# Display width: ansi escapes are invisible but counted by `str length`, and
# `str length` counts UTF-8 bytes unless asked for grapheme clusters.
def als-width [s: string] {
    $s | ansi strip | str length --grapheme-clusters
}

# Nushell has no string-repeat operator; `fill` is the primitive.
def als-rep [c: string, n: int] {
    if $n <= 0 { "" } else { "" | fill --character $c --width $n }
}

def als-words [s: string] {
    $s | str trim | split row $ALS_SP | where {|w| $w != "" }
}

# Normalise one `scope aliases` record into the shape the matcher wants.
def als-row [a: record] {
    let nw = (als-words $a.expansion)
    {
        name: $a.name
        expansion: $a.expansion
        nw: $nw
        n: ($nw | length)
        fw: ($nw | get -o 0 | default "")
        saved: ((($nw | str join $ALS_SP) | str length -g) - ($a.name | str length -g))
    }
}

# Rows whose expansion word-list is a prefix of `w`.
def als-prefix-hits [rows: list<any>, w: list<string>, min: int] {
    $rows | where {|a|
        ($a.n <= ($w | length)) and (($w | first $a.n) == $a.nw) and ($a.saved >= $min)
    }
}

# Longest expansion wins, then most saved, then alphabetical.
# The tie-break is explicit because `sort-by --reverse` is NOT stable for ties.
def als-pick-best [hits: list<any>] {
    if ($hits | is-empty) { return null }
    let nmax = ($hits | get n | math max)
    let tier = ($hits | where n == $nmax)
    let smax = ($tier | get saved | math max)
    $tier | where saved == $smax | sort-by name | first
}

# ─── index ──────────────────────────────────────────────────────────────────

# Build the alias index from the live scope. ~2.4ms for 244 aliases.
export def "als build-index" [] {
    let rows = (scope aliases | each {|r| als-row $r } | where n > 0)
    {
        count: ($rows | length)
        rows: $rows
        by_first: ($rows | group-by fw)
        by_name: ($rows | group-by name)
    }
}

# Cached index, rebuilt when the alias scope changes. Degrades safely to a
# fresh build if $env caching is unavailable.
export def "als index" [] {
    let cached = ($env.ALS_INDEX? | default null)
    if ($cached != null) and ($cached.count == (scope aliases | length)) {
        $cached
    } else {
        als build-index
    }
}

export def --env "als reindex" [] {
    $env.ALS_INDEX = (als build-index)
    print $"als: indexed ($env.ALS_INDEX.count) aliases"
}

# ─── matching ───────────────────────────────────────────────────────────────

# Aliases whose expansion is a word-boundary prefix of `line` — i.e. shorter
# things you could have typed instead.
export def "als match" [line: string, --index: any = null, --min-saved: int = 1] {
    let ix = (if $index == null { als index } else { $index })
    let w = (als-words $line)
    if ($w | is-empty) { return [] }
    als-prefix-hits ($ix.by_first | get -o ($w | first) | default []) $w $min_saved
}

# Aliases whose expansion STARTS WITH `line` — i.e. longer, more specific
# aliases you could reach for. This is what makes `als git log` useful.
export def "als related" [line: string, --index: any = null, --limit: int = 20] {
    let ix = (if $index == null { als index } else { $index })
    let w = (als-words $line)
    if ($w | is-empty) { return [] }
    $ix.by_first
    | get -o ($w | first)
    | default []
    | where {|a| ($a.n > ($w | length)) and (($a.nw | first ($w | length)) == $w) }
    | sort-by n name
    | first $limit
}

# The single best alias to hint for, or null.
# Policy: longest expansion wins, then most saved, then alphabetical.
# The explicit tie-break matters — `sort-by --reverse` is NOT stable for ties.
export def "als best" [line: string, --index: any = null, --min-saved: int = 1] {
    als-pick-best (als match $line --index $index --min-saved $min_saved)
}

# ─── presentation ───────────────────────────────────────────────────────────

export def "als box" [title: string, rows: list<string>] {
    let w = ([(als-width $title) ...($rows | each {|r| als-width $r })] | math max)
    let dim = (ansi dark_gray)
    let rst = (ansi reset)
    let head = $"($dim)╭─($rst)(ansi yellow_bold) ($title) ($rst)($dim)(als-rep $ALS_DASH ($w - (als-width $title)))─╮($rst)"
    let body = ($rows | each {|r| $"($dim)│($rst)  ($r)(als-rep $ALS_SP ($w - (als-width $r)))  ($dim)│($rst)" })
    let foot = $"($dim)╰(als-rep $ALS_DASH ($w + 4))╯($rst)"
    [$head ...$body $foot] | str join (char newline)
}

# ─── hint ───────────────────────────────────────────────────────────────────

# Returns the box string for `line`, or null when no hint is warranted.
# This deliberately does NOT build the alias index. Building it costs ~37ms,
# which would be paid on EVERY command; filtering `scope aliases` down to the
# handful of candidates sharing a first word costs ~2ms and needs no cache.
export def "als hint" [line: string] {
    if not ($env.ALS_HINT? | default true | into bool) { return null }
    # A leading space means "don't record this" by history convention; respect it.
    if ($line | str starts-with $ALS_SP) { return null }

    let t = ($line | str trim)
    if ($t | is-empty) { return null }

    let w = (als-words $t)
    if ($w | is-empty) { return null }
    let w0 = ($w | first)
    let sc = (scope aliases)

    # Already typed an alias — never nag. The common case, and the cheapest bail.
    if (($sc | where name == $w0 | length) > 0) { return null }

    # Only aliases whose expansion begins with the same first word can match.
    let cands = (
        $sc
        | where {|a| ($a.expansion == $w0) or ($a.expansion | str starts-with $"($w0) ") }
        | each {|a| als-row $a }
    )
    if ($cands | is-empty) { return null }

    let min = ($env.ALS_MIN_SAVED? | default 1 | into int)
    let b = (als-pick-best (als-prefix-hits $cands $w $min))
    if ($b == null) { return null }
    if ($b.name in ($env.ALS_IGNORE? | default [])) { return null }

    als box "alias" [
        $"(ansi yellow_bold)($b.name)(ansi reset)  (ansi dark_gray)->(ansi reset)  ($b.expansion)"
        $"(ansi dark_gray)saves ($b.saved) keystrokes(ansi reset)"
    ]
}

# What the pre_execution hook calls. Never throws, never returns a value.
export def "als hint-line" [line: string] {
    let box = (try { als hint $line } catch { null })
    if ($box != null) { print $box }
}

# ─── lookup ─────────────────────────────────────────────────────────────────

# Render a group of aliases with the name column padded to a common width.
def als-print-rows [rows: list<any>, --savings] {
    let w = ($rows | each {|a| $a.name | str length -g } | math max)
    for a in $rows {
        let pad = (als-rep $ALS_SP ($w - ($a.name | str length -g)))
        let tail = if $savings { $"(ansi dark_gray)  \(saves ($a.saved)\)(ansi reset)" } else { "" }
        print $"  (ansi yellow_bold)($a.name)(ansi reset)($pad)  (ansi dark_gray)->(ansi reset)  ($a.expansion)($tail)"
    }
}

export def "als list" [] {
    (als index).rows | select name expansion | sort-by name
}

# ─── stats ──────────────────────────────────────────────────────────────────

# Analyse shell history for keystrokes saved (aliases used) and missed
# (long form typed when a shorter alias existed).
#
# Reads through the `history` COMMAND rather than the history file, so this
# works unchanged on both plaintext and sqlite history backends.
export def "als report" [--top: int = 10, --index: any = null] {
    let ix = (if $index == null { als index } else { $index })
    let raw = (history)
    let cols = ($raw | columns)
    let has_ts = ("start_timestamp" in $cols)
    let lines = ($raw | get command | where {|l| ($l | str trim) != "" })

    # Classify in one pass. Built with `each` rather than `mut ... | append`:
    # appending to a growing list is O(n^2) and costs ~8s over 9.6k lines.
    let classified = (
        $lines
        | each {|line|
            let w = (als-words $line)
            if ($w | is-empty) { return null }
            let hit = ($ix.by_name | get -o ($w | first))
            if ($hit != null) {
                let a = ($hit | first)
                return {kind: "used", name: $a.name, expansion: $a.expansion, saved: $a.saved}
            }
            let b = (als best $line --index $ix --min-saved 1)
            if ($b == null) { return null }
            {kind: "missed", name: $b.name, expansion: $b.expansion, saved: $b.saved}
        }
        | compact
    )
    let used = ($classified | where kind == "used")
    let missed = ($classified | where kind == "missed")

    {
        schema: $ALS_STATS_SCHEMA
        hostname: (sys host | get hostname)
        aliases: $ix.count
        history: {
            format: ($env.config.history.file_format? | default "unknown")
            entries: ($raw | length)
            analyzed: ($lines | length)
            has_timestamps: $has_ts
        }
        used: {
            commands: ($used | length)
            keystrokes: ($used | get saved | math sum | default 0)
        }
        missed: {
            commands: ($missed | length)
            keystrokes: ($missed | get saved | math sum | default 0)
        }
        top_missed: (als-tally $missed $top)
        top_used: (als-tally $used $top)
    }
}

def als-tally [rows: list<any>, top: int] {
    if ($rows | is-empty) { return [] }
    $rows
    | group-by name
    | transpose alias entries
    | each {|g|
        {
            alias: $g.alias
            expansion: ($g.entries | first | get expansion)
            count: ($g.entries | length)
            keystrokes: ($g.entries | get saved | math sum)
        }
    }
    | sort-by keystrokes --reverse
    | first $top
}

# Aggregate reports across the fleet over ssh.
# Hosts come from $env.ALS_FLEET so the module stays portable.
export def "als fleet-report" [--top: int = 10, --timeout: int = 8] {
    let spec = ($env.ALS_FLEET? | default [])
    let me = (sys host | get hostname)
    let local = (als report --top $top)

    let remote = (
        $spec
        | where {|h| ($h.enabled? | default true) and ($h.name != $me) }
        | par-each {|h|
            # `nu -c` does NOT load config, so aliases would be invisible.
            # The login flag is mandatory here.
            let cmd = ($h.remote? | default "nu -l -c 'als stats --json'")
            let r = (^ssh -o BatchMode=yes -o $"ConnectTimeout=($timeout)" $h.target $cmd | complete)
            if $r.exit_code != 0 {
                {ok: false, host: $h.name, target: $h.target, exit_code: $r.exit_code,
                 error: ($r.stderr | str trim | lines | last | default "ssh failed")}
            } else {
                # Skip any MOTD noise; the report is the last JSON object emitted.
                let body = ($r.stdout | lines | where {|l| $l | str starts-with "{" } | last | default "")
                try {
                    {ok: true, report: ($body | from json)}
                } catch {
                    {ok: false, host: $h.name, target: $h.target, exit_code: 0,
                     error: "unparseable response"}
                }
            }
        }
    )

    let reports = ([$local ...($remote | where ok | get report)])
    {
        schema: $ALS_FLEET_SCHEMA
        hosts: $reports
        unreachable: ($remote | where {|r| not $r.ok } | select host target exit_code error)
        skipped: (
            $spec
            | where {|h| not ($h.enabled? | default true) }
            | each {|h| {host: $h.name, reason: "inactive in vars/hosts.nix"} }
        )
        totals: {
            used: {
                commands: ($reports | get used.commands | math sum)
                keystrokes: ($reports | get used.keystrokes | math sum)
            }
            missed: {
                commands: ($reports | get missed.commands | math sum)
                keystrokes: ($reports | get missed.keystrokes | math sum)
            }
        }
    }
}

def als-render-report [d: record] {
    print (als box $"als · ($d.hostname)" [
        $"(ansi green_bold)($d.used.keystrokes)(ansi reset) keystrokes saved  (ansi dark_gray)\(($d.used.commands) commands\)(ansi reset)"
        $"(ansi red_bold)($d.missed.keystrokes)(ansi reset) keystrokes missed (ansi dark_gray)\(($d.missed.commands) commands\)(ansi reset)"
        $"(ansi dark_gray)($d.aliases) aliases · ($d.history.analyzed) history lines · ($d.history.format)(ansi reset)"
    ])
    if ($d.top_missed | is-not-empty) {
        print ""
        print $"(ansi dark_gray)top missed opportunities:(ansi reset)"
        $d.top_missed | select alias expansion count keystrokes | table | print
    }
}

def als-render-fleet [d: record] {
    $d.hosts | each {|h| als-render-report $h; print "" }
    print (als box "als · fleet total" [
        $"(ansi green_bold)($d.totals.used.keystrokes)(ansi reset) keystrokes saved across ($d.hosts | length) hosts"
        $"(ansi red_bold)($d.totals.missed.keystrokes)(ansi reset) keystrokes missed"
    ])
    if ($d.unreachable | is-not-empty) {
        print ""
        print $"(ansi red)unreachable:(ansi reset)"
        $d.unreachable | table | print
    }
    if ($d.skipped | is-not-empty) {
        print ""
        print $"(ansi dark_gray)skipped:(ansi reset)"
        $d.skipped | table | print
    }
}

export def "als stats" [
    --json          # emit the raw record instead of a rendered report
    --fleet         # aggregate across $env.ALS_FLEET over ssh
    --top: int = 10 # how many entries in the top-N tables
    --timeout: int = 8
] {
    let data = if $fleet {
        als fleet-report --top $top --timeout $timeout
    } else {
        als report --top $top
    }
    if $json {
        $data | to json
    } else if $fleet {
        als-render-fleet $data
    } else {
        als-render-report $data
    }
}

# ─── entry point ────────────────────────────────────────────────────────────

# `--wrapped` is required: reverse queries routinely carry flags, e.g.
# `als git log --oneline`. The cost is that --help must be handled by hand.
export def --wrapped als [...rest] {
    if ($rest | is-empty) { return (als list) }
    if ("-h" in $rest) or ("--help" in $rest) { return (help als) }

    let query = ($rest | str join $ALS_SP)
    let ix = (als index)
    let words = (als-words $query)

    # 1. the query names an alias directly
    let exact = (if ($words | length) == 1 { $ix.by_name | get -o ($words | first) | default [] } else { [] })
    # 2. aliases that are a shorter way to type the query
    let shorter = (als match $query --index $ix --min-saved 1 | sort-by n --reverse)
    # 3. aliases that extend the query
    let related = (als related $query --index $ix)

    if ($exact | is-empty) and ($shorter | is-empty) and ($related | is-empty) {
        print $"(ansi dark_gray)no alias found for(ansi reset) ($query)"
        return
    }

    if ($exact | is-not-empty) {
        print $"(ansi green_bold)alias(ansi reset)"
        als-print-rows $exact
    }
    if ($shorter | is-not-empty) {
        if ($exact | is-not-empty) { print "" }
        print $"(ansi green_bold)shorter(ansi reset)(ansi dark_gray) — you could type this instead(ansi reset)"
        als-print-rows $shorter --savings
    }
    if ($related | is-not-empty) {
        if ($exact | is-not-empty) or ($shorter | is-not-empty) { print "" }
        print $"(ansi green_bold)related(ansi reset)(ansi dark_gray) — aliases that start with this(ansi reset)"
        als-print-rows $related
    }
    null
}
