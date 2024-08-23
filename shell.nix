# let
#   nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
#   pkgs = import nixpkgs { config = {}; overlays = []; };
# in

# pkgs.mkShellNoCC {
#   packages = with pkgs; [
#     magic-wormhole
#     tree
#     cowsay
#     lolcat
#     git
#     vscode
#     nil
#     nixpkgs-fmt
#   ];

#   GREETING = "You've entered the NixOS Configuration Environment!";

#   shellHook = ''
#     echo $GREETING | cowsay | lolcat
#     git config --global user.email "gignsky@gmail.com"
#     git config --global user.name "Gignsky"
#   '';
# }

#################### DevShell ####################
#
# Custom shell for bootstrapping on new hosts, modifying nix-config, and secrets management

{ pkgs ? # If pkgs is not defined, instantiate nixpkgs from locked commit
  let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
  import nixpkgs { overlays = [ ]; }
, ...
}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs)
	      wget
        cowsay
        lolcat
	      bat
        tree
        magic-wormhole


        nix
        home-manager
        git
        vscode # We NEED to add a if statement here somehow that checks if you're in wsl
        # rnix-lsp
        nil
        nixpkgs-fmt
        just;
        # pre-commit

        # age
        # ssh-to-age
        # sops

        # libiconv
    };

    GREETING = "You've entered the NixOS Configuration Environment!";

    # shellHook = ''
    #   echo $GREETING | cowsay | lolcat
    #   git config --global user.email "gignsky@gmail.com"
    #   git config --global user.name "Gignsky"
    # '';
  };
}
