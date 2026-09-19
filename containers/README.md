# containers/

Container definitions migrated from the standalone
[`GeeM-Enterprises/dot-spacedock`](https://github.com/GeeM-Enterprises/dot-spacedock)
flake as part of the spacedock onboarding (dotfiles#14).

Two mechanisms are preserved — a container can run **as a service** or **adhoc** —
split hybrid-style: the generic *engine* lives in **gigpkgs**
(`gigpkgs.nixosModules.containers` → the `gigpkgs.containers.*` options), and the
spacedock-specific *payloads* live here as data.

## As a service — `containers/services/`

systemd-managed OCI containers via `virtualisation.oci-containers`.

- `services/default.nix` — the aggregator. A payload runs iff it is imported here.
- `services/pihole.nix` (+ `pihole-config.nix`) — **enabled**. Pi-hole DNS replica
  on `192.168.51.2` (`:53`, web UI `:1702`) plus a nebula-sync oneshot + 4 h timer
  that clones blocklists, groups, clients and DNS config from the master on
  memory-alpha (`192.168.51.3:20720`). The API password is a sops secret
  (`pihole/api-password`), injected via `environmentFiles`, never in the store.
  Sync is **selective, not `FULL_SYNC`** — see the reasoning in `pihole.nix`.
- `services/tdarr-node.nix` — **enabled**. Tdarr transcode node (CIFS mounts +
  samba creds).
- `services/avec-moi-app.nix` — **enabled**. Static slide deck on `:8081`.

Toggle one by commenting its import in/out of `services/default.nix`. The host must
import `containers/services` (spacedock does) and have the engine on:

```nix
gigpkgs.containers = {
  enable = true;
  backend = "podman";   # or "docker"
  adhoc.enable = true;
};
```

You can also declare a service inline through the engine instead of a payload file:

```nix
gigpkgs.containers.services.myapp = {
  image = "docker.io/library/nginx:latest";
  ports = [ "8080:80" ];
};
```

⚠️ These payloads hardcode LAN IPs (`192.168.51.x`) — confirm them before reusing
this on another network. Secrets must go through sops-nix and reach the container
via `environmentFiles`, never through `environment` (which lands in the
world-readable nix store); `services/pihole.nix` is the worked example.

## Adhoc — `containers/buzz/`, `containers/mini/`

`nixos-generators`-built OCI images plus podman/docker runner scripts, for
building and running containers by hand (`nix run .#buzz`, etc.).

- `buzz/` — "spacedock replication" image (Docker + Podman runner variants).
- `mini/` — minimal NixOS base image for `dockerTools.buildLayeredImage`.

These are **not wired into flake outputs**. To expose them, add a
`nixos-generators` input to `flake.nix` (`inputs.nixpkgs.follows = "nixpkgs"`)
and surface the module's `packages` / `nixosConfigurations`, e.g.:

```nix
# in flake.nix let-bindings
buzz = import ./containers/buzz { inherit inputs lib system; };
# then, in outputs:
packages.${system} = customPkgs // buzz.packages;
nixosConfigurations.buzz = buzz.nixosConfiguration;
```
