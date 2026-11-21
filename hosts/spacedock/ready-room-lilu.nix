# Lilu's Computer: a second Ready Room on spacedock, for Lilu (Lord Gig's
# ruling, 21 November 2026). It never holds the annex. Its record is one folder
# of gignsky/column-and-coin; Column & Coin only; she may beam onto that
# folder's transporter pad; her own passphrase alone opens the door; every call
# and sign-in goes to an audit log she is told about.
#
# The module is ready-room's `services.ready-room.guests` (nix/guest.nix,
# docs/guest.md). What it builds: the unit `ready-room-lilu`, run as the user
# `ready-room-lilu`, state in /var/lib/ready-room-lilu (0700), its own clone,
# and no reach into /var/lib/ready-room (the annex's clone and the Captain's
# index): the user cannot read it and the unit has it made inaccessible.
#
# Read the log:  sudo tail -f /var/lib/ready-room-lilu/audit.jsonl | jq -c .
{
  config,
  lib,
  options,
  ...
}:
let
  # Flip once these sit in nix-secrets (`just sops`), each owned by
  # ready-room-lilu (the module's user):
  #   ready-room-lilu:
  #     repo-key:        <private half of a read-only deploy key on gignsky/column-and-coin>
  #     repo-key-rw:     <private half of a read-write deploy key on the same repo>
  #     door-passphrase: <Lilu's passphrase: new, long, never the Captain's>
  # Add the two public halves on GitHub (column-and-coin, Settings, Deploy
  # keys; tick "Allow write access" on the second).
  haveLiluSecrets = false;

  # The guests option arrives with the ready-room input that carries
  # nix/guest.nix; an older pin still evaluates, with Lilu off.
  liluOn = haveLiluSecrets && options.services.ready-room ? guests;

  # The one folder of column-and-coin she reaches. To rename it, move the
  # folder in that repo and change this in the same breath.
  folder = "ready-room";

  hostname = "lilu.giglab.dev";
  port = 7475;

  # Scribby's call notes, for Column & Coin's own calls only: name the
  # Column & Coin Discord server here by its id (Server Settings, Widget, or
  # right-click the server with Developer Mode on, "Copy Server ID"). Empty =
  # no call notes on her door. Never every server, and never by name.
  callGuildIds = [ ];

  secret = name: config.sops.secrets."ready-room-lilu/${name}".path;
in
{
  # optionalAttrs, not mkIf: with an older input the option is not declared,
  # and the module system checks a definition's option even under mkIf false.
  config = lib.optionalAttrs liluOn {
    sops.secrets = {
      "ready-room-lilu/repo-key".owner = "ready-room-lilu";
      "ready-room-lilu/repo-key-rw".owner = "ready-room-lilu";
      "ready-room-lilu/door-passphrase".owner = "ready-room-lilu";
    };

    services.ready-room.guests.lilu = {
      enable = true;
      name = "Lilu";
      repo = {
        name = "column-and-coin";
        url = "git@github.com:gignsky/column-and-coin.git";
        inherit folder;
      };
      sshKeyFile = secret "repo-key";
      sshWriteKeyFile = secret "repo-key-rw";
      passphraseFile = secret "door-passphrase";
      inherit port;
      publicUrl = "https://${hostname}";
      calls.guildIds = callGuildIds;
    };

    # The door listens on loopback only; the world reaches it through the
    # same cloudflared tunnel as ready-room.giglab.dev, whose CNAME
    # giglab-dns upserts on every switch (hosts/spacedock/cloudflare-dns.nix).
    # No LAN port is opened.
    services.cloudflared.tunnels."1a878786-561d-427c-90cd-358f1b82aea4".ingress.${hostname} = {
      service = "http://127.0.0.1:${toString port}";
    };
  };
}
