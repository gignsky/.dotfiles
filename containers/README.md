# containers/

Container definitions migrated from the standalone
[`GeeM-Enterprises/dot-spacedock`](https://github.com/GeeM-Enterprises/dot-spacedock)
flake as part of the spacedock onboarding (dotfiles#14).

Two mechanisms are preserved — a container can run **as a service** or **adhoc** —
split hybrid-style: the generic *engine* lives in **gigpkgs**
(`gigpkgs.nixosModules.containers` → the `gigpkgs.containers.*` options), and the
spacedock-specific *payloads* live here as data. **Everything here is disabled by
default.**

## As a service — `containers/services/`

systemd-managed OCI containers via `virtualisation.oci-containers`.

- `services/default.nix` — aggregator; imports **nothing** until you uncomment a payload.
- `services/pihole.nix` (+ `pihole-config.nix`) — Pi-hole + nebula-sync.
- `services/tdarr-node.nix` — Tdarr transcode node (needs CIFS mounts + samba creds).

Enable one by uncommenting its import in `services/default.nix`. The host must
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

⚠️ The ported payloads carry placeholder secrets (e.g. Pi-hole `WEBPASSWORD`) and
hardcoded LAN IPs (`192.168.51.x`). Move secrets to sops-nix and confirm the IPs
before enabling.

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
