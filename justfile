just check
    nix flake check --impure

just checkpure
    nix flake check

just iso
    nix build .#nixosConfigurations.minimalIso.config.system.build.isoImage