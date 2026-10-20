# Floatplane-Downloader (github.com/Inrixia/Floatplane-Downloader), run as a
# service on spacedock. Scoped to downloading two Linus Media Group channels,
# "The WAN Show" and "Techquickie", and writing each straight into the series
# folder Sonarr already manages for it, so Sonarr can match the files by
# air date — no renaming or moving ever happens on either side.
#
# How the two shows share one container: `filePathFormatting` below uses the
# tool's `%channelTitle%` placeholder for both the subfolder and the filename
# prefix, and the volumes section bind-mounts each of Sonarr's own series
# folders (its TRaSH-style "WAN Show, The (2013)" / "TechQuickie (2013)"
# names) onto `/fp/videos/<channel title>`. The tool sees plain channel-title
# folders; the share sees Sonarr's folder names; nothing is renamed. Sonarr
# ignores the filename's title part when scanning a folder it already owns
# (RescanSeries parses only the date), so the mismatch between "Techquickie"
# in the filename and "TechQuickie (2013)" on disk is irrelevant.
# Adding a third LMG show later = add its Sonarr series + folder, add a
# matcher for it ABOVE the catch-all in settings.json (step 3 below), add a
# bind mount for its folder here, and add its series id to the rescan loop.
#
# ALREADY DONE (confirmed live against Sonarr's API, 2026-10-20):
#   - Series added, both seriesType "daily", monitored false, root folder
#     `/media/floatplane`:
#       "The WAN Show"  id 875, tvdbId 333624, path `/media/floatplane/WAN Show, The (2013)`
#       "TechQuickie"   id 876, tvdbId 319512, path `/media/floatplane/TechQuickie (2013)`
#     IMPORTANT: Sonarr's `/media` is NOT this share's root — it's this
#     share's `video/` folder. Confirmed directly on spacedock: `~/mnt/media`
#     (core/samba.nix's mount of the same share) has both a `video/`
#     subfolder and Sonarr's OTHER series lives at
#     `/media/Television/Collections/...`, which only lines up if Sonarr's
#     `/media` == `~/mnt/media/video`. So every path below keeps `video/`.
#     Sonarr's "create empty series folders" is apparently off — both series
#     folders were created by hand under `~/mnt/media/video/floatplane/`.
#   - Sonarr is reachable at http://192.168.51.3:30113 (NOT the usual 8989 —
#     that port is closed on this host; 30113 is a remapped port).
#   - Parse-tested directly against Sonarr's API with a real title+date
#     ("The WAN Show - 2026-10-16 - ..."): it resolves to series.id 875 and a
#     real unfiled episode (S2026E42) — title format, date format and
#     seriesId are confirmed correct, not just plausible.
#   - `floatplane-sonarr-env` sops secret exists (nix-secrets commit 6f08e01)
#     with the real SONARR_URL/SONARR_API_KEY.
#   - Step 1: this file is imported from containers/services/default.nix and
#     has been switched in on spacedock (CIFS mount, db dir, rescan timer).
#   - Step 2: interactive device-code login done; `auth.json` lives in
#     /var/lib/floatplane-wan-show/db. The login scratch dir was removed.
#   - Step 3: /var/lib/floatplane-wan-show/db/settings.json edited as root
#     (pre-edit copy kept beside it as settings.json.bak). The LMG
#     subscription ("59f94c0bdd241b70349eb72b") now has exactly these
#     channels, in this order — matching is first-match-wins, so the
#     catch-all at the end blocks every other official LTT/TechLinked/etc.
#     channel, including ones the tool appends on later runs:
#       { "title": "The WAN Show",  "skip": false,
#         "isChannel": "(post) => isChannel(post, '63fe42c309e691e4e36de93d') && post.title?.toLowerCase().includes('- wan show')" }
#       { "title": "Techquickie",   "skip": false,
#         "isChannel": "(post) => isChannel(post, '64135e27c773b27ff22c97eb')" }
#       { "title": "Skip everything else", "skip": true, "isChannel": "() => true" }
#     The two `title` values MUST stay exactly "The WAN Show" and
#     "Techquickie" — they are what `%channelTitle%` expands to, and the
#     bind mounts below are keyed on them.
#     If you ever subscribe to a non-LMG creator, give its subscription entry
#     its own top-level `"skip": true` the same way.
#     The process holds settings in memory and periodically rewrites the
#     file, so ALWAYS `sudo systemctl stop podman-floatplane-wan-show` before
#     editing settings.json, then start it again.
#
# STILL TODO:
#
#   4. (This switch.) `autoStart = true` below and `floatplane_videosToSearch`
#      = "1000000" for the initial backfill — `blogPostsIterable`
#      (floatplaneAPI.ts's creator.ts) stops on its own once the creator's
#      post history runs out, so this walks the entire feed back to the
#      start rather than actually fetching a million posts. Watch it land:
#        sudo journalctl -fu podman-floatplane-wan-show
#      `Checking for new videos in 5 minutes...` only prints once every
#      queued download from the backfill has finished — once you see that
#      line, lower `floatplane_videosToSearch` below to something like "100"
#      and switch again. This matters: the tool's own `downloadNewVideos()`
#      loop does reset this value to its default (5) in settings.json after
#      each pass, but the Nix env var re-overrides that on every container
#      start — leaving it at "1000000" is harmless but slower than needed on
#      every restart, while leaving it unset (or forgetting this step) means
#      any restart after the backfill searches only the last 5 LMG video
#      posts across ALL its channels combined, which is shallow enough that
#      spacedock being down for as little as a day could skip an episode.
#      "100" is a buffer generous enough to absorb a few weeks of downtime
#      without re-walking the whole feed every time.
#
#   5. Verify Sonarr actually matches the files. The rescan timer below runs
#      every 15 min; after the first few files exist, check each series in
#      Sonarr shows them as imported, and spot-check a couple of filenames'
#      dates against TVDB's air dates
#      (thetvdb.com/series/wan-show, thetvdb.com/series/techquickie).
#      - WAN Show is a live show, so Floatplane post date == air date.
#      - Techquickie is the one to watch: LMG often posts to Floatplane as
#        EARLY ACCESS, a day or so before the YouTube publish date TVDB
#        records, and Sonarr's daily matching is an exact-date match. If
#        Techquickie files sit in the folder unimported while WAN Show files
#        import fine, that's why — it then needs a different mapping for
#        that show (e.g. a post-processing rename against Sonarr's API, or
#        Sonarr's manual import), not a tweak to this file.
#      - A WAN Show mismatch, by contrast, usually means the container's TZ
#        isn't being honored as expected.
#      If the earliest WAN Show file is more recent than expected: the
#      matcher above requires a specific Floatplane channel id that this
#      creator only appears to have used from roughly 2023 onward, so the
#      realistic backfill is "WAN Show on Floatplane", not back to 2013.
#      To loosen it, stop the service first (see step 3), change that
#      entry's `isChannel` to a title-only match
#        (post) => post.title?.toLowerCase().includes('- wan show')
#      set `floatplane_videosToSearch` back to the backfill value and start
#      the service back up.
#
#   IMPORTANT: never run Sonarr's "Rename Files"/organize on these series.
#   Floatplane-Downloader tracks each video by its exact file size at its
#   exact path (db/attachments.json); a Sonarr rename (or a Move-mode import)
#   makes the file unrecognizable to it and it will download that episode
#   again next poll. Since the container writes directly into what is
#   already Sonarr's own series folder, nothing ever needs to be moved —
#   Sonarr just needs to notice the file is already there, which is exactly
#   what the RescanSeries timer below does (its own scheduled Refresh Series
#   task would eventually notice anyway, on a much longer ~12h cadence).
#
#   Storage/bandwidth: the backfill is every WAN Show episode Floatplane has
#   at 1080p (each ~2-3 hours, several GB) plus every Techquickie episode on
#   Floatplane — very possibly several hundred GB in total on the share.
#   `maxDownloadSpeed` (mbps, env var `maxDownloadSpeed`) defaults to -1
#   (unlimited) — set it if the backfill shouldn't saturate the link.
{
  config,
  configVars,
  lib,
  pkgs,
  ...
}:
let
  shareRoot = "/mnt/floatplane-media/video/floatplane";
  # Sonarr series this service feeds. `channel` is the exact channel `title`
  # from settings.json (what %channelTitle% expands to); `folder` is Sonarr's
  # own series folder name on the share; `sonarrId` is Sonarr's series id.
  shows = [
    {
      channel = "The WAN Show";
      folder = "WAN Show, The (2013)";
      sonarrId = 875;
    }
    {
      channel = "Techquickie";
      folder = "TechQuickie (2013)";
      sonarrId = 876;
    }
  ];
in
{
  sops.secrets.floatplane-sonarr-env = { };

  # Dedicated mount (rather than reusing core/samba.nix's `/home/gig/mnt/media`)
  # so this service's dependency on the share is self-contained in one file,
  # same pattern as containers/services/tdarr-node.nix.
  fileSystems."/mnt/floatplane-media" = {
    device = "//192.168.51.3/media";
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=/etc/samba/cifs-creds,uid=${toString configVars.uid},gid=${toString configVars.gid},vers=3.0"
    ];
  };

  virtualisation.oci-containers.containers.floatplane-wan-show = {
    image = "docker.io/inrix/floatplane-downloader:latest";
    autoStart = true;
    environment = {
      # LMG is Vancouver-based and WAN Show airs Friday evenings local time;
      # using the container's own TZ for %year%/%month%/%day% keeps the date
      # Sonarr parses in sync with the air-date TVDB recorded, instead of
      # shifting a Friday-night release into Saturday under a US-Eastern clock.
      TZ = "America/Vancouver";
      headless = "true";
      # %channelTitle% is the channel `title` from settings.json ("The WAN
      # Show" / "Techquickie"); each `/fp/videos/<title>` directory is a bind
      # mount of that show's Sonarr series folder (see `volumes`), so the
      # folder names Sonarr uses never have to appear here. Date-first,
      # title-only filename so Sonarr's daily parser gets an unambiguous
      # YYYY-MM-DD (no "(2013)" year in the prefix to confuse it).
      filePathFormatting = "/fp/videos/%channelTitle%/%channelTitle% - %year%-%month%-%day% - %videoTitle%";
      floatplane_videoResolution = "1080";
      extras_downloadArtwork = "true";
      # "1000000" for the initial backfill (step 4 in the header). Lower to
      # something like "100" once the backfill finishes and switch again.
      floatplane_videosToSearch = "1000000";
      # maxDownloadSpeed (mbps) defaults to -1 (unlimited) — set this if the
      # backfill shouldn't saturate the link, e.g. maxDownloadSpeed = "20";
    };
    volumes = [
      "/var/lib/floatplane-wan-show/db:/fp/db"
    ]
    ++ map (s: "${shareRoot}/${s.folder}:/fp/videos/${s.channel}") shows;
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/floatplane-wan-show/db 0750 root root -"
    ];

    # Sonarr import trigger. Not strictly required — Sonarr's own scheduled
    # Refresh Series task already picks up new files within its default ~12h
    # cadence with no wiring at all — but wired up anyway to cut that latency
    # to 15 minutes. RescanSeries (not DownloadedEpisodesScan) because the
    # container writes straight into Sonarr's own series folders — there's no
    # separate download-client folder to move files out of, and Move-mode
    # import would break Floatplane-Downloader's own tracking (see the header).
    services.floatplane-wan-show-sonarr-import = {
      description = "Trigger a Sonarr RescanSeries for the Floatplane-fed series";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets.floatplane-sonarr-env.path;
      };
      script = lib.concatMapStringsSep "\n" (s: ''
        ${pkgs.curl}/bin/curl -sf -X POST "$SONARR_URL/api/v3/command" \
          -H "X-Api-Key: $SONARR_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{"name":"RescanSeries","seriesId":${toString s.sonarrId}}'
      '') shows;
    };

    timers.floatplane-wan-show-sonarr-import = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "15m";
      };
    };
  };

  environment.systemPackages = [ pkgs.cifs-utils ];
}
