check:
    nix flake check --impure --no-build

show:
    nix flake show

switch:
    sudo nixos-rebuild switch --flake ~/.dotfiles/.
    home-manager switch --flake ~/.dotfiles/.

test:
    sudo nixos-rebuild test --flake ~/.dotfiles/.
    home-manager switch --flake ~/.dotfiles/.

iso:
    nix build ~/.dotfiles/.#nixosConfigurations.minimalIso.config.system.build.isoImage

default:
    @just --list
