# Floatplane-Downloader (github.com/Inrixia/Floatplane-Downloader), run as a
# service on spacedock. Scoped to downloading only "The WAN Show" channel
# from the Linus Media Group creator and naming files so Sonarr can pick
# them up as the TVDB series "The WAN Show" (id 333624) via air-date
# matching.
#
# "The WAN Show" is a channel the tool's own defaults already carve out of
# the LMG creator feed (src/lib/defaults.ts, defaultSubChannels), matching
# posts in Floatplane's WAN Show channel whose title contains "- wan show".
# Its title happens to already match thetvdb.com's title exactly. Step 7
# below replaces the LMG subscription's entire `channels` list with just that
# one matcher plus an explicit catch-all `skip: true`, rather than trying to
# skip every live-fetched official channel (main LTT, TechLinked,
# Techquickie, Shorts, ...) one at a time — those get appended by the tool
# on every run, so a per-channel skip list is never actually complete; the
# catch-all is, because matching is first-match-wins and newly appended
# channels land after it.
#
# DISABLED by default (not imported by containers/services/default.nix) —
# this needs one-time manual setup, IN THIS ORDER, before it's safe to
# enable:
#
#   1. Add to nix-secrets/secrets.yaml (`just sops`) a key
#      `floatplane-sonarr-env` whose value is an env file:
#        SONARR_URL=http://192.168.51.3:8989
#        SONARR_API_KEY=<Sonarr API key, from Settings > General>
#      validateSopsFiles is on, so the build fails until the key exists.
#
#   2. In Sonarr: add the series by TVDB id 333624 ("The WAN Show"):
#        - Series Type: "Daily" (matches episodes by air-date instead of
#          season/episode — required, since the filename below carries a
#          date, not SxxExx).
#        - Monitor: "None", and untick "Start search for missing episodes".
#          Sonarr almost certainly has indexers configured here (nzbget is
#          already in the fleet); a monitored series with search on will go
#          hunt down 13 years of WAN Show on Usenet, and any grab it
#          upgrades to will delete the Floatplane-downloaded file out from
#          under it — which re-triggers the exact re-download loop warned
#          about below, just via Sonarr instead of a rename.
#        - Root folder: wherever SONARR ITSELF sees this NAS share's
#          `video/floatplane` path — that is almost certainly NOT
#          `/mnt/floatplane-media` below, which is just spacedock's own CIFS
#          mount of the same share. Ask Sonarr's own root-folder picker what
#          path it uses locally.
#      After adding it, open the series' Edit screen and confirm the Path
#      ends exactly in `/The WAN Show` — Sonarr's folder-naming format
#      (e.g. TRaSH-style `{Series TitleYear} [tvdbid-…]`) can easily produce
#      something else, in which case fix the Series Folder Format or rename
#      the folder by hand so it matches what Floatplane-Downloader writes.
#      Then check the title/date parse (fill in your real API key):
#        curl "http://192.168.51.3:8989/api/v3/parse?title=The%20WAN%20Show%20-%202026-10-16%20-%20Test" -H "X-Api-Key: <your Sonarr API key>"
#      A real `series` + `episodes` in the response confirms the title
#      matches; an empty one means nothing will ever import. It does NOT
#      confirm the date the downloader itself produces — do that after step
#      6, by comparing a couple of real downloaded filenames against TVDB's
#      air dates (thetvdb.com/series/wan-show/seasons/official/<year>) once
#      files exist. A mismatch there usually means the container's TZ isn't
#      being honored the way expected.
#      IMPORTANT: never run Sonarr's "Rename Files"/organize on this series.
#      Floatplane-Downloader tracks each video by its exact file size at its
#      exact path (db/attachments.json); a Sonarr rename (or a Move-mode
#      import) makes the file unrecognizable to it and it will download that
#      episode again next poll. Since the container writes directly into
#      what is already Sonarr's own root folder, nothing ever needs to be
#      moved — Sonarr just needs to notice the file is already there.
#
#   3. Once you know that path, uncomment and fill in the
#      floatplane-wan-show-sonarr-import service + timer at the bottom of
#      this file (uses RescanSeries, not DownloadedEpisodesScan — there is
#      no download-client folder to move files out of here; RescanSeries
#      registers files already in the series' own folder without moving or
#      renaming them).
#
#   4. Uncomment this file's import in containers/services/default.nix and
#      `just rebuild` on spacedock — with `autoStart = false` as committed,
#      this only creates the CIFS mount, the /var/lib/floatplane-wan-show/db
#      directory and the sops secret; it does not start the container yet.
#
#   5. On spacedock (sudo needed — the dirs below are root-owned, and the
#      real service runs under the system's rootful podman, so the manual
#      login run should use that same instance, not a per-user rootless one):
#        sudo mkdir -p /mnt/floatplane-media/video/floatplane-login-scratch
#        sudo mkdir -p /mnt/floatplane-media/video/floatplane
#      The second path is the real output folder — the bind mount in this
#      file fails if its source doesn't exist yet. The scratch folder is
#      deliberately separate so nothing lands in the real library before
#      step 7 has replaced the channel list (see why there).
#
#   6. First run needs an interactive login — Floatplane uses a device-code
#      flow, not a plain password:
#        sudo podman run -it --rm -v /var/lib/floatplane-wan-show/db:/fp/db -v /mnt/floatplane-media/video/floatplane-login-scratch:/fp/videos -e headless=false docker.io/inrix/floatplane-downloader:latest
#      Watch the console for the login URL/code and finish login in a
#      browser. As soon as it confirms you're authenticated, Ctrl-C — don't
#      wait for it to finish fetching/downloading anything. (Its generated
#      settings.json will likely be incomplete or even absent at this point;
#      that's fine, step 7 writes the part that matters directly.)
#
#   7. Edit /var/lib/floatplane-wan-show/db/settings.json as root. Under
#      `subscriptions`, set the Linus Media Group entry's `channels` to
#      exactly this (creatorId confirmed from the tool's own source,
#      src/lib/defaults.ts — if your file shows a subscription whose
#      `plan` looks like an LTT/LMG tier under a different key, use that
#      key instead):
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
#      one, and no race with how far the login run in step 6 got before you
#      hit Ctrl-C — matching is first-match-wins, so the catch-all at the
#      end blocks anything the tool appends later too, including channels
#      that don't even exist yet.
#      If you're subscribed to any non-LMG creators, give each of those
#      subscription entries its own top-level `"skip": true` the same way.
#      Floatplane only has what was actually posted to Floatplane, and the
#      WAN Show matcher above additionally requires a specific Floatplane
#      channel id that this LMG creator only appears to have used from
#      roughly 2023 onward — so the realistic backfill is "WAN Show on
#      Floatplane", not necessarily all the way back to 2013. After the
#      first real run, check the earliest downloaded file's date; if it's
#      more recent than expected, loosen the WAN Show entry's `isChannel`
#      above to a title-only match instead:
#        (post) => post.title?.toLowerCase().includes('- wan show')
#
#   8. Delete the scratch directory from step 5 and
#      /var/lib/floatplane-wan-show/db/attachments.json (if it has entries
#      from the login run), then flip `autoStart` back to true below and
#      switch. The container will do its real first pass into
#      `video/floatplane`, bound by `floatplane_videosToSearch` (see its
#      comment below — set high for the initial backfill, then lowered).
{
  configVars,
  pkgs,
  ...
}:
{
  sops.secrets.floatplane-sonarr-env = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/floatplane-wan-show/db 0750 root root -"
  ];

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
    autoStart = false; # flip to true only after completing steps 1-8 above
    environment = {
      # LMG is Vancouver-based and WAN Show airs Friday evenings local time;
      # using the container's own TZ for %year%/%month%/%day% keeps the date
      # Sonarr parses in sync with the air-date TVDB recorded, instead of
      # shifting a Friday-night release into Saturday under a US-Eastern clock.
      TZ = "America/Vancouver";
      headless = "true";
      # %channelTitle% gives every Floatplane channel its own subfolder, so
      # un-skipping another LMG channel later (TechLinked, Techquickie, ...)
      # needs no config change here — it'll just sort itself alongside
      # "The WAN Show".
      filePathFormatting = "/fp/videos/%channelTitle%/%channelTitle% - %year%-%month%-%day% - %videoTitle%";
      floatplane_videoResolution = "1080";
      floatplane_videosToSearch = "5000"; # see step 8 above — lower once the backlog is caught up
      extras_downloadArtwork = "true";
    };
    volumes = [
      "/var/lib/floatplane-wan-show/db:/fp/db"
      "/mnt/floatplane-media/video/floatplane:/fp/videos"
    ];
  };

  # Sonarr import trigger — Floatplane-Downloader has no Sonarr integration of
  # its own (only Plex), and Sonarr does not watch arbitrary folders, so
  # something has to periodically tell it to look. RescanSeries (not
  # DownloadedEpisodesScan) because the container writes straight into
  # Sonarr's own root folder — there's no separate download-client folder to
  # move files out of, and Move-mode import would break Floatplane-
  # Downloader's own tracking (see step 2's warning above). Commented out
  # until step 3 is done (needs the series' Sonarr-side numeric id, e.g. from
  # `GET $SONARR_URL/api/v3/series`). When uncommenting, also add `config` to
  # this file's function arguments above — it's unused (and would fail
  # deadnix) while this block stays commented out.
  #
  # systemd.services.floatplane-wan-show-sonarr-import = {
  #   description = "Trigger a Sonarr RescanSeries for The WAN Show";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     EnvironmentFile = config.sops.secrets.floatplane-sonarr-env.path;
  #   };
  #   script = ''
  #     # FIXME: The WAN Show's Sonarr seriesId, see step 3 above.
  #     SONARR_SERIES_ID="FIXME"
  #     ${pkgs.curl}/bin/curl -sf -X POST "$SONARR_URL/api/v3/command" \
  #       -H "X-Api-Key: $SONARR_API_KEY" \
  #       -H "Content-Type: application/json" \
  #       -d "{\"name\":\"RescanSeries\",\"seriesId\":$SONARR_SERIES_ID}"
  #   '';
  # };
  #
  # systemd.timers.floatplane-wan-show-sonarr-import = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnBootSec = "5m";
  #     OnUnitActiveSec = "15m";
  #   };
  # };

  environment.systemPackages = [ pkgs.cifs-utils ];
}
