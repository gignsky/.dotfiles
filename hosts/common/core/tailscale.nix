{ ... }:

{
  services.tailscale = {
    enable = true;
    # package = inputs.tailscale.packages.${pkgs.system}.default;
    authKeyFile = "/etc/tailscale/creds";
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--ssh"
      "--accept-routes"
      # "--advertise-routes=172.29.118.0/20"
    ];
  };
}
