{ inputs, ... }:
{
  imports = [ inputs.nufetch.homeManagerModules.nufetch ];

  programs.nufetch = {
    enable = true;
    packages = true;
    resolution = true;
    theme = true;
    icons = true;
    terminal_font = true;
    cpu_usage = true;
    public_ip = true;
    local_ip = true;
    song = true;
    users = true;
  };
}
