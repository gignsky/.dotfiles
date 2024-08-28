{ pkgs, lib, inputs, ... }:

{
    # unstable overlay
    nixpkgs.overlays = [
        (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
            system = final.system;
            config.allowUnfree = true;
        };
        })
    ];

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
    ];

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
            als = "alias";
            syst = "systemctl";
            expo = "export NIXPKGS_ALLOW_UNFREE=1";
            cat = "bat";
        };

        shellInit = ''
            cat ${sword} | ${pkgs.lolcat}/bin/lolcat
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
