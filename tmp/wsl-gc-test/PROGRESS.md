# better clean + gc — progress (2026-11-11, paused)

## Done
- `scripts/clean-results.nu`: removes `result`/`result-*` links in the dotfiles root only
  when spacedock has the same store path rooted at `~/cache-roots/<host>-<name>`.
  Pushes missing ones first. On spacedock it roots them locally. Supports `--dry-run`, `--force` and `--no-push`.
  Reports worktree result links without touching them. Dry-run tested on spacedock: OK.
- `scripts/gc.nu`: clean-results, then delete old generations of the system profile (sudo; the old gc
  never did this, and spacedock alone has 245 system gens), then the user profiles,
  then `nix-store --gc` (skipped on the cache server), then optimise. On WSL it also runs fstrim and stages the ps1.
  Dry-run tested on spacedock: OK.
- `scripts/wsl-compact-vhd.ps1`: elevated Windows script. It finds the vhdx via the Lxss registry,
  runs `wsl --shutdown`, then Optimize-VHD or diskpart compact. `-Sparse` is optional. It logs to `%USERPROFILE%`.
- justfile: `clean` calls clean-results. `gc *args` now runs gc.nu (with sudo-keepalive).
  New recipe: `clean-results`.
- `tmp/wsl-gc-test/run.sh`: runs on WSL with `diagnose` | `apply` | `post`. Logs go to results/ and only
  this folder gets committed and pushed.

## WSL test (2026-11-11, run directly on WSL in-session)
- Diagnose: WSL 2.7.8, Optimize-VHD available, `--set-sparse` listed (no `--allow-unsafe`).
  vhdx was **already sparse** but had 232.5 GB allocated against 177 GB used.
- Dry runs of clean-results and gc ran OK on the client path. All 8 result links were confirmed on spacedock.
- `just gc` applied: 218 system generations deleted, 127k paths / 57.6 GiB freed, optimise 0.7 GiB,
  fstrim 862 GiB. df went from 177G to 112G.
- vhdx allocation after fstrim alone (no shutdown): 232.5 GB to **178.5 GB**. Sparse + fstrim reclaims without the ps1.
- Fixes: harness exports `WSLENV=WSL_UTF8` (without it wsl.exe printed UTF-16 and broke the sparse grep);
  harness reports the sparse flag; the ps1 logs the sparse state and skips `--set-sparse` if already set.

- gc.nu now checks the vhdx sparse flag. When it's set, the ps1 is presented as optional (tested via dry run).

## Still to do
- Optional: run the ps1 (elevated) for a full Optimize-VHD pass, then `bash tmp/wsl-gc-test/run.sh post`.
- Not yet tested on a non-server, non-WSL client (merlin/ganoslal) with result links that need pushing.
- Delete `tmp/wsl-gc-test/` before graduating.
