_: {
  # Configure sudo permissions
  security.sudo = {
    # Allow wheel group to use sudo
    enable = true;

    # Add specific rules for nixos-rebuild to be passwordless
    extraRules = [
      {
        users = [ "gig" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
