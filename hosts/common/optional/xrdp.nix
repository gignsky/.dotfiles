{ pkgs, ... }:

# RDP server for connecting from Windows' Remote Desktop client (mstsc).
#
# niri is Wayland-only and implements no RemoteDesktop portal, so the local
# niri session can't be shared. xrdp instead starts a separate X11 session
# (Xorg + xorgxrdp) running XFCE. It sits alongside niri/greetd without
# needing `services.xserver.enable` and without adding a display manager.
#
# Connect to <host>:3389 and log in as gig at the xrdp login screen using
# your system password. Any app that holds a per-user lock (Firefox,
# Discord, ...) can't run in both sessions at the same time.
{
  services.xserver.desktopManager.xfce.enable = true;

  services.xrdp = {
    enable = true;
    port = 3389;
    openFirewall = true;
    # Left at the module defaults (/etc/xrdp/{cert,key}.pem): if they don't
    # exist, a self-signed pair is generated on first start.
    defaultWindowManager = "${pkgs.xfce4-session}/bin/xfce4-session";
  };
}
