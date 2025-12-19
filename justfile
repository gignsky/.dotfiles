# SOPS_FILE := "../nix-secrets/secrets.yaml"

default:
	# @just --list | bat --file-name "justfile"
	@just --choose

#perform a lock update
lock:
  @nix-shell -p lolcat --run "echo 'Locking Nix Flake & Commiting Lock File' | lolcat 2> /dev/null"
  nix flake lock --commit-lock-file
  @nix-shell -p lolcat --run "echo 'For your convience, the two most recent git commit have been posted below:' | lolcat 2> /dev/null"
  git log -2

pre-pull-stash:
	@nix-shell -p lolcat --run "echo 'Running pre-pull stash on all files in dotfiles and nix-secrets' | lolcat 2> /dev/null"
	git stash push -m "pre-pull"
	cd ~/nix-secrets
	git stash push -m "pre-pull"
	cd ~/.dotfiles
	
post-pull-stash:
  @nix-shell -p lolcat --run "echo 'Running post-pull stash to unstash files stashed before the pre-pull' | lolcat 2> /dev/null"
  @- git stash pop "stash@{0}"
  cd ~/nix-secrets
  @- git stash pop "stash@{0}"
  cd ~/.dotfiles
  @nix-shell -p lolcat --run "echo 'Post-Pull Unstash Complete' | lolcat 2> /dev/null"

pull:
	@nix-shell -p lolcat --run "echo 'Running git pull on all files in dotfiles and nix-secrets' | lolcat 2> /dev/null"
	just pre-pull-stash
	git pull
	just pull-nix-secrets
	just post-pull-stash

pull-rebuild:
	just pull
	@nix-shell -p lolcat --run "echo 'Rebuilding...' | lolcat 2> /dev/null"
	just rebuild
	@nix-shell -p lolcat --run "echo 'Rebuilt.' | lolcat 2> /dev/null"

pull-home:
  @nix-shell -p lolcat --run "echo 'Rebuilding Home-Manager...' | lolcat 2> /dev/null"
  just pull
  just home
  @nix-shell -p lolcat --run "echo 'Home-Manager Rebuilt.' | lolcat 2> /dev/null"

pull-rebuild-full:
  @nix-shell -p lolcat --run "echo 'Full Rebuild Running...' | lolcat 2> /dev/null"
  just pull-rebuild
  just pull-home
  @nix-shell -p lolcat --run "echo 'Full Rebuild Complete.' | lolcat 2> /dev/null"

pull-nix-secrets:
  cd ~/nix-secrets && git fetch && git pull && cd ~/.dotfiles

# Run before every rebuild, every time
rebuild-pre:
  @nix-shell -p lolcat --run 'echo "[PRE] Rebuilding NixOS..." | lolcat 2> /dev/null'
  just dont-fuck-my-build
  @nix-shell -p lolcat --run 'echo "Updating Nix-Secrets Repo..." | lolcat 2> /dev/null'

dont-fuck-my-build:
  @nix develop -c echo '*The Pre-Commit has been given a chance to Update!*'
  git ls-files --others --exclude-standard -- '*.nix' '*.sh' | xargs -r git add -v
  nix flake update nix-secrets --commit-lock-file
  @nix-shell -p lolcat --run 'echo "Very little chance your build is fucked! 👍" | lolcat 2> /dev/null'

switch args="":
	just rebuild {{args}}
	just home

clean:
  @echo "🧹 Starting smart clean process..."
  # First: Failsafe logging checkpoint (in case OpenCode gets broken)
  @echo "📝 Pre-clean failsafe logging checkpoint..."
  @bash -c 'source scripts/scotty-logging-lib.sh && failsafe_log "Smart clean initiated" "preserving OpenCode history, cleaning caches"' 
  
  # Clean standard caches (safe)
  rm -rfv ~/.cargo/
  rm -rfv ~/.cache/pre-commit/
  rm -rfv ~/.cache/nvf/
  rm -rfv ~/.cache/starship/
  rm -rfv ~/.config/zsh/zplug
  rm -rfv result
  
  # Smart OpenCode cleanup - preserve history, clean configuration
  @echo "🔧 Smart OpenCode cleanup (preserving history)..."
  @if [ -d ~/.local/share/opencode ]; then \
    echo "📁 Backing up OpenCode history..."; \
    mkdir -p /tmp/opencode-backup; \
    cp -r ~/.local/share/opencode/log /tmp/opencode-backup/ 2>/dev/null || true; \
    cp -r ~/.local/share/opencode/storage /tmp/opencode-backup/ 2>/dev/null || true; \
    cp ~/.local/share/opencode/auth.json /tmp/opencode-backup/ 2>/dev/null || true; \
    echo "🗑️ Cleaning OpenCode config (will rebuild)..."; \
    rm -rf ~/.local/share/opencode/snapshot 2>/dev/null || true; \
    rm -rf ~/.local/share/opencode/exports 2>/dev/null || true; \
    rm -rf ~/.local/share/opencode/bin 2>/dev/null || true; \
    echo "📂 Restoring OpenCode history..."; \
    cp -r /tmp/opencode-backup/log ~/.local/share/opencode/ 2>/dev/null || true; \
    cp -r /tmp/opencode-backup/storage ~/.local/share/opencode/ 2>/dev/null || true; \
    cp /tmp/opencode-backup/auth.json ~/.local/share/opencode/ 2>/dev/null || true; \
    rm -rf /tmp/opencode-backup; \
    echo "✅ OpenCode history preserved, config cleaned"; \
  else \
    echo "ℹ️ OpenCode not yet initialized - nothing to clean"; \
  fi
  
  @if [ -d ~/.config/opencode ]; then \
    echo "🧹 Cleaning OpenCode config directory (preserving node_modules temporarily)..."; \
    mkdir -p /tmp/opencode-node-backup; \
    cp -r ~/.config/opencode/node_modules /tmp/opencode-node-backup/ 2>/dev/null || true; \
    rm -rf ~/.config/opencode; \
    mkdir -p ~/.config/opencode; \
    cp -r /tmp/opencode-node-backup/node_modules ~/.config/opencode/ 2>/dev/null || true; \
    rm -rf /tmp/opencode-node-backup; \
    echo "✅ OpenCode config cleaned (node_modules preserved for faster rebuild)"; \
  fi
  
  # Quick results cleanup
  nix run .#quick-results
  
  # Post-clean failsafe logging
  @echo "📝 Post-clean failsafe logging checkpoint..."
  @bash -c 'source scripts/scotty-logging-lib.sh && failsafe_log "Smart clean completed" "OpenCode ready for rebuild, caches cleared"'
  @echo "✅ Smart clean complete - OpenCode history preserved, configuration reset for rebuild"

# Run after every rebuild, some of the time
rebuild-post:
	# just check-sops
	@nix-shell -p lolcat --run 'echo "[POST] Rebuilt." | lolcat 2> /dev/null'
	@echo "✅ Rebuild completed successfully - engineering logs handled by rebuild script"

# Rebuild the system
rebuild args="":
	just rebuild-pre
	@nix-shell -p lolcat --run 'echo "[REBUILD] Attempting Rebuild..." | lolcat' 2> /dev/null 
	nix run .#system-flake-rebuild -- {{args}}
	just rebuild-post

# Rebuild the system verbosely (with SCOTTY_DEBUG)
rebuild-v args="":
	just rebuild-pre
	@nix-shell -p lolcat --run 'echo "[REBUILD-V] Attempting Verbose Rebuild..." | lolcat' 2> /dev/null 
	env SCOTTY_DEBUG=true nix run .#system-flake-rebuild -- {{args}}
	just rebuild-post

# Test rebuilds the system
rebuild-test args="":
	just rebuild-pre
	nix run .#system-flake-rebuild-test -- {{args}}
	@nix-shell -p lolcat --run 'echo "[TEST] Finished." | lolcat 2> /dev/null'
	@echo "📊 Logging test rebuild to engineering records..."
	@just log-commit "System test rebuild completed successfully"
	@echo "🧹 Cleaning up engineering logs..."
	@git add scottys-journal/ 2>/dev/null || true
	@git commit -m "📊 Scotty: Auto-update engineering logs" 2>/dev/null || true

# Rebuild-full with new shell
rebuild-full-new args="":
        just rebuild-full {{args}}
        nu

# Rebuild the system and check sops and home manager
rebuild-full args="":
	just rebuild {{args}}
	just home {{args}}

# Bare rebuild commands (minimal, no logging, no scripts)
rebuild-bare host=`scripts/get-flake-target.sh`:
	@echo "Bare system rebuild for {{host}}..."
	sudo nixos-rebuild switch --flake .#{{host}}

home-bare host=`scripts/get-flake-target.sh`:
	@echo "Bare home-manager rebuild for gig@{{host}}..."
	home-manager switch --flake .#gig@{{host}}

rebuild-full-bare host=`scripts/get-flake-target.sh`:
	@echo "Bare full rebuild for {{host}}..."
	sudo nixos-rebuild switch --flake .#{{host}}
	home-manager switch --flake .#gig@{{host}}

# Test rebuild commands (dry-run evaluation without applying)
test-rebuild host=`scripts/get-flake-target.sh`:
	@echo "Testing system rebuild for {{host}} (evaluation only)..."
	nixos-rebuild dry-run --flake .#{{host}} --verbose

test-home host=`scripts/get-flake-target.sh`:
	@echo "Testing home-manager rebuild for gig@{{host}} (evaluation only)..."
	home-manager build --flake .#gig@{{host}} --verbose

test-rebuild-full host=`scripts/get-flake-target.sh`:
	@echo "Testing full rebuild for {{host}} (evaluation only)..."
	nixos-rebuild dry-run --flake .#{{host}} --verbose
	home-manager build --flake .#gig@{{host}} --verbose

single-update:
	nix run github:gignsky/nix-update-input

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
	nix flake check --keep-going --allow-import-from-derivation
	@nix-shell -p lolcat --run 'echo "[CHECK] Finished." | lolcat 2> /dev/null'

check-iso:
	just dont-fuck-my-build
	nix flake check --impure --no-build nixos-installer/.
	@nix-shell -p lolcat --run 'echo "[CHECK] Finished." | lolcat 2> /dev/null'

pre-commit:
	pre-commit run --all-files

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
	@nix-shell -p lolcat --run 'echo "[PRE-HOME] Finished." | lolcat 2> /dev/null'

# Runs after every home rebuild
post-home:
	@nix-shell -p lolcat --run 'echo "[POST-HOME] Finished." | lolcat 2> /dev/null'
	@echo "✅ Home-manager rebuild completed - engineering logs handled by rebuild script"

simple-home *ARGS:
	nix run .#home-manager-flake-rebuild -- {{ ARGS }}

home *ARGS:
  just pre-home
  @nix-shell -p lolcat --run 'echo "[HOME] Attempting Home Rebuild..." | lolcat 2> /dev/null'
  just simple-home {{ ARGS }}
  just post-home

# Rebuild home-manager verbosely (with SCOTTY_DEBUG)
home-v *ARGS:
  just pre-home
  @nix-shell -p lolcat --run 'echo "[HOME-V] Attempting Verbose Home Rebuild..." | lolcat 2> /dev/null'
  env SCOTTY_DEBUG=true just simple-home {{ ARGS }}
  just post-home

# Runs just home
# home-core:

#nu'er home
nu home:
  just new home

# Runs just home and then zsh
new home:
  just clean
  just home
  exec nu

home-trace:
	just dont-fuck-my-build
	home-manager switch --flake ~/.dotfiles/. --show-trace
	@nix-shell -p lolcat --run 'echo "[HOME-TRACE] Finished." | lolcat 2> /dev/null'

gc:
	@nix-shell -p lolcat --run 'nix-collect-garbage --delete-old | lolcat 2> /dev/null'
	@nix-shell -p lolcat --run 'nix store gc | lolcat 2> /dev/null'

pre-build:
	@nix-shell -p lolcat --run 'echo "Pre-Build Starting..." | lolcat 2> /dev/null'
	just dont-fuck-my-build
	rm -rfv result

build *args:
	just pre-build
	nix run .#flake-build -- {{args}}
	just post-build

post-build:
	@nix-shell -p lolcat --run 'echo "Build Finished." | lolcat 2> /dev/null'
	nix run .#quick-results

#
# test:
#     sudo nixos-rebuild test --flake ~/.dotfiles/.
#     home-manager switch --flake ~/.dotfiles/.

# helper justfile arg
setup-vm-pre:
	@nix-shell -p lolcat --run 'echo "[VM] Running VM pre-setup..." | lolcat 2> /dev/null'
	just cleanup-vm
	@nix-shell -p lolcat --run 'echo "[VM] VM pre-setup complete." | lolcat 2> /dev/null'

# helper justfile arg
setup-vm-post:
	@nix-shell -p lolcat --run 'echo "[VM] Running VM post-setup..." | lolcat 2> /dev/null'
	@nix-shell -p lolcat --run 'echo "[VM] Showing Results..." | lolcat 2> /dev/null'
	nix run .#quick-results
	@nix-shell -p lolcat --run 'echo "[VM] Making tmp-iso dir..." | lolcat 2> /dev/null'
	mkdir -p ./tmp-iso/nixos-vm
	@nix-shell -p lolcat --run 'echo "[VM] Creating qemu img from ISO..." | lolcat 2> /dev/null'
	nix shell nixpkgs#qemu --command bash -c 'qemu-img create -f qcow2 -q ./tmp-iso/nixos-vm/vm.img 16G'
	@nix-shell -p lolcat --run 'echo "[VM] VM post-setup complete." | lolcat 2> /dev/null'


# helper justfile arg
setup-vm-minimal:
	just setup-vm-pre
	@nix-shell -p lolcat --run 'echo "[VM] Building ISO..." | lolcat 2> /dev/null'
	nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
	just setup-vm-post

# helper justfile arg
setup-vm-full-vm:
	just setup-vm-pre
	@nix-shell -p lolcat --run 'echo "[VM] Building ISO..." | lolcat 2> /dev/null'
	nix build .#nixosConfigurations.full-vm.config.system.build.isoImage
	@nix-shell -p lolcat --run 'echo "[VM] Cleaning Results dir..." | lolcat 2> /dev/null'
	just setup-vm-post

# cleanup vm files
cleanup-vm:
	@nix-shell -p lolcat --run 'echo "[VM] Removing tmp-iso dir..." | lolcat 2> /dev/null'
	rm -rfv ./tmp-iso
	@nix-shell -p lolcat --run 'echo "[VM] tmp-iso Removed." | lolcat 2> /dev/null'
	@nix-shell -p lolcat --run 'echo "[VM] Cleaning Results dir..." | lolcat 2> /dev/null'
	just clean
	@nix-shell -p lolcat --run 'echo "[VM] Finished." | lolcat 2> /dev/null'

# helper justfile arg
call-vm:
    @nix-shell -p lolcat --run 'echo "[VM] Running VM..." | lolcat 2> /dev/null'
    - nix run .#run-iso-vm -- result/iso/*.iso ./tmp-iso/nixos-vm/vm.img
    @nix-shell -p lolcat --run 'echo "[VM] VM Closed." | lolcat 2> /dev/null'

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
	@nix-shell -p lolcat --run 'echo "[VM] Reconnecting to VM..." | lolcat 2> /dev/null'
	- nix run .#run-iso-vm -- result/iso/*.iso ./tmp-iso/nixos-vm/vm.img --choose
	@nix-shell -p lolcat --run 'echo "[VM] VM Closed." | lolcat 2> /dev/null'

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
	@nix-shell -p lolcat --run 'ls ~/virtualization-boot-files/template/iso | grep nixos | lolcat 2> /dev/null'
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
  -just pull-nix-secrets
  @just sops-config-edit
  @just sops-edit
  @just sops-secrets
  @just rekey

#edit .sops.yaml only (no rekey)
sops-config-edit:
  -just pull-nix-secrets
  @nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/.sops.yaml" | lolcat 2> /dev/null'
  vi ~/nix-secrets/.sops.yaml

#edit secrets.yaml only (no rekey)
sops-edit:
  -just pull-nix-secrets
  @nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/secrets.yaml" | lolcat 2> /dev/null'
  sops ~/nix-secrets/secrets.yaml

#alias for the sops-secrets command
notes-edit: 
  # -git add notes.md
  # -git commit -m "updated notes via just notes"
  @just sops-secrets
  # @just rekey

# Edit secret notes and commit
notes-edit-commit: notes-edit 
  just rekey

# commit regular note file
noted:
  git add notes.md
  git commit -m "new notes!!"
  @nix-shell -p lolcat --run 'echo "It is so Noted!!" | lolcat 2> /dev/null'


#edit secret notes.mdl only (no rekey)
sops-secrets:
  -just pull-nix-secrets
  @nix-shell -p lolcat --run 'echo "Editing ~/nix-secrets/notes.md" | lolcat 2> /dev/null'
  sops ~/nix-secrets/notes.md

notes-commit:
  @just sops-secrets
  @nix-shell -p lolcat --run 'echo "Committing notes.md" | lolcat 2> /dev/null'
  cd ../nix-secrets && (\
  git add -u && (git commit --no-verify -m "chore: updating notes" || true) && git push \
  )
  @nix-shell -p lolcat --run 'echo "Updated Notes!" | lolcat 2> /dev/null'

# Update the keys in the secrets file without pre-commit hooks (for bootstrap)
rekey:
  @just dont-fuck-my-build
  -just pull-nix-secrets
  @nix-shell -p lolcat --run 'echo "Rekeying with sops: ~/nix-secrets/secrets.yaml" | lolcat 2> /dev/null'
  cd ~/nix-secrets && (\
  nix-shell -p sops --run "sops updatekeys -y secrets.yaml" && \
  nix-shell -p sops --run "sops updatekeys -y notes.md" && \
  git add -u && (git commit --no-verify -m "chore: rekey" || true) && git push \
  )
  @nix-shell -p lolcat --run 'echo "Updated Secrets!" | lolcat 2> /dev/null'
  @just dont-fuck-my-build
  nix flake update nix-secrets --commit-lock-file

sops-fix:
  just pre-home
  just update-nix-secrets
  systemctl --user reset-failed
  home-manager switch --refresh --flake ~/.dotfiles/.
  just home

update-nix-secrets:
	just rekey
	(cd ../nix-secrets && git fetch && git rebase) || true
	nix flake update nix-secrets --commit-lock-file

store-photo:
	nix-shell -p graphviz nix-du --run "nix-du -s=500MB | \dot -Tpng > store.png"

bootstrap *args:
	just dont-fuck-my-build
	nix run .#bootstrap-nixos -- {{args}}

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

# Interactive script packager with fzf selection and OpenCode test generation
package-script:
	nix run .#package-script

# Check hardware configuration synchronization
check-hardware:
	nix run .#check-hardware-config

# Batched logging commands for reduced commit noise
batch-commit-logs:
	@echo "📊 Committing batched engineering logs..."
	@bash -c 'cd ~/.dotfiles && source scripts/scotty-logging-lib.sh && _commit_batch_logs'

batch-status:
	@echo "📊 Batch logging status:"
	@bash -c 'cd ~/.dotfiles && if [ -d ".batch-logs" ]; then find .batch-logs -name "*.batch" -exec echo "  📄 {}" \; -exec grep -c "^---BATCH-ENTRY-START---" {} \; 2>/dev/null | paste - - | sed "s/\t/ entries: /"; else echo "  No pending batch logs"; fi'

# Manual engineering log entry for commits
log-commit message="":
	@if [ -z "{{message}}" ]; then \
		echo "📝 Logging most recent commit to engineering records..."; \
		bash -c 'cd ~/.dotfiles && source scripts/scotty-logging-lib.sh && scotty_log_event "git-commit" "$$(git log -1 --pretty=%s)"'; \
	else \
		echo "📝 Logging custom message to engineering records..."; \
		bash -c 'cd ~/.dotfiles && source scripts/scotty-logging-lib.sh && scotty_log_event "git-commit" "{{message}}"'; \
	fi
	@echo "✅ Engineering log entry created successfully"
	@echo "🧹 Auto-committing engineering logs..."
	@git add scottys-journal/ 2>/dev/null || true
	@git commit -m "📊 Scotty: Auto-commit engineering logs" 2>/dev/null || true
	@echo "✅ Engineering logs committed to repository"

# Scotty's system state analysis and gap detection
log-status:
	@echo "🔍 Running Chief Engineer's system state analysis..."
	@bash -c 'cd ~/.dotfiles && source scripts/scotty-logging-lib.sh && log_status'
