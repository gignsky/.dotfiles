{ lib, ... }:

{
    # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh.settings.PasswordAuthentication = true;
}