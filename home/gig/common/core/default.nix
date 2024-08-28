{ lib, pkgs, ... }:

{
    # imports = [
    #     ./bash.nix
    # ];

    nix = {
        package = lib.mkDefault pkgs.nix;
        settings = {
            experimental-features = [ "nix-command" "flakes" "repl-flake" ];
            # warn-dirty = false;
        };
    };

    services.ssh-agent.enable = true;

    home = {
        username = "gig";
        homeDirectory = "/home/gig";
        stateVersion = "24.05";
        sessionPath = []; # Add paths to $PATH
        sessionVariables = {
            FLAKE = "$HOME/.dotfiles/.";
            SHELL = "zsh";
            # TERM = "kitty";
            # TERMINAL = "kitty";
            EDITOR = "nano";
            # MANPAGER = "batman"; # see ./cli/bat.nix
        };
    };

    # home.packages = builtins.attrValues {
    #     inherit (pkgs)
    #         btop
    #         coreutils
    #         fzf;
    # };

    nixpkgs.config.allowUnfree = true;

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";
}
