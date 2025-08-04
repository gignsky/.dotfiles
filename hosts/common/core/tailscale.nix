_: {
  services.tailscale = {
    enable = true;
    # package = inputs.tailscale.packages.${pkgs.system}.default;
    authKeyFile = "/etc/tailscale/creds";
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
    ];
  };
}
