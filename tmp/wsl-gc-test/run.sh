#!/usr/bin/env bash
# Temporary WSL test harness for `just clean` / `just gc` (roll/166-1111-better-clean-and-gc).
# Delete this folder once the branch graduates.
#
# Run from the dotfiles root on WSL. Every run logs to tmp/wsl-gc-test/results/
# and commits + pushes ONLY that folder to the current branch.
#
#   bash tmp/wsl-gc-test/run.sh            # 1. diagnose — read-only + dry runs
#   bash tmp/wsl-gc-test/run.sh apply      # 2. real `just gc` with before/after sizes
#   (Windows, elevated) wsl-compact-vhd.ps1  # 3. printed by step 2; shuts WSL down
#   bash tmp/wsl-gc-test/run.sh post       # 4. after WSL restarts: collect compaction log + new vhdx size
set -uo pipefail

MODE="${1:-diagnose}"
ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$ROOT" || exit 1
DIR="tmp/wsl-gc-test"
BRANCH="$(git branch --show-current)"
case "$BRANCH" in main | rolling | "")
	echo "refusing to commit test logs to '$BRANCH'"
	exit 1
	;;
esac
case "$MODE" in diagnose | apply | post) ;; *)
	echo "usage: $0 [diagnose|apply|post]"
	exit 1
	;;
esac

mkdir -p "$DIR/results"
LOG="$DIR/results/$(date +%Y%m%d-%H%M%S)-$(hostname)-$MODE.log"
exec 3>&1 4>&2
exec > >(tee -a "$LOG") 2>&1
TEE_PID=$!
export WSL_UTF8=1 WSLENV="WSL_UTF8${WSLENV:+:$WSLENV}"  # WSLENV forwards it to wsl.exe

section() { printf '\n===== %s =====\n' "$*"; }
run() {
	printf '\n$ %s\n' "$*"
	"$@"
	echo "[exit $?]"
}
ps() { powershell.exe -NoProfile -NonInteractive -Command "$1" 2>&1 | tr -d '\r'; }

vhdx_size() {
	section "vhdx on Windows"
	ps '$d=$env:WSL_DISTRO_NAME; Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | % { Get-ItemProperty $_.PSPath } | % { $p = Join-Path ($_.BasePath -replace "^\\\\\?\\","") "ext4.vhdx"; $s = if (Test-Path $p) { "{0:N1} GB" -f ((Get-Item $p).Length/1GB) } else { "missing" }; $sp = if ((Test-Path $p) -and ((Get-Item $p).Attributes -band [IO.FileAttributes]::SparseFile)) { "sparse" } else { "-" }; "{0}`t{1}`t{2}`t{3}" -f $_.DistributionName,$s,$sp,$p }'
}

disk() {
	section "disk usage inside WSL"
	run df -h / /nix
	run sudo du -xsh /nix/store /home /var /tmp /root
	run sudo du -xsh /var/lib/* --threshold=1G
	run du -xsh "$HOME"/.cache "$HOME"/.local/share "$HOME"/.cargo "$HOME"/local_repos --threshold=1G
}

echo "mode=$MODE branch=$BRANCH host=$(hostname) distro=${WSL_DISTRO_NAME:-?} date=$(date -Is)"
echo "commit=$(git rev-parse --short HEAD)"

case "$MODE" in
diagnose)
	vhdx_size
	disk
	section "windows / wsl tooling"
	run wsl.exe --version
	echo "--- sparse support in wsl --help:"
	wsl.exe --help 2>&1 | tr -d '\r' | grep -i -A2 -- 'sparse' || echo "(no --set-sparse in this WSL build)"
	echo "--- Optimize-VHD available:"
	ps 'if (Get-Command Optimize-VHD -ErrorAction SilentlyContinue) { "yes" } else { "no (diskpart fallback)" }'
	echo "--- .wslconfig:"
	ps 'Get-Content "$env:USERPROFILE\.wslconfig" -ErrorAction SilentlyContinue'
	section "generations"
	for p in /nix/var/nix/profiles/system "$HOME"/.local/state/nix/profiles/*[!0-9k] /nix/var/nix/profiles/per-user/"$USER"/*[!0-9k]; do
		[ -L "$p" ] || continue
		echo "$p: $(ls -d "$p"-*-link 2>/dev/null | wc -l) generations"
	done
	section "gc roots (excluding /proc and profiles)"
	nix-store --gc --print-roots 2>/dev/null | grep -v -e '^/proc/' -e '/profiles/' | sort | head -100
	section "dead paths right now"
	echo "$(nix-store --gc --print-dead 2>/dev/null | wc -l) dead store paths"
	section "other big consumers"
	run sudo journalctl --disk-usage
	command -v docker >/dev/null && run sudo docker system df
	run sudo du -sh /var/lib/postgresql /var/lib/redis*
	section "dry run: clean-results"
	run nu scripts/clean-results.nu --dry-run
	section "dry run: gc"
	run nu scripts/gc.nu --dry-run
	;;
apply)
	vhdx_size
	run df -h /
	section "just gc"
	run just gc
	section "after"
	run df -h /
	vhdx_size
	echo
	echo "NEXT: run the PowerShell command printed above (elevated, on Windows),"
	echo "      then reopen WSL and run: bash $DIR/run.sh post"
	;;
post)
	section "compaction log from Windows"
	ps 'Get-Content "$env:USERPROFILE\wsl-compact-vhd.log" -ErrorAction SilentlyContinue'
	vhdx_size
	run df -h /
	;;
esac

exec 1>&3 2>&4
wait "$TEE_PID" 2>/dev/null
# Commit and push only this folder.
{
	git add -- "$DIR"
	git commit --no-verify -m "test(wsl-gc): $MODE results from $(hostname)" -- "$DIR"
	git pull --rebase --autostash origin "$BRANCH"
	git push origin "$BRANCH"
} || echo "commit/push failed — log is at $LOG"
