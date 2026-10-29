# Prism Launcher plus a ready-made "Create Server" instance that matches the
# Create server on spacedock (containers/services/minecraft-create.nix): same
# Minecraft and NeoForge versions, same mod jars, both read from the shared
# containers/services/minecraft-create-modpack.nix. Bump mods there and
# `just home` -- this instance follows.
#
# The mod jars are fetched by hash and symlinked into the instance's mods
# folder, so Home Manager adds and removes them as the pack changes. Jars you
# drop in by hand are left alone (but the server won't have them).
#
# Prism rewrites instance.cfg as you play (play time, last launch), so it is
# only seeded when missing and stays yours to tweak in the UI. mmc-pack.json
# (the Minecraft/NeoForge versions) is overwritten on every switch to keep it
# pinned to the server; change versions in the modpack file, not in Prism.
#
# Sign in with the Microsoft account that owns Java Edition, launch the
# instance, then Multiplayer -> Add Server -> games.gignsky.com.
{
  config,
  configLib,
  lib,
  pkgs,
  ...
}:
let
  modpack = import (configLib.relativeToRoot "containers/services/minecraft-create-modpack.nix");
  instance = "PrismLauncher/instances/create-server";

  mmcPack = pkgs.writeText "mmc-pack.json" (
    builtins.toJSON {
      formatVersion = 1;
      # Prism resolves the remaining components (LWJGL etc.) itself on launch.
      components = [
        {
          uid = "net.minecraft";
          version = modpack.minecraftVersion;
          important = true;
        }
        {
          uid = "net.neoforged";
          version = modpack.neoforgeVersion;
        }
      ];
    }
  );

  instanceCfg = pkgs.writeText "instance.cfg" (
    lib.generators.toINI { } {
      General = {
        ConfigVersion = "1.2";
        InstanceType = "OneSix";
        name = "Create Server";
        iconKey = "default";
        # Create with a few hundred contraptions wants more than Prism's
        # default 4 GB; ganoslal has 46 GB.
        OverrideMemory = true;
        MinMemAlloc = 1024;
        MaxMemAlloc = 6144;
      };
    }
  );
in
{
  # The nixpkgs build wraps Java 8/17/21, so the instance finds Java 21
  # without any setup.
  programs.prismlauncher.enable = true;

  xdg.dataFile = lib.listToAttrs (
    map (
      m:
      lib.nameValuePair "${instance}/minecraft/mods/${m.file}" {
        source = pkgs.fetchurl {
          inherit (m) url sha512;
          # The URL basename can be percent-encoded, which a store path
          # name can't hold.
          name = m.file;
        };
      }
    ) modpack.mods
  );

  home.activation.minecraftCreateInstance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="${config.xdg.dataHome}/${instance}"
    run mkdir -p "$dir"
    run install -m644 ${mmcPack} "$dir/mmc-pack.json"
    if [ ! -e "$dir/instance.cfg" ]; then
      run install -m644 ${instanceCfg} "$dir/instance.cfg"
    fi
  '';
}
