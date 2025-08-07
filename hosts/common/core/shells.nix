{
  inputs,
  pkgs,
  outputs,
  configLib,
  ...
}:
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
    nmap
    just
    # neofetch

    # nixos-unstable packages
    # unstable.just

    # Personal packages
    # wrap.wrap # example for overlays
    inputs.wrapd.packages.${system}.wrapd
    inputs.tax-matrix.packages.${system}.tax-matrix
  ];

  programs = {
    direnv = {
      enable = false;
      package = pkgs.direnv;
      silent = false;
      loadInNixShell = true;
      direnvrcExtra = "";
      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };
    };
    bash =
      let
        sword = configLib.relativeToRoot "hosts/common/resources/sword.art";
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
    zsh = {
      enable = true;
      enableCompletion = true;
    };
  };
}
