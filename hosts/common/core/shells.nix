{ pkgs, lib, inputs, outputs, ... }:

{
    # unstable overlay
    nixpkgs.overlays = [ outputs.overlays.unstable-packages ];


    environment.systemPackages = with pkgs; [
        tree
        btop
        bat
        tree
        git
        gedit
        fzf
        magic-wormhole
        wget

        # nixos-unstable packages
        unstable.just
    ];

    # Direnv
    programs.direnv = {
        enable = lib.mkDefault true;
        # Expanded settings:
        nix-direnv = {
            enable = true;
            package = pkgs.nix-direnv;
        };
        silent = false;
        # loadInNixShell = true;
        # direnvrcExtra = lib.mkDefault ''
        #     echo "direnv: loading direnvrc"
        # '';
    };

    programs.bash = let
        sword = ./resources/sword.art;
    in {
        # enable = true;
        enableCompletion = true;
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
        };

        # shellInit = ''
        #     cat ${sword} | ${pkgs.lolcat}/bin/lolcat
        # '';

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
