# Bootloader Configuration Documentation

This document explains the bootloader options available in the `.dotfiles` repository and their compatibility with dual-boot Windows configurations.

## Overview

The repository provides a flexible bootloader configuration system that supports multiple bootloader types through the `bootloader.kind` option in `hosts/common/core/bootloader.nix`.

## Available Bootloader Options

### 1. GRUB (`bootloader.kind = "grub"`)

**Best for**: Dual-boot setups with Windows, complex boot configurations, legacy systems

**Advantages**:
- Excellent Windows dual-boot support with os-prober
- Works with both BIOS and UEFI systems
- Highly configurable and themeable
- Robust boot menu with recovery options

**Configuration**:
```nix
bootloader = {
  kind = "grub";
  grub = {
    useOSProber = true;      # Automatically detect Windows
    efiSupport = true;       # Enable UEFI support
    efiInstallAsRemovable = true;  # Install as removable for compatibility
    device = "nodev";        # Use "nodev" for UEFI systems
  };
};
```

### 2. systemd-boot (`bootloader.kind = "systemd-boot"`)

**Best for**: UEFI-only systems, simple configurations, faster boot times

**Advantages**:
- Faster boot times
- Simpler configuration
- Native UEFI integration
- Cleaner boot menu

**Limitations**:
- UEFI only (no BIOS support)
- Limited dual-boot support (manual configuration required)
- No automatic Windows detection

**Configuration**:
```nix
bootloader = {
  kind = "systemd-boot";
  systemd-boot = {
    configurationLimit = 10;  # Number of generations in boot menu
    consoleMode = "max";      # Console resolution
  };
};
```

### 3. None (`bootloader.kind = "none"`)

**Best for**: WSL, containers, specialized environments

**Use case**: Systems that don't need a traditional bootloader

## Dual-Boot Configuration

### GRUB with Windows (Recommended)

For dual-boot setups with Windows, GRUB is the recommended option:

```nix
# In your host configuration (e.g., hosts/merlin/default.nix)
bootloader = {
  kind = "grub";
  grub = {
    useOSProber = true;           # Detect Windows automatically
    efiSupport = true;            # Required for modern systems
    efiInstallAsRemovable = true; # Better compatibility
    device = "nodev";             # UEFI systems use "nodev"
  };
};

# Additional GRUB packages might be needed
environment.systemPackages = with pkgs; [
  grub2_efi
  os-prober
];
```

### systemd-boot with Windows (Manual)

While possible, systemd-boot requires manual Windows entry configuration:

```nix
bootloader = {
  kind = "systemd-boot";
  systemd-boot = {
    configurationLimit = 10;
    consoleMode = "max";
  };
};

# Manual Windows entry (create in /boot/loader/entries/windows.conf)
# This would need to be added manually or through systemd.services
```

## Installation Procedures

### Fresh Installation

For new installations on dual-boot systems:

1. **Install Windows first** (if not already installed)
2. **Shrink Windows partition** to make space for NixOS
3. **Boot from NixOS ISO** and run the bootstrap script
4. **Use GRUB configuration** for automatic Windows detection

### Switching Between Bootloaders

**⚠️ Safety Warning**: Switching bootloaders can make your system unbootable if not done carefully.

#### From systemd-boot to GRUB

```bash
# 1. Update configuration
# Edit your host configuration to change bootloader.kind to "grub"

# 2. Rebuild system
sudo nixos-rebuild switch --flake .#your-hostname

# 3. The switch should handle the transition automatically
```

#### From GRUB to systemd-boot

```bash
# 1. Update configuration  
# Edit your host configuration to change bootloader.kind to "systemd-boot"

# 2. Rebuild system
sudo nixos-rebuild switch --flake .#your-hostname

# 3. Clean up old GRUB files if needed
sudo rm -rf /boot/grub
```

**Note**: Always have a recovery USB available when switching bootloaders.

## Bootloader Safety

### Safe Switching Conditions

**✅ Generally Safe**:
- systemd-boot → GRUB (GRUB can coexist)
- Fresh installation with proper bootloader choice
- Systems with working recovery media

**⚠️ Use Caution**:
- GRUB → systemd-boot (removes GRUB completely)
- Dual-boot systems (test thoroughly)
- Production systems (test on similar hardware first)

**❌ Not Recommended**:
- Switching during system updates
- On systems without recovery options
- Without understanding your current boot setup

### Recovery Procedures

If bootloader switching fails:

1. **Boot from NixOS ISO**
2. **Mount the system**:
   ```bash
   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mount /dev/disk/by-label/BOOT /mnt/boot
   ```
3. **Reinstall bootloader**:
   ```bash
   sudo nixos-install --root /mnt --no-root-passwd --no-channel-copy
   ```

## Host-Specific Recommendations

### merlin (Dual-boot with Windows)

**Recommended configuration**:
```nix
bootloader = {
  kind = "grub";
  grub = {
    useOSProber = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
};
```

**Rationale**: GRUB's os-prober will automatically detect and add Windows to the boot menu.

### ganosLal (Dual-boot with Windows)

**Recommended configuration**:
```nix
bootloader = {
  kind = "grub";
  grub = {
    useOSProber = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
};
```

**Rationale**: Same as merlin, GRUB provides the best dual-boot experience.

### wsl (WSL environment)

**Current configuration**:
```nix
bootloader.kind = "none";
```

**Rationale**: WSL doesn't need a traditional bootloader.

## Configuration Options Reference

### GRUB Options

```nix
bootloader.grub = {
  useOSProber = true;           # Enable OS detection
  efiSupport = true;            # UEFI support
  efiInstallAsRemovable = true; # Install as removable
  device = "nodev";             # Bootloader device ("nodev" for UEFI)
};
```

### systemd-boot Options

```nix
bootloader.systemd-boot = {
  configurationLimit = 10;     # Max generations in menu
  consoleMode = "max";         # Console mode ("0", "1", "2", "auto", "max", "keep")
};
```

## Troubleshooting

### Common Issues

#### GRUB not detecting Windows

```bash
# Ensure os-prober is enabled and working
sudo os-prober

# Manually regenerate GRUB configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Check if Windows EFI entry exists
sudo efibootmgr -v
```

#### systemd-boot not appearing

```bash
# Reinstall systemd-boot
sudo bootctl install

# Check EFI variables
sudo efibootmgr -v

# Verify EFI partition is mounted
mount | grep /boot
```

#### Dual-boot Windows disappeared

```bash
# Check if Windows EFI entry still exists
sudo efibootmgr -v

# For GRUB, run os-prober
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg

# For systemd-boot, manually add Windows entry
```

### Boot Repair

If bootloader becomes corrupted:

1. **Boot from recovery media**
2. **Chroot into system**:
   ```bash
   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mount /dev/disk/by-label/BOOT /mnt/boot
   sudo nixos-enter
   ```
3. **Reinstall bootloader**:
   ```bash
   nixos-rebuild switch --flake .#your-hostname
   ```

## Best Practices

### For Dual-Boot Systems

1. **Install Windows first**, then NixOS
2. **Use GRUB** for automatic OS detection
3. **Keep Windows recovery media** available
4. **Test boot menu** after installation
5. **Backup EFI variables** before major changes:
   ```bash
   sudo efibootmgr -v > efi-backup.txt
   ```

### For Single-Boot Systems

1. **systemd-boot** for UEFI-only environments
2. **GRUB** for maximum compatibility
3. **Test bootloader switching** on non-production systems first

### General Safety

1. **Always have recovery media** available
2. **Test configurations** on similar hardware first
3. **Document your specific setup** for future reference
4. **Keep backups** of working configurations

## References

- [NixOS Bootloader Documentation](https://nixos.org/manual/nixos/stable/index.html#sec-installation-partitioning)
- [GRUB Manual](https://www.gnu.org/software/grub/manual/grub/grub.html)
- [systemd-boot Documentation](https://www.freedesktop.org/software/systemd/man/systemd-boot.html)
- [Dual Boot Setup Guide](https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows)