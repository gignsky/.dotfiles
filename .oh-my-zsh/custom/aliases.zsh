#cargo
alias cb='cargo build'
alias cr='cargo run'
alias cbr='cargo build --release'
alias cbrw='cargo build --target x86_64-pc-windows-gnu --release'
alias ccl='cargo clean'
alias cc='cargo check'
alias cbin='cargo binstall -y'
alias cin='cargo install'
alias cuin='cargo uninstall'

#pipdeptree
alias pipd=pipdeptree
alias pipdf='pipdeptree -f > requirements.txt'

#tar
alias tarball='tar -czf'
alias untar='tar -xzf'

#du
alias duh='sudo du -hscx * | sort -h'

#pdf to word helper
alias pdftoword='abiword --to=doc' 

alias localnmap='nmap -v -sn 192.168.51.0/24 | grep -v down'

#ls
alias lla=lsa

#rsync
alias rs='rsync -avuh --info=progress2'
alias drs='rsync -avunhi --info=progress2'
alias srs='sudo rsync -avuh --info=progress2'
alias dsrs='sudo rsync -avunhi --info=progress2'

#alias modification line
alias alsmod='nano $HOME/.oh-my-zsh/custom/aliases.zsh'

#ssh
alias sshm=mosh

#ubuntu stuff
alias syst='sudo systemctl'
alias mounta='sudo mount -av'

#zsh alias fix cause I keep forgetting
alias asc=acs
alias als=acs

#proxmox stuff
alias qm='sudo qm'
alias pct='sudo pct'
alias pvecm='sudo pvecm'

#ansible
alias apingg="a -i ./inventory all -m ping -u gig"
alias apingr="a -i ./inventory all -m ping -u root"
alias alint='ansible-lint'

#pip && Python
alias pipupdate='python3 -m pip install --upgrade pip'
alias python=python3

#ytcustom
alias ytcustom='time yt-dlp -f bv\*+ba --embed-metadata --embed-info-json --embed-subs --sub-format srt --convert-subs srt --embed-chapters --merge-output-format mkv -N 100 --restrict-filenames --write-thumbnail'
alias ytcustomplaylist='time yt-dlp -f bv\*+ba --embed-metadata --embed-info-json --embed-subs --sub-format srt --convert-subs srt --embed-chapters --merge-output-format mkv -N 100 --restrict-filenames -o "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" --write-thumbnail'

#file management
alias rm='rm -v'
alias rdd='rm -rfv'
alias srdd='sudo rm -rfv'
alias cp='cp -v'
alias mv='mv -v'

#user .bashrc updates
alias update='home-manager switch'
alias upgrade='sudo nixos-rebuild switch'
alias upgrader='sudo nixos-rebuild switch && sudo reboot'

#clear
alias ccls='clear && neofetch'
alias cls='clear'
alias cll='clear && ll'
