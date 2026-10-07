# cache-watch — build every watched branch/tag head when it changes.
#
# Config (JSON):
#   { stateDir: str,
#     repos: { <name>: { url, flake, branches: [glob], tags: [glob], attrs: [str] } } }
#
# Per repo, state lives in <stateDir>/watch/<name>.json as
#   { <ref>: { sha, ok, at } }
# and roots in <stateDir>/roots/watch/<name>/<ref>@<attr>. A ref is rebuilt only
# when its sha moves (failures are not retried until then), and refs that
# vanish from the remote (merged/deleted roll branches) lose their roots.

# Glob → anchored regex; `*` matches across `/` so `roll/*` covers `roll/a/b`.
def glob-regex [glob: string] {
    let escaped = $glob | str replace -ar '([.+?^${}()|\[\]\\])' '\$1'
    $"^($escaped | str replace -a '*' '.*')$"
}

def matches-any [name: string, globs: list<string>] {
    $globs | any {|g| $name =~ (glob-regex $g) }
}

# Remote heads matching the repo's globs → table<ref, sha>. For annotated
# tags the peeled `^{}` entry wins, since `?rev=` needs a commit, not a tag object.
def remote-refs [repo: record] {
    let r = ^git ls-remote $repo.url | complete
    if $r.exit_code != 0 { error make { msg: $"ls-remote ($repo.url) failed: ($r.stderr)" } }
    let all = $r.stdout | lines | parse "{sha}\t{full}"

    let branches = $all
        | where full starts-with "refs/heads/"
        | each {|e| { ref: ($e.full | str replace "refs/" ""), name: ($e.full | str replace "refs/heads/" ""), sha: $e.sha } }
        | where {|e| matches-any $e.name $repo.branches }

    let tags = $all
        | where full starts-with "refs/tags/"
        | each {|e|
            let peeled = $e.full | str ends-with "^{}"
            let full = $e.full | str replace "^{}" ""
            { ref: ($full | str replace "refs/" ""), name: ($full | str replace "refs/tags/" ""), sha: $e.sha, peeled: $peeled }
        }
        | where {|e| matches-any $e.name $repo.tags }
        | group-by ref
        | values
        | each {|g| $g | sort-by peeled --reverse | first | reject peeled }

    $branches | append $tags | select ref sha
}

def root-name [ref: string, attr: string] {
    $"($ref | str replace -a '/' '_')@($attr)"
}

def watch-repo [name: string, repo: record, state_dir: string] {
    let state_file = $state_dir | path join watch $"($name).json"
    let roots = $state_dir | path join roots watch $name
    mkdir ($state_file | path dirname) $roots

    let state = if ($state_file | path exists) { open $state_file } else { {} }
    let current = remote-refs $repo

    mut next = {}
    mut failures = 0
    for e in $current {
        let prev = $state | get -o $e.ref
        if $prev != null and $prev.sha == $e.sha {
            $next = $next | insert $e.ref $prev
            continue
        }
        print $"==> ($name) ($e.ref) @ ($e.sha | str substring 0..<12)"
        let results = $repo.attrs | each {|attr|
            let link = $roots | path join (root-name $e.ref $attr)
            let r = ^nix build $"($repo.flake)?rev=($e.sha)#($attr)" --out-link $link | complete
            if $r.exit_code != 0 { print -e $r.stderr }
            $r.exit_code == 0
        }
        let ok = $results | all {|x| $x }
        if not $ok { $failures += 1 }
        $next = $next | insert $e.ref { sha: $e.sha, ok: $ok, at: (date now | format date "%+") }
    }

    # Drop roots + state for refs that no longer exist (or no longer match).
    let keep = $current.ref | each {|ref| $repo.attrs | each {|attr| root-name $ref $attr } } | flatten
    ls -a $roots
        | where {|f| ($f.name | path basename) not-in $keep }
        | each {|f| print $"pruning ($f.name | path basename)"; rm $f.name }

    $next | to json | save -f $state_file
    $failures
}

def main [config: path] {
    let cfg = open $config
    let failures = $cfg.repos | transpose name repo | each {|r|
        try { watch-repo $r.name $r.repo $cfg.stateDir } catch {|err| print -e $err.msg; 1 }
    } | math sum
    if $failures > 0 {
        print -e $"($failures) ref\(s\) failed to build"
        exit 1
    }
}
