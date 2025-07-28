{
  description = "Gig's nix config";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixos-anywhere.url = "github:nix-community/nixos-anywhere";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      # inputs = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      # flake-utils.follows = "flake-utils"; # unnecessary as of 2/13/25
      # };
    };

    # Haven't quite figured out how to use this yet
    # hardware = {
    #   url = "github:nixos/nixos-hardware";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    #################### Utilities ####################
    # Flake Utils (used internally by some other utilities and locked to this one version for sanities sake)
    flake-utils.url = "github:numtide/flake-utils";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    # Optional, if you intend to follow nvf's obsidian-nvim input
    # you must also add it as a flake input.
    # obsidian-nvim.url = "github:epwalsh/obsidian.nvim";

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
      # # Optionally, you can also override individual plugins
      # # for example:
      # inputs.obsidian-nvim.follows = "obsidian-nvim"; # <- this will use the obsidian-nvim from your inputs
    };

    # Pre-commit hooks for managing Git hooks declaratively
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    # Dev tools
    # treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix = {
      url = "github:mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Expandable neofetch
    nufetch = {
      url = "github:gignsky/nufetch/develop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    neve = {
      url = "github:redyf/Neve";
    };

    # nixvim = {
    #   url = "github:nix-community/nixvim/nixos-24.05";
    #   # If you are not running an unstable channel of nixpkgs, select the corresponding branch of nixvim.
    #   # url = "github:nix-community/nixvim/nixos-24.11";

    #   # inputs.nixpkgs.follows = "nixpkgs";
    # };

    #################### Personal Repositories ####################

    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticate via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@github.com/gignsky/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };

    # Recursive tarballs
    wrap = {
      url = "github:gignsky/wrap";
      flake = true;
    };

    # tax-matrix - currently on develop branch
    tax-matrix = {
      url = "github:gignsky/tax-matrix/develop";
      flake = true;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
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
      customPkgs = import ./pkgs { inherit pkgs; };
      pkgs = nixpkgs.legacyPackages.${system} // customPkgs;
      assertAllHostsHaveVmTest = configs:
        let
          missing = nixpkgs.lib.filterAttrs (_: config: (config.config.system.build.vmTest or null) == null) configs;
        in
        if missing != { } then
          throw ''\nSome nixosConfigurations are missing a vmTest!\nOffending hosts: ${builtins.concatStringsSep ", " (builtins.attrNames missing)}\nEach host must define config.system.build.vmTest.''
        else
          true;
    in
    {

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {

        # WSL configuration entrypoint - name can not be changed from nixos without some extra work TODO
        wsl = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            inputs.vscode-server.nixosModules.default
            (_: {
              services.vscode-server.enable = true;
            })
            inputs.nixos-wsl.nixosModules.default
            {
              system.stateVersion = "24.05";
              wsl.enable = true;
              # wsl.nativeSystemd = true;
            }
            # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
            # home-manager.nixosModules.home-manager {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/wsl
          ];
        };

        #wsl based vm
        full-vm = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            {
              system.stateVersion = "25.05";
            }
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./hosts/full-vm
          ];
        };

        # # # Merlin configuration entrypoint - unused as merlin has a wsl instance
        # merlin = nixpkgs.lib.nixosSystem {
        #   inherit system specialArgs;
        #   modules = [
        #     # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
        #     # home-manager.nixosModules.home-manager {
        #     #   home-manager.extraSpecialArgs = specialArgs;
        #     # }
        #     ./hosts/merlin
        #   ];
        # };

        # # Not yet working, but this is the entrypoint for a tdarr node
        # tdarr-node = nixpkgs.lib.nixosSystem {
        #   inherit system specialArgs;
        #   # > Our main nixos configuration file <
        #   modules = [
        #     # home-manager.nixosModules.home-manager
        #     # {
        #     #   home-manager.extraSpecialArgs = specialArgs;
        #     # }
        #     ./hosts/tdarr-node
        #   ];
        # };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # ganoslalWSL
        "gig@nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs configLib; };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/wsl.nix ];
          # config = {
          #   isWSL = true;
          # };
        };

        # spacedock - unused with spacedock having a wsl instance
        "gig@spacedock" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs configLib; };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/spacedock.nix ];
        };

        # # merlin - unused with merlin having a wsl instance
        # "gig@merlin" = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs; # Home-manager requires 'pkgs' instance
        #   extraSpecialArgs = { inherit inputs outputs configLib; };
        #   # > Our main home-manager configuration file <
        #   modules = [ ./home/gig/merlin.nix ];
        # };

        # # tdarr-node
        # "gig@tdarr-node" = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs; # Home-manager requires 'pkgs' instance
        #   extraSpecialArgs = { inherit inputs outputs configLib; };
        #   # > Our main home-manager configuration file <
        #   modules = [ ./home/gig/tdarr-node.nix ];
        # };
      };

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

      checks = {
        ${system} =
          let
            nixosTests =
              assert assertAllHostsHaveVmTest self.nixosConfigurations;
              nixpkgs.lib.filterAttrs (_: v: v != null) (
                nixpkgs.lib.mapAttrs'
                  (name: config: {
                    name = "nixosTest-${name}";
                    value = config.config.system.build.vmTest or null;
                  })
                  self.nixosConfigurations
              );
            homeManagerChecks = nixpkgs.lib.mapAttrs'
              (name: cfg: {
                name = "homeManager-${name}";
                value = cfg.activationPackage;
              })
              self.homeConfigurations;
            packageBuilds = nixpkgs.lib.mapAttrs'
              (name: pkg: {
                name = "build-${name}";
                value = pkg;
              })
              (import ./pkgs { inherit pkgs; });
          in
          nixosTests // homeManagerChecks // packageBuilds // {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixpkgs-fmt = {
                  enable = true;
                };
                statix = {
                  enable = true;
                };
                deadnix = {
                  enable = true;
                  excludes = [ "home/gig/common/optional/starship.nix" ];
                };
                shellcheck = {
                  enable = true;
                };
                markdownlint = {
                  enable = true;
                };
                yamllint = {
                  enable = true;
                  excludes = [ ".github/workflows/flake-check.yml" ];
                };
                end-of-file-fixer = {
                  enable = true;
                };
                # nix-flake-check-main-develop = {
                #   enable = true;
                #   name = "nix flake check on develop/main";
                #   entry = "./scripts/pre-commit-flake-check.sh";
                #   language = "script";
                #   pass_filenames = false;
                #   stages = [ "pre-commit" "pre-merge-commit" ];
                # };
              };
            };
          };
      };

      # Shell configured with packages that are typically only needed when working on or with nix-config.
      devShells.${system}.default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes ";

        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

        nativeBuildInputs = builtins.attrValues {
          inherit (pkgs)
            git
            pre-commit
            lolcat
            nixd
            nil
            age
            ssh-to-age
            sops
            home-manager
            just
            lazygit
            statix
            deadnix
            nix

            #unstable packages
            # unstable.statix

            # personal packages
            quick-results
            upjust
            upflake
            upspell

            #necessary for bootstrapping
            ripgrep
            ;
        };
      };
      # import ./shell.nix { inherit pkgs; };


      # TODO change this to something that has better looking output rules
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
