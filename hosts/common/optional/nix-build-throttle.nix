# Keep nix builds from starving interactive use.
#
# Opt-in, for hosts someone is actually sitting at (ganoslal, merlin). Build
# servers deliberately do NOT import this: throttling spacedock's nix-daemon
# would slow the nightly builder and the roll-flow watcher for nobody's benefit.
#
# The problem this fixes: nix defaults to `max-jobs = auto` (one job per
# hardware thread) with `cores = 0` (each job free to use every thread). On
# ganoslal that measured as `max-jobs = 12, cores = 0` on a 6-core/12-thread
# 5600X — up to 12 concurrent jobs each trying to use all 12 threads. Nothing
# capped memory or I/O either, so a rebuild made the whole desktop unusable.
#
# Two independent layers, because they fail differently:
#
#   1. Admission control (max-jobs / cores) bounds how much work is ever
#      in flight. This applies whether or not anything else is running.
#   2. Priority (scheduling policy + cgroup weights) decides who wins when
#      there IS contention. These are proportional, not caps: with the machine
#      otherwise idle a build still gets essentially the whole box, which is
#      what makes this different from `CPUQuota`.
#
# Layer 2 is the part that answers "reserve resources only if other things are
# trying to use them". Layer 1 is what stops memory/IO thrashing, which is
# usually what actually makes a desktop *hang* rather than merely feel slow.
#
# Mirrors the approach already used for the binary-cache builder units in
# modules/nixos/binary-cache/service.nix ("Builds are background work; never
# starve interactive use." — Nice 19 + IOSchedulingClass idle).
{
  lib,
  ...
}:
{
  nix = {
    settings = {
      # mkDefault throughout so a host can raise these in its own default.nix
      # without needing mkForce.
      #
      # 4 x 2 = at most ~8 busy threads, leaving >=4 free on ganoslal (12) and
      # >=8 on merlin (16). Deliberately expressed as small absolute numbers
      # rather than "auto": "auto" is what produced the 12-job oversubscription
      # in the first place.
      #
      # Why not max-jobs = 1? Most of a nixos-rebuild is many small derivations,
      # which parallelise well; serialising them would roughly triple rebuild
      # time to solve a problem the priority layer below already handles.
      max-jobs = lib.mkDefault 4;

      # NIX_BUILD_CORES per job. Note this is advisory -- a build that hardcodes
      # `make -j$(nproc)` ignores it, which is the other reason layer 2 exists.
      cores = lib.mkDefault 2;

      # Substitutions are network-bound, not CPU-bound, so they do not need the
      # same restraint -- but 16 parallel downloads did saturate the link while
      # pulling from spacedock's cache. Halved rather than cut hard.
      max-substitution-jobs = lib.mkDefault 8;
    };

    # SCHED_BATCH, not SCHED_IDLE. Both deprioritise the daemon, but SCHED_IDLE
    # risks priority inversion: a build process holding a lock (or a store-wide
    # sqlite transaction) that an interactive nix command then waits on can be
    # starved indefinitely by the very policy meant to protect that command.
    # SCHED_BATCH gets the scheduling-latency penalty without the starvation
    # tail, which is the right trade for a machine where the same person both
    # builds and works.
    daemonCPUSchedPolicy = lib.mkDefault "batch";

    # I/O is usually the real culprit behind "the whole system hangs": a build
    # writing to the store evicts the page cache and queues ahead of the
    # interactive reads behind every UI interaction. `idle` here only yields
    # when something else wants the disk.
    daemonIOSchedClass = lib.mkDefault "idle";
  };

  # cgroup-level weights, which the options above do not set. These bound the
  # daemon AND the build processes it forks, since those stay inside its cgroup.
  #
  # Weights are relative to the default of 100, and only take effect under
  # contention -- an idle machine still hands a build everything it asks for.
  #
  # To burst for a one-off big build without editing config or rebuilding:
  #   sudo systemctl set-property --runtime nix-daemon.service CPUWeight=100 IOWeight=100
  # (--runtime means it reverts on reboot.)
  systemd.services.nix-daemon.serviceConfig = {
    CPUWeight = lib.mkDefault 20;
    IOWeight = lib.mkDefault 20;

    # Soft limit: past this the kernel applies reclaim pressure to the build
    # cgroup instead of letting it push everything else into swap. NOT
    # MemoryMax, which would hard-fail builds that legitimately need more (a
    # chromium or LLVM link, say) -- the goal is to keep the desktop
    # responsive, not to break the build.
    #
    # A percentage rather than an absolute so this is portable across hosts
    # with different amounts of RAM.
    MemoryHigh = lib.mkDefault "60%";
  };
}
