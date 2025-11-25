{ config, lib, ... }:
with lib;
{
  options.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale VPN service";
    };

    authKeyFile = mkOption {
      type = types.str;
      default = "/etc/tailscale/creds";
      description = "Path to the Tailscale auth key file";
    };

    operator = mkOption {
      type = types.str;
      default = "gig";
      description = "User allowed to operate Tailscale without sudo";
    };

    enableSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale SSH functionality";
    };

    useRoutingFeatures = mkOption {
      type = types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "client";
      description = "Tailscale routing features to enable";
    };

    extraUpFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional flags for 'tailscale up' command";
    };

    hostname = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Hostname for secret lookup (defaults to networking.hostName)";
    };
  };

  config = mkIf config.tailscale.enable {
    services.tailscale = {
      enable = true;
      inherit (config.tailscale) authKeyFile;
      inherit (config.tailscale) useRoutingFeatures;
      extraUpFlags =
        (optional config.tailscale.enableSSH "--ssh")
        ++ [ "--operator=${config.tailscale.operator}" ]
        ++ config.tailscale.extraUpFlags;
    };

    # SOPS secret configuration using nested path
    sops.secrets."tailscale-creds/${config.tailscale.hostname}-auth" = {
      path = config.tailscale.authKeyFile;
    };

    # User and group configuration
    users.groups.tailscale-operators = { };
    users.users.${config.tailscale.operator}.extraGroups = [ "tailscale-operators" ];

    # Sudo rules
    security.sudo.extraRules = [
      {
        groups = [ "tailscale-operators" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/tailscale";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
