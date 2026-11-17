# Star Citizen on ganoslal: the RSI Launcher wrapped in wine-astral, via the
# nix-citizen flake (LovingMelody/nix-citizen, built on fufexan/nix-gaming).
#
# Opt-in, for the one host someone games on. Importing this file is enabling it.
#
# What nix-citizen's `programs.rsi-launcher` module gives us for free, so none
# of it is repeated here (see https://wiki.nixos.org/wiki/Star_Citizen and the
# LUG prerequisites it links to):
#   - sysctl vm.max_map_count = 16777216 and fs.file-max = 524288
#   - PAM soft nofile limit of 16777216 for every login
#   - ntsync kernel module (kernel >= 6.14; 26.05 ships 6.18 with ntsync.ko)
#     and snd-aloop
#   - a `rsi-launcher` command + desktop entry that creates the wine prefix
#     under `location`, installs the winetricks verbs, and runs the RSI
#     installer on first launch
#
# Two deliberate deviations from the module's defaults:
#
#   1. includeOverlay = false. The default overlay re-evaluates wine-astral,
#      dxvk, etc. against OUR nixpkgs (gigpkgs 26.05). nix-citizen's cachix
#      cache only holds builds against nix-citizen's own locked nixos-unstable,
#      so the overlay guarantees a cache miss and a multi-hour Wine build.
#      Taking the packages from `inputs.nix-citizen.packages` keeps the store
#      paths identical to the cache. For the same reason flake.nix does NOT
#      make nix-citizen follow our nixpkgs.
#
#   2. udevRules = false. With the overlay off, `pkgs.lug-helper` does not
#      exist and the module's udev rule (joystick permissions) would fail
#      evaluation. The flake's lug-helper is added to services.udev.packages
#      below instead, which is the same rule.
#
# Hardware facts this leans on (ganoslal, measured 2026-11-17):
#   - nvidia-smi enumerates the GTX 970 as GPU 0 and the RTX 3060 Ti as GPU 1,
#     and DXVK picks the first Vulkan device by default. Without the
#     DXVK/VKD3D device filter the game renders on the 970.
#   - 46 GB RAM + 23.5 GB zram + 51.7 GB swap partition, well over the LUG
#     RAM+swap recommendation, so no extra swap is configured here
#     (memory-tuning.nix already owns zram).
#   - hardware.graphics.enable32Bit and pipewire alsa.support32Bit are already
#     on (hosts/ganoslal/nvidia.nix, hosts/common/optional/audio.nix).
#   - The game installs under ~/Games/rsi-launcher on the single SATA SSD
#     (262 GB free at the time); a LIVE install is roughly 100-150 GB.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  scPkgs = inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  programs.rsi-launcher = {
    enable = true;

    # Use nix-citizen's prebuilt closure, see header (1).
    includeOverlay = false;
    package = scPkgs.rsi-launcher;
    wine = scPkgs.wine-astral;

    # pkgs.lug-helper is absent without the overlay, see header (2).
    udevRules = false;

    location = lib.mkDefault "$HOME/Games/rsi-launcher";

    # gamemode: CPU governor + niceness while the game runs.
    launchCommand = "gamemoderun %command%";

    preCommands = ''
      # The GTX 970 is Vulkan device 0 on this box; pin the renderer to the
      # 3060 Ti. Exact string from `vulkaninfo --summary` / nvidia-smi -L.
      export DXVK_FILTER_DEVICE_NAME="NVIDIA GeForce RTX 3060 Ti"
      export VKD3D_FILTER_DEVICE_NAME="NVIDIA GeForce RTX 3060 Ti"
    '';

    # Left at their defaults on purpose:
    #   setLimits = true          (sysctl + PAM limits above)
    #   enableNTsync = true       (kernel 6.18 >= 6.14)
    #   enforceWaylandDrv = true  (native Wayland driver under niri; if the
    #                              cursor misbehaves, patchXwayland = true is
    #                              the fallback -- that one DOES add an
    #                              xwayland overlay and rebuild)
    #   disableEAC = false        (Easy Anti-Cheat stays on; the game needs it)
  };

  programs.gamemode.enable = true;

  # LUG helper script: prefix repair, shader-cache cleanup, EAC troubleshooting,
  # and the joystick udev rules the module would otherwise install (header 2).
  services.udev.packages = [ scPkgs.lug-helper ];
  environment.systemPackages = [ scPkgs.lug-helper ];

  # Same pattern as modules/nixos/binary-cache/client.nix. nix-gaming's cache
  # is listed too since nix-citizen's wine/dxvk stack derives from it.
  nix.settings = {
    extra-substituters = [
      "https://nix-citizen.cachix.org"
      "https://nix-gaming.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };
}
