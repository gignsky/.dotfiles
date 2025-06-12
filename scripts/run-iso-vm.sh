#!/usr/bin/env bash
ISO_PATH="$1"
DISK_IMG="$2"
CLEANUP_EXTRA_DISK="$3"

# Uncomment the next line to enable KVM
# -enable-kvm

qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom "$ISO_PATH" \
  -boot d \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -drive file="$DISK_IMG",format=qcow2,if=virtio
