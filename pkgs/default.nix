# You can build these directly using 'nix build .#example'

{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import packaged scripts
  scripts = import ./scripts.nix { inherit pkgs; };
in
rec {
  #################### Example Packages #################################
  # example = pkgs.writeShellScriptBin "example" ''
  #   ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
  # '';

  #################### Package name wrappers #############################
  # pear-desktop is YouTube Music's actual upstream package name; expose it
  # under the name people actually look for.
  ytmusic = pkgs.symlinkJoin {
    name = "ytmusic";
    paths = [ pkgs.pear-desktop ];
    postBuild = ''
      ln -sfn ${pkgs.pear-desktop}/bin/pear-desktop $out/bin/ytmusic
    '';
    meta = pkgs.pear-desktop.meta // {
      mainProgram = "ytmusic";
    };
  };
  #################### Binary cache scripts ##############################
  # Live next to their NixOS module (modules/nixos/binary-cache) so the two
  # extract together; exposed here for `nix run .#cache-push`.
  inherit (pkgs.callPackage ../modules/nixos/binary-cache/package.nix { })
    cache-build
    cache-watch
    cache-push
    ;

  #################### Packages with external source ####################
  # zsh-als-aliases = pkgs.callPackage ./zsh-als-aliases { }; # Removed as unnecessary but left for help in the future

  #################### Rebuild scripts (from gigpkgs) ####################
  # Moved to gigpkgs as `gig-nixos-rebuild` / `gig-home-switch` (named so they
  # never shadow nixpkgs' own `nixos-rebuild`). Re-exported under their old
  # names so the justfile's `nix run .#nixos-rebuild` / `.#home-switch` keep
  # working unchanged. They still build the flake in the current directory.
  nixos-rebuild = pkgs.gig-nixos-rebuild;
  home-switch = pkgs.gig-home-switch;

  #################### Packaged Scripts ####################
  # Import all packaged scripts from scripts.nix
  inherit (scripts)
    check-hardware-config
    flake-build
    pre-commit-flake-check
    run-iso-vm
    package-script
    seed-thunderbird-logins
    polybar-net-graph
    polybar-hidden-count
    bspwm-hidden-picker
    ;
}
