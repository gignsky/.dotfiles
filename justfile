# SOPS_FILE := "../nix-secrets/secrets.yaml"

default:
	@just --list | bat --file-name "justfile"

pre-pull-stash:
	nix-shell -p lolcat --run "echo 'Running pre-pull stash on all files in dotfiles and nix-secrets' | lolcat"
	git stash push -m "pre-pull"
	cd ~/nix-secrets
	git stash push -m "pre-pull"
	cd ~/.dotfiles
	
pull:
	nix-shell -p lolcat --run "echo 'Running git pull on all files in dotfiles and nix-secrets' | lolcat"
	just pre-pull-stash
	git pull
	just pull-nix-secrets

pull-rebuild:
	just pull
	nix-shell -p lolcat --run "echo 'Rebuilding...' | lolcat"
	just rebuild
	nix-shell -p lolcat --run "echo 'Rebuilt.' | lolcat"

pull-home:
	nix-shell -p lolcat --run "echo 'Rebuilding Home-Manager...' | lolcat"
	just pull
	just home
	nix-shell -p lolcat --run "echo 'Home-Manager Rebuilt.' | lolcat"

pull-rebuild-full:
	nix-shell -p lolcat --run "echo 'Full Rebuild Running...' | lolcat"
	just pull-rebuild
	just pull-home
	nix-shell -p lolcat --run "echo 'Full Rebuild Complete.' | lolcat"

pull-nix-secrets:
	cd ~/nix-secrets && git fetch && git pull && cd ~/.dotfiles

# Run before every rebuild, every time
rebuild-pre:
	nix-shell -p lolcat --run 'echo "[PRE] Rebuilding NixOS..." | lolcat'
	just dont-fuck-my-build
	nix-shell -p lolcat --run 'echo "Updating Nix-Secrets Repo..." | lolcat'

dont-fuck-my-build:
	git ls-files --others --exclude-standard -- '*.nix' | xargs -r git add -v
	nix flake lock --update-input nix-secrets
	nix-shell -p lolcat --run 'echo "Very little chance your build is fucked! 👍" | lolcat'

switch args="":
	just rebuild {{args}}
	just home

clean:
	rm -rfv result
	quick-results

# Run after every rebuild, some of the time
rebuild-post:
	# just check-sops
	nix-shell -p lolcat --run 'echo "[POST] Rebuilt." | lolcat'

# Rebuild the system
rebuild args="":
	just rebuild-pre
	nix-shell -p lolcat --run 'echo "[REBUILD] Attempting Rebuild..." | lolcat' 2> /dev/null 
	scripts/system-flake-rebuild.sh {{args}}
	just rebuild-post

# Rebuild the system verbosely
rebuild-v args="":
	just rebuild-pre
	scripts/system-flake-rebuild-verbose.sh {{args}}
	just rebuild-post

# Test rebuilds the system
rebuild-test args="":
	just rebuild-pre
	scripts/system-flake-rebuild-test.sh {{args}}
	nix-shell -p lolcat --run 'echo "[TEST] Finished." | lolcat'

# Rebuild the system and check sops and home manager
rebuild-full args="":
	just rebuild {{args}}
	just home

single-update:
	nix run github:vimjoyer/nix-update-input

# Update the flake
update:
	just dont-fuck-my-build
	just rekey
	nix flake update --commit-lock-file

update-no-commit:
	just dont-fuck-my-build
	just rekey
	nix flake update

# Rebuild the system and update the flake
update-rebuild-no-commit:
	just update-no-commit
	just rebuild

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

show:
	just dont-fuck-my-build
	just om show .

om *ARGS:
	nix run github:juspay/omnix -- {{ ARGS }}

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
	nix-shell -p lolcat --run 'echo "[POST-HOME] Finished." | lolcat'

home:
	just pre-home
	nix-shell -p lolcat --run 'echo "[HOME] Attempting Home Rebuild..." | lolcat'
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

# helper justfile arg
setup-vm-pre:
	nix-shell -p lolcat --run 'echo "[VM] Running VM pre-setup..." | lolcat'
	nix-shell -p lolcat --run 'echo "[VM] Cleaning Results dir..." | lolcat'
	just clean
	nix-shell -p lolcat --run 'echo "[VM] VM pre-setup complete." | lolcat'

# helper justfile arg
setup-vm-post:
	nix-shell -p lolcat --run 'echo "[VM] Running VM post-setup..." | lolcat'
	nix-shell -p lolcat --run 'echo "[VM] Showing Results..." | lolcat'
	quick-results
	nix-shell -p lolcat --run 'echo "[VM] Making tmp-iso dir..." | lolcat'
	mkdir -p ./tmp-iso/nixos-vm
	nix-shell -p lolcat --run 'echo "[VM] Creating qemu img from ISO..." | lolcat'
	nix shell nixpkgs#qemu --command bash -c 'qemu-img create -f qcow2 -q ./tmp-iso/nixos-vm/vm.img 16G'
	nix-shell -p lolcat --run 'echo "[VM] VM post-setup complete." | lolcat'


# helper justfile arg
setup-vm-minimal:
	just setup-vm-pre
	nix-shell -p lolcat --run 'echo "[VM] Building ISO..." | lolcat'
	nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
	just setup-vm-post

# helper justfile arg
setup-vm-full-vm:
	just setup-vm-pre
	nix-shell -p lolcat --run 'echo "[VM] Building ISO..." | lolcat'
	nix build .#nixosConfigurations.full-vm.config.system.build.isoImage
	nix-shell -p lolcat --run 'echo "[VM] Cleaning Results dir..." | lolcat'
	just setup-vm-post

# cleanup vm files
cleanup-vm:
	nix-shell -p lolcat --run 'echo "[VM] Removing tmp-iso dir..." | lolcat'
	rm -rfv ./tmp-iso
	nix-shell -p lolcat --run 'echo "[VM] tmp-iso removed." | lolcat'
	nix-shell -p lolcat --run 'echo "[VM] Cleaning Results dir..." | lolcat'
	just clean
	nix-shell -p lolcat --run 'echo "[VM] Finished." | lolcat'

# helper justfile arg
call-vm:
	nix-shell -p lolcat --run 'echo "[VM] Running VM..." | lolcat'
	- nix shell nixpkgs#qemu --command bash -c 'bash scripts/run-iso-vm.sh result/iso/*.iso ./tmp-iso/nixos-vm/vm.img'
	nix-shell -p lolcat --run 'echo "[VM] VM Closed." | lolcat'

# run vm with minimal iso - while not deleting files afterwards
vm-minimal:
	just setup-vm-minimal
	just call-vm

# run vm with full iso - while not deleting files afterwards
vm-full:
	just setup-vm-full-vm
	just call-vm

# reconnect to vm that has already been created
vm-reconnect:
	nix-shell -p lolcat --run 'echo "[VM] Reconnecting to VM..." | lolcat'
	just call-vm

# run vm with minimal iso - while deleting files afterwards
vm-tmp-minimal:
	just setup-vm-minimal
	just call-vm
	just cleanup-vm

# run vm with full iso - while deleting files afterwards
vm-tmp-full:
	just setup-vm-full-vm
	just call-vm
	just cleanup-vm

iso:
	# If we dont remove this folder, libvirtd VM doesn't run with the new iso...
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
	echo "cat output from .config/sops/age/keys.txt"
	bat ~/.config/sops/age/keys.txt

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

#edit all sops files then rekey
sops:
	nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/secrets.yaml" | lolcat'
	nano ~/nix-secrets/.sops.yaml
	sops ~/nix-secrets/secrets.yaml
	just rekey

#edit .sops.yaml only (no rekey)
sops-edit:
	nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/.sops.yaml" | lolcat'
	nano ~/nix-secrets/.sops.yaml

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
	systemctl --user reset-failed
	home-manager switch --refresh --flake ~/.dotfiles/.
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
#   nix flake update nix-secrets
#
# iso:
#   # If we dont remove this folder, libvirtd VM doesn't run with the new iso...
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
