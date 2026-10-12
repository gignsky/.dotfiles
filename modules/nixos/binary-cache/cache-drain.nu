# cache-drain — upload the paths the post-build hook queued, then forget them.
#
#   cache-drain --queue-dir <dir> --to <store-uri>
#
# The hook appends output paths to <dir>/queue. This claims that file
# (rename, so the hook keeps appending to a fresh one), merges it with
# anything left in <dir>/retry, drops paths that were garbage-collected in
# the meantime, and `nix copy`s the rest. If the copy fails (cache off the
# LAN, server down) the paths go back to <dir>/retry for the timer to try
# again. It never touches <dir>/queue on failure, so the path unit watching
# it doesn't spin while the cache is unreachable.

def main [
    --queue-dir: string   # directory holding `queue` (written by the hook) and `retry`
    --to: string          # destination store URI, e.g. ssh-ng://user@host?ssh-key=…
] {
    if $queue_dir == null or $to == null {
        error make { msg: "--queue-dir and --to are required" }
    }
    let queue = $queue_dir | path join queue
    let retry = $queue_dir | path join retry

    # Claim new entries. Leftover work-* files are from an interrupted run.
    if ($queue | path exists) {
        mv -f $queue ($queue_dir | path join $"work-(date now | format date '%s%f')")
    }
    let work = glob ($queue_dir | path join "work-*")
    let sources = $work | append (if ($retry | path exists) { [$retry] } else { [] })
    if ($sources | is-empty) { return }

    let paths = $sources
        | each {|f| open --raw $f | split row -r '\s+' }
        | flatten
        | where {|p| $p starts-with "/nix/store/" and ($p | path exists) }
        | uniq

    if ($paths | is-empty) {
        $sources | each {|f| rm -f $f } | ignore
        return
    }

    print $"cache-drain: copying ($paths | length) paths → ($to)"
    # Chunked so a long build session can't overflow the argument list.
    let failed = $paths
        | chunks 500
        | each {|chunk|
            let r = ^nix copy --no-check-sigs --to $to ...$chunk | complete
            if $r.exit_code != 0 {
                print --stderr $"cache-drain: copy failed: ($r.stderr | str trim)"
                $chunk
            } else { [] }
        }
        | flatten

    $work | each {|f| rm -f $f } | ignore
    if ($failed | is-empty) {
        rm -f $retry
    } else {
        print $"cache-drain: ($failed | length) paths kept for retry"
        $failed | str join "\n" | save -f $retry
    }
}
