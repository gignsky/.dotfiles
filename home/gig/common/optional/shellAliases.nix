{
  # Basics
  # quit = "exit"; # Should update to use new super-exit program
  _ = "sudo";
  dot = "cd ~/.dotfiles";
  work = "cd ~/workingFile";
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
  ndw = "nix develop .#windows -c nu";
  diddy = "touch";

  # ssh
  spacedock = "ssh -i ~/.ssh/gment gig@192.168.51.2";
  ganoslal = "ssh gig@ganoslal-wsl";
  merlin = "ssh gig@merlins-windows-wsl";
  spacedockm = "mosh gig@192.168.51.2";
  ganoslalm = "mosh gig@ganoslal-wsl";
  merlinm = "mosh gig@merlins-windows-wsl";

  # nmap
  localnmap = "nmap -v -sn 192.168.51.0/24 | grep -v down";

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
  fupdate = "nix run github:gignsky/nix-update-input";
}
