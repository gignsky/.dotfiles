{ inputs, pkgs, outputs, configLib, ... }:

{
  # overlays
  nixpkgs.overlays = [
    outputs.overlays.unstable-packages
    # outputs.overlays.wrap-packages # example for overlays
  ];


  environment.systemPackages = with pkgs; [
    tree
    btop
    bat
    tree
    git
    gedit
    magic-wormhole
    wget
    screen
    just
    # neofetch

    # nixos-unstable packages
    # unstable.just

    # Personal packages
    # wrap.wrap # example for overlays
    inputs.wrap.packages.${system}.default
    inputs.tax-matrix.packages.${system}.tax-matrix
  ];

  # # Direnv
  # programs.direnv = {
  #     enable = lib.mkDefault true;
  #     # Expanded settings:
  #     nix-direnv = {
  #         enable = true;
  #         package = pkgs.nix-direnv;
  #     };
  #     silent = true;
  #     loadInNixShell = true;
  #     # direnvrcExtra = lib.mkDefault ''
  #     #     echo "direnv: loading direnvrc"
  #     # '';
  # };

  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };

  programs.bash =
    let
      sword = (configLib.relativeToRoot "resources/sword.art");
    in
    {
      # enable = true;
      completion.enable = true;
      enableLsColors = true;
      shellAliases = {
        ll = "ls -lh";
        lla = "ls -lah";
        cp = "cp -rv";
        mv = "mv -v";
        rd = "rmdir";
        rdd = "rm -rfv";
        cls = "clear";
        md = "mkdir";
        # als = "alias";
        syst = "systemctl";
        expo = "export NIXPKGS_ALLOW_UNFREE=1";
        cat = "bat";
        dot = "cd ~/.dotfiles";
      };

      shellInit = ''
        cat ${sword} | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
      '';

      # loginShellInit = ''
      #     Shell script code called during login bash shell init
      # '';
    };

  # Most basic zsh install just so it's already on the system
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
}
