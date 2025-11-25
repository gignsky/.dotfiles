# Ganoslal GPU Configuration Setup

## Post-Configuration Steps

After rebuilding the configuration, you MUST verify the Bus IDs are correct for your hardware.

### 1. Verify Bus IDs
Run this command on ganoslal to check current GPU Bus IDs:
```bash
lspci | grep -E "(VGA|3D|Display)"
```

Expected output format:
```
23:00.0 VGA compatible controller: AMD/ATI ...
45:00.0 3D controller: NVIDIA Corporation ...
```

### 2. Update Bus IDs if Needed
If the Bus IDs don't match `PCI:45:0:0` (NVIDIA) and `PCI:23:0:0` (AMD), update `hosts/ganoslal/nvidia.nix`:

```nix
prime = {
  sync.enable = true;
  nvidiaBusId = "PCI:XX:0:0";   # Replace XX with NVIDIA bus number
  amdgpuBusId = "PCI:YY:0:0";   # Replace YY with AMD bus number
};
```

### 3. Verify Monitor Setup
Check connected monitors:
```bash
xrandr --listmonitors
# or
xrandr | grep " connected"
```

Update `home/gig/common/resources/bspwm/ganoslal.conf` if monitor names have changed.

### 4. Test Commands After Rebuild
```bash
# Verify NVIDIA is working
nvidia-smi

# Check OpenGL is using NVIDIA
glxinfo | grep "OpenGL renderer"

# Test bspwm configuration
echo $XDG_SESSION_DESKTOP
```

## Changes Made

1. **Fixed X11 video drivers**: Added `services.xserver.videoDrivers = [ "nvidia" ];` to `hosts/ganoslal/default.nix:66`
2. **Modernized NVIDIA config**: Updated `hosts/ganoslal/nvidia.nix` with:
   - Better documentation
   - 32-bit graphics support 
   - Power management
   - Modern driver best practices
   - Debug environment variables (commented)

## Configuration Summary

- **GPU Setup**: NVIDIA Primary + AMD Secondary 
- **Mode**: PRIME Sync (NVIDIA always on, handles all rendering)
- **Monitors**: 6-monitor support via both GPUs
- **Driver**: Latest stable NVIDIA drivers with kernel modesetting
- **bspwm**: Will use NVIDIA for rendering with proper multi-monitor support
