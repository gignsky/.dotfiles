{
  description = "Gig's nix config";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################
    # FIXME: TEMPORARY UNSTABLE UPGRADE FOR OPENCODE TESTING
    # Original stable: nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # 25.11 readiness: keep this line commented for quick switch when 25.11 drops
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-local.url = "git+file:///home/gig/local_repos/nixpkgs";
    # nixos-anywhere.url = "github:nix-community/nixos-anywhere";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      # inputs = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      # flake-utils.follows = "flake-utils"; # unnecessary as of 2/13/25
      # };
    };

    # nixos-hardware, to fix hardware issues and firmware for specific machines
    # found at: https://github.com/NixOS/nixos-hardware
    nixos-hardware.url = "github:nixos/nixos-hardware";

    #################### Utilities ####################
    # Nix Sweep, a nix store tool
    nix-sweep.url = "github:jzbor/nix-sweep";

    # Flake Utils (used internally by some other utilities and locked to this one version for sanities sake)
    flake-utils.url = "github:numtide/flake-utils";

    # Home manager
    # FIXME: TEMPORARY UPGRADE TO MASTER FOR UNSTABLE COMPATIBILITY
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # Original: url = "github:nix-community/home-manager/release-25.05";
      # 25.11 readiness: keep this line commented for quick switch when 25.11 drops
      # url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    # flake-iter.url = "github:determinatesystems/flake-iter";

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

    # optnix.url = "github:water-sucks/optnix";

    git-aliases = {
      url = "github:KamilKleina/git-aliases.nu";
      flake = false;
    };

    #################### Personal Repositories ####################

    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticate via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@github.com/gignsky/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };

    # private repo with fancy fonts
    fancy-fonts = {
      url = "git+ssh://git@github.com/gignsky/personal-fonts-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Recursive tarballs
    wrapd = {
      url = "github:gignsky/wrapd";
      flake = true;
    };

    # tax-matrix - currently on develop branch
    # tax-matrix = {
    #   url = "github:gignsky/tax-matrix/develop";
    #   flake = true;
    # };

    gigvim.url = "github:gignsky/gigvim";

    # nufetch.url = "github:gignsky/nufetch";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
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
      pkgs =
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        }
        // customPkgs;
      assertAllHostsHaveVmTest =
        configs:
        let
          missing = nixpkgs.lib.filterAttrs (
            _: config: (config.config.system.build.vmTest or null) == null
          ) configs;
        in
        if missing != { } then
          throw "\\nSome nixosConfigurations are missing a vmTest!\\nOffending hosts: ${builtins.concatStringsSep ", " (builtins.attrNames missing)}\\nEach host must define config.system.build.vmTest."
        else
          true;
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # WSL configuration entrypoint - name can not be changed from nixos without some extra work TODO
        wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = specialArgs // {
            configVars = configVars // {
              uid = 1000; # WSL compatibility
              guid = 1000; # Keep gig group as 1000, not 100
            };
          };
          modules = [
            inputs.vscode-server.nixosModules.default
            (_: { services.vscode-server.enable = true; })
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

        # #wsl based vm
        # full-vm = nixpkgs.lib.nixosSystem {
        #   inherit system specialArgs;
        #   modules = [
        #     { system.stateVersion = "25.05"; }
        #     "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        #     "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        #     ./hosts/full-vm
        #   ];
        # };

        # # Merlin configuration entrypoint - unused as merlin has a wsl instance
        merlin = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
            # home-manager.nixosModules.home-manager {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/merlin

            # https://github.com/NixOS/nixos-hardware/tree/master/framework/16-inch/7040-amd
            inputs.nixos-hardware.nixosModules.framework-16-7040-amd
          ];
        };

        # # GanosLal configuration entrypoint - but to build on merlin's hardware
        # mganos = nixpkgs.lib.nixosSystem {
        #   inherit system specialArgs;
        #   modules = [
        #     # Activate this if you want home-manager as a module of the system, maybe enable this for vm's or minimal system, idk. #TODO
        #     # home-manager.nixosModules.home-manager {
        #     #   home-manager.extraSpecialArgs = specialArgs;
        #     # }
        #     ./hosts/mganos
        #
        #     # https://github.com/NixOS/nixos-hardware/tree/master/framework/16-inch/7040-amd
        #     inputs.nixos-hardware.nixosModules.framework-16-7040-amd
        #   ];
        # };

        ganoslal = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          # > Our main nixos configuration file <
          modules = [
            # home-manager.nixosModules.home-manager
            # {
            #   home-manager.extraSpecialArgs = specialArgs;
            # }
            ./hosts/ganoslal
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # ganoslalWSL
        "gig@wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              configLib
              system
              ;
            overlays = import ./overlays { inherit inputs; };
            # flakeRoot = self;
          };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/wsl.nix ];
          # config = {
          #   isWSL = true;
          # };
        };

        # spacedock - unused with spacedock having a wsl instance
        "gig@spacedock" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              configLib
              system
              ;
            overlays = import ./overlays { inherit inputs; };
            # flakeRoot = self;
          };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/spacedock.nix ];
        };

        # merlin - unused with merlin having a wsl instance
        "gig@merlin" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              configLib
              system
              ;
            overlays = import ./overlays { inherit inputs; };
          };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/merlin.nix ];
        };

        # ganoslal - unused with ganoslal having a wsl instance
        "gig@ganoslal" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              configLib
              system
              ;
            overlays = import ./overlays { inherit inputs; };
          };
          # > Our main home-manager configuration file <
          modules = [ ./home/gig/ganoslal.nix ];
        };

        # # mganos - unused with mganos having a wsl instance
        # "gig@mganos" = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs; # Home-manager requires 'pkgs' instance
        #   extraSpecialArgs = {
        #     inherit
        #       inputs
        #       outputs
        #       configLib
        #       system
        #       ;
        #     overlays = import ./overlays { inherit inputs; };
        #   };
        #   # > Our main home-manager configuration file <
        #   modules = [ ./home/gig/mganos.nix ];
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

      # Home Manager modules that can be imported by other flakes
      # homeModules = {
      #   gig-spacedock =
      #     { ... }:
      #     {
      #       imports = [
      #         ./home/gig/spacedock.nix
      #       ];
      #       # Provide the flakeRoot and other args through _module.args
      #       _module.args = {
      #         flakeRoot = ./.; # Use the source path directly
      #         # Pass overlays directly instead of outputs to avoid circular reference
      #         overlays = import ./overlays { inherit inputs; };
      #       };
      #     };
      #   gig-base =
      #     { ... }:
      #     {
      #       imports = [
      #         ./home/gig/home.nix
      #       ];
      #       # Provide the flakeRoot and other args through _module.args
      #       _module.args = {
      #         flakeRoot = ./.; # Use the source path directly
      #         # Pass overlays directly instead of outputs to avoid circular reference
      #         overlays = import ./overlays { inherit inputs; };
      #       };
      #     };
      #
      #   # Common modules that can be imported individually
      #   core =
      #     { ... }:
      #     {
      #       imports = [
      #         (import ./home/gig/common/core { flakeRoot = self; })
      #       ];
      #     };
      #   optional =
      #     { ... }:
      #     {
      #       imports = [
      #         (import ./home/gig/common/optional { flakeRoot = self; })
      #       ];
      #     };
      # };
      #
      # # Alternative naming that's more standard for Home Manager flakes
      # homeManagerModules = self.homeModules;

      checks = {
        ${system} =
          let
            nixosTests =
              assert assertAllHostsHaveVmTest self.nixosConfigurations;
              nixpkgs.lib.filterAttrs (_: v: v != null) (
                nixpkgs.lib.mapAttrs' (name: config: {
                  name = "nixosTest-${name}";
                  value = config.config.system.build.vmTest or null;
                }) self.nixosConfigurations
              );
            homeManagerChecks = nixpkgs.lib.mapAttrs' (name: cfg: {
              name = "homeManager-${name}";
              value = cfg.activationPackage;
            }) self.homeConfigurations;
            packageBuilds = nixpkgs.lib.mapAttrs' (name: pkg: {
              name = "build-${name}";
              value = pkg;
            }) (import ./pkgs { inherit pkgs; });
          in
          nixosTests
          // homeManagerChecks
          // packageBuilds
          // {
            # Pre-commit check configuration - manual execution, not part of flake check
            pre-commit-check-manual = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixfmt-rfc-style = {
                  enable = true;
                  excludes = [
                    ".*/hardware-configuration\\.nix$" # Exclude autogenerated files
                    "scottys-journal/.*" # Exclude engineering logs from formatting
                  ];
                };
                statix = {
                  enable = true;
                  excludes = [ "scottys-journal/.*" ]; # Exclude engineering logs from nix linting
                };
                deadnix = {
                  enable = true;
                  excludes = [
                    "home/gig/common/optional/starship.nix"
                    "hosts/common/users/gig/default.nix"
                    "scottys-journal/.*" # Exclude engineering logs from deadnix
                  ];
                };
                shellcheck = {
                  enable = true;
                  excludes = [ "scottys-journal/.*" ]; # Exclude engineering logs from shellcheck
                };
                markdownlint = {
                  enable = false;
                };
                yamllint = {
                  enable = true;
                  excludes = [
                    ".github/workflows/flake-check.yml"
                    "scottys-journal/.*" # Exclude engineering logs from yaml linting
                  ];
                };
                end-of-file-fixer = {
                  enable = true;
                };

                # Scotty's Engineering Logging Hooks
                scotty-post-commit-log = {
                  enable = true;
                  name = "scotty-post-commit-log";
                  entry = "${pkgs.bash}/bin/bash";
                  args = [
                    "-c"
                    ''
                      # Source Scotty's logging library
                      source "${./scripts/scotty-logging-lib.sh}"

                      # Get the commit message and log the operation
                      commit_message=$(git log -1 --pretty=%B)
                      scotty_log_event "git-commit" "$commit_message"
                    ''
                  ];
                  stages = [ "post-commit" ];
                  verbose = true;
                };

                scotty-pre-push-log = {
                  enable = true;
                  name = "scotty-pre-push-log";
                  entry = "${pkgs.bash}/bin/bash";
                  args = [
                    "-c"
                    ''
                      # Source Scotty's logging library
                      source "${./scripts/scotty-logging-lib.sh}"

                      # Log the push preparation
                      current_branch=$(git branch --show-current)
                      scotty_log_event "git-push-prep" "Preparing to push branch: $current_branch"
                    ''
                  ];
                  stages = [ "pre-push" ];
                  verbose = true;
                };
              };
            };
          };
      };

      # Shell configured with packages that are typically only needed when working on or with nix-config.
      devShells.${system}.default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes ";

        # Don't auto-include pre-commit packages - manual setup like spacedock

        nativeBuildInputs = builtins.attrValues {
          inherit (pkgs)
            git
            pre-commit # Manual pre-commit setup
            lolcat
            nixfmt-rfc-style
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
            fzf
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

        shellHook = ''
          # Command to ensure the .pre-commit-config.yaml is set up 
          # by the 'pre-commit' package, which should be in nativeBuildInputs.
          if [ ! -f .pre-commit-config.yaml ]; then
            echo "Setting up pre-commit hooks..."
            # Clear hooksPath to allow pre-commit installation 
            ${pkgs.git}/bin/git config --unset-all core.hooksPath 2>/dev/null || true
            ${pkgs.pre-commit}/bin/pre-commit install --install-hooks
          fi

          echo "Welcome to the dotfiles devShell" | ${pkgs.lolcat}/bin/lolcat
          echo "Note: Pre-commit hooks are available but not part of flake check"
        '';
      };
      # import ./shell.nix { inherit pkgs; };

      # TODO change this to something that has better looking output rules
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
