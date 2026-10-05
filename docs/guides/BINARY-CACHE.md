# Fleet Binary Cache

Spacedock serves its `/nix/store` as a signed binary cache (Harmonia) on the
LAN, so expensive builds like roll-flow, gigvim and claude-desktop are
compiled once and then downloaded by every other host.

```
               ┌──────────── spacedock ────────────┐
 push (nix copy│  binary-cache-build  (nightly)    │  http://192.168.51.2:5000
 over ssh-ng)  │  binary-cache-watch  (every 5m)   │ ─────────────────────────▶ merlin, ganoslal, wsl
 ─────────────▶│  harmonia ── signs ── /nix/store  │      (extra-substituter)
               └───────────────────────────────────┘
```

| Piece | Where |
|---|---|
| Module (host-agnostic) | `modules/nixos/binary-cache/` |
| Scripts (`cache-build`, `cache-watch`, `cache-push`) | `modules/nixos/binary-cache/*.nu`, packaged by `package.nix` |
| Fleet values (URL, public key) | `vars/binary-cache.nix` |
| Client wiring (all hosts) | `hosts/common/core/binary-cache.nix` |
| Server wiring | `hosts/spacedock/binary-cache.nix` |
| Recipes | `just cache-push`, `just cache-poke`, `just cache-status` |

## How the cache gets filled

1. **Builder:** `binary-cache-build.timer` runs nightly. It builds
   `binaryCache.builder.targets` and roots each result at
   `/var/lib/binary-cache/roots/build/<name>`. The targets are the big gigpkgs
   packages on `gigos-2605` and `gigos-unstable`. Once a deploy key exists (see
   below), it also builds each active host's system and home closure from
   dotfiles `main`.
2. **Watcher:** `binary-cache-watch.timer` runs every 5 minutes. It runs
   `git ls-remote` against roll-flow, and builds every `main`, `develop`,
   `roll/*` and `v*` head whose SHA has changed, no matter which machine
   pushed it.
   - Run `just cache-poke` right after a push to skip the wait.
   - When a branch is deleted or merged away, its root is removed on the next run.
   - A failed build isn't retried until that ref's SHA changes.
3. **Pushes:** `just rebuild`, `just home` and `just build` finish with
   `just cache-push`. That `nix copy`s the result to spacedock and roots it as
   `~gig/cache-roots/<host>-<kind>`.
   - If spacedock is unreachable it skips, and it never fails the rebuild.

### Why the watcher's builds hit for gigpkgs

gigpkgs pins roll-flow (`roll-flow`, `roll-flow-0.2.5`, `roll-flow-0.2.6-dev`)
**without** `inputs.nixpkgs.follows`. Each pin therefore uses roll-flow's own
`flake.lock`, so `github:gignsky/roll-flow?rev=<sha>#default` is the same
derivation that gigpkgs and this repo's devShell evaluate. This was checked on
2026-10-05: the `.drv` paths matched across all four.

**If gigpkgs ever adds `follows` to a roll-flow input, this stops being true.**
At that point, watch gigpkgs `roll/*` instead, or add gigpkgs attrs to
`builder.targets`.

## Retention

Spacedock has no timed GC. Nix auto-collects only when free space drops below
`min-free` (20G), and stops once `max-free` (60G) is free again. These survive
collection:
- builder roots;
- watcher roots, one per live ref;
- each host's latest pushed system and home;
- spacedock's own generations.

Everything else stays cached until disk pressure evicts it.

## One-time setup

1. **Signing key.** Run this on spacedock, or anywhere, and keep the secret
   out of shell history and logs:
   ```nu
   nix key generate-secret --key-name spacedock-cache-1 | save -f /tmp/cache.sec
   open /tmp/cache.sec | nix key convert-secret-to-public
   ```
   - `just sops` → add `binary-cache: { spacedock-signing-key: <contents of /tmp/cache.sec> }`, then `rm /tmp/cache.sec`.
   - Put the printed public key in `vars/binary-cache.nix` → `publicKey`.
2. **Switch spacedock first** (`just rebuild` on spacedock). Then check
   `just cache-status`.
3. **Switch the clients.** They only add the substituter once `publicKey` is
   set; until then they print a warning and carry on as before.
4. **Optional: deploy key for host closures.** Create a read-only GitHub
   deploy key, add it to both `gignsky/.dotfiles` and `gignsky/nix-secrets`,
   and store the private half at `binary-cache/builder-github-key`. Then set
   `haveDeployKey = true` in `hosts/spacedock/binary-cache.nix`.

### Rotating the key

Generate `spacedock-cache-2`. For one rebuild cycle, list **both** public keys
(`binaryCache.publicKey` takes one, so add the old one to
`nix.settings.extra-trusted-public-keys` temporarily). Then swap the secret,
switch spacedock, and drop the old key.

## Trust model

- Clients trust only paths signed by `spacedock-cache-1`.
- Harmonia signs whatever is in spacedock's store, so anything that can write
  to that store can feed the fleet:
  - root;
  - `trustedPushers`, which is `gig`;
  - the builder and watcher, which can only build pinned refs from the
    configured repos.
- `gig` is a `trusted-user` on spacedock **only**. That setting is
  root-equivalent there.
- Traffic is plain HTTP on the LAN. Integrity comes from the signatures, not
  from TLS.

## Troubleshooting

- `journalctl -u binary-cache-watch -u binary-cache-build` on spacedock, or `just cache-status`.
- Watch state: `sudo cat /var/lib/binary-cache/watch/roll-flow.json`, a map of ref → `{sha, ok, at}`. Delete an entry to force a rebuild.
- If a client is slow off the LAN: `connect-timeout` is 3s, and Nix stops trying a dead substituter for the rest of that invocation.
- To check a path is served and signed: `nix path-info --store http://192.168.51.2:5000 --sigs <path>`.

## Extraction / upstream path

The module was written to move into gigpkgs unchanged:
- no hosts, addresses, repos or secret backend inside `modules/nixos/binary-cache/`;
- everything comes in through options.

Steps to extract:
1. Copy `modules/nixos/binary-cache/` to `gigpkgs/modules/nixos/binary-cache/`.
   It is auto-discovered there, and becomes `inputs.nixpkgs.nixosModules.binary-cache` here.
2. Rename the option namespace `binaryCache` → `gigpkgs.binaryCache`, to match
   `gigpkgs.containers`.
3. Move `package.nix` and the `.nu` scripts into `gigpkgs/pkgs/programs/` so
   they appear in `legacyPackages`. The module then refers to `pkgs.cache-*`
   instead of `callPackage ./package.nix`.
4. Here: delete the local module, import the gigpkgs one in
   `hosts/common/core/binary-cache.nix`, and drop the `cache-*` entries from
   `pkgs/default.nix`.
5. Later, for a public or Tailscale cache: once spacedock is reachable from
   GitHub Actions, gigpkgs and roll-flow CI could push directly. That needs a
   pusher credential, which is the point to reconsider Attic over Harmonia.
