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
	nix build .#nixosConfigurations.spacedock.config.system.build.isoImage
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
vm-spacedock:
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
vm-tmp-spacedock:
	just setup-vm-full-vm
	just call-vm
	just cleanup-vm
