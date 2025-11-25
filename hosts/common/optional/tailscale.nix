_: {
  services.tailscale = {
    enable = true;
    # package = inputs.tailscale.packages.${pkgs.stdenv.hostPlatform.system}.default;
    authKeyFile = "/etc/tailscale/creds";
    # useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
    ];
  };
}
