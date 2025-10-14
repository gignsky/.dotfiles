{
  # rdp stuff
  services.xrdp = {
    enable = true;
    # audio.enable = true;
    port = 3389;
    openFirewall = true;
    sslCert = "/etc/xrdp/cert.pem"; # convert this to a sops token
    defaultWindowManager = "startplasma-x11"; # default "xterm
  };

  # workaround for slow initalization and lack of clipboard support, clipboard not working still :(
  #  environment.etc = {
  #   "xrdp/sesman.ini".source = "${config.services.xrdp.confDir}/sesman.ini";
  #};
}
