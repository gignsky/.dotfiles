# gc — reclaim nix store space on this host.
#
#   nu scripts/gc.nu [--dry-run] [--older-than 14d] [--keep-results] [--no-optimise]
#
# 1. clean-results: drop dotfiles `result*` links that spacedock already holds.
# 2. Delete old generations of the *system* profile (sudo — the old `just gc`
#    never did this) and of every per-user profile (home-manager, nix profile).
# 3. Collect garbage (skipped on the cache server: a full GC there would evict
#    every un-rooted cached path; it auto-collects under disk pressure instead).
# 4. `nix store optimise` — hard-link identical files.
# 5. WSL only: `fstrim` so freed blocks can be released from the vhdx, then
#    stage scripts/wsl-compact-vhd.ps1 on the Windows side and say how to run it.

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

    if not $keep_results {
        print "── result links"
        if $dry_run {
            nu ($dir | path join scripts/clean-results.nu) --dry-run
        } else {
            nu ($dir | path join scripts/clean-results.nu)
        }
    }

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
        stage-compact $dir $dry_run
    }

    ^df -h /nix | print
    if not $on_wsl and not $dry_run {
        print "note: boot menu entries for deleted generations disappear on the next `just rebuild`."
    }
}

# Copy the compaction script to the Windows side (it must not live on the WSL
# disk: `wsl --shutdown` would pull it out from under PowerShell).
def stage-compact [dir: path, dry_run: bool] {
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
    let q = $"$e = Get-ChildItem HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Lxss | % { Get-ItemProperty $_.PSPath } | ? { $_.DistributionName -eq '($distro)' } | select -First 1; if \($e) { $p = Join-Path \($e.BasePath -replace '^\\\\\\\\\\?\\\\','') 'ext4.vhdx'; [bool]\(\(Get-Item $p).Attributes -band [IO.FileAttributes]::SparseFile) }"
    let sparse = (^powershell.exe -NoProfile -NonInteractive -Command $q | complete | get stdout | str trim) == "True"
    if $sparse {
        print "  The vhdx is sparse, so the fstrim above already returned freed space to Windows."
        print "  Optional full compaction, from an *elevated* PowerShell (closes every WSL session):"
    } else {
        print "  The vhdx only shrinks once WSL is shut down and the disk is compacted."
        print "  From an *elevated* PowerShell on Windows (this closes every WSL session):"
    }
    print $"    powershell -ExecutionPolicy Bypass -File \"($win_home)\\wsl-compact-vhd.ps1\" -Distro ($distro)"
}
