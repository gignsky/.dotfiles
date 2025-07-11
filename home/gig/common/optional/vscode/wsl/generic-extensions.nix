_:

{
  # info at
  # https://nixos.wiki/wiki/Visual_Studio_Code
  ##############################################

  # search extentions at
  # https://search.nixos.org/packages?type=packages&query=vscode-extensions
  ##############################################

  # Home Manager Way
  programs = {
    vscode = {
      enable = false;
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;
      mutableExtensionsDir = false; # disallows vscode from installing its own extensions
      # copy and paste user settings into the field below
      userSettings = { };

      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        oderwat.indent-rainbow
        ms-vscode-remote.remote-ssh
        github.copilot
        github.copilot-chat
      ];
    };

    # # A "wonderful CLI to track your time"
    # watson = {
    #     enable = false;
    #     enableZshIntegration = true;
    # };
  };
}
