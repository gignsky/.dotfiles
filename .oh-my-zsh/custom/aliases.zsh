#cleanup
alias cleanup='sudo apt autoremove -y'

#nzbget
alias nzbget='/export/utility-share/nzbgetFiles/nzbget'

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

#ansible
alias apingg="a -i ./inventory all -m ping -u gig"
alias apingr="a -i ./inventory all -m ping -u root"
alias alint='ansible-lint'

#pip && Python
alias pipupdate='python3 -m pip install --upgrade pip'
alias python=python3

#ytcustom
alias ytcustom='time yt-dlp -f bv*+ba --embed-metadata --embed-info-json --embed-subs --sub-format srt --convert-subs srt --embed-chapters --merge-output-format mkv -N 100 -o "%(title)s.%(ext)s"'

#yadm aliases
alias ys='yadm status'
alias ya='yadm add'
alias ycm='yadm commit -m'
alias ycam='yadm commit -am'
alias yps='yadm push'
alias ypl='yadm pull'
alias yr='yadm restore'
alias yd='yadm diff'

#file management
alias rm='rm -v'
alias rdd='rm -rfvi'
alias cp='cp -v'
alias mv='mv -v'

#user .bashrc updates
alias start='sudo apt install net-tools qemu-guest-agent -y'
alias testup='sudo apt update && sudo apt list --upgradable'
alias startupdate='sudo apt install net-tools qemu-guest-agent -y && sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y'
alias smbstart='echo "please use root command"'
alias smbend='sudo apt remove cifs-utils smbclient -y && sudo rm -rf /home/.creds && sudo apt auto-remove -y'
#alias nfsstart='sudo apt install nfs-common -y'
#alias nfsend='sudo apt remove nfs-common -y && sudo apt auto-remove -y'
alias whatsOut='sudo apt list --upgradable'
#alias davstart='sudo apt install davfs2 cadaver -y'
alias fix='sudo apt --fix-broken install'
alias stats='cat /run/motd.dynamic'
alias update='sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y'
alias updatec='sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y && clear'
alias updater='sudo apt auto-remove -y && sudo apt update -y && sudo apt list --upgradable && sudo apt-get upgrade -y && sudo reboot'

#clear
alias ccls='clear && neofetch'
alias cls='clear'
alias cll='clear && ll'

#install remove
alias install='sudo apt install -y'
alias remove='sudo apt remove -y && sudo apt auto-remove -y'
