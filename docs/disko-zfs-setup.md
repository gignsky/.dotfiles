# Disko and ZFS Setup Documentation

This document provides comprehensive instructions for using disko to set up ZFS pools for NixOS installations, including manual setup procedures and system migration.

## Overview

The `.dotfiles` repository uses [disko](https://github.com/nix-community/disko) for declarative disk partitioning and ZFS filesystem setup. This provides reproducible, automated disk configuration for all hosts.

## ZFS Pool Configuration

### Standard Disk Configuration

The repository includes a standard disk configuration at `hosts/common/disks/standard-disk-config.nix` that creates:

- **GPT partition table** with three partitions:
  - `boot` (1M, BIOS boot partition)
  - `ESP` (500M, EFI System Partition, FAT32, mounted at `/boot`)
  - `root` (remaining space, ZFS pool)

- **ZFS pool `zroot`** with datasets:
  - `zroot/root` (mounted at `/`)
  - `zroot/nix` (mounted at `/nix/store`)

### Disk Layout

```
/dev/sdX
├── /dev/sdX1 (1M)     - BIOS boot partition
├── /dev/sdX2 (500M)   - EFI System Partition (/boot)
└── /dev/sdX3 (rest)   - ZFS pool (zroot)
    ├── zroot/root     → /
    └── zroot/nix      → /nix/store
```

## Manual Disko Setup from Live ISO

### Prerequisites

1. Boot from the custom ISO built with this repository
2. Ensure network connectivity
3. Identify the target disk using `lsblk` or `fdisk -l`
4. **CRITICAL**: Verify disk identity using serial numbers to avoid overwriting wrong drives

### Step 1: Identify Target Disk Safely

```bash
# List all disks with serial numbers
lsblk -o NAME,SIZE,MODEL,SERIAL

# Get detailed disk information
sudo smartctl -a /dev/sdX  # Replace X with your target disk

# Store the disk serial for verification
DISK_SERIAL=$(sudo smartctl -a /dev/sdX | grep "Serial Number" | awk '{print $3}')
echo "Target disk serial: $DISK_SERIAL"
```

### Step 2: Clone the Repository

```bash
# Clone the dotfiles repository
git clone https://github.com/gignsky/.dotfiles.git
cd .dotfiles
```

### Step 3: Run Disko Manually

```bash
# Navigate to the nixos-installer directory
cd nixos-installer

# Run disko to partition and format the disk
# DANGER: This will destroy all data on the target disk!
sudo nix run github:nix-community/disko -- \
    --mode disko \
    --flake .#spacedock \
    --arg disk '"/dev/disk/by-id/ata-YOUR_DISK_SERIAL"'

# Alternative: Use disk path if serial method doesn't work
# sudo nix run github:nix-community/disko -- \
#     --mode disko \
#     --flake .#spacedock \
#     --arg disk '"/dev/sdX"'
```

### Step 4: Verify ZFS Pool Creation

```bash
# Check ZFS pool status
sudo zpool status zroot

# List ZFS datasets
sudo zfs list

# Verify mount points
mount | grep zfs
```

### Step 5: Generate Hardware Configuration

```bash
# Generate hardware configuration for the new system
sudo nixos-generate-config --root /mnt

# Copy hardware config to the appropriate host directory
cp /mnt/etc/nixos/hardware-configuration.nix ../hosts/YOUR_HOSTNAME/
```

## Automated Bootstrap Setup

### Using the Bootstrap Script

The repository includes an automated bootstrap script that handles disk setup:

```bash
# From the .dotfiles directory
./scripts/bootstrap-nixos.nu \
    -n YOUR_HOSTNAME \
    -d TARGET_IP_ADDRESS \
    -k ~/.ssh/id_rsa
```

The script will:
1. Verify disk identity using serial numbers
2. Run disko automatically with safety checks
3. Generate and copy hardware configuration
4. Set up ZFS pools according to the standard configuration
5. Install NixOS with the appropriate host configuration

## System Migration Guide

### Migrating from Single Drive to New Drive

This section covers migrating an existing NixOS system to a new drive using ZFS.

#### Prerequisites

- Both drives connected to the system
- Current system running and accessible
- New drive properly identified by serial number
- Sufficient free space for temporary snapshots

#### Step 1: Prepare New Drive

```bash
# Identify both drives
OLD_DRIVE="/dev/disk/by-id/ata-OLD_SERIAL"
NEW_DRIVE="/dev/disk/by-id/ata-NEW_SERIAL"

# Verify drive identities
echo "Old drive: $(basename $OLD_DRIVE)"
echo "New drive: $(basename $NEW_DRIVE)"
lsblk $OLD_DRIVE $NEW_DRIVE
```

#### Step 2: Set Up New Drive with Disko

```bash
# Clone the current configuration
cd ~/.dotfiles

# Run disko on the new drive
sudo nix run github:nix-community/disko -- \
    --mode disko \
    --flake .#$(hostname) \
    --arg disk "\"$NEW_DRIVE\""
```

#### Step 3: Create ZFS Snapshots

```bash
# Create recursive snapshot of all datasets
sudo zfs snapshot -r zroot@migration-$(date +%Y%m%d-%H%M%S)

# List snapshots to verify
sudo zfs list -t snapshot
```

#### Step 4: Send ZFS Data to New Pool

```bash
# Stop services that might interfere
sudo systemctl stop nix-daemon

# Send root dataset
sudo zfs send zroot/root@migration-* | \
    sudo zfs receive -F newzroot/root

# Send nix dataset
sudo zfs send zroot/nix@migration-* | \
    sudo zfs receive -F newzroot/nix

# Verify data transfer
sudo zfs list newzroot
```

#### Step 5: Update Bootloader

```bash
# Mount new root
sudo mkdir -p /mnt/newroot
sudo mount -t zfs newzroot/root /mnt/newroot
sudo mount -t zfs newzroot/nix /mnt/newroot/nix/store

# Mount boot partition from new drive
NEW_BOOT_PART="${NEW_DRIVE}-part2"
sudo mount $NEW_BOOT_PART /mnt/newroot/boot

# Install bootloader on new drive
sudo nixos-install --root /mnt/newroot --no-root-passwd --no-channel-copy

# Or manually install grub/systemd-boot
# For GRUB:
sudo grub-install --target=x86_64-efi --efi-directory=/mnt/newroot/boot --bootloader-id=NixOS $NEW_DRIVE

# For systemd-boot:
sudo bootctl --path=/mnt/newroot/boot install
```

#### Step 6: Update Disk References

```bash
# Update hardware-configuration.nix to use new disk
# Edit hosts/$(hostname)/hardware-configuration.nix
# Replace old disk UUIDs/paths with new ones

# Get new filesystem UUIDs
sudo blkid $NEW_DRIVE-part2  # For boot partition

# Update configuration
nixos-rebuild switch --flake .#$(hostname)
```

#### Step 7: Verify and Clean Up

```bash
# Reboot to test new drive
sudo reboot

# After successful boot, clean up old snapshots
sudo zfs destroy zroot@migration-*

# Optionally, securely wipe old drive
sudo shred -vfz -n 3 $OLD_DRIVE
```

## Troubleshooting

### Common Issues

#### ZFS Pool Import Errors

```bash
# Force import if pool was not properly exported
sudo zpool import -f zroot

# Import with different pool name to avoid conflicts
sudo zpool import zroot newzroot
```

#### Boot Partition Issues

```bash
# Regenerate grub configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Reinstall systemd-boot
sudo bootctl --path=/boot install
```

#### ZFS Dataset Mount Issues

```bash
# Check dataset properties
sudo zfs get mountpoint,canmount zroot/root

# Force mount datasets
sudo zfs mount zroot/root
sudo zfs mount zroot/nix
```

### Recovery Procedures

#### Recovering from Failed Migration

```bash
# If new system fails to boot, boot from old drive
# Mount new pool as backup
sudo zpool import -N newzroot

# Access data from new pool
sudo mkdir /mnt/backup
sudo mount -t zfs newzroot/root /mnt/backup
```

#### Emergency ZFS Repair

```bash
# Check pool health
sudo zpool status -v

# Attempt repair
sudo zpool scrub zroot

# Clear errors if disk is healthy
sudo zpool clear zroot
```

## Safety Considerations

### Disk Identification

- **Always** use `/dev/disk/by-id/` paths when possible
- Verify disk serial numbers before any destructive operations
- Double-check target disk with `lsblk` and `smartctl`
- Consider creating a verification checksum before migration

### Backup Strategy

- Create ZFS snapshots before any major changes
- Test restore procedures on non-production systems
- Keep bootable recovery media available
- Document your specific hardware configuration

### Testing

- Test the bootstrap procedure on virtual machines first
- Verify ZFS pool functionality before production use
- Test migration procedures on spare hardware
- Validate bootloader installation on target hardware

## Configuration Customization

### Custom Disk Layouts

To create custom disk configurations:

1. Copy `hosts/common/disks/standard-disk-config.nix`
2. Modify partition sizes and ZFS dataset structure
3. Reference the new configuration in your host's `default.nix`
4. Test thoroughly with disko before production use

### ZFS Tuning

Common ZFS optimizations for NixOS:

```nix
# In your host configuration
boot.kernelParams = [
  "zfs.zfs_arc_max=8589934592"  # 8GB ARC limit
];

services.zfs = {
  autoScrub.enable = true;
  autoScrub.interval = "monthly";
  autoSnapshot.enable = true;
  autoSnapshot.monthly = 1;
};
```

## References

- [Disko Documentation](https://github.com/nix-community/disko)
- [ZFS on NixOS](https://nixos.wiki/wiki/ZFS)
- [NixOS Installation Guide](https://nixos.org/manual/nixos/stable/)
- [ZFS Administration Guide](https://openzfs.github.io/openzfs-docs/)