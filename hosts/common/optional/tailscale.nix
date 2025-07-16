_:

{
  services.tailscale = {
    enable = true;
    # package = inputs.tailscale.packages.${pkgs.system}.default;
    authKeyFile = "/etc/tailscale/creds";
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--ssh"
      "--accept-routes"
    ];
    extraSetFlags = [
      "--advertise-routes=192.168.51.0/24"
      "--advertise-exit-node"
    ];
  };
}
