# gc — reclaim nix store space on this host.
#
#   nu scripts/gc.nu [--dry-run] [--older-than 14d] [--keep-results] [--no-optimise]
#                    [--direnv-days 7] [--keep-direnv]
#
# 1. clean-results: drop dotfiles `result*` links that spacedock already holds.
#    Then drop nix-direnv caches (dev shells + pinned flake inputs) of projects
#    not entered for --direnv-days days; they pin far more of the store than the
#    system does. direnv rebuilds them the next time you cd into the project.
# 2. Delete old generations of the *system* profile (sudo — the old `just gc`
#    never did this) and of every per-user profile (home-manager, nix profile).
# 3. Collect garbage (skipped on the cache server: a full GC there would evict
#    every un-rooted cached path; it auto-collects under disk pressure instead).
# 4. `nix store optimise` — hard-link identical files.
# 5. WSL only: `fstrim` so freed blocks can be released from the vhdx, then
#    stage scripts/wsl-compact-vhd.ps1 on the Windows side and say how to run it.
# 6. Summary: space freed on the /nix filesystem (and, on WSL, how much the
#    ext4.vhdx shrank on the Windows drive).

def profiles [] {
    let user_dirs = [
        ($env.HOME | path join .local/state/nix/profiles)
        $"/nix/var/nix/profiles/per-user/($env.USER)"
    ]
    let user = $user_dirs
        | where {|d| $d | path exists }
        | each {|d| ls -a $d | where type == symlink | get name }
        | flatten
        | where {|p| not (($p | path basename) =~ '-\d+-link$') }
        | each {|p| { path: $p, sudo: false } }
    [{ path: /nix/var/nix/profiles/system, sudo: true }] ++ $user
}

def --wrapped run [tag: string, dry_run: bool, sudo: bool, ...cmd: string] {
    let full = if $sudo { [sudo] ++ $cmd } else { $cmd }
    print $"($tag)$ ($full | str join ' ')"
    if not $dry_run { run-external ...$full }
}

def main [
    --dry-run              # report only; nothing is deleted
    --older-than: string   # keep generations newer than this (e.g. 14d); default: keep only current
    --keep-results         # don't run clean-results first
    --no-optimise          # skip `nix store optimise`
    --no-trim              # WSL: skip fstrim
    --direnv-days: int = 7 # drop nix-direnv caches of projects unused for this many days
    --keep-direnv          # don't touch nix-direnv caches
] {
    let dir = $env.FILE_PWD | path dirname
    let vars = ^nix eval --json -f ($dir | path join vars/binary-cache.nix) | from json
    let host = sys host | get hostname
    let on_server = $host == $vars.serverHost
    let on_wsl = ("/proc/sys/fs/binfmt_misc/WSLInterop" | path exists) or ("WSL_DISTRO_NAME" in $env)
    let tag = if $dry_run { "[dry-run] " } else { "" }
    let gens = if $older_than == null { "old" } else { $older_than }

    print $"── gc on ($host)(if $on_server { ' (cache server)' } else { '' })(if $on_wsl { ' (WSL)' } else { '' })"
    ^df -h /nix | print
    let used_before = used-bytes
    let vhd_before = if $on_wsl { vhd-info $dir } else { null }

    if not $keep_results {
        print "── result links"
        if $dry_run {
            nu ($dir | path join scripts/clean-results.nu) --dry-run
        } else {
            nu ($dir | path join scripts/clean-results.nu)
        }
    }

    if not $keep_direnv { prune-direnv $direnv_days $dry_run }

    print $"── generations \(deleting: ($gens))"
    for p in (profiles) {
        let n = ls -a ($p.path | path dirname)
            | where {|f| ($f.name | path basename) =~ $'^(($p.path | path basename))-\d+-link$' }
            | length
        print $"  ($p.path): ($n) generations"
        run $tag $dry_run $p.sudo nix-env --profile $p.path --delete-generations $gens
    }

    print "── garbage collection"
    if $on_server {
        print "  skipped on the cache server (would evict un-rooted cached paths)"
    } else if $dry_run {
        let r = ^nix-store --gc --print-dead | complete
        print $"  ($r.stdout | lines | length) store paths currently dead \(more after generations are deleted)"
    } else {
        run $tag $dry_run true nix-store --gc
    }

    if not $no_optimise {
        print "── optimise"
        run $tag $dry_run true nix-store --optimise
    }

    if $on_wsl {
        print "── WSL disk"
        if not $no_trim { run $tag $dry_run true fstrim -v / }
        stage-compact $dir $dry_run $vhd_before
    }

    ^df -h /nix | print
    if not $on_wsl and not $dry_run {
        print "note: boot menu entries for deleted generations disappear on the next `just rebuild`."
    }

    print "── summary"
    if $dry_run {
        print "  dry run — nothing was freed"
        return
    }
    let used_after = used-bytes
    print $"  /nix filesystem: (gib $used_before) → (gib $used_after) used — freed (gib ($used_before - $used_after))"
    if $vhd_before != null {
        let vhd_after = vhd-info $dir
        if $vhd_after != null {
            print $"  ext4.vhdx on Windows: (gib $vhd_before.allocated) → (gib $vhd_after.allocated) on disk — released (gib ($vhd_before.allocated - $vhd_after.allocated))"
            let slack = $vhd_after.allocated - $used_after
            if $slack > 10 * 1073741824 {
                print $"  note: the vhdx holds (gib $slack) more than ext4 uses. Trim only returns vhdx blocks that are"
                print "  entirely free, so blocks left half-full by deleted store paths stay allocated. Only rewriting"
                print "  the disk packs them back together: wsl --export the distro, then wsl --unregister + wsl --import it."
            }
        }
    }
}

# nix-direnv keeps a GC root per project: .direnv/flake-profile-<hash>
# (the dev shell) and .direnv/flake-inputs/* (every flake input). Remove only
# those, so anything else a project keeps in .direnv (venvs, etc.) survives.
# "Last used" is the newest atime/mtime of the cached .rc: direnv reads it on
# every load, and relatime updates atime at least once a day.
def prune-direnv [days: int, dry_run: bool] {
    print $"── direnv caches \(unused for ($days)+ days)"
    let now = date now | into int | $in / 1_000_000_000
    let dirs = ^nix-store --gc --print-roots | complete | get stdout | lines
        | where {|l| not ($l starts-with '"/proc') and not ($l starts-with '/proc') }
        | parse -r '^"?(?<d>[^"]*?/\.direnv)/'
        | get d | uniq | where {|d| $d | path exists }
    if ($dirs | is-empty) { print "  none found"; return }
    let rows = $dirs | each {|d|
        # Only the .rc: listing the dir or resolving the root symlinks (as
        # print-roots just did) bumps their atime too.
        let rc = ^find $d -maxdepth 1 -name 'flake-profile-*.rc' -printf '%A@\n%T@\n' | lines
        let last = if ($rc | is-empty) {
            ^stat -c '%Y' $d | into float
        } else { $rc | into float | math max }
        { dir: $d, idle: (($now - $last) / 86400 | math floor) }
    } | sort-by idle --reverse
    for r in $rows {
        let stale = $r.idle >= $days
        let project = $r.dir | path dirname | str replace $env.HOME '~'
        print $"  (if $stale { 'drop' } else { 'keep' })  ($r.idle | fill -a r -w 4)d  ($project)"
        if $stale and not $dry_run {
            let targets = ls -a $r.dir | get name
                | where {|n| ($n | path basename) =~ '^(flake-profile-.*|flake-inputs)$' }
            rm -rf ...$targets
        }
    }
}

def used-bytes []: nothing -> int {
    ^df --output=used -B1 /nix | lines | last | str trim | into int
}

def gib [b: int]: nothing -> string {
    let r = $b / 1073741824 | math round --precision 1
    $"(if $r == 0 { 0.0 } else { $r }) GiB"
}

# Size of this distro's ext4.vhdx as seen from Windows ({path, sparse, length,
# allocated}), or null when PowerShell interop is unavailable. The helper is
# copied to the Windows temp dir because powershell.exe won't run scripts from
# the \\wsl$ share without prompting.
def vhd-info [dir: path] {
    let distro = $env.WSL_DISTRO_NAME? | default NixOS
    let r = ^powershell.exe -NoProfile -NonInteractive -Command '$env:TEMP' | complete
    if $r.exit_code != 0 { return null }
    let win_tmp = $r.stdout | str trim
    let dest = (^wslpath -u $win_tmp | str trim) | path join wsl-vhd-info.ps1
    cp ($dir | path join scripts/wsl-vhd-info.ps1) $dest
    let q = ^powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $"($win_tmp)\\wsl-vhd-info.ps1" -Distro $distro | complete
    if $q.exit_code != 0 { return null }
    try { $q.stdout | str trim | from json } catch { null }
}

# Copy the compaction script to the Windows side (it must not live on the WSL
# disk: `wsl --shutdown` would pull it out from under PowerShell).
def stage-compact [dir: path, dry_run: bool, vhd: any] {
    let distro = $env.WSL_DISTRO_NAME? | default NixOS
    let r = ^powershell.exe -NoProfile -NonInteractive -Command '$env:USERPROFILE' | complete
    if $r.exit_code != 0 {
        print "  powershell.exe unavailable (WSL interop off?) — copy scripts/wsl-compact-vhd.ps1 to Windows manually"
        return
    }
    let win_home = $r.stdout | str trim
    let dest = (^wslpath -u $win_home | str trim) | path join wsl-compact-vhd.ps1
    if not $dry_run { cp ($dir | path join scripts/wsl-compact-vhd.ps1) $dest }
    print $"  staged ($dest)"
    print ""
    # A sparse vhdx hands trimmed blocks back to Windows on its own; compaction is then optional.
    if ($vhd != null) and $vhd.sparse {
        print "  The vhdx is sparse, so the fstrim above already returned freed space to Windows."
        print "  Optional full compaction, from an *elevated* PowerShell (closes every WSL session):"
    } else {
        print "  The vhdx only shrinks once WSL is shut down and the disk is compacted."
        print "  From an *elevated* PowerShell on Windows (this closes every WSL session):"
    }
    print $"    powershell -ExecutionPolicy Bypass -File \"($win_home)\\wsl-compact-vhd.ps1\" -Distro ($distro)"
}
