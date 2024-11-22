{
  description = "Gig's nix config";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Haven't quite figured out how to use this yet
    # hardware = {
    #   url = "github:nixos/nixos-hardware";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    #################### Utilities ####################
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt-nix = {
    #   url = "github:numtide/treefmt-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Secrets management
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # # Declarative partitioning and formatting
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    #################### Personal Repositories ####################

    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticate via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@github.com/gignsky/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # forAllSystems = nixpkgs.lib.genAttrs [
      #   "x86_64-linux"
      #   "aarch64-linux"
      #   "i686-linux"
      #   "aarch64-darwin"
      #   "x86_64-darwin"
      # ];
      configVars = import ./vars { inherit inputs lib; };
      configLib = import ./lib { inherit lib; };
      specialArgs = {
        inherit
          inputs
          outputs
          nixpkgs
          configVars
          configLib
          ;
      };
    in
    {
      # Custom packages to be shared or upstreamed.
      # packages = forAllSystems (
      #   system:
      #   let
      #     pkgs = nixpkgs.legacyPackages.${system};
      #   in
      #   import ./pkgs { inherit pkgs; }
      # );
      # nixosModules = { inherit (import ./modules/nixos); };

      packages.${system} = import ./pkgs { inherit pkgs; };

      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs; };

      # Shell configured with packages that are typically only needed when working on or with nix-config.
      devShells.${system}.default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

        # inherit (self.checks.${system}.pre-commit-check) shellHook;
        # buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

        nativeBuildInputs = builtins.attrValues {
          inherit (pkgs)
            git
            lolcat
            nix
            nil
            age
            ssh-to-age
            sops
            home-manager
            just

            #nececcary for bootstraping
            ripgrep
            ;
        };
      };
      # import ./shell.nix { inherit pkgs; };

      # TODO change this to something that has better looking output rules
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter.${system} = pkgs.nixpkgs-fmt;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # WSL configuration entrypoint - name can not be channged from nixos without some extra work TODO
        wsl = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            inputs.nixos-wsl.nixosModules.default {
              system.stateVersion = "24.05";
              wsl.enable = true;
              # wsl.nativeSystemd = true;
            }
            # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
            # home-manager.nixosModules.home-manager {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/ganosLal/wsl
          ];
        };

        # Merlin configuration entrypoint
        merlin = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
            # home-manager.nixosModules.home-manager {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/merlin
          ];
        };

        cams-countertop = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          # > Our main nixos configuration file <
          modules = [
            # home-manager.nixosModules.home-manager
            # {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/cams-countertop
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # ganoslalWSL
        "gig@nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {inherit inputs outputs configLib;};
          # > Our main home-manager configuration file <
          modules = [./home/gig/wsl.nix];
        };

        # merlin
        "gig@merlin" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {inherit inputs outputs configLib;};
          # > Our main home-manager configuration file <
          modules = [./home/gig/merlin.nix];
        };

        # buzz
	"gig@buzz" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {inherit inputs outputs configLib;};
          # > Our main home-manager configuration file <
          modules = [./home/gig/buzz.nix];
        };
	
	# cams-countertop
        "gig@cams-countertop" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {inherit inputs outputs configLib;};
          # > Our main home-manager configuration file <
          modules = [./home/gig/cams-countertop.nix];
        };
      };
    };
}
