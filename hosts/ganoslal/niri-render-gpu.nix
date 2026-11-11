{
  config,
  lib,
  ...
}:
let
  # RTX 3060 Ti. Must match `render-drm-device` in home/gig/ganoslal.nix.
  renderGpu = "0000:2d:00.0";
in
# Don't start niri until the GPU it is pinned to has a render node.
#
# nvidia-drm brings the two cards up one after the other, and the 3060 Ti is
# the slow one: on 2026-11-08 greetd launched niri at 15:52:47.3 but the 3060
# Ti's DRM device only appeared at 15:52:49.24 -- 170ms after niri had tried
# the pinned render node, logged "NotFound", and fallen back to renderD128,
# the GTX 970. The 970 then composited all four monitors (5120x1440@144
# included) at P0 and copied every frame across PCIe to the three panels on
# the 3060 Ti, which sat idle in P8. Visible as a constant shimmer on every
# screen, and only on boots that lost the race.
#
# udev does not tag render nodes for systemd, so there is no device unit to
# order against until this rule adds one. systemd then exposes the node under
# each of its symlinks, including the by-path one niri is pointed at.
#
# Wants, not Requires: with the 3060 Ti dead, greetd still starts once the
# device job times out (DefaultDeviceTimeoutSec, 90s) and niri falls back to
# the 970 -- a slow login on the working card beats no login at all.
lib.mkIf config.programs.niri.enable {
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", KERNELS=="${renderGpu}", TAG+="systemd"
  '';

  systemd.services.greetd =
    let
      device = "dev-dri-by\\x2dpath-pci\\x2d${renderGpu}\\x2drender.device";
    in
    {
      wants = [ device ];
      after = [ device ];
    };
}
