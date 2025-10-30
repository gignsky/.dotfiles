{
  # Basics
  # quit = "exit"; # Should update to use new super-exit program
  _ = "sudo";
  dot = "cd ~/.dotfiles";
  work = "cd ~/workingFile/";
  # ll = "ls -lh";
  lla = "eza -gla";
  # cp = "cp -rv";
  mv = "mv -v";
  rd = "rmdir";
  rdd = "rm -rfv";
  cls = "clear";
  md = "mkdir";
  syst = "systemctl";
  cat = "bat";
  alsmod = "nano $env.HOME/.dotfiles/home/gig/common/optional/shellAliases.nix";
  # als = "alias";
  cd = "z";
  nd = "nix develop -c nu";
  nr = "nix run";
  nb = "nix build";
  ndw = "nix develop .#windows -c nu";
  diddy = "touch";

  #recursive listing for searching
  # need to write a nushell script to make this work since it uses pipes
  # lsr = "ls **/* \| where type == file \| sort-by size";

  # ssh
  spacedock = "ssh -i ~/.ssh/gment gig@192.168.51.2";
  ganoslal = "ssh gig@ganoslal-wsl";
  merlin = "ssh gig@merlins-windows-wsl";
  spacedockm = "mosh gig@192.168.51.2";
  ganoslalm = "mosh gig@ganoslal-wsl";
  merlinm = "mosh gig@merlins-windows-wsl";

  # nmap
  localnmap = "nix shell nixpkgs#nmap -c nmap -v -sn --open 192.168.51.0/24";
  spacenmap = "nix shell nixpkgs#nmap -c nmap -A -T4 192.168.51.2";
  fullnmap = "nix shell nixpkgs#nmap -c nmap -A -T4 -v --open 192.168.51.0/24 | less";

  # Git
  lg = "lazygit";

  # Keygen
  new-age = "nix-shell -p age --run 'age-keygen -o key.txt'";
  ssh-age = "nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'";
  new-ssh = "ssh-keygen -t ed25519 -f ";
  password = "mkpasswd -s";

  # Template commands
  rusty-repo = "nix --accept-flake-config run github:juspay/omnix -- init github:gignsky/rust-nix-template -o";
  nixup = "nix --accept-flake-config run github:juspay/omnix -- init github:gignsky/nix-template -o";
  om = "nix run github:juspay/omnix --";
  inspect = "nix run github:bluskript/nix-inspect";
  mvim = "nix run github:gignsky/gigvim";
  mini = "nix run github:gignsky/gigvim#mini";
  full = "nix run github:gignsky/gigvim#full";
  fupdate = "nix run github:gignsky/nix-update-input";
}
