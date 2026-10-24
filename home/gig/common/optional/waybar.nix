{ pkgs, ... }:
{
  # Status bar for niri. Not a line-for-line port of polybar.nix -- the two
  # bar frameworks differ enough (single bar vs. one-process-per-monitor,
  # different module systems) that a direct translation wouldn't be
  # meaningful. Same Nord-ish palette as polybar.nix for visual continuity.
  programs.waybar = {
    enable = true;
    # Autostart is handled by niri's spawn-at-startup instead.
    systemd.enable = false;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "tray"
        ];

        "niri/workspaces" = {
          format = "{index}";
        };

        "niri/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%m/%d %I:%M %p}";
          interval = 5;
        };

        cpu = {
          format = "CPU: {usage}%";
          interval = 2;
        };

        memory = {
          format = "MEM: {used:0.1f}G/{total:0.1f}G";
          interval = 2;
        };

        pulseaudio = {
          format = " {volume}%";
          format-muted = " muted";
          scroll-step = 5;
          on-click = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };

        network = {
          format-wifi = "WiFi: {essid} ({signalStrength}%) ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
          format-ethernet = " {ipaddr}";
          format-disconnected = "";
          interval = 3;
        };

        battery = {
          bat = "BAT1";
          adapter = "AC1";
          full-at = 98;
          format = "BAT: {capacity}%";
          format-charging = " {capacity}%";
          states = {
            warning = 25;
            critical = 10;
          };
        };
      };
    };

    style = ''
      * {
        font-family: "DejaVu Sans", "Font Awesome 7 Free", "Font Awesome 7 Brands";
        font-size: 11px;
      }

      window#waybar {
        background: #2E3440;
        color: #D8DEE9;
      }

      #workspaces button {
        padding: 0 6px;
        color: #D8DEE9;
      }

      #workspaces button.active {
        background: #88C0D0;
        color: #2E3440;
      }

      #clock, #cpu, #memory, #pulseaudio, #network, #battery, #window, #tray {
        padding: 0 8px;
      }

      #battery.warning {
        color: #EBCB8B;
      }

      #battery.critical {
        color: #BF616A;
      }
    '';
  };
}
