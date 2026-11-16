# Keep swap and big writes from freezing the desktop.
#
# Opt-in, for hosts someone is actually sitting at (ganoslal, merlin) -- the
# same split as nix-build-throttle.nix.
#
# The problem this fixes, as measured on ganoslal (2026-11-08): copying a 51 GB
# archive off the NAS pushed the TEAM T253X2 SATA SSD to ~260 ms per read once
# its SLC cache ran out. Root, /nix, /home AND the swap partition all live on
# that one drive, and with swappiness 60 the kernel had already pushed ~4 GB of
# desktop apps to that swap while 19 GB of RAM sat free. Every click into a
# swapped-out app queued a read behind the copy; the desktop stalled ~67% of
# the time (PSI io full) with the CPU 85% idle.
#
# Three layers, because they fail differently:
#
#   1. zram puts a compressed swap device in RAM, ahead of the disk partition.
#      Swapping out/in becomes a few microseconds of zstd instead of a disk
#      round-trip, so cold app memory no longer depends on the SSD at all. The
#      disk partition stays as overflow (and for hibernation on merlin).
#   2. Swap tuning for an in-RAM swap device (see the sysctl comments).
#   3. Dirty-page limits, so one big writer can't build up gigabytes of
#      unflushed data that everyone else then waits behind.
{
  lib,
  ...
}:
{
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";

    # Cap on the *uncompressed* size of what zram may hold, not RAM reserved up
    # front -- an empty zram device costs nothing. At a typical ~3:1 ratio, 50%
    # of RAM worth of swapped pages occupies roughly 1/6 of real RAM.
    memoryPercent = lib.mkDefault 50;

    # Priority is left at the NixOS default of 5. The disk partitions carry no
    # priority, so the kernel gives them -2; higher wins, so zram fills first
    # and the disk only sees overflow.
  };

  boot.kernel.sysctl = {
    # With swap on a slow disk, a low value (~10) is the usual advice. With
    # zram in front it is the wrong trade: swapping an idle page out to zram is
    # cheap, while dropping page cache means re-reading it from the SSD later.
    # 100 weighs the two equally; the kernel allows up to 200 for in-RAM swap.
    "vm.swappiness" = lib.mkDefault 100;

    # Swap readahead (default 3 = 8 pages) exists to amortise disk seeks. zram
    # has no seeks, so readahead only decompresses pages nobody asked for.
    "vm.page-cluster" = lib.mkDefault 0;

    # Defaults are ratios of RAM: 10% background / 20% hard, which on
    # ganoslal's 46 GB is ~4.6 GB / ~9 GB of dirty data -- around 90 seconds
    # of writeback at that SSD's sustained speed, during which unrelated
    # fsyncs and reads queue behind it. Absolute byte limits make the writer
    # (cp, rsync, a nix build) throttle itself early instead. Setting *_bytes
    # makes the kernel ignore the matching *_ratio.
    "vm.dirty_background_bytes" = lib.mkDefault (64 * 1024 * 1024);
    "vm.dirty_bytes" = lib.mkDefault (256 * 1024 * 1024);
  };
}
