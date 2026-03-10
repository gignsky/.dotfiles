{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.oterm ];
    # Set environment variables for bat
    sessionVariables = {
      OLLAMA_URL = "http://192.168.51.3:30068";
      OLLAMA_HOST = "http://192.168.51.3:30068";
    };
  };
}
