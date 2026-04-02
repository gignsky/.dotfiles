{ lib, ... }:

{
  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = lib.mkDefault true;
    startWhenNeeded = false; # FIXME switch to true after everything is stable
    allowSFTP = true;
    authorizedKeysInHomedir = true;
    banner = lib.mkDefault "spacedock.gig welcomes you!\n";
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
    ];
    ports = [ 22 ];
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = lib.mkDefault "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = lib.mkDefault false;
      PrintMotd = true;
      AllowGroups = [
        "gig"
        "git"
        "gitlab"
      ];
      AllowUsers = [
        "gig"
        "git"
        "gitlab"
      ];
      GatewayPorts = "yes";
      UseDns = true;
    };
  };
}
