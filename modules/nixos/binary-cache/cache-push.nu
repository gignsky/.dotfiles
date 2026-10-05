# cache-push — copy locally built closures to the cache host and root them
# there. Never fails the caller for an unreachable cache: it just skips.
#
#   cache-push --to <ssh-host> [--server-host <hostname>] [paths...]
#
# With no paths, pushes this host's current system and home-manager
# generation. Each path is rooted on the server at
# ~/cache-roots/<this-host>-<kind> (kind = basename of the given path), so the
# latest push per host+kind survives the server's GC.

def main [
    --to: string            # ssh host of the cache server (as in ~/.ssh/config)
    --server-host: string   # hostname of the cache server; pushing is skipped there
    ...paths: string
] {
    if $to == null { error make { msg: "--to <ssh-host> is required" } }
    let host = sys host | get hostname
    if $server_host != null and $host == $server_host {
        print "cache-push: this is the cache server, nothing to push"
        return
    }

    let ssh_opts = [-o ConnectTimeout=2 -o BatchMode=yes]
    if (^ssh ...$ssh_opts $to true | complete).exit_code != 0 {
        print $"cache-push: ($to) unreachable, skipping"
        return
    }

    let candidates = if ($paths | is-empty) {
        [
            { kind: system, path: /run/current-system }
            { kind: home, path: ($env.HOME | path join .local/state/home-manager/gcroots/current-home) }
        ]
    } else {
        $paths | each {|p| { kind: ($p | path expand --no-symlink | path basename), path: $p } }
    }

    let targets = $candidates
        | where {|c| $c.path | path exists }
        | each {|c| $c | update path ($c.path | path expand) }
    if ($targets | is-empty) {
        print "cache-push: nothing to push"
        return
    }

    ^ssh ...$ssh_opts $to mkdir cache-roots | complete | ignore
    for t in $targets {
        print $"cache-push: ($t.path) → ($to)"
        ^nix copy --to $"ssh-ng://($to)" $t.path
        ^ssh ...$ssh_opts $to nix-store --realise $t.path --add-root $"cache-roots/($host)-($t.kind)" | ignore
    }
}
