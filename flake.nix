{
  description = "Gig's nix config";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #################### Utilities ####################

    # # Secrets management
    # sops-nix = {
    #   url = "github:mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # # Declarative partitioning and formatting
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    #################### Personal Repositories ####################

    # # Private secrets repo.  See ./docs/secretsmgmt.md
    # # Authenticate via ssh and use shallow clone
    # nix-secrets = {
    #   url = "git+ssh://git@gitlab.com/emergentmind/nix-secrets.git?ref=main&shallow=1";
    #   flake = false;
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        #"aarch64-darwin"
      ];
      specialArgs = { inherit inputs outputs nixpkgs; };
      exampleBaseIso = {
          isoImage.squashfsCompression = "gzip -Xcompression-level 1";
          systemd.services.sshd.wantedBy = nixpkgs.lib.mkForce [ "multi-user.target" ];
          # users.users.root.openssh.authorizedKeys.keys = [ "<my ssh key>" ];
        };
    in
    {
#       # Shell configured with packages that are typically only needed when working on or with nix-config.
#       devShells = forAllSystems
#         ( system: import ./shell.nix { inherit pkgs; });
#
#       # Example Hello World package
#       packages.${system}.default = pkgs.writeShellScriptBin "example" ''
#         ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat
#       '';
#
#       # TODO change this to something that has better looking output rules
#       # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
#       formatter = forAllSystems
#         (system:
#           nixpkgs.legacyPackages.${system}.nixpkgs-fmt
#         );


      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        minimalIso = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            exampleBaseIso
            ./hosts/minimalIso
          ];
        };

        # WSL configuration entrypoint - name can not be channged from nixos without some extra work TODO
        nixos = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            inputs.nixos-wsl.nixosModules.default {
              system.stateVersion = "24.05";
              wsl.enable = true;
            }
            # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
            # home-manager.nixosModules.home-manager {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/ganosLal/wsl
          ];
        };

        buzz = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          # > Our main nixos configuration file <
          modules = [
            # home-manager.nixosModules.home-manager
            # {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/buzz
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "gig@nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {inherit specialArgs;};
          # > Our main home-manager configuration file <
          modules = [./home/home.nix];
        };
      };
  };
}
