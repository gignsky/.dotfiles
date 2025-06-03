#!/usr/bin/env bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom "${minimalIsoPath}" \
  -boot d \
  -enable-kvm \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -drive file=minimal-vm.img,format=qcow2,if=virtio