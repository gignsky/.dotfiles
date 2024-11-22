{ pkgs, ... }:

{
    programs.git = {
        enable = true;
        extraConfig = {
        user.useConfigOnly = true;
        user.name = "gignsky";
        user.email = "gig@gignsky.com";
        # pull.rebase = true;
        # pull.ff = "only";
        };
    };
}