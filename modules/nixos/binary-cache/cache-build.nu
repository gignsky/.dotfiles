# cache-build — build a fixed set of installables and keep each GC-rooted.
#
# Config (JSON): { stateDir: str, targets: { <name>: <installable> } }
# Roots live at <stateDir>/roots/build/<name>; roots for names no longer in
# the config are removed so their closures become collectable.

def main [config: path] {
    let cfg = open $config
    let roots = $cfg.stateDir | path join roots build
    mkdir $roots

    let targets = $cfg.targets | transpose name ref
    let results = $targets | each {|t|
        print $"==> ($t.name): ($t.ref)"
        let r = ^nix build $t.ref --out-link ($roots | path join $t.name) | complete
        if $r.exit_code != 0 { print -e $r.stderr }
        { name: $t.name, ok: ($r.exit_code == 0) }
    }

    # Prune roots of targets that were dropped from the config.
    ls -a $roots
        | where {|f| ($f.name | path basename) not-in $targets.name }
        | each {|f| print $"pruning ($f.name)"; rm $f.name }

    let failed = $results | where ok == false
    print $"built ($results | length) targets, ($failed | length) failed"
    if ($failed | is-not-empty) {
        print -e $"failed: ($failed.name | str join ', ')"
        exit 1
    }
}
