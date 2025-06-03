# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ minimalIsoPath
, configLib
, pkgs
, ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    # ./hardware-configuration.nix
    # # core utils
    # (configLib.relativeToRoot "hosts/common/core")

    # # optional
    # # (configLib.relativeToRoot "hosts/common/optional/gui.nix")
    # # (configLib.relativeToRoot "hosts/common/optional/firefox.nix")
    # # ../common/optional/xrdp.nix

    # #gig users
    # (configLib.relativeToRoot "hosts/common/users/gig")

    # # wifi
    # (configLib.relativeToRoot "hosts/common/optional/wifi.nix")
  ];

  networking.hostName = "minimal-iso-vm";

  # Services needed for virtualization
  services.libvirtd.enable = true; # If you prefer libvirt/virt-manager
  # Or if you want to use raw QEMU directly:
  # virtualisation.qemu.enable = true;
  # virtualisation.qemu.runScript = ''
  #   qemu-system-x86_64 \
  #     -m 2G \
  #     -cpu host \
  #     -smp 2 \
  #     -vga std \
  #     -display gtk,gl=on \
  #     -cdrom "${minimalIsoPath}" \
  #     -hda /var/lib/vm-tester/disk.img \
  #     -boot d \
  #     -enable-kvm \
  #     -net nic,model=virtio \
  #     -net user,hostfwd=tcp::2222-:22 \
  #     # You might want to mount a host directory for your bootstrapping script
  #     # -virtfs local,path=/path/to/your/bootstrapping/scripts,mount_tag=myscripts,security_model=passthrough
  # '';

  # Define the VM using `virtualisation.qemu.machines` (recommended for easier management)
  virtualisation.qemu.machines = {
    "minimal-iso-vm" = {
      # The amount of RAM for your test VM
      memory = 2048; # 2GB
      # Number of CPU cores
      cores = 2;
      # Specify the disk image for the VM
      # This will create a new disk image if it doesn't exist.
      # You might want to remove this file before each test run if you want a clean slate.
      diskImages = [
        {
          size = "20G"; # Size of the virtual hard drive for the VM
          file = "/var/lib/vm-tester/disk.qcow2"; # Path to the disk image
        }
      ];
      # Boot from the ISO image
      # The `minimalIsoPath` is passed from your flake.nix
      bootDevices = [
        { type = "cdrom"; file = minimalIsoPath; }
        { type = "disk"; file = "/var/lib/vm-tester/disk.qcow2"; } # Ensure it boots from CD first
      ];
      # Enable KVM for hardware virtualization
      options = [
        "-enable-kvm"
        "-cpu host" # Use host CPU features
        "-display gtk,gl=on" # Or "vnc=:1" for VNC access
        # Network configuration: virtio for performance, user mode for simplicity
        "-net nic,model=virtio"
        "-net user,hostfwd=tcp::2222-:22" # Forward host port 2222 to VM's port 22 (for SSH)
        # Optional: Share a host directory with the VM for your bootstrapping script
        # -virtfs local,path=${toString /path/to/your/bootstrapping/scripts},mount_tag=nix-scripts,security_model=passthrough
      ];
      # Autostart the VM when the host system starts (optional, useful for dedicated testers)
      autostart = true;
    };
  };

  # Allow the user who will be running the VM to interact with QEMU
  users.users.gig = {
    isNormalUser = true;
    extraGroups = [ "kvm" "libvirtd" ]; # Adjust based on your setup
  };

  # Environment for your user, particularly if you want to run `virt-viewer`
  environment.systemPackages = with pkgs; [
    qemu
    # virt-viewer # If you use libvirt and want a graphical interface
  ];

  # You might want to clean up the disk image before each run for fresh tests
  # Consider a small script that deletes /var/lib/vm-tester/disk.qcow2
  # before you run `nixos-rebuild switch --flake .#vmTester`
}
