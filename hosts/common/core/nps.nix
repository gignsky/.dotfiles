{ pkgs, configVars, ... }:
{
  environment.systemPackages = [
    pkgs.nps
  ];

  # # setting env vars
  # environment.variables = {
  #   # forcing flake mode
  #   NIX_PACKAGE_SEARCH_EXPERIMENTAL = "true";
  #   # NIX_PACKAGE_SEARCH_MULTI_LINE = "true";
  #   NIX_PACKAGE_SEARCH_TRUNCATE = "true"; # Can only be enabled if multi-line is off
  # };

  # automating cache refresh
  systemd.timers."refresh-nps-cache" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # DEFAULT: # OnCalendar = "weekly"; # or however often you'd like
      OnCalendar = "hourly"; # or however often you'd like
      Persistent = true;
      Unit = "refresh-nps-cache.service";
    };
  };

  systemd.services."refresh-nps-cache" = {
    # Make sure `nix` and `nix-env` are findable by systemd.services.
    path = [ "/run/current-system/sw/" ];
    serviceConfig = {
      Type = "oneshot";
      User = "${configVars.username}"; # ⚠️ replace with your "username" or "${user}", if it's defined
    };
    script = ''
      set -eu
      echo "Start refreshing nps cache..."
      # ⚠️ note the use of overlay (as described above), adjust if needed
      # ⚠️ use `nps -dddd -e -r` if you use flakes
      ${pkgs.nps}/bin/nps -r -dddd
      echo "... finished nps cache with exit code $?."
    '';
  };
}
