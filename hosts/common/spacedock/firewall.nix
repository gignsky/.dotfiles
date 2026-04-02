_: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      22
    ];
  };
}
