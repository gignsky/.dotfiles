# Floatplane-Downloader (github.com/Inrixia/Floatplane-Downloader), run as a
# service on spacedock. Scoped to downloading only "The WAN Show" channel
# from the Linus Media Group creator and writing straight into the series
# folder Sonarr already manages for it (TVDB id 333624) for air-date
# matching — no renaming or moving ever happens on either side.
#
# "The WAN Show" is a channel the tool's own defaults already carve out of
# the LMG creator feed (src/lib/defaults.ts, defaultSubChannels), matching
# posts in Floatplane's WAN Show channel whose title contains "- wan show".
# Step 3 below replaces the LMG subscription's entire `channels` list with
# just that one matcher plus an explicit catch-all `skip: true`, rather than
# trying to skip every live-fetched official channel (main LTT, TechLinked,
# Techquickie, Shorts, ...) one at a time — those get appended by the tool on
# every run, so a per-channel skip list is never actually complete; the
# catch-all is, because matching is first-match-wins and newly appended
# channels land after it. Adding another LMG show later means inserting its
# own matcher ABOVE the catch-all in settings.json, not just un-skipping
# something — the catch-all would otherwise claim it first.
#
# ALREADY DONE (confirmed live against Sonarr's API, 2026-10-20):
#   - Series added: "The WAN Show", id 875, tvdbId 333624, seriesType
#     "daily", monitored false.
#   - Its Path is `/media/floatplane/WAN Show, The (2013)` — Sonarr's own
#     TRaSH-style folder naming, NOT the literal channel title. Rather than
#     fight Sonarr's naming (the user's call), this file hardcodes that exact
#     folder name below instead of relying on Floatplane-Downloader's
#     `%channelTitle%` placeholder, which would produce a plain "The WAN
#     Show" folder that doesn't exist.
#     IMPORTANT: Sonarr's `/media` is NOT this share's root — it's this
#     share's `video/` folder. Confirmed directly on spacedock: `~/mnt/media`
#     (core/samba.nix's mount of the same share) has both a `video/`
#     subfolder and Sonarr's OTHER series lives at
#     `/media/Television/Collections/...`, which only lines up if Sonarr's
#     `/media` == `~/mnt/media/video`. So every path below keeps `video/`.
#     The series folder itself did NOT exist on disk (Sonarr's "create empty
#     series folders" is apparently off) — created by hand as part of this
#     setup: `mkdir -p "~/mnt/media/video/floatplane/WAN Show, The (2013)"`.
#   - Sonarr is reachable at http://192.168.51.3:30113 (NOT the usual 8989 —
#     that port is closed on this host; 30113 is a remapped port).
#   - Parse-tested directly against Sonarr's API with a real title+date: it
#     resolves to series.id 875 and a real unfiled episode (S2026E42, air-date
#     2026-10-16) — title format, date format and seriesId are all confirmed
#     correct, not just plausible.
#   - `floatplane-sonarr-env` sops secret exists (nix-secrets commit 6f08e01)
#     with the real SONARR_URL/SONARR_API_KEY, so the import-trigger service
#     below is wired up and uncommented, not left as a TODO.
#
# STILL TODO, in order, before `autoStart` can flip to true:
#
#   1. Uncomment this file's import in containers/services/default.nix and
#      `just rebuild` on spacedock — with `autoStart = false` as committed,
#      this only creates the CIFS mount, the /var/lib/floatplane-wan-show/db
#      directory, and wires up the Sonarr import timer; it does not start the
#      downloader container yet. Note: this repo's rebuild script
#      (scripts/nixos-rebuild.sh) auto-commits the working tree as part of a
#      successful switch — this and the default.nix import will land in a
#      commit on the current roll branch, not just on disk. This is a
#      SHARED, actively multi-host repo — re-verify the committed file's
#      content right after any rebuild (a concurrent pull/merge from another
#      session has already clobbered this file once; don't assume disk state
#      matches what was last agreed without checking).
#
#   2. First run needs an interactive login — Floatplane uses a device-code
#      flow, not a plain password. `floatplane_videosToSearch=0` below makes
#      `fetchNewVideos` return immediately for every subscription (see
#      Subscription.ts) as long as the value actually arrives as the number
#      0 — the point is to make this run as low-risk as practical while it
#      discovers every creator/channel you're subscribed to, not to search
#      or download anything. The login scratch volume is on local disk
#      (`/var/lib/floatplane-wan-show/login-scratch`), not the CIFS share —
#      no reason to depend on the mount, or risk anything landing near the
#      library, for a run that's supposed to download nothing:
#        sudo mkdir -p /var/lib/floatplane-wan-show/login-scratch
#        sudo podman run -it --rm -v /var/lib/floatplane-wan-show/db:/fp/db -v /var/lib/floatplane-wan-show/login-scratch:/fp/videos -e headless=true -e floatplane_videosToSearch=0 docker.io/inrix/floatplane-downloader:latest
#      (sudo throughout this file's manual commands: the dirs are root-owned,
#      and the real service runs under the system's rootful podman, so a
#      manual run should use that same instance, not a per-user rootless one.)
#      headless=true means it won't try to open a browser itself — watch the
#      console for the login URL and open it yourself. Once logged in, let
#      it keep running until you see a `Queued … videos...` line, then in a
#      second shell confirm every creator you're subscribed to (not just
#      LMG) shows up under `subscriptions`:
#        sudo cat /var/lib/floatplane-wan-show/db/settings.json
#      (the db may flush lazily, so trust this check over the console log
#      timing). Ctrl-C once that looks complete.
#
#   3. Edit /var/lib/floatplane-wan-show/db/settings.json as root. Under
#      `subscriptions`, set the Linus Media Group entry's `channels` to
#      exactly this (creatorId confirmed from the tool's own source,
#      src/lib/defaults.ts — if your file shows a subscription whose `plan`
#      looks like an LTT/LMG tier under a different key, use that key
#      instead):
#        "59f94c0bdd241b70349eb72b": {
#          "creatorId": "59f94c0bdd241b70349eb72b",
#          "plan": "<keep whatever plan string is already there — display only>",
#          "skip": false,
#          "channels": [
#            {
#              "title": "The WAN Show",
#              "skip": false,
#              "isChannel": "(post, video) => isChannel(post, '63fe42c309e691e4e36de93d') && post.title?.toLowerCase().includes('- wan show')"
#            },
#            { "title": "Skip everything else", "skip": true, "isChannel": "() => true" }
#          ]
#        }
#      Replacing the whole list (rather than editing whatever the tool
#      generated) sidesteps two problems: there's no need to chase down and
#      skip every official LTT/TechLinked/Techquickie/etc. channel one by
#      one, and no race with how far the login run in step 2 got before you
#      hit Ctrl-C — matching is first-match-wins, so the catch-all at the end
#      blocks anything the tool appends later too, including channels that
#      don't even exist yet.
#      If you're subscribed to any non-LMG creators, give each of those
#      subscription entries its own top-level `"skip": true` the same way.
#      Floatplane only has what was actually posted to Floatplane, and the
#      WAN Show matcher above additionally requires a specific Floatplane
#      channel id that this LMG creator only appears to have used from
#      roughly 2023 onward — so the realistic backfill is "WAN Show on
#      Floatplane", not necessarily all the way back to 2013. After the first
#      real run (step 4), check the earliest downloaded file's date. If it's
#      more recent than expected, FIRST `sudo systemctl stop
#      podman-floatplane-wan-show` (the running process holds settings in
#      memory and periodically rewrites the file, so an edit made while it's
#      up can get silently overwritten), THEN loosen the WAN Show entry's
#      `isChannel` to a title-only match:
#        (post) => post.title?.toLowerCase().includes('- wan show')
#      set `floatplane_videosToSearch` back to the backfill value (see step 4
#      below) and start the service back up.
#      IMPORTANT: never run Sonarr's "Rename Files"/organize on this series.
#      Floatplane-Downloader tracks each video by its exact file size at its
#      exact path (db/attachments.json); a Sonarr rename (or a Move-mode
#      import) makes the file unrecognizable to it and it will download that
#      episode again next poll. Since the container writes directly into
#      what is already Sonarr's own series folder, nothing ever needs to be
#      moved — Sonarr just needs to notice the file is already there, which
#      is exactly what the RescanSeries timer below does (every 15 min; its
#      own scheduled Refresh Series task would eventually notice it anyway,
#      just on a much longer ~12h cadence). Once files exist, also spot-check
#      a couple of real downloaded filenames' dates against TVDB's air dates
#      (thetvdb.com/series/wan-show/seasons/official/<year>) — a mismatch
#      there usually means the container's TZ isn't being honored as expected.
#
#   4. Delete the scratch directory from step 2 and
#      /var/lib/floatplane-wan-show/db/attachments.json, then flip
#      `autoStart` back to true below and switch. `floatplane_videosToSearch`
#      is set to "1000000" in the environment below for this first real
#      pass — `blogPostsIterable` (floatplaneAPI.ts's creator.ts) stops on
#      its own once the creator's post history runs out, so this walks the
#      entire feed back to the start rather than actually fetching a million
#      posts. Watch it land:
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
#      spacedock being down for as little as a day could skip that week's
#      episode. "100" is a buffer generous enough to absorb a few weeks of
#      downtime without re-walking the whole feed every time.
#
#   Storage/bandwidth: this backfill is every WAN Show episode Floatplane
#   has at 1080p — each episode runs ~2-3 hours, so expect several GB per
#   episode and very possibly several hundred GB in total on the share.
#   `maxDownloadSpeed` (mbps, env var `maxDownloadSpeed`) defaults to -1
#   (unlimited) — set it if the backfill shouldn't saturate the link.
{
  config,
  configVars,
  pkgs,
  ...
}:
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
    autoStart = false; # flip to true only after completing steps 1-4 above
    environment = {
      # LMG is Vancouver-based and WAN Show airs Friday evenings local time;
      # using the container's own TZ for %year%/%month%/%day% keeps the date
      # Sonarr parses in sync with the air-date TVDB recorded, instead of
      # shifting a Friday-night release into Saturday under a US-Eastern clock.
      TZ = "America/Vancouver";
      headless = "true";
      # Hardcoded to Sonarr's actual folder name (not %channelTitle%, which
      # would produce a plain "The WAN Show" folder Sonarr doesn't use — see
      # the file header). The volume below already scopes /fp/videos to that
      # exact folder, so this is flat: no extra show-named subfolder level.
      filePathFormatting = "/fp/videos/The WAN Show - %year%-%month%-%day% - %videoTitle%";
      floatplane_videoResolution = "1080";
      extras_downloadArtwork = "true";
      # "1000000" for the initial backfill (step 4) — blogPostsIterable
      # stops on its own once the creator's post history runs out, so this
      # just means "walk the whole feed," not "fetch a million posts".
      # Lower to something like "100" once the backfill finishes (watch for
      # "Checking for new videos in 5 minutes..." in the logs) and switch
      # again — this value re-applies on every container start, so leaving
      # it at the full backfill depth forever is harmless but slower than
      # needed, while dropping it too low (or to the tool's own default of 5)
      # risks a restart/reboot missing an episode if spacedock was down long
      # enough for more than a handful of other LMG posts to land first.
      floatplane_videosToSearch = "1000000";
      # maxDownloadSpeed (mbps) defaults to -1 (unlimited) — the initial
      # backfill is every WAN Show episode at 1080p, several GB each; set
      # this if that shouldn't saturate the link, e.g. maxDownloadSpeed = "20";
    };
    volumes = [
      "/var/lib/floatplane-wan-show/db:/fp/db"
      "/mnt/floatplane-media/video/floatplane/WAN Show, The (2013):/fp/videos"
    ];
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/floatplane-wan-show/db 0750 root root -"
    ];

    # Sonarr import trigger. Not strictly required — Sonarr's own scheduled
    # Refresh Series task already picks up new files within its default ~12h
    # cadence with no wiring at all — but wired up anyway to cut that latency
    # to 15 minutes. RescanSeries (not DownloadedEpisodesScan) because the
    # container writes straight into Sonarr's own series folder — there's no
    # separate download-client folder to move files out of, and Move-mode
    # import would break Floatplane-Downloader's own tracking (see step 3's
    # warning above).
    services.floatplane-wan-show-sonarr-import = {
      description = "Trigger a Sonarr RescanSeries for The WAN Show";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets.floatplane-sonarr-env.path;
      };
      script = ''
        ${pkgs.curl}/bin/curl -sf -X POST "$SONARR_URL/api/v3/command" \
          -H "X-Api-Key: $SONARR_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{"name":"RescanSeries","seriesId":875}'
      '';
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
