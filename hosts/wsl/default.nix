{ configLib, ... }: {
  imports = [
    (configLib.relativeToRoot "hosts/common/core")
    (configLib.relativeToRoot "hosts/common/users/gig")
    (configLib.relativeToRoot "hosts/common/optional/samba.nix")
    # (configLib.relativeToRoot "hosts/common/optional/neofetch.nix")
    # inputs.nixos-wsl.modules
    # inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  # programs.nix-ld = {
  #   enable = true;
  #   package = pkgs.nix-ld-rs;
  # };

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
