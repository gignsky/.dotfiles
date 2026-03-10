{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      oterm
      ollama
    ];
    # Set environment variables for bat
    sessionVariables = {
      OLLAMA_URL = "http://192.168.51.3:30068";
      OLLAMA_HOST = "http://192.168.51.3:30068";
    };
  };
  programs.nushell = {
    # This appends the variables directly to your env.nu file
    envFile.text = ''
      $env.OLLAMA_URL = "http://192.168.51.3:30068"
      $env.OLLAMA_HOST = "http://192.168.51.3:30068"
    '';
  };
}
