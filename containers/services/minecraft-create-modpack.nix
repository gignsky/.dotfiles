# The Create server's modpack, shared by the server (./minecraft-create.nix,
# spacedock) and the client instance (home/gig/common/optional/
# minecraft-create.nix, Prism Launcher). Plain data, not a module -- it is
# imported, never listed in ./default.nix.
#
# This list is the WHOLE pack: the server no longer pulls in dependencies on
# its own, so every required dependency must be listed here too, or the
# client and server drift apart. Check a version's deps with
#   curl -s https://api.modrinth.com/v2/version/<version> | jq .dependencies
#
# Bumping a mod: take the new Modrinth version id (the 8-char id on the
# version page, or `/v2/project/<slug>/version?loaders=["neoforge"]&
# game_versions=["1.21.1"]`), then copy `file`, `url` and `sha512` from that
# version's primary file in `/v2/version/<version>`. Switch spacedock, then
# `just home` on each client. Back up the world first for a Create bump.
{
  minecraftVersion = "1.21.1";
  neoforgeVersion = "21.1.265";

  # Pinned so a restart never silently upgrades the server out from under the
  # players' mods.zip.
  mods = [
    {
      # Create 6.0.10+mc1.21.1
      slug = "create";
      version = "UjX6dr61";
      file = "create-1.21.1-6.0.10.jar";
      url = "https://cdn.modrinth.com/data/LNytGWDc/versions/UjX6dr61/create-1.21.1-6.0.10.jar";
      sha512 = "11cc8fc049d2f67f6548c7abfada6b82a3adb5c7ca410a742de04bbca76e03862c518721b88d806f6e6d768a4d68531fdb903a85859b25d1484d550cc7bafd4b";
    }
    {
      # Just Enough Items 19.64.0.455 -- recipe lookup
      slug = "jei";
      version = "iv3KiVkE";
      file = "jei-1.21.1-neoforge-19.64.0.455.jar";
      url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/iv3KiVkE/jei-1.21.1-neoforge-19.64.0.455.jar";
      sha512 = "fdd02e57ce4dcf20b69860a5ace1b97d9a771486241179cf9edfe71e30c69bb4003b046d0cce8d8c4913b9689f1d8b04cf0542b0b04a6cf0b3b0465f3bb11702";
    }
    {
      # Jade 15.10.6 -- shows what you're looking at
      slug = "jade";
      version = "eYz2YBGT";
      file = "Jade-1.21.1-NeoForge-15.10.6.jar";
      url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/eYz2YBGT/Jade-1.21.1-NeoForge-15.10.6.jar";
      sha512 = "dad9755dce8d85d914fc4df2baa0211f13e5839a71c1925fdd01f69081a95e30a2934e6273f8b01f0169adebe7a9dae57a8d904de0c4cb36dc17369bb474f0f2";
    }
    {
      # AppleSkin 3.0.9 -- food/saturation display
      slug = "appleskin";
      version = "uAKA6Laj";
      file = "appleskin-neoforge-mc1.21-3.0.9.jar";
      url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/uAKA6Laj/appleskin-neoforge-mc1.21-3.0.9.jar";
      sha512 = "f4ea46273e407334b63e262e2555c9a8204f7b5e60f23f272fbaa83ad9e88800e0ee186aca840710df2dbe0a18b37758695fef2ae1a902c10b3706e3de772937";
    }
    {
      # Steam 'n' Rails 0.3.0-beta.2. The official project stops at 1.20.1;
      # this is the unofficial 1.21.1 port
      # (github.com/Porters-of-Railways/Railway-1.21.1), still beta. Built
      # against Create 6.0.10, needs NeoForge >= 21.1.233. Back up the world
      # before bumping it.
      slug = "create-steam-n-rails-1.21.1";
      version = "czVeSmZo";
      file = "railways-0.3.0-beta.2+neoforge-mc1.21.1.jar";
      url = "https://cdn.modrinth.com/data/L3Jv0QZI/versions/czVeSmZo/railways-0.3.0-beta.2%2Bneoforge-mc1.21.1.jar";
      sha512 = "def5c767467bf7863e2efc1a8cc3bf3442e1090ee1504e447c4120b9ff4ff6780de93d2a7d1bf696cd19407010d465b99f00bbf780776b0a9648804fa1b45f75";
    }
    {
      # MezzConfig 0.6.9 -- JEI's required config library. It has only ever
      # published beta builds.
      slug = "mezzconfig";
      version = "RdGonQpr";
      file = "mezz_config-1.21.1-neoforge-0.6.9-standalone.jar";
      url = "https://cdn.modrinth.com/data/7tEfOcA7/versions/RdGonQpr/mezz_config-1.21.1-neoforge-0.6.9-standalone.jar";
      sha512 = "2a20fdcca268c0f80547806582c94d79de6d339aabd3714af4bc5cf25ce983028f72ae707d52b44786adeb4e4c1976bebd7dbc4a75a3bf4575ec44c2bcd28dc3";
    }
  ];
}
