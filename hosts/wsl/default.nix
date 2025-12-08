{
  pkgs,
  configLib,
  configVars,
  lib,
  ...
}:
{
  imports = [
    (configLib.relativeToRoot "hosts/common/core")
    (configLib.relativeToRoot "hosts/common/users/gig")
    (configLib.relativeToRoot "hosts/common/optional/nix-sweep.nix")
    # (configLib.relativeToRoot "hosts/common/optional/neofetch.nix")
    # inputs.nixos-wsl.modules
    # inputs.home-manager.nixosModules.home-manager
  ];

  # WSL-specific user ID override (group stays at 1701)
  users.users.${configVars.username}.uid = lib.mkForce 1000;

  networking.hostName = "nixos";

  # Tailscale configuration (currently disabled)
  # To enable Tailscale on WSL:
  # 1. Generate auth key for WSL in Tailscale admin console with these settings:
  #    - Description: "wsl-nixos-auto-auth"
  #    - Reusable: Yes, Ephemeral: No, Pre-approved: Yes
  #    - Expiry: 1 year (or never)
  # 2. Add "wsl-auth: tskey-auth-..." to tailscale-creds in secrets.yaml
  # 3. Import the tailscale module in imports above
  # 4. Uncomment the block below
  #
  # tailscale = {
  #   enable = true;
  #   enableSSH = false;        # Usually disabled in WSL
  #   useRoutingFeatures = "none";  # Minimal routing for WSL
  # };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };

  environment.systemPackages = with pkgs; [
    wayland
    libxkbcommon
  ];

  # Alternative that doesn't effect other files -- depreciated and doesn't work
  # inputs.vscode-remote-workaround.enable = true;

  # NEW METHOD FOR VSCODE FROM: https://github.com/nix-community/nixos-vscode-server

  wsl.enable = true; # Redunent with nixosModules.default on the flake.nix level
  wsl.defaultUser = "gig";

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Opinionated: disable global registry
    flake-registry = "";
    trusted-users = [ "gig" ];
  };

  #   # I think this is unneccecary if I'm going with standalone home-manager rather than flake os module home-manager
  #   home-manager = {
  #     extraSpecialArgs = { inherit inputs outputs; };
  #     users = {
  #       # Import your home-manager configuration
  #       gig = import ../../../home/gig/ganosLal/wsl.nix;
  #     };
  #   };

  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
