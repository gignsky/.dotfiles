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
      # Create: Power Loader 2.0.5 -- chunk loaders driven by Create
      # rotation, so trains and factories keep running with nobody nearby.
      slug = "create-power-loader";
      version = "3Y4r0ItR";
      file = "create_power_loader-2.0.5-mc1.21.1.jar";
      url = "https://cdn.modrinth.com/data/wPQ6GgFE/versions/3Y4r0ItR/create_power_loader-2.0.5-mc1.21.1.jar";
      sha512 = "e4f06cfe79eafa538a2edf45d0b173051475f2a20d6c2352668f6980f4433078f2cdd8ffdd047984c30dfd903142ea37eadde48ff71a3892f18154662f20eb57";
    }
    {
      # Copycats+ 3.0.9 -- copycat stairs, slabs, panels, fences etc. that
      # take the look of any block; work on contraptions.
      slug = "copycats";
      version = "bPYeUWZx";
      file = "copycats-3.0.9+mc.1.21.1-neoforge.jar";
      url = "https://cdn.modrinth.com/data/UT2M39wf/versions/bPYeUWZx/copycats-3.0.9%2Bmc.1.21.1-neoforge.jar";
      sha512 = "432b5cde473976476b0729172710d32805576d0c3a5fd66d21f882d96cef0c4eef1b85e4e3a1a316e2adc473784b11e156b0265b0f62bcfd5b035a6ff7dfcc6e";
    }
    {
      # Create: Connected 1.3.3 -- extra Create parts (brass gearbox,
      # sequenced pulse generator, inventory bridge, ...).
      slug = "create-connected";
      version = "Xe7EqzfQ";
      file = "create_connected-1.3.3-mc1.21.1.jar";
      url = "https://cdn.modrinth.com/data/Vg5TIO6d/versions/Xe7EqzfQ/create_connected-1.3.3-mc1.21.1.jar";
      sha512 = "485675693980a266611669857fa9cd348e2a29140b87bf0a8ab3e13c3591422cceaa36b7a2eb90084d35ec1868c8eec9f924383bb4dada2dddcb72e9f09361b0";
    }
    {
      # Create Deco 2.1.3 -- industrial building blocks. Declares
      # create [6.0.7,6.1.0): bump it together with Create 6.1.
      slug = "create-deco";
      version = "qrcMVoBD";
      file = "createdeco-2.1.3.jar";
      url = "https://cdn.modrinth.com/data/sMvUb4Rb/versions/qrcMVoBD/createdeco-2.1.3.jar";
      sha512 = "c536662f9d47ad57a37419165ded14835b23ad6c3e82a920298ecd7ee074244b0b6062ef9cc7ea4501ddd35919a840faccd7fc64e43eb8df31e12076681c3c0d";
    }
    {
      # Design n' Decor 2.2b -- decorative Create blocks. Needs Flywheel
      # and Ponder, which the Create jar bundles.
      slug = "create-design-n-decor";
      version = "uQsIRky8";
      file = "Design-n-Decor-1.21.1-2.2b.jar";
      url = "https://cdn.modrinth.com/data/x49wilh8/versions/uQsIRky8/Design-n-Decor-1.21.1-2.2b.jar";
      sha512 = "d888553c8a254c3654f8da2ae2cae0bb642594546c71988739c93bf6b18668145e0ce5b1c20ae0544b9b6019f17e4da944bd5bc17e4c6b73e7f1374cfa2c9db9";
    }
    {
      # Farmer's Delight 1.3.4 -- cooking, crops and meals with buffs.
      slug = "farmers-delight";
      version = "XTVZDOol";
      file = "FarmersDelight-1.21.1-1.3.4.jar";
      url = "https://cdn.modrinth.com/data/R2OftAxM/versions/XTVZDOol/FarmersDelight-1.21.1-1.3.4.jar";
      sha512 = "1f6f8796469f747cff36f477b4f589a3d69613882399f9ee7f86db36c7bca9aa4828731f43db15dc6c7f5a4c1bbe3d4092a232e8cef010b09cec0581848fda90";
    }
    {
      # Create: Dragons Plus 1.11.9 -- library, required by Central Kitchen.
      slug = "create-dragons-plus";
      version = "b0u9vk8C";
      file = "CreateDragonsPlus-1.11.9.jar";
      url = "https://cdn.modrinth.com/data/dzb1a5WV/versions/b0u9vk8C/CreateDragonsPlus-1.11.9.jar";
      sha512 = "43299e49afe7132515aa8ad545b8c9566d90f12cfb39456b3d6e1ebc8e03f05787fbc420e7cc9495df4d6b585d13e7a4c4c7385f82f20aeb829c9491b725af53";
    }
    {
      # Create: Central Kitchen 2.6.2b -- automates Farmer's Delight
      # cooking with Create machines.
      slug = "create-central-kitchen";
      version = "qZxkZR8W";
      file = "create-central-kitchen-2.6.2b.jar";
      url = "https://cdn.modrinth.com/data/btq68HMO/versions/qZxkZR8W/create-central-kitchen-2.6.2b.jar";
      sha512 = "d4d0a383b5288a7272392ae475d67bc947cd019bc627612bd01992f5ecd702bda078fe75302b83c9619eb26a754195e9ef5f2212cb200eef802bb7d49c255358";
    }
    {
      # Sophisticated Core 1.5.19.2434 -- library, required by
      # Sophisticated Backpacks.
      slug = "sophisticated-core";
      version = "p1iOw2RH";
      file = "sophisticatedcore-1.21.1-1.5.19.2434.jar";
      url = "https://cdn.modrinth.com/data/nmoqTijg/versions/p1iOw2RH/sophisticatedcore-1.21.1-1.5.19.2434.jar";
      sha512 = "a8ef09646497a372e7e00d12366465d2d18809ff4d8c1358e40303c8567bc9e7100d76940908c563095167777c5cb5bbed50cc3bbb371573fcab40490cf01321";
    }
    {
      # Sophisticated Backpacks 3.26.17.2232 -- tiered, upgradeable
      # backpacks.
      slug = "sophisticated-backpacks";
      version = "7V3OGECb";
      file = "sophisticatedbackpacks-1.21.1-3.26.17.2232.jar";
      url = "https://cdn.modrinth.com/data/TyCTlI4b/versions/7V3OGECb/sophisticatedbackpacks-1.21.1-3.26.17.2232.jar";
      sha512 = "f01ef419bfdd6744acb4a7536751535bd0aa6ea4b2807468cad1c63e59878c8875324375247c84c3baae21f34d7599860a1db05238a89ad20aa6d6c5a7cb528a";
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
    {
      # Stargate Journey 0.6.52 -- stargates, DHDs and gate networks; gates
      # generate with the world, so they only appear in fresh chunks. Beta
      # (it has only ever published betas). No required deps.
      slug = "sgjourney";
      version = "HcYWpI7G";
      file = "Stargate.Journey-1.21.1-0.6.52.jar";
      url = "https://cdn.modrinth.com/data/qlc8dxM6/versions/HcYWpI7G/Stargate.Journey-1.21.1-0.6.52.jar";
      sha512 = "af9796b0ac81f6f092f7e37e2924f5a3c58885eb4da37e7b74a0f708c725f264f85da2ffcc09715a690c40384a068743409d09b35fcbe908fff464eb9b1190ed";
    }
    {
      # Xaero's Minimap 26.6.0 -- minimap with waypoints. Client-side, but
      # optional on the server, so it rides along in mods.zip. Bundles Xaero
      # Lib (jar-in-jar); no separate entry needed.
      slug = "xaeros-minimap";
      version = "irjR7dHk";
      file = "xaerominimap-neoforge-1.21.1-26.6.0.jar";
      url = "https://cdn.modrinth.com/data/1bokaNcj/versions/irjR7dHk/xaerominimap-neoforge-1.21.1-26.6.0.jar";
      sha512 = "d56b93ddb921285624b491d6a85aba23748bec9974867399c881c257eb25a746df92a735473adf3a6875e0928a56ff78245d5238eb9207b0e45c3fec20c896dc";
    }
    {
      # CraftedCore 5.8.3 -- library, required by Woodwalkers and RemorphED.
      slug = "crafted-core";
      version = "T4KaObAV";
      file = "craftedcore-5.8.3.jar";
      url = "https://cdn.modrinth.com/data/Dg7PHdkJ/versions/T4KaObAV/craftedcore-5.8.3.jar";
      sha512 = "33f76a90d6c819b50062c1787943ae38602eaaf5146aeb1b723baa1bbcfa0c3ef979f5c8dd0a041db1b39bc9675e7b19b36dce3f31f759869b584879cda5bb00";
    }
    {
      # Woodwalkers 5.8.13 -- the shape-shifting engine, required by
      # RemorphED.
      slug = "woodwalkers";
      version = "k5PBmBwF";
      file = "walkers-5.8.13.jar";
      url = "https://cdn.modrinth.com/data/Sr1HeD8z/versions/k5PBmBwF/walkers-5.8.13.jar";
      sha512 = "218a69fc90cc9f9faff44f6715f09e0678b12e8730d4a05d40fb168f2124de4a9633718a149de2bad57c88d091c1709fab9d607222d0f52ffce3f1bc1b28270b";
    }
    {
      # RemorphED 4.2 -- morph into any mob you have killed. Its last 1.21.1
      # build (2024) and it declares walkers [5.2,): every Walkers and
      # CraftedCore class/method it calls was checked against the versions
      # above. Re-check before bumping Woodwalkers or CraftedCore.
      slug = "remorphed";
      version = "JcEPAMP3";
      file = "remorphed-4.2.jar";
      url = "https://cdn.modrinth.com/data/8aeV5uJW/versions/JcEPAMP3/remorphed-4.2.jar";
      sha512 = "0283d0144fbaf33986053255fdf41aab7f1c3f239b0a5d29ef57838e9dd781e5d378b47d88e0aec69e446997f6df8a0065881f7cab62d98cb1a7a6ba6d2cc4fe";
    }
  ];

  # Optional client-only mods for shaders. Never on the server (Iris crashes a
  # dedicated server), so they are not in mods.zip: the website links them
  # separately and the Prism instance installs them. Iris 1.8 needs Sodium
  # 0.8; Create's Flywheel accepts Sodium >= 0.6.
  clientMods = [
    {
      # Sodium 0.8.13 -- renderer, required by Iris.
      slug = "sodium";
      version = "uMOpc5uV";
      file = "sodium-neoforge-0.8.13+mc1.21.1.jar";
      url = "https://cdn.modrinth.com/data/AANobbMI/versions/uMOpc5uV/sodium-neoforge-0.8.13%2Bmc1.21.1.jar";
      sha512 = "4f537696af95411e9daf15795fb5fcbc49913d488a96fa912fa8f1d7db408710995e8a1461190f3cd0f8217bf9e35e9539176592428ed587ca2d7aa84450a390";
    }
    {
      # Iris 1.8.14-beta.1 -- loads shader packs.
      slug = "iris";
      version = "KduFYu4t";
      file = "iris-neoforge-1.8.14-beta.1+mc1.21.1.jar";
      url = "https://cdn.modrinth.com/data/YL57xq9U/versions/KduFYu4t/iris-neoforge-1.8.14-beta.1%2Bmc1.21.1.jar";
      sha512 = "33fddb430e16222902eac75b8b3d57c381b0f3cc729f3b56c4628df12ca108f23a0b11e2feb167923d6d14d1fc7e8ee1a977ec421b19d1951bdca74c4092b9c5";
    }
  ];

  # Shader packs (need Sodium + Iris above) and resource packs, offered on the
  # website and installed into the Prism instance. Their licenses forbid
  # re-hosting, so the website links Modrinth's CDN rather than mirroring.
  # `name` is the label on the website.
  shaderpacks = [
    {
      name = "Complementary Reimagined r5.9.3";
      file = "ComplementaryReimagined_r5.9.3.zip";
      url = "https://cdn.modrinth.com/data/HVnmMxH1/versions/Bqen1mJX/ComplementaryReimagined_r5.9.3.zip";
      sha512 = "45304b1d7862afdb2177b7e6226fc9c6737911d17a4ad46cc9c519ca4deb935f05072cd337cd8b19a15bb8062b57b54eceec7bdee4cd572d94858e2946d37d85";
    }
    {
      name = "Complementary Unbound r5.9.3";
      file = "ComplementaryUnbound_r5.9.3.zip";
      url = "https://cdn.modrinth.com/data/R6NEzAwj/versions/B1kyfoUZ/ComplementaryUnbound_r5.9.3.zip";
      sha512 = "a085d1d8cda67cd17a2b414eeba48bbd809da069f269bab46246235ec8fe714a275013c70d0504527b0987d810deddddba4564332414ab3b3bd7435932ff808c";
    }
    {
      name = "BSL Shaders 10.1.8";
      file = "BSL_v10.1.8.zip";
      url = "https://cdn.modrinth.com/data/Q1vvjJYV/versions/Y68yiql9/BSL_v10.1.8.zip";
      sha512 = "94a3c25d6820868db624e11347873e6b572e7cd571967d9ac6f4690ca5d37ca302a7645d85eec800e0654541e3825fba14d37b5a25d3996aaf038178552be26f";
    }
  ];

  # Plain vanilla packs only: no CIT/EMF/ETF-dependent ones, which need
  # extra mods to do anything.
  resourcepacks = [
    {
      name = "Faithful 32x (1.21.1)";
      file = "Faithful 32x - 1.21.1.zip";
      url = "https://cdn.modrinth.com/data/w0TnApzs/versions/ruZOIEZE/Faithful%2032x%20-%201.21.1.zip";
      sha512 = "5ceaff9539f1440434a7255a5ede1118b00491f85db5c414fb4463872bd041a590e84275daa3bfaecd52772967f114d09c53dc97070e6d3959752f31d4a63885";
    }
    {
      name = "Better Leaves 9.6";
      file = "Better-Leaves-9.6.zip";
      url = "https://cdn.modrinth.com/data/uvpymuxq/versions/w4ReEpuG/Better-Leaves-9.6.zip";
      sha512 = "793dacaca4c200656e8875195e42975ecb628af114e13aad2059368b51cf45f00280f86075368e9adf492e847718a9d593bdf481664e10cf1aa9628d2a51a8d6";
    }
  ];
}
