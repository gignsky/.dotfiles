#!/usr/bin/env bash
# Minimal script to enable secondary GPU outputs
# Ganoslal: Dual NVIDIA GPU configuration (RTX 3060 Ti + GTX 970)

echo "Enabling RTX 3060 Ti outputs..."

# Wait for X11 to fully initialize
sleep 1

# Link RTX 3060 Ti (provider 1) outputs to primary display
xrandr --setprovideroutputsource 1 0 2>/dev/null

# Auto-enable all connected outputs
xrandr --auto

# Set main monitor resolution and make it primary
xrandr --output DP-1-2 --mode 2560x1440 --rate 120 --primary

# Position monitors edge-to-edge
# Top row: left to right at y=0
xrandr --output HDMI-1-0 --pos 0x0 2>/dev/null || true
xrandr --output DP-1 --pos 1920x0 2>/dev/null || true  
xrandr --output DP-1-1 --pos 3840x0 2>/dev/null || true
# Bottom: main monitor centered under DP-1 (GTX970 middle monitor)
xrandr --output DP-1-2 --pos 960x1080 2>/dev/null || true

echo "Monitor configuration complete"
