#!/usr/bin/env bash
ISO_PATH="$1"
DISK_IMG="$2"
CLEANUP_EXTRA_DISK="$3"

EXTRA_DISK="/tmp/vm-extra.qcow2"

# create the extra disk
qemu-img create -f qcow2 -q "$EXTRA_DISK" 15G

if [[ "$CLEANUP_EXTRA_DISK" == "yes" ]]; then
  cleanup() {
    rm -f "$EXTRA_DISK"
  }
  trap cleanup EXIT
fi

qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom "${ISO_PATH}" \
  -boot order=dc \
  # -enable-kvm \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -drive file="${DISK_IMG}",format=qcow2,if=virtio \
  -drive file=${EXTRA_DISK},format=qcow2,if=scsi