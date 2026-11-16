# clean-results — remove `result` / `result-*` out-links from the dotfiles root
# once the binary cache (spacedock) holds them, so the local store can GC them.
#
#   nu scripts/clean-results.nu [--dry-run] [--force] [--no-push]
#
# A link is only removed when spacedock has the *same* store path rooted at
# ~/cache-roots/<this-host>-<link-name> (the root `cache-push` creates). If the
# root is missing or stale, the link is pushed first (unless --no-push) and
# re-checked. On the cache server itself the root is created locally instead,
# so cleaning there never un-roots a cached closure.
#
# Links inside ./worktrees/ are reported but never touched.

def link-names [dir: path] {
    ls -a $dir
    | where type == symlink
    | where {|f| ($f.name | path basename) =~ '^result(-.*)?$' }
    | get name
}

def remote-root [ssh_opts: list<string>, to: string, name: string] {
    let r = ^ssh ...$ssh_opts $to readlink $"cache-roots/($name)" | complete
    if $r.exit_code == 0 { $r.stdout | str trim } else { null }
}

def main [
    --dry-run   # only report what would happen
    --force     # remove links even if the cache copy can't be confirmed
    --no-push   # don't push links that spacedock is missing
] {
    let dir = $env.FILE_PWD | path dirname
    let vars = ^nix eval --json -f ($dir | path join vars/binary-cache.nix) | from json
    let host = sys host | get hostname
    let on_server = $host == $vars.serverHost
    let ssh_opts = [-o ConnectTimeout=3 -o BatchMode=yes]
    let tag = if $dry_run { "[dry-run] " } else { "" }

    let links = link-names $dir
    if ($links | is-empty) {
        print "clean-results: no result links in the dotfiles root"
    }

    let reachable = $on_server or ((^ssh ...$ssh_opts $vars.sshTarget true | complete).exit_code == 0)
    if not $reachable and not $force {
        print $"clean-results: ($vars.sshTarget) unreachable — keeping all result links \(use --force to remove anyway)"
    }

    for link in $links {
        let name = $link | path basename
        let target = $link | path expand
        let root = $"($host)-($name)"

        if not ($target | path exists) {
            print $"($tag)rm ($name) \(dangling)"
            if not $dry_run { rm $link }
            continue
        }

        let safe = if $on_server {
            # The store *is* the cache: root it where pushes are rooted, then drop the link.
            let root_path = $env.HOME | path join cache-roots $root
            print $"($tag)root ($target) at ($root_path)"
            if not $dry_run {
                mkdir ($root_path | path dirname)
                ^nix-store --realise $target --add-root $root_path | ignore
            }
            true
        } else if not $reachable {
            false
        } else {
            mut cached = (remote-root $ssh_opts $vars.sshTarget $root) == $target
            if not $cached and not $no_push {
                print $"($tag)push ($name) → ($vars.sshTarget)"
                if not $dry_run {
                    ^nix run $"($dir)#cache-push" -- --to $vars.sshTarget --server-host $vars.serverHost $link
                    $cached = (remote-root $ssh_opts $vars.sshTarget $root) == $target
                } else {
                    $cached = true
                }
            }
            $cached
        }

        if $safe or $force {
            let why = if $safe { "cached on " + $vars.serverHost } else { "FORCED, not confirmed in cache" }
            print $"($tag)rm ($name) \(($why))"
            if not $dry_run { rm $link }
        } else {
            print $"keep ($name) — not confirmed in cache at cache-roots/($root)"
        }
    }

    let wt = glob ($dir | path join "worktrees/*/result*")
    if not ($wt | is-empty) {
        print "clean-results: these worktree links also pin store paths (not touched):"
        $wt | each {|p| print $"  ($p)" } | ignore
    }
}
