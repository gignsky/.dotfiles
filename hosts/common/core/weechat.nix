{ pkgs, ... }:
{
  services.weechat = {
    enable = true;
  };
  environment.systemPackages = [
    pkgs.weechatScripts.weechat-matrix
  ];
}
