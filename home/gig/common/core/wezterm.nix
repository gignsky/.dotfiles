{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.font = wezterm.font_with_fallback({
      	"MonoLisa Variable",
      	"JetBrainsMono Nerd Font Mono",
      	"GoMono Nerd Font Mono",
      	"DejaVu Sans Mono",
      })
      config.font_size = 15.0

      config.hide_tab_bar_if_only_one_tab = true

      config.window_padding = {
      	left = 8,
      	right = 8,
      	top = 6,
      	bottom = 6,
      }

      config.window_decorations = "TITLE | RESIZE"

      -- config.keys = {
      --	{
      --		key = "Enter",
      --		mods = "ALT",
      --		action = wezterm.action.DisableDefaultAssignment,
      --	},
      -- }

      -- ganoslal: dual NVIDIA on X11. One wezterm-gui process hosts every
      -- window on every desktop, and that process segfaults inside the NVIDIA
      -- EGL driver whenever the GL context is lost: the log ends with
      --   window::egl > make_current failed ... MakeCurrent: BAD_ALLOC
      -- and the very next paint dies in libnvidia-eglcore (coredumpctl:
      -- glium::ops::draw::draw -> libnvidia-eglcore.so, "segfault at 0").
      -- Nine core dumps between 2026-03-15 and 2026-10-16, two on 2026-10-16
      -- alone, across driver 580.173/580.178 and two wezterm snapshots. No
      -- Xid in the kernel log and VRAM is nowhere near full, so it is the
      -- driver losing the context, not the hardware. Upstream (open):
      --   https://github.com/wezterm/wezterm/issues/8255
      -- front_end = "Software" does NOT avoid it: that path still goes
      -- through NVIDIA EGL (confirmed in the same issue). Two layers instead:
      --
      -- 1. The WebGpu front end on Vulkan, so libnvidia-eglcore is never used
      --    to draw. Pinned to the RTX 3060 Ti, which is the X primary
      --    (hosts/ganoslal/nvidia.nix). wgpu's default happens to pick it too,
      --    but the GTX 970 (PRIME sink) and llvmpipe are also enumerated and a
      --    driver update could reorder them; presenting from the 970 to a
      --    screen owned by the 3060 Ti is exactly the kind of thing that
      --    fails. `wezterm.gui` is nil when wezterm-mux-server or `wezterm
      --    cli` evaluates this file, hence the guard.
      --
      -- 2. A local multiplexer, so every shell lives in wezterm-mux-server
      --    rather than in the GUI. If the GUI still dies, every window, tab,
      --    pane and its scrollback survives; super + Return reconnects and
      --    brings them all back (home/gig/common/optional/bspwm.nix explains
      --    why that key cannot simply run `wezterm` any more). The mux server
      --    is spawned on demand by the first `wezterm connect unix`, with the
      --    same environment the GUI had, and is daemonized so it outlives the
      --    GUI process that started it. `default_domain` makes a window
      --    spawned through the running GUI (`wezterm cli spawn`) land in the
      --    mux too, not in the GUI-local domain that dies with it.
      if wezterm.hostname() == "ganoslal" then
        config.front_end = "WebGpu"
        if wezterm.gui then
          for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
            if
              gpu.backend == "Vulkan"
              and gpu.device_type == "DiscreteGpu"
              and gpu.name:find("RTX 3060 Ti", 1, true)
            then
              config.webgpu_preferred_adapter = gpu
              break
            end
          end
        end

        config.unix_domains = { { name = "unix" } }
        config.default_domain = "unix"
        config.default_gui_startup_args = { "connect", "unix" }
      end

      return config
    '';
  };
}
