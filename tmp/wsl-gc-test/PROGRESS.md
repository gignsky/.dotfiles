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

## Still to do
- Not yet tested on a client host (non-server path of clean-results) or on WSL.
- Push the branch, then on WSL: `bash tmp/wsl-gc-test/run.sh`, then `... apply`, then the ps1, then `... post`.
- Check `wsl --set-sparse` support/flags (newer builds may need `--allow-unsafe`) from the diagnose log.
- Delete `tmp/wsl-gc-test/` before graduating.
