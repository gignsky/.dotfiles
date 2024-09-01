# SOPS_FILE := "../nix-secrets/secrets.yaml"

default:
    @just --list | bat --file-name "justfile"

# Run before every rebuild, everytime
rebuild-pre:
    nix-shell -p lolcat --run 'echo "[PRE] Rebuilding..." | lolcat'
    # just update-nix-secrets
    git add *.nix

# Run after every rebuild, some of the time
rebuild-post:
    # just check-sops
    nix-shell -p lolcat --run 'echo "[POST] Rebuilt." | lolcat'

# Rebuild the system
rebuild:
    just rebuild-pre
    scripts/system-flake-rebuild.sh

# Rebuild the system and check sops
rebuild-full:
    just rebuild
    just rebuild-post

# Update the flake
update:
    nix flake update

# Rebuild the system and update the flake
rebuild-update:
    just update
    just rebuild

# Rebuild the system and update the flake with rebuild-post
rebuild-update-full:
    just update
    just rebuild

check:
    just rebuild-pre
    nix flake check --impure --no-build
    nix-shell -p lolcat --run 'echo "[CHECK] Finished." | lolcat'

show:
    nix flake show

# switch:
#     sudo nixos-rebuild switch --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.
#
home:
    just rebuild-pre
    home-manager switch --flake ~/.dotfiles/.
    nix-shell -p lolcat --run 'echo "[HOME] Finished." | lolcat'

new home:
    just home
    zsh

home-trace:
    just rebuild-pre
    home-manager switch --flake ~/.dotfiles/. --show-trace
    nix-shell -p lolcat --run 'echo "[HOME-TRACE] Finished." | lolcat'

gc:
    nix-collect-garbage
#
# test:
#     sudo nixos-rebuild test --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.

# iso:
#     nix build ~/.dotfiles/.#nixosConfigurations.minimalIso.config.system.build.isoImage

# rebuild-pre: update-nix-secrets
#   git add *.nix
#
# rebuild-post:
#   just check-sops
#
# # Add --option eval-cache false if you end up caching a failure you can't get around
# rebuild: rebuild-pre
#   scripts/system-flake-rebuild.sh
#
# # Requires sops to be running and you must have reboot after initial rebuild
# rebuild-full: rebuild-pre && rebuild-post
#   scripts/system-flake-rebuild.sh
#
# # Requires sops to be running and you must have reboot after initial rebuild
# rebuild-trace: rebuild-pre && rebuild-post
#   scripts/system-flake-rebuild-trace.sh
#
# update:
#   nix flake update
#
# rebuild-update: update && rebuild
#
# diff:
#   git diff ':!flake.lock'
#
# # sops:
# #   echo "Editing {{SOPS_FILE}}"
# #   nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops {{SOPS_FILE}}"
#
# age-key:
#   nix-shell -p age --run "age-keygen"
#
# rekey:
#   cd ../nix-secrets && (\
#     sops updatekeys -y secrets.yaml && \
#     (pre-commit run --all-files || true) && \
#     git add -u && (git commit -m "chore: rekey" || true) && git push \
#   )
# check-sops:
#   scripts/check-sops.sh
#
# update-nix-secrets:
#   (cd ../nix-secrets && git fetch && git rebase) || true
#   nix flake lock --update-input nix-secrets
#
# iso:
#   # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
#   rm -rf result
#   nix build ./nixos-installer#nixosConfigurations.minimalIso.config.system.build.isoImage
#
# # iso-install DRIVE: iso
# #   sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync
#
# disko DRIVE PASSWORD:
#   echo "{{PASSWORD}}" > /tmp/disko-password
#   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
#     --mode disko \
#     disks/btrfs-luks-impermanence-disko.nix \
#     --arg disk '"{{DRIVE}}"' \
#     --arg password '"{{PASSWORD}}"'
#   rm /tmp/disko-password
#
# sync USER HOST:
#   rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}}" . {{USER}}@{{HOST}}:nix-config/
#
# sync-secrets USER HOST:
#   rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}}" . {{USER}}@{{HOST}}:nix-secrets/
