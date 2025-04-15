{
  # Basics
  _ = "sudo";
  dot = "cd ~/.dotfiles";
  work = "cd ~/workingFile";
  # ll = "ls -lh";
  lla = "eza -gla";
  # cp = "cp -rv";
  cp = "cpv --progress -r -hhh";
  mv = "mv -v";
  rd = "rmdir";
  rdd = "rm -rfv";
  cls = "clear";
  ccls = "clear && neofetch";
  md = "mkdir -p";
  syst = "systemctl";
  cat = "bat";
  alsmod = "nano $HOME/.dotfiles/home/gig/common/optional/shellAliases.nix";
  # als = "alias";

  # NIX Specific
  expo = "export NIXPKGS_ALLOW_UNFREE=1";

  # Keygen
  new-age = "nix-shell -p age --run 'age-keygen -o key.txt'";
  ssh-age = "nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'";
  new-ssh = "ssh-keygen -t ed25519 -f ";
  password = "mkpasswd -s";

  # Template commands
  rustup = "nix --accept-flake-config run github:juspay/omnix -- init github:gignsky/rust-nix-template -o";
  om = "nix run github:juspay/omnix --";

  #   # Cargo
  #   alias cb = "cargo build";
  #   alias cr = "cargo run";
  #   alias cbr = "cargo build --release";
  #   alias cbrw = "cargo build --target x86_64-pc-windows-gnu --release";
  #   alias ccl = "cargo clean";
  #   alias cc = "cargo check";
  #   alias cbin = "cargo binstall -y";
  #   alias cin = "cargo install";
  #   alias cuin = "cargo uninstall";
  #   alias ceb = "cargo expand --color=always| bat";
  #   alias cep = "cargo expand > expanded.rs";
  #   alias ce = "cargo expand";
  #
  #   #pipdeptree
  #   alias pipd=pipdeptree
  #   alias pipdf = "pipdeptree -f > requirements.txt";
  #
  #   #tdarr-switcher reactivate venv
  #   alias reactivate = "deactivate; rdd .venv; python -m venv .venv; cd ..; cd tdarr-node-switcher; pip list; pipi wheel pipdeptree; cd ..; cd tdarr-node-switcher; pipdeptree; pipupdate";
  #
  #   #buildozer
  #   alias bdinit = "buildozer init";
  #   alias bddebug = "buildozer android debug";
  #   alias bdrelease = "buildozer android release";
  #   alias bd=buildozer
  #   alias bda = "buildozer android";
  #
  #   #tar
  #   alias tarball = "tar -czf";
  #   alias untar = "tar -xzf";
  #
  #   #du
  #   alias duh = "sudo du -hscx * | sort -h";
  #
  #   #pdf to word helper
  #   alias pdftoword = "abiword --to=doc";
  #
  #   #cleanup
  #   alias cleanup = "sudo apt autoremove -y";
  #
  #   alias localnmap = "nmap -v -sn 192.168.51.0/24 | grep -v down";
  #
  #   #nzbget
  #   alias nzbget = "/export/danger-fast-nzbget/nzbgetFiles/nzbget";
  #
  #   #ls
  #   alias lla=lsa
  #
  #   #rsync
  #   alias rs = "rsync -avuh --info=progress2";
  #   alias drs = "rsync -avunhi --info=progress2";
  #   alias srs = "sudo rsync -avuh --info=progress2";
  #   alias dsrs = "sudo rsync -avunhi --info=progress2";
  #
  #   #alias modification line
  #   alias alsmod = "nano $HOME/.oh-my-zsh/custom/aliases.zsh";
  #
  #   #ssh
  #   alias sshm=mosh
  #
  #   #ubuntu stuff
  #   alias syst = "sudo systemctl";
  #   alias mounta = "sudo mount -av";
  #
  #   #zsh alias fix cause I keep forgetting
  #   alias asc=acs
  #   alias als=acs
  #
  #   #proxmox stuff
  #   alias qm = "sudo qm";
  #   alias pct = "sudo pct";
  #   alias pvecm = "sudo pvecm";
  #
  #   #ansible
  #   alias apingg="a -i ./inventory all -m ping -u gig"
  #   alias apingr="a -i ./inventory all -m ping -u root"
  #   alias alint = "ansible-lint";
  #
  #   #pip && Python
  #   alias pipupdate = "python3 -m pip install --upgrade pip";
  #   alias python=python3
  #
  #   #ytcustom
  #   alias ytcustom = "time yt-dlp -f bv\*+ba --embed-metadata --embed-info-json --embed-subs --sub-format srt --convert-subs srt --embed-chapters --merge-output-format mkv -N 100 --restrict-filenames --write-thumbnail";
  #   alias ytcustomplaylist = "time yt-dlp -f bv\*+ba --embed-metadata --embed-info-json --embed-subs --sub-format srt --convert-subs srt --embed-chapters --merge-output-format mkv -N 100 --restrict-filenames -o "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" --write-thumbnail";
  #
  #   #yadm aliases
  #   alias ys = "yadm status";
  #   alias ya = "yadm add";
  #   alias ycm = "yadm commit -m";
  #   alias ycam = "yadm commit -am";
  #   alias yps = "yadm push";
  #   alias ypl = "yadm pull";
  #   alias yr = "yadm restore";
  #   alias yd = "yadm diff";
  #
  #   #file management
  #   alias rm = "rm -v";
  #   alias rdd = "rm -rfv";
  #   alias srdd = "sudo rm -rfv";
  #   alias cp = "cp -v";
  #   alias mv = "mv -v";
  #
  #   #user .bashrc updates
  #   alias start = "sudo apt install net-tools qemu-guest-agent -y";
  #   alias testup = "sudo apt update && sudo apt list --upgradable";
  #   alias startupdate = "sudo apt install net-tools qemu-guest-agent -y && sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y";
  #   alias smbstart = "echo "please use root command"";
  #   alias smbend = "sudo apt remove cifs-utils smbclient -y && sudo rm -rf /home/.creds && sudo apt auto-remove -y";
  #   #alias nfsstart = "sudo apt install nfs-common -y";
  #   #alias nfsend = "sudo apt remove nfs-common -y && sudo apt auto-remove -y";
  #   alias whatsOut = "sudo apt list --upgradable";
  #   #alias davstart = "sudo apt install davfs2 cadaver -y";
  #   alias fix = "sudo apt --fix-broken install";
  #   alias stats = "cat /run/motd.dynamic";
  #   alias update = "sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y";
  #   alias updatec = "sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y && clear";
  #   alias updater = "sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y && sudo reboot";
  #
  #   #clear
  #   alias ccls = "clear && neofetch";
  #   alias cls = "clear";
  #   alias cll = "clear && ll";
  #
  #   #install remove
  #   alias install = "sudo apt install -y";
  #   alias remove = "sudo apt remove -y && sudo apt auto-remove -y";
}
