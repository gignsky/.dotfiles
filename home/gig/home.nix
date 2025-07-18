# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  outputs
, lib
  # , config,
, pkgs
, ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./common/core
    ./common/optional/zsh.nix
    ./common/optional/neofetch.nix
  ];
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = "nix-command flakes";
      # warn-dirty = false;
    };
  };

  home = {
    username = "gig";
    homeDirectory = "/home/gig";
    sessionPath = [ ]; # Add paths to $PATH
    sessionVariables = {
      FLAKE = "$HOME/.dotfiles/.";
      SHELL = "zsh";
      # TERM = "kitty";
      # TERMINAL = "kitty";
      EDITOR = "nano";
      # MANPAGER = "batman"; # see ./cli/bat.nix
    };
  };

  # Services

  # Lorri service for direnv integration, direnv is enabled by default.
  # services.lorri.enable = true;

  # Programs
  home.packages = with pkgs; [
    # shell packages defined in this repo
    supertree
    # quick-results
    # upjust
    # cargo-update

    # direnv # direnv is enabled by default
    dua
    # TRYING THESE OUT FROM https://blog.dalanmiller.com/my-favorite-command-line-tools/
    dust
    hwatch
    hyperfine
    mtr
    lazygit
    countryfetch
    # restic
    # xsv
    # ncdu # unneccecary due to the ability to use `dua i` for interactive better dua the only downside is that dua doesn't have a way of sorting folders at the top
    ################################################################
    ## look through and decide if these might be good to have then sort them throughout the configuration of the home files and the dotfiles, all new packages should start here for testing purposes if not used in a nix-shell -p command
    ################################################################
    # borgbackup
    # eza
    # fd
    # findutils
    # jq
    # nix-tree
    # ncdu
    # pciutils
    # pfetch
    # p7zip
    # ripgrep
    # usbutils
    # unzip
    # unrar
    # zip
    # vscode
    # curl
    # pre-commit;
    # tree
  ];

  # programs.direnv.enable = true;

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      # outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  services.ssh-agent.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
