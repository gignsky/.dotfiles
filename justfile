# SOPS_FILE := "../nix-secrets/secrets.yaml"

default:
    @just --list | bat --file-name "justfile"

# Run before every rebuild, everytime
rebuild-pre:
    nix-shell -p lolcat --run 'echo "[PRE] Rebuilding..." | lolcat'
    just dont-fuck-my-build
    # just rekey

dont-fuck-my-build:
    git ls-files --others --exclude-standard -- '*.nix' | xargs -r git add -v
    nix flake lock --update-input nix-secrets
    nix-shell -p lolcat --run 'echo "No chance your build is fucked! 👍" | lolcat'

switch args="":
    just rebuild {{args}}
    just home

# Run after every rebuild, some of the time
rebuild-post:
    # just check-sops
    nix-shell -p lolcat --run 'echo "[POST] Rebuilt." | lolcat'

# Rebuild the system
rebuild args="":
    just rebuild-pre
    scripts/system-flake-rebuild.sh {{args}}

# Test rebuilds the system
rebuild-test args="":
    just rebuild-pre
    scripts/system-flake-rebuild-test.sh {{args}}
    nix-shell -p lolcat --run 'echo "[TEST] Finished." | lolcat'

# Rebuild the system and check sops and home manager
rebuild-full args="":
    just rebuild {{args}}
    just rebuild-post
    just home

# Update the flake
update:
    just dont-fuck-my-build
    just rekey
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
    nix-shell -p lolcat --run 'echo "[CHECK] Finished." | lolcat'

check-iso:
    just dont-fuck-my-build
    nix flake check --impure --no-build nixos-installer/.
    nix-shell -p lolcat --run 'echo "[CHECK] Finished." | lolcat'

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
    nix-shell -p lolcat --run 'echo "[PRE-HOME] Finished." | lolcat'

# Runs after every home rebuild
post-home:
    nix-shell -p lolcat --run 'echo "[HOME] Finished." | lolcat'

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
    nix-shell -p lolcat --run 'echo "[HOME-TRACE] Finished." | lolcat'

gc:
    nix-shell -p lolcat --run 'nix-collect-garbage --delete-old | lolcat'
    nix-shell -p lolcat --run '# nix store gc | lolcat'

pre-build:
    nix-shell -p lolcat --run 'echo "Pre-Build Starting..." | lolcat'
    just dont-fuck-my-build
    rm -rfv result

build *args:
    just pre-build
    scripts/flake-build.sh {{args}}
    just post-build

post-build:
    nix-shell -p lolcat --run 'echo "Build Finished." | lolcat'
    quick-results

#
# test:
#     sudo nixos-rebuild test --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.

iso:
    # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
    # rm ~/virtualization-boot-files/template/iso/nixos*
    just pre-build
    nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
    just post-build
    cp result/iso/nixos* ~/virtualization-boot-files/template/iso/.
    nix-shell -p lolcat --run 'ls ~/virtualization-boot-files/template/iso | grep nixos | lolcat'
    rm -rfv result

iso-keep:
    just pre-build
    nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
    just post-build

keygen:
    echo "User Key @ ~/.config/sops/age/keys.txt"
    nix-shell -p age --run 'mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt'
    echo "Host Key based on /etc/ssh/ssh_host_ed25519_key.pub"
    nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

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
    nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/secrets.yaml" | lolcat'
    nano ~/nix-secrets/.sops.yaml
    sops ~/nix-secrets/secrets.yaml
    just rekey

# Update the keys in the secrets file
rekey:
    just dont-fuck-my-build
    nix-shell -p lolcat --run 'echo "Updating ~/nix-secrets/secrets.yaml" | lolcat'
    cd ../nix-secrets && (\
    nix-shell -p sops --run "sops updatekeys -y secrets.yaml" && \
    git add -u && (git commit -m "chore: rekey" || true) && git push \
    )
    nix-shell -p lolcat --run 'echo "Updated Secrets!" | lolcat'
    just dont-fuck-my-build

sops-fix:
    just pre-home
    just update-nix-secrets
    home-manager switch --refresh --flake ~/.dotfiles/.
    systemctl --user reset-failed
    just home

update-nix-secrets:
    just rekey
    (cd ../nix-secrets && git fetch && git rebase) || true
    nix flake lock --update-input nix-secrets

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
