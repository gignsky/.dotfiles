# Spacedock system configuration.
#
# Repurposed from the standalone `dot-spacedock` flake into the main fleet.
# Spacedock is a legacy-BIOS box (GRUB on /dev/sda), so it does NOT use the
# fleet's EFI defaults — its bootloader and hardware block are carried over.
#
# nixpkgs base: the fleet `nixpkgs` input is already the gigos-2605 gigpkgs
# super-nixpkgs channel, so spacedock rides gigos with no extra wiring.
#
# See engineering/enhancement-protocols/SEP-spacedock-onboarding.md.
{
  lib,
  config,
  configLib,
  pkgs,
  ...
}:
{
  imports = [
    # Hardware — carried from dot-spacedock. REGENERATE on the box with
    # `nixos-generate-config` before the first switch.
    ./hardware-configuration.nix

    # Core: locale, sops, sshd, samba, nix settings, virtualisation, vm-test, ...
    (configLib.relativeToRoot "hosts/common/core")

    # Containers — run-as-a-service OCI payloads (pihole enabled in the
    # aggregator; see containers/README.md). The runtime comes from the
    # gigpkgs container engine configured below.
    (configLib.relativeToRoot "containers/services/spacedock")

    # Users
    (configLib.relativeToRoot "hosts/common/users/gig")
  ];
  # gigpkgs container engine — the module is injected in flake.nix as
  # `inputs.nixpkgs.nixosModules.containers`. Provides the OCI runtime for
  # containers that run either as a service (via `gigpkgs.containers.services`
  # or the payloads under containers/services) or adhoc (podman CLI + the
  # nixos-generators images under containers/{buzz,mini}).
  gigpkgs.containers = {
    enable = true;
    backend = "podman";
    adhoc.enable = true;
  };

  # Discrete AMD Polaris GPU (RX 470/480/570/580/590, PCI 1002:67df) bound to
  # the in-tree `amdgpu` driver. Enable the VA-API userspace so the tdarr-node
  # container can hardware-transcode via radeonsi. `libva-utils` supplies
  # `vainfo` for on-box diagnosis. See containers/services/tdarr-node.nix.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libva-utils
    ];
  };

  networking = {
    hostName = "spacedock";
    networkmanager.enable = true;
  };

  boot = {
    # Bootloader — legacy BIOS (GRUB on the primary disk). Carried from
    # dot-spacedock; adjust `device` if the disk differs after regeneration.
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;
  };

  # broadcom-sta's package name embeds the running kernel version, so a
  # hardcoded entry breaks on every kernel bump. Derive the suffix from the
  # actual kernel version so this auto-tracks kernel updates. The driver
  # version prefix (6.30.223.271-59) is frozen upstream (unmaintained driver).
  # NOTE: build from kernel.version, NOT broadcom_sta.name — referencing the
  # insecure package's own name here would recurse through the permit check.
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-${config.boot.kernelPackages.kernel.version}"
  ];

  # Tailscale defaults to enabled fleet-wide; keep it off here until configured.
  tailscale.enable = false;

  # stateVersion reflects spacedock's ORIGINAL install (dot-spacedock = 25.05).
  # Do NOT bump. https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
