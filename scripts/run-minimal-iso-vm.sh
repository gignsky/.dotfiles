#!/usr/bin/env bash
ISO_PATH="$1"
DISK_IMG="$2"

qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom "${ISO_PATH}" \
  -boot d \
  # -enable-kvm \
  # -net nic -net user,hostfwd=tcp::2222-:22 \
  -netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=mynet0 \
  -drive file="${DISK_IMG}",format=qcow2,if=virtio