# SOPS_FILE := "../nix-secrets/secrets.yaml"

default:
    @just --list | bat --file-name "justfile"

# Run before every rebuild, everytime
rebuild-pre:
    echo "[PRE] Rebuilding..." | lolcat
    # just update-nix-secrets
    just dont-fuck-my-build
    just sops-update

dont-fuck-my-build:
    git ls-files --others --exclude-standard -- '*.nix' | xargs -r git add -v | lolcat
    echo "No chance your build is fucked! 👍" | lolcat

switch args="":
    just rebuild {{args}}
    just home

# Run after every rebuild, some of the time
rebuild-post:
    # just check-sops
    echo "[POST] Rebuilt." | lolcat

# Rebuild the system
rebuild args="":
    just rebuild-pre
    scripts/system-flake-rebuild.sh {{args}}

# Test rebuilds the system
rebuild-test args="":
    just rebuild-pre
    scripts/system-flake-rebuild-test.sh {{args}}
    echo "[TEST] Finished." | lolcat

# Rebuild the system and check sops and home manager
rebuild-full args="":
    just rebuild {{args}}
    just rebuild-post
    just home

# Update the flake
update:
    just dont-fuck-my-build
    just sops-update
    nix flake update

# Rebuild the system and update the flake
update-rebuild:
    just update
    just rebuild

# Rebuild the system and update the flake with rebuild-post
update-rebuild-full:
    just update
    just rebuild
    just home

check:
    just dont-fuck-my-build
    nix flake check --impure --no-build
    echo "[CHECK] Finished." | lolcat

check-iso:
    just dont-fuck-my-build
    nix flake check --impure --no-build nixos-installer/.
    echo "[CHECK] Finished." | lolcat

show args="":
    just dont-fuck-my-build
    scripts/flake-show.sh {{args}}

# switch:
#     sudo nixos-rebuild switch --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.
#

# Run before every home rebuild, on non-quick build
pre-home:
    just dont-fuck-my-build
    echo "[PRE-HOME] Finished." | lolcat

# Runs after every home rebuild
post-home:
    echo "[HOME] Finished." | lolcat

home:
    just pre-home
    home-manager switch --flake ~/.dotfiles/.
    just post-home

# Runs just home
# home-core:

# Runs just home and then zsh
new home:
    just home
    zsh

home-trace:
    just dont-fuck-my-build
    home-manager switch --flake ~/.dotfiles/. --show-trace
    echo "[HOME-TRACE] Finished." | lolcat

gc:
    nix-collect-garbage --delete-old | lolcat
    # nix store gc | lolcat

pre-build:
    echo "Pre-Build Starting..." | lolcat
    just dont-fuck-my-build
    rm -rfv result

build *args:
    just pre-build
    scripts/flake-build.sh {{args}}
    just post-build

post-build:
    echo "Build Finished." | lolcat
    quick-results

#
# test:
#     sudo nixos-rebuild test --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.

iso:
  # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
  rm ~/virtualization-boot-files/template/iso/nixos*
  just pre-build
  nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
  just post-build
  cp result/iso/nixos* ~/virtualization-boot-files/template/iso/.
  ls ~/virtualization-boot-files/template/iso | grep nixos | lolcat
  rm -rfv result

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
diff:
  git diff ':!flake.lock'

sops:
  just sops-update
  echo "Editing ~/nix-secrets/secrets.yaml" | lolcat
  sops ~/nix-secrets/secrets.yaml

sops-update:
  echo "Updating ~/nix-secrets/secrets.yaml" | lolcat
  sops updatekeys ~/nix-secrets/secrets.yaml
  echo "Updated Secrets!" | lolcat

sops-fix:
    just pre-home
    home-manager switch --refresh --flake ~/.dotfiles/.
    systemctl --user reset-failed
    just home

store-photo:
    nix-shell -p graphviz nix-du --run "nix-du -s=500MB | \dot -Tpng > store.png"

bootstrap *args:
    just dont-fuck-my-build
    ~/.dotfiles/scripts/bootstrap-nixos.sh {{args}}

#   echo $SOPS_FILE
#   PS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# age-key:
#   -keygen
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
