{ pkgs, ... }:
{
  services.weechat = {
    enable = true;
  };
  environment.systemPackages = [
    pkgs.weechatScripts.weechat-matrix
    pkgs.screen
  ];
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
