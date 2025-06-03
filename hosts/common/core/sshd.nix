{ lib, ... }:

{
  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = lib.mkDefault "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = lib.mkDefault false;
    };
  };
}
