#!/usr/bin/env bash
ISO_PATH="$1"
DISK_IMG="$2"
CREATE_EXTRA_DISK="$3"
CLEANUP_EXTRA_DISK="$4"

EXTRA_DISK="/tmp/vm-extra.qcow2"

if [[ "$CREATE_EXTRA_DISK" == "yes" && ! -f "$EXTRA_DISK" ]]; then
  qemu-img create -f qcow2 "$EXTRA_DISK" 15G
fi

if [[ "$CLEANUP_EXTRA_DISK" == "yes" ]]; then
  cleanup() {
    rm -f "$EXTRA_DISK"
  }
  trap cleanup EXIT
fi

EXTRA_DRIVE_ARG="-drive file=${EXTRA_DISK},format=qcow2,if=virtio"

qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom "${ISO_PATH}" \
  -boot d \
  # -enable-kvm \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -drive file="${DISK_IMG}",format=qcow2,if=virtio \
  $EXTRA_DRIVE_ARG