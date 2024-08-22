{ pkgs, lib, ... }:

{
    environment.systemPackages = with pkgs; [
        # cowsay
        lolcat
        tree
        btop
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