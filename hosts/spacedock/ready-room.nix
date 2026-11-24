# Ready Room — the ship's Computer: an MCP door onto the annex, served from
# spacedock. The module comes from the `ready-room` flake input
# (gignsky/ready-room, nix/module.nix); the config beside this file holds no
# secret. See ready-room's docs/spacedock.md for the whole walk.
{
  config,
  inputs,
  lib,
  options,
  pkgs,
  ...
}:
let
  # The repositories the crew may work on, and the Computer indexes. One list.
  allowedRepos = {
    ready-room = {
      url = "git@github.com:gignsky/ready-room.git";
    };
    dotfiles = {
      url = "git@github.com:gignsky/.dotfiles.git";
      branchesOnly = true;
      # The crew's pre-push hook defaults to main, master and rolling; this
      # repo's rolling branch is `develop` (.roll-flow.toml), so name it too.
      # Setting the list replaces the default, hence the old three kept.
      protectedBranches = [
        "main"
        "master"
        "rolling"
        "develop"
      ];
    };
  };

  # The Computer reads her own clone of each allowed repository, under
  # /var/lib/ready-room/clones/<name>, apart from the crew's working clones,
  # pulled with a read-only deploy key of its own: GitHub attaches a deploy
  # key to one repository only, so the annex's read key cannot serve them.
  # Flip once, for every name in allowedRepos, the private half of a
  # read-only deploy key on that repo sits in nix-secrets as
  #   ready-room:
  #     <name>-key:   e.g. ready-room-key, dotfiles-key
  # (`clones.<name>.sshKeyFile` is in the pinned input, ready-room v0.6.2.)
  # Until then the Computer indexes the annex alone, as before.
  haveRepoKeys = false;
  indexedRepos = lib.optionalAttrs haveRepoKeys allowedRepos;
  repoKey = name: config.sops.secrets."ready-room/${name}-key".path;

  # How the Computer reads each allowed repository, by name. A name missing
  # here is indexed whole, with no law.
  indexRules = {
    ready-room.law = "CLAUDE.md";
    dotfiles = {
      law = "CLAUDE.md";
      # The sops files: never opened, listed or named, not even as
      # ciphertext, dropped by path before anything is read (as the annex's
      # library/sealed/ is). Today the secrets and their creation rules live
      # in gignsky/nix-secrets, and no sops file is tracked here; these are
      # the paths sops files have held in this repo's history (removed
      # 23 September 2024), sealed in case one returns. A sops file at any
      # new path must be added here.
      sealed = [
        ".sops.yaml"
        "secrets.yaml"
        "hosts/common/core/resources/secrets.yaml"
      ];
    };
  };

  # One [[repos]] block per indexed repository, appended to ready-room.toml,
  # so the index is written from the same list the crew are. TOML's strings
  # and arrays of strings share JSON's syntax, hence toJSON.
  repoBlock =
    name: _:
    let
      rules = indexRules.${name} or { };
    in
    ''

      [[repos]]
      name = ${builtins.toJSON name}
      path = ${builtins.toJSON "/var/lib/ready-room/clones/${name}"}
      pull = true
    ''
    + lib.optionalString (rules ? sealed) "sealed = ${builtins.toJSON rules.sealed}\n"
    + lib.optionalString (rules ? law) "law = ${builtins.toJSON rules.law}\n";

  # Calls: Scribby's live notes (ready-room `calls` and `call`, read-only).
  # On once both halves are here: Scribby's container on this host, and a
  # ready-room input that knows the [calls] table. An older core refuses an
  # unknown table at start, so the block waits on the input, not on a flag.
  scribbyHere = config.virtualisation.oci-containers.containers ? scribbydascribe;
  callsReady = scribbyHere && builtins.pathExists "${inputs.ready-room}/crates/rr-core/src/calls.rs";
  callsBlock = lib.optionalString callsReady ''

    [calls]
    # Scribby's recordings, read as they grow; never written. Every server's
    # calls (Lord Gig, 21 Nov 2026: live notes for everything). To narrow it,
    # name servers by id or name: guilds = ["Column & Coin"]
    sessions_dir = "/var/lib/scribbydascribe/sessions"
  '';

  extraToml = callsBlock + lib.concatStrings (lib.mapAttrsToList repoBlock indexedRepos);
  configFile =
    if extraToml == "" then
      ./ready-room.toml
    else
      pkgs.writeText "ready-room.toml" (builtins.readFile ./ready-room.toml + extraToml);

  # Flip once the secrets sit in nix-secrets (`just sops`), owned by the
  # service user:
  #   ready-room:
  #     door-token:      <any long random string>
  #     annex-key:       <private half of a read-only deploy key on gignsky/annex>
  #     annex-key-rw:    <private half of a read-write deploy key on gignsky/annex>
  #     door-passphrase: <the phrase Lord Gig types on the door's sign-in page>
  # Until then the service is declared but not enabled, so the host still
  # evaluates and builds.
  haveSecrets = true;

  # The crew, confined (work order "a real runner on spacedock", 19 Nov 2026).
  # Flip once these sit in nix-secrets (`just sops`). Each stays root-owned:
  # systemd hands it to the crew's units as a credential, and the crew user
  # can read no sops file and holds no key to decrypt one.
  #   ready-room:
  #     crew-claude-token:   <the token `claude setup-token` prints>
  #     crew-ready-room-key: <private half of a read-write deploy key on gignsky/ready-room>
  #     crew-dotfiles-key:   <private half of a read-write deploy key on gignsky/.dotfiles>
  haveCrewSecrets = false;
  # `services.ready-room.crew` is in the pinned input (ready-room v0.6.2);
  # the option check stays so an older pin still evaluates.
  crewOn = haveSecrets && haveCrewSecrets && options.services.ready-room ? crew;

  # Fastmail: the Computer's own read-only JMAP token, so it can read mail
  # (16 Nov 2026 ruling: one token per agent, read-only to start; made as in
  # the Fastmail runbook, section 7: Type JMAP, Scopes "Read-only access"
  # only). Flip once it sits in nix-secrets (`just sops`) as
  #   ready-room:
  #     fastmail-token: <the token Fastmail shows once, on creation>
  # Owned by the service user, like the door token. The core is handed the
  # file's path, never the token, as $RR_FASTMAIL_TOKEN_FILE, beside the JMAP
  # session resource it starts from (Fastmail's developer page: send the token
  # as `Authorization: Bearer <token>`). The core reads it from ready-room
  # roll/11-1123-mail on (the `mail` and `mail_item` tools), where the module
  # takes the file as `mailTokenFile` and refuses a guest handed the same
  # file. An older pin gets the variable through `environment` instead and
  # ignores it, so the flag only puts the secret in place until the input
  # carries the mail roll. This token is the Captain's alone; Lilu's Computer
  # reads her own (ready-room-lilu.nix).
  haveFastmailToken = true;
  fastmailOn = haveSecrets && haveFastmailToken;
  mailOption = options.services.ready-room ? mailTokenFile;
  fastmailToken = config.sops.secrets."ready-room/fastmail-token".path;

  # A user of their own with clones apart from ~gig/local_repos, the claude
  # CLI on their path, the token from sops. Reports reach the pad through the
  # core's beam, so the crew need no reach into the annex. On the dotfiles:
  # branches only (a pre-push hook; protect `main` and `develop` on GitHub as
  # well), never a rebuild or deploy (no privilege), no sops key. See
  # ready-room's nix/crew.nix.
  crew = {
    config = lib.optionalAttrs crewOn {
      sops.secrets = {
        "ready-room/crew-claude-token" = { };
        "ready-room/crew-ready-room-key" = { };
        "ready-room/crew-dotfiles-key" = { };
      };
      services.ready-room.crew = {
        enable = true;
        tokenFile = config.sops.secrets."ready-room/crew-claude-token".path;
        claudePackage = pkgs.unstable.claude-code;
        # `nix develop` for the repos' own gates; builds only, never a switch.
        extraPath = [ config.nix.package ];
        repos = lib.mapAttrs (
          name: r: r // { sshKeyFile = config.sops.secrets."ready-room/crew-${name}-key".path; }
        ) allowedRepos;
      };
    };
  };
in
{
  imports = [
    inputs.ready-room.nixosModules.default
    crew
  ];

  config = lib.mkIf haveSecrets {
    sops.secrets = {
      "ready-room/door-token".owner = "ready-room";
      # Two deploy keys on gignsky/annex: annex-key (read-only) does every
      # clone, fetch and pull; annex-key-rw (read-write) is used only by
      # `git push` — each beam to the transporter pad and each pad review.
      "ready-room/annex-key".owner = "ready-room";
      "ready-room/annex-key-rw".owner = "ready-room";
      "ready-room/door-passphrase".owner = "ready-room";
    }
    # One read-only deploy key per allowed repository, for the Computer's clone.
    // lib.mapAttrs' (
      name: _: lib.nameValuePair "ready-room/${name}-key" { owner = "ready-room"; }
    ) indexedRepos
    // lib.optionalAttrs fastmailOn {
      "ready-room/fastmail-token".owner = "ready-room";
    };

    services.ready-room = {
      enable = true;
      # ready-room.toml, with a [[repos]] block per indexed repository.
      inherit configFile;
      doorTokenFile = config.sops.secrets."ready-room/door-token".path;
      sshKeyFile = config.sops.secrets."ready-room/annex-key".path; # reads
      sshWriteKeyFile = config.sops.secrets."ready-room/annex-key-rw".path; # pushes
      # Opens the OAuth door (ready-room roll/1-1116-oauth): claude.ai adds
      # https://ready-room.giglab.dev/mcp as a custom connector and signs in
      # on the passphrase page the core serves. The bearer token still works.
      passphraseFile = config.sops.secrets."ready-room/door-passphrase".path;
      # Cloned into /var/lib/ready-room/clones/annex before the first start,
      # then pulled every five minutes by the core's watcher.
      # The allowed repositories follow, each with its own read key.
      clones = {
        annex.url = "git@github.com:gignsky/annex.git";
      }
      // lib.mapAttrs (name: r: {
        inherit (r) url;
        sshKeyFile = repoKey name;
      }) indexedRepos;
      # For `summaries = "haiku"` the claude CLI must be on the service PATH:
      # extraPath = [ pkgs.claude-code ];
    }
    # Mail, read-only (haveFastmailToken above). The session URL is the
    # core's default, Fastmail's own.
    // lib.optionalAttrs (fastmailOn && mailOption) {
      mailTokenFile = fastmailToken;
    }
    // lib.optionalAttrs (fastmailOn && !mailOption) {
      environment.RR_FASTMAIL_TOKEN_FILE = fastmailToken;
    };

    # Scribby's folder is root's (0750); its group lets the core read the
    # recordings' live notes. Read only: the unit's ProtectSystem = "strict"
    # leaves it no write there, and the core never tries.
    users.users.ready-room.extraGroups = lib.mkIf callsReady [ "scribbydascribe" ];

    # The door listens on the LAN (ready-room.toml binds 0.0.0.0:7474). Do not
    # forward it on the router: away from the house it is reached through the
    # cloudflared tunnel below, which terminates TLS at Cloudflare.
    networking.firewall.allowedTCPPorts = [ 7474 ];

    # Public road: https://ready-room.giglab.dev/mcp, for merlin and the phone
    # (Pebble) away from home. Same tunnel as kottonmouth-keeper.nix and
    # christina-auth.nix (NixOS merges tunnels.<id>.ingress across files);
    # giglab.dev is in the same Cloudflare account as kottonmouthband.com.
    # The whole hostname is routed: /mcp (the door), /oauth/* and
    # /.well-known/* (the OAuth sign-in claude.ai needs), /health. The locks
    # are the door's own — bearer token or OAuth access token — since the
    # phone client cannot do a Cloudflare Access login; see ready-room.toml.
    #
    # Its proxied CNAME  ready-room -> <tunnel-id>.cfargotunnel.com  is
    # upserted on every switch by giglab-dns (hosts/spacedock/
    # cloudflare-dns.nix); the apex/DDNS records are left untouched.
    services.cloudflared.tunnels."1a878786-561d-427c-90cd-358f1b82aea4".ingress."ready-room.giglab.dev" =
      {
        service = "http://127.0.0.1:7474";
      };
  };
}
