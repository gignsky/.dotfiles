# Monitor Detection & Auto-Recovery Service
# Template for systemd service that monitors display configuration
# and automatically attempts to fix missing monitors

{
  pkgs,
  ...
}:

{
  systemd = {
    user = {
      # Systemd user service for monitor detection and recovery
      services.monitor-auto-recovery = {
        description = "Monitor Detection & Auto-Recovery Service";

        # Start after graphical session is ready
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        # Service configuration
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          # Script that runs on service start
          ExecStart = pkgs.writeShellScript "monitor-recovery-check" ''
            set -e

            # Configuration
            EXPECTED_MONITORS=6  # Change this to your expected monitor count
            MAX_RETRIES=10
            RETRY_INTERVAL=30  # seconds between retries
            LOG_FILE="$HOME/.local/share/monitor-recovery.log"

            # Ensure log directory exists
            mkdir -p "$(dirname "$LOG_FILE")"

            # Logging function
            log() {
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
            }

            # Monitor detection function
            detect_monitors() {
                xrandr --query 2>/dev/null | grep " connected" | wc -l
            }

            # Monitor configuration function
            configure_monitors() {
                log "Attempting to configure monitors..."
                
                # Enable all known outputs (add your specific outputs here)
                xrandr --output HDMI-0 --auto 2>/dev/null || true
                xrandr --output DP-1 --auto 2>/dev/null || true
                xrandr --output DP-2 --auto 2>/dev/null || true
                xrandr --output DP-3 --auto 2>/dev/null || true
                xrandr --output DP-4 --auto 2>/dev/null || true
                xrandr --output DP-5 --auto 2>/dev/null || true
                
                # Apply your specific layout (customize this for your setup)
                # Example layout - replace with your actual configuration
                xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x1600 \
                       --output DP-1 --mode 1920x1080 --pos 0x1600 \
                       --output DP-2 --mode 1920x1080 --pos 3840x1600 \
                       --output DP-3 --mode 1920x1080 --pos 1920x0 2>/dev/null || true
                
                # Reload BSPWM configuration
                if command -v bspc &> /dev/null; then
                    bspc wm -r
                    log "Reloaded BSPWM configuration"
                fi
            }

            log "=== Monitor Auto-Recovery Service Started ==="
            log "Expected monitors: $EXPECTED_MONITORS"

            # Initial detection
            CURRENT_MONITORS=$(detect_monitors)
            log "Currently detected monitors: $CURRENT_MONITORS"

            if [ "$CURRENT_MONITORS" -ge "$EXPECTED_MONITORS" ]; then
                log "All monitors detected successfully!"
                configure_monitors
                log "Monitor configuration applied"
                exit 0
            fi

            # Retry loop
            for i in $(seq 1 $MAX_RETRIES); do
                log "Retry $i/$MAX_RETRIES - Detected $CURRENT_MONITORS/$EXPECTED_MONITORS monitors"
                
                # Try to reconfigure
                configure_monitors
                sleep 2
                
                # Check again
                CURRENT_MONITORS=$(detect_monitors)
                
                if [ "$CURRENT_MONITORS" -ge "$EXPECTED_MONITORS" ]; then
                    log "SUCCESS: All monitors detected on retry $i"
                    
                    # Send notification to user
                    if command -v notify-send &> /dev/null; then
                        notify-send "Monitor Detection" "All $EXPECTED_MONITORS monitors configured successfully (retry $i)"
                    fi
                    
                    exit 0
                fi
                
                # Wait before next retry
                if [ "$i" -lt "$MAX_RETRIES" ]; then
                    log "Waiting $RETRY_INTERVAL seconds before next retry..."
                    sleep "$RETRY_INTERVAL"
                fi
            done

            # All retries exhausted
            log "ERROR: Failed to detect all monitors after $MAX_RETRIES retries"
            log "Final count: $CURRENT_MONITORS/$EXPECTED_MONITORS monitors"

            # Send error notification
            if command -v notify-send &> /dev/null; then
                notify-send -u critical "Monitor Detection Failed" \
                    "Only $CURRENT_MONITORS of $EXPECTED_MONITORS monitors detected. Check logs: $LOG_FILE"
            fi

            exit 1
          '';
        };
      };

      # Optional: Timer to periodically check monitor status
      timers.monitor-auto-recovery = {
        description = "Periodic Monitor Detection Check";

        wantedBy = [ "timers.target" ];

        timerConfig = {
          # Check every 5 minutes
          OnBootSec = "2min"; # First check 2 minutes after boot
          OnUnitActiveSec = "5min"; # Then every 5 minutes
          Persistent = true; # Run missed timers on boot
        };
      };

      # Alternative: Path-based activation (triggers on DRM device changes)
      # This is more responsive than a timer but may trigger too frequently
      paths.monitor-hotplug-detector = {
        description = "Monitor Hotplug Detection";

        # Disabled by default - uncomment to enable
        # wantedBy = [ "graphical-session.target" ];

        pathConfig = {
          # Watch for changes in DRM subsystem
          PathModified = "/sys/class/drm";
        };

        triggers = [ "monitor-auto-recovery.service" ];
      };
    };
  };
}
