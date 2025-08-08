{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    # Follow main flake inputs
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home manager for minimal user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Declarative partitioning and formatting
    disko.url = "github:nix-community/disko";
    
    # Personal projects
    gigvim.url = "github:gignsky/gigvim";
    nufetch.url = "github:gignsky/nufetch";
    
    # Git aliases for nushell
    git-aliases = {
      url = "github:KamilKleina/git-aliases.nu";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      configVars = import ../vars { inherit inputs lib; };
      configLib = import ../lib { inherit lib; };
      minimalConfigVars = lib.recursiveUpdate configVars { isMinimal = true; };
      minimalSpecialArgs = {
        inherit inputs outputs configLib system;
        configVars = minimalConfigVars;
      };

      # FIXME: Specify arch eventually probably
      # This mkHost is way better: https://github.com/linyinfeng/dotfiles/blob/8785bdb188504cfda3daae9c3f70a6935e35c4df/flake/hosts.nix#L358
      newConfig =
        name: disk: qemuGuest:
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = minimalSpecialArgs;
          modules = [
            inputs.disko.nixosModules.disko
            (configLib.relativeToRoot "hosts/common/disks/standard-disk-config.nix")
            {
              _module.args = {
                inherit disk;
              };
            }
            ./minimal-configuration.nix
            {
              _module.args = {
                inherit qemuGuest;
              };
            }
            {
              networking = {
                hostName = name;
                hostId = "a56f8db2"; # Unique 8-character hex string, can be generated with `head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n'`
              };
            }
            (configLib.relativeToRoot "hosts/${name}/hardware-configuration.nix")
          ];
        });
    in
    {
      nixosConfigurations = {
        # host = newConfig "name" disk" "qemuGuest";
        # Swap size is in GiB
        # merlin = newConfig "merlin" "/dev/nvme1n1" false;
        spacedock = newConfig "spacedock" "/dev/sda" false;

        # Custom ISO
        #
        # `just iso` - from nix-config directory to generate the iso standalone
        # 'just iso-install <drive>` - from nix-config directory to generate and copy directly to USB drive
        # `nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage` - from nix-config directory to generate the iso manually
        #
        # Generated images will be output to the ~/nix-config/results directory unless drive is specified
        iso = nixpkgs.lib.nixosSystem {
          specialArgs = minimalSpecialArgs;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            # Include home-manager as a module for the installer
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = minimalSpecialArgs;
              home-manager.users.gig = import ../home/gig/nixos-installer.nix;
            }
            ./iso
          ];
        };
      };
      
      # Home Manager configurations for the installer
      homeConfigurations = {
        "gig@nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = minimalSpecialArgs;
          modules = [ ../home/gig/nixos-installer.nix ];
        };
      };
    };
}
