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
#      VERIFIED 2026-10-20 on the first live run: Sonarr imported both
#      series' files via RescanSeries within minutes, and every Techquickie
#      filename date matched Sonarr's air date (the early-access worry did
#      not materialise: Floatplane and TVDB dates agree for that show). The
#      one miss was a WAN Show VOD posted just after midnight Pacific and
#      so dated Saturday — the reason TZ below is UTC-12, see its comment.
#      Two things to know about what Sonarr sees:
#      - The tool downloads to `<name>.partial` and muxes into `<name>.mp4`
#        as it goes, so Sonarr can import an mp4 that is still growing. It
#        records the size at that moment and corrects it on a later rescan;
#        harmless, but a freshly imported episode may be unplayable for a
#        few minutes.
#      - `extras_downloadArtwork` plus the tool's default saveNfo and
#        downloadCaptions put .jpg/.nfo/.en.vtt beside each video. Sonarr
#        picks up the .vtt as a subtitle and ignores the rest.
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
#   If the service ever crash-loops with `Unable to authenticate with
#   floatplane... unexpected HTTP response status code` /
#   `OAUTH_RESPONSE_IS_NOT_CONFORM`: stop it first (`sudo systemctl stop
#   podman-floatplane-wan-show`) so it stops hammering auth.floatplane.com,
#   wait ~10 minutes for any 429 to clear, then check (a) the image digest
#   below is current (see the `image` comment) and (b) `db/auth.json` is
#   less than 90 days old — past that the refresh token is dead and step 2's
#   interactive login has to be redone.
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
    # Pinned by manifest-list digest, not the `latest` tag. The default
    # `pull = "missing"` never re-pulls a tag that already exists locally, so
    # a floating `latest` silently went stale here: the host still had a
    # January 2026 build of 5.19.4, whose bundled Floatplane library treated
    # every OAuth token as already expired and refreshed it before nearly
    # every API call. ~40 refreshes in, auth.floatplane.com returned a
    # Cloudflare 429 and the process crashed (upstream issue #290, fixed
    # 2026-09-17). This digest is 5.19.9, built 2026-10-10, which bundles
    # the fixed library. To bump:
    #   nix run nixpkgs#skopeo -- inspect --no-tags docker://docker.io/inrix/floatplane-downloader:latest | jq -r .Digest
    # paste the new digest here, switch, then `sudo systemctl restart
    # podman-floatplane-wan-show`. (The Digest skopeo prints for a tag is the
    # multi-arch index digest, which podman also records under RepoDigests,
    # so the two agree.)
    image = "docker.io/inrix/floatplane-downloader@sha256:86f5743968376ebe810409708e4e56bacb98f79f4511cc310d02b8f2bfaf5aa9";
    autoStart = true;
    environment = {
      # %year%/%month%/%day% come from each post's release time in the
      # container's TZ, and Sonarr needs that date to equal TVDB's air date.
      # UTC-12 (POSIX sign: Etc/GMT+12 IS twelve hours BEHIND UTC), not
      # Vancouver, on purpose. Checked against the release times of the 82
      # posts the tool had seen by 2026-10-20 (db/attachments.json):
      #   - WAN Show airs Friday ~16:30 Pacific and the VOD is posted 2-8h
      #     later. Under America/Vancouver 5 of 42 Friday shows (Jan 30,
      #     Mar 13, Mar 20, Aug 28, Oct 2 2026) were posted just after
      #     midnight Pacific and got a SATURDAY date, which Sonarr can never
      #     match. Under UTC-12 all 42 land on the Friday; the latest such
      #     post (09:42 UTC Sat) still has 2h18m of margin.
      #   - Techquickie posts 14:20-23:07 UTC (business hours Pacific), so
      #     UTC-12 gives every one of the 36 the same date Vancouver did —
      #     and those were verified equal to Sonarr's air dates.
      #   - Two WAN episodes were posted the following MONDAY (Jan 24 and
      #     Mar 6 2026); no timezone fixes those — Sonarr manual import.
      # Anything posted before 12:00 UTC (04:00 Pacific) would shift a day
      # EARLY under this setting; nothing in either channel's history does.
      TZ = "Etc/GMT+12";
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

    # The oci-containers module gives the unit Restart=on-failure with systemd's
    # default 100ms RestartSec. When Floatplane's auth endpoint rejects the
    # token (rate limit, outage, or a refresh token that finally expired after
    # its 90 days), that meant a fresh container every ~2.5s, each one hitting
    # the OAuth endpoint again — 118 restarts in six minutes on 2026-10-20,
    # which only deepens a 429. Two minutes between attempts still recovers
    # from transient failures on its own, at a rate the endpoint tolerates.
    services.podman-floatplane-wan-show.serviceConfig.RestartSec = "2min";

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
