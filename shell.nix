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
        figlet
        lolcat
	      bat
        tree
        magic-wormhole
        home-manager
        git
        # vscode # We NEED to add a if statement here somehow that checks if you're in wsl
        # rnix-lsp
        # lorri
        nil
        # hello
        # nixpkgs-fmt
        just;
        # pre-commit

        # age
        # ssh-to-age
        # sops

        # libiconv
    };

    GREETING = "Moo!";

    shellHook = ''
      echo $GREETING | figlet | cowsay | lolcat
    '';
  };
}
