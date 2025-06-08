#!/bin/bash
clear

# Vars
user='root'
tasks=5

# ANSI escape codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'
CLEAR='\r\033[K'

# Verify user
if [[ "$(whoami)" != "${user}" ]]; then
    echo -e "${RED}Error: Invalid UID. Please run this script as root.${RESET}"
    exit 1
else
    echo -e "${BOLD}${CYAN}--- Super User Setup: \"$(whoami)\" ---${RESET}"
fi


# ---------------------------------------------------------------------
task=0
current_task=''

terminal_task() {
    code=${@}
    ptyxis -- bash -c "echo -ne '\033]0;$current_task\007'; $code" 1>/dev/null 2>&1
}

task_init() {
    current_task="${*}"
    ((task++))
    echo -ne " [${BOLD}${YELLOW}~${RESET}] ${task}/${tasks}: ${current_task}"
}

task_complete() {
    local title
    if [[ -z $1 ]]; then
        title=$current_task
    else
        title="${*}"
    fi
    echo -e "${CLEAR} [${BOLD}${GREEN}+${RESET}] ${task}/${tasks}: ${title}"
}

sub_tasks() {
    local inc=0
    local ind=$1
    local -n tasks=$2

    local tempfile=$(mktemp)
    trap "rm -rf '$tempfile'" RETURN

    for arr_ref in "${@:2}"; do
        local -n array="$arr_ref"
        printf '%s\n' "${array[@]}" >> $tempfile
    done

    if [[ "$ind" == "+" ]]; then
        ind="${BOLD}${GREEN}+${RESET}"
    elif [[ "$ind" == "-" ]]; then
        ind="${BOLD}${RED}-${RESET}"
    fi

    sort $tempfile | while read -r task; do
        ((inc++))
        printf "     [$ind] %2d. $task\n" "$inc"
    done
}

# ---------------------------------------------------------------------

# 1. Update DNF conf
task_init "Optimizing DNF Conf"

cat <<EOF > /etc/dnf/dnf.conf
# see \`man dnf.conf\` for defaults and possible options

[main]
installonly_limit=2
clean_requirements_on_remove=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
deltarpm=True
EOF

task_complete "DNF Conf optimized"


# 2. System Updates 
task_init "Updating System packages"

terminal_task "dnf upgrade -y"

task_complete "System updated"


# 3. Remove Bloatware
task_init "Removing bloatware"

declare -A bloat
bloat["gnome-calculator"]="Calculator"
bloat["gnome-connections"]="Connections"
bloat["gnome-contacts"]="Contacts"
bloat["gnome-disk-utility"]="Disks"
bloat["simple-scan"]="Document Scanner"
bloat["evince"]="Document Viewer"
bloat["firefox"]="Firefox"
bloat["yelp"]="Help"
bloat["gnome-maps"]="Maps"
bloat["malcontent-control"]="Parental Control"
bloat["abrt"]="Problem Reporting"
bloat["rhythmbox"]="Rhythmbox"
bloat["gnome-tour"]="Tour"

terminal_task "dnf remove -y ${!bloat[@]}"

task_complete "Bloatware removed"
sub_tasks "-" bloat


# 4. Install softwares
task_init "Installing softwares"

declare -A rpms
declare -A flatpaks
declare -A urls

rpms["akmod-nvidia"]="Nvidia Smi"
rpms["asusctl"]="Asusctl CLI"
rpms["asusctl-rog-gui"]="Asusctl GUI"
rpms["bat"]="Bat"
rpms["code"]="Visual Studio Code"
rpms["fastfetch"]="Fast Fetch"
rpms["fd-find"]="FD Find"
rpms["fzf"]="Fuzzy Finder"
rpms["gnome-tweaks"]="Gnome Tweaks"
rpms["kernel-devel"]="Kernel Devel"
rpms["rancher-desktop"]="Rancher Desktop"
rpms["rog-control-center"]="ROG Control Center"
rpms["supergfxctl"]="Supergfxctl"
rpms["xorg-x11-drv-nvidia-cuda"]="Nvidia Packages"

flatpaks["com.mattjakeman.ExtensionManager"]="Gnome Extensions Manager"
flatpaks["org.qbittorrent.qBittorrent"]="QBittorent"
flatpaks["com.spotify.Client"]="Spotify"
flatpaks["org.telegram.desktop"]="Telegram"
flatpaks["app.zen_browser.zen"]="Zen Browser"

urls["https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"]="Gnome Shell Extension Installer"

terminal_task "
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/isv:/Rancher:/stable/fedora/isv:Rancher:stable.repo
dnf copr enable -y lukenukem/asus-linux

rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf install -y ${!rpms[@]}
flatpak install -y ${!flatpaks[@]}
cd /tmp
for url in '${!urls[@]}'; do
    file=\$(basename \$url)
    curl -LO \$url
    chmod 755 \$file
    mv \$file /usr/local/bin
done
"

task_complete "Softwares Installed"
sub_tasks "+" rpms flatpaks urls


# 5. ROG Settings
task_init "Applying ROG Settings"

declare -A rog_settings

rog_settings["1"]="Asusd and Supergfx enabled"
rog_settings["2"]="Charge limit set to 80"
rog_settings["3"]="Keyboard backlit enabled"
rog_settings["4"]="Lightbar disabled"
rog_settings["5"]="Nvidia Service enabled"

terminal_task "
systemctl enable nvidia-hibernate nvidia-suspend nvidia-resume nvidia-powerd asusd supergfxd
systemctl start asusd
asusctl aura static -c ffffff
asusctl aura-power lightbar
asusctl --kbd-bright high
asusctl --chg-limit 80
"

task_complete "ROG settings applied"
sub_tasks "+" rog_settings


# 6. Reboot
echo -e "\n${BOLD}All settings have applied. Please reboot your system!${RESET}"
read -p "Proceed to reboot? [Y/n]: " response
response=${response:-y}
if [[ "${response}" =~ ^[Yy]$ ]]; then
	echo -e "Rebooting your system..."
	sleep 1
	reboot
else
	echo -e "\n${RED}Declined${RESET}. It is highly recommended to reboot your system before using it."
fi
