{ pkgs, ... }:
{
  services.weechat = {
    enable = true;
  };
  environment.systemPackages = [
    pkgs.weechatScripts.weechat-matrix
  ];
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
