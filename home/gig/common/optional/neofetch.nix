{ inputs, ... }:
{
  imports = [
    inputs.nufetch.homeManagerModules.nufetch
  ];

  programs.nufetch = {
    enable = true;
    public_ip = true;
    # local_ip = false;
    # extraPrintInfoFields = ''
    #   info "Public IP" public_ip
    # '';
  };
}
