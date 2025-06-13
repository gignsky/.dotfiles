#!/usr/bin/env bash
ISO_PATH="$1"
DISK_IMG="$2"
MODE="$3"

if [[ "$MODE" == "--choose" ]]; then
  echo "Select boot mode:" >&2
  select BOOT_MODE in "Boot from ISO (install)" "Boot from disk image (normal)"; do
    case $REPLY in
      1)
        # Boot with ISO for installation
        qemu-system-x86_64 \
          -m 2048 \
          -smp 2 \
          -cdrom "${ISO_PATH}" \
          -d guest_errors \
          -boot order=dc \
          -net nic -net user,hostfwd=tcp::2222-:22 \
          -drive file="${DISK_IMG}",format=qcow2,if=virtio \
          # -enable-kvm
        break
        ;;
      2)
        # Boot from disk image only
        qemu-system-x86_64 \
          -m 2048 \
          -smp 2 \
          -d guest_errors \
          -boot order=c \
          -net nic -net user,hostfwd=tcp::2222-:22 \
          -drive file="${DISK_IMG}",format=qcow2,if=virtio \
          # -enable-kvm
        break
        ;;
      *)
        echo "Invalid option. Please select 1 or 2." >&2
        ;;
    esac
  done
else
  # Default: two-phase process
  qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom "${ISO_PATH}" \
    -d guest_errors \
    -boot order=dc \
    -no-reboot \
    -net nic -net user,hostfwd=tcp::2222-:22 \
    -drive file="${DISK_IMG}",format=qcow2,if=virtio \
    # -enable-kvm

  qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -d guest_errors \
    -boot order=c \
    -net nic -net user,hostfwd=tcp::2222-:22 \
    -drive file="${DISK_IMG}",format=qcow2,if=virtio \
    # -enable-kvm
fi