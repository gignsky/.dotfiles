{ configLib, ... }:
{
  programs.thunderbird = {
    enable = true;
    settings = { };
    profiles = { };
  };

  # home.file.".config/direnv/direnv.toml".source =
  #   configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
}
