# shellcheck shell=bash
# Content-addressed cache in front of nix-direnv's `use flake`.
#
# nix-direnv invalidates its single cached devShell whenever a watched file
# (flake.nix / flake.lock / .envrc) has a newer *mtime* than the cache. With
# roll-flow, every branch switch, merge, and rebuild commit rewrites those
# files, so we pay a full `nix print-dev-env` eval even when we've already
# evaluated that exact content before.
#
# This wrapper keeps up to $FLAKE_CACHE_SLOTS previously evaluated devShells
# per directory, keyed by a hash of the watched files' *content*. On a hit, it
# restores that env as nix-direnv's current profile and refreshes the rc
# mtime, so nix-direnv takes its "Using cached dev shell" path. On a miss,
# nix-direnv evaluates as usual and we save the result into a new slot.
#
# Every slot is a registered GC root (`nix build --out-link`), so `nix gc`
# can't delete an env we might restore later.

: "${FLAKE_CACHE_SLOTS:=5}"

if declare -f use_flake >/dev/null && ! declare -f _flake_cache_orig_use_flake >/dev/null; then
  eval "_flake_cache_orig_use_flake() $(declare -f use_flake | tail -n +2)"

  use_flake() {
    local flake_expr="${1:-.}"
    local flake_uri="${flake_expr%#*}"
    local flake_dir=${flake_uri#"path:"}

    # Only local flake dirs; anything unusual goes straight to nix-direnv.
    # Preflight also sets $_nix_direnv_nix, which `_nix_add_gcroot` needs.
    if [[ $flake_expr == -* || ! -d $flake_dir || ! -f $flake_dir/flake.nix ]] \
      || ! _nix_direnv_preflight 2>/dev/null; then
      _flake_cache_orig_use_flake "$@"
      return
    fi

    local layout_dir profile profile_rc slots key slot
    layout_dir=$(direnv_layout_dir)
    profile="${layout_dir}/flake-profile$(_nix_argsum_suffix "$flake_expr")"
    profile_rc="${profile}.rc"
    slots="${layout_dir}/flake-cache-slots"

    local -a hashed=("$flake_dir/flake.nix")
    local f
    for f in "$flake_dir/flake.lock" "$flake_dir/devshell.toml" ".envrc"; do
      [[ -f $f ]] && hashed+=("$f")
    done

    key=$({
      printf '%s\0' "$@"
      cat "${hashed[@]}"
    } | sha256sum)
    key=${key:0:32}
    slot="${slots}/${key}"

    # --- Hit: restore the slot as nix-direnv's current cache -------------
    if [[ -e $slot.rc && -e $slot.env ]]; then
      local slot_path
      slot_path=$(readlink -f "$slot.env")
      if [[ -e $slot_path ]]; then
        if [[ $(readlink -f "$profile" 2>/dev/null) != "$slot_path" ]]; then
          _nix_add_gcroot "$slot_path" "$profile" >/dev/null
        fi
        if ! cmp -s "$slot.rc" "$profile_rc"; then
          cp "$slot.rc" "$profile_rc"
        fi
        # Content matches, so tell nix-direnv's mtime check the cache is fresh.
        touch "$profile_rc" "$slot.rc"
      fi
    fi

    _flake_cache_orig_use_flake "$@"
    local rc=$?

    # --- Save: if nix-direnv now holds a fresh cache, remember it --------
    if [[ $rc -eq 0 && -e $profile && -e $profile_rc ]]; then
      local fresh=1
      for f in "${hashed[@]}"; do
        [[ $f -nt $profile_rc ]] && fresh=0
      done
      if [[ $fresh -eq 1 ]]; then
        local profile_path
        profile_path=$(readlink -f "$profile")
        mkdir -p "$slots"
        if [[ $(readlink -f "$slot.env" 2>/dev/null) != "$profile_path" ]]; then
          _nix_add_gcroot "$profile_path" "$slot.env" >/dev/null
        fi
        cmp -s "$profile_rc" "$slot.rc" || cp "$profile_rc" "$slot.rc"

        # LRU prune: keep the N most recently used slots.
        local old
        while IFS= read -r old; do
          rm -f "${old%.rc}.rc" "${old%.rc}.env"
        done < <(ls -1t "$slots"/*.rc 2>/dev/null | tail -n +$((FLAKE_CACHE_SLOTS + 1)))
      fi
    fi

    return $rc
  }
fi
