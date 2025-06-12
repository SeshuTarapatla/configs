#!/bin/bash
clear

# Vars
user='seshu'
tasks=11

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
    echo -e "${RED}Error: Invalid UID. Please run this script as user.${RESET}"
    exit 1
else
    echo -e "${BOLD}${CYAN}--- User Setup: \"$(whoami)\" ---${RESET}"
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
    echo -ne " [${BOLD}${YELLOW}~${RESET}] ${task}/${tasks}: $current_task"
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

# 1. UI Settings
task_init "UI Settings"

declare -A ui_settings

ui_settings["1"]="Dark theme applied"
ui_settings["2"]="Hot corner disabled"
ui_settings["3"]="Middle click minimize"
ui_settings["4"]="Middle click paste disabled"
ui_settings["5"]="Show batter level"

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'minimize'

task_complete
sub_tasks "+" ui_settings


# 2. Power Settings
task_init "Power Settings"

declare -A power_settings

power_settings["1"]="Automatic suspend on AC disabled"
power_settings["2"]="Screen turnoff disabled"

gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

task_complete
sub_tasks "+" power_settings


# 3. Git Config
task_init "Git Configuration"

git config --global user.name "SeshuTarapatla"
git config --global user.email "seshu.tarapatla@gmail.com"

task_complete


# 4. Text Editor
task_init "Text Editor defaults"

declare -A editor

editor["1"]="Highlight current line"
editor["2"]="Line numbers enabled"
editor["3"]="Tab width set to 4"

gsettings set org.gnome.TextEditor show-line-numbers true
gsettings set org.gnome.TextEditor highlight-current-line true
gsettings set org.gnome.TextEditor tab-width 4

task_complete
sub_tasks "+" editor


# 5. Terminal Settings
task_init "Terminal Settings"

declare -A terminal

terminal["1"]="Restore Window size disabled"

task_complete
sub_tasks "+" terminal


# 6. Bashrc
task_init "Bashrc Customization"

update_bashrc() {
	if !(cat ~/.bashrc | grep -q "${1}"); then
		echo $1 >> ~/.bashrc
	fi
}

declare -A bashrc

bashrc["1"]="alias be: Edit Bashrc"
bashrc["2"]="alias bs: Source Bashrc"
bashrc["3"]="alias up: DNF Upgrade"
bashrc["4"]="fzf  Alt+C shortcut"
bashrc["5"]="fzf Ctrl+T shortcut"

update_bashrc 'alias be="code ~/.bashrc"'
update_bashrc 'alias bs="source ~/.bashrc"'
update_bashrc 'alias up="sudo dnf upgrade -y"'
update_bashrc "export FZF_ALT_C_COMMAND='fd . \$HOME --type d --hidden 2>/dev/null'"
update_bashrc "export FZF_CTRL_T_COMMAND='fd . \$HOME --hidden 2>/dev/null'"
update_bashrc 'eval "$(fzf --bash)"'

task_complete
sub_tasks "+" bashrc


# 7. Gnome Extensions
task_init "Gnome Extensions"

declare -A g_exts

g_exts["1"]="Auto Move Windows"
g_exts["2"]="Blur My Shell"
g_exts["3"]="Desktop Icons"
g_exts["4"]="Net Speed"
g_exts["5"]="Places Indicator"

terminal_task '
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
RESET="\e[0m"

declare -A extensions
extensions["auto-move-windows@gnome-shell-extensions.gcampax.github.com"]="16"
extensions["blur-my-shell@aunetx"]="3193"
extensions["ding@rastersoft.com"]="2087"
extensions["netspeed@alynx.one"]="4478"
extensions["places-menu@gnome-shell-extensions.gcampax.github.com"]="8"

installed=$(gnome-extensions list)
temp=$(mktemp -d)
trap "rm -rf \"$temp\"" EXIT
cd $temp
for uuid in "${!extensions[@]}"; do
	if (echo $installed | grep -q $uuid); then
		gnome-extensions enable $uuid
		echo -e "${uuid%@*}: ${BOLD}${GREEN}Enabled${RESET}"
	else
		echo ""
		gnome-shell-extension-installer "${extensions[$uuid]}" --no-install
		gnome-extensions install $uuid*.zip
		export new_extensions=1
		echo -e "${uuid%@*}: ${BOLD}${BLUE}Installed${RESET}\n"
	fi
done
if [ -v new_extensions ]; then
	echo -e "${BOLD}${YELLOW}ALERT${RESET}: New Extensions installed. \nDue to Wayland restrictions - you have to restart the session and run this script again to enable them.\n"
	read -p ">>> Do you want to logout? [Y/n]: " answer
	answer=${answer:-y}
	if [[ "${answer}" =~ ^[Yy]$ ]]; then
		echo -e "Logging out"
		sleep 1
		gnome-session-quit --logout --no-prompt
	else
		echo -e "Logout declined"
		sleep 1
	fi
fi'

task_complete
sub_tasks "+" g_exts


# 8. UV
task_init "uv Python manager"

if !(which uv 1>/dev/null 2>&1); then
    terminal_task "curl -Lf https://astral.sh/uv/install.sh | sh"
fi

task_complete

# 9. Nerd Fonts
task_init "Nerd Fonts"

declare -A fonts

fonts["1"]="JetBrains Mono"

terminal_task '
font="JetBrainsMonoNerdFontMono-Regular.ttf"
url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
fonts_dir="$HOME/.local/share/fonts"

mkdir -p $fonts_dir
if !(fc-list | grep -q $font); then
    echo "Font missing. Downloading from GitHub."
    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT
    cd $temp
    curl -LO $url
    file=$(basename $url)
    tar -xf $file
    cp $font $fonts_dir
    echo "Font copied. Updating cache."
    fc-cache -f
fi
'

task_complete
sub_tasks "+" fonts


# 10. Vscode
task_init "Visual Studio Code"

declare -A code_exts

code_exts["charliermarsh.ruff"]="Ruff"
code_exts["christian-kohler.path-intellisense"]="Path Intellisense"
code_exts["enkia.tokyo-night"]="Tokyo Night"
code_exts["mads-hartmann.bash-ide-vscode"]="Bash IDE"
code_exts["ms-python.python"]="Python"
code_exts["ms-toolsai.jupyter"]="Jupyter"
code_exts["njpwerner.autodocstring"]="Python Docstring Generator"
code_exts["pkief.material-icon-theme"]="Material Icon Theme"
code_exts["rpinski.shebang-snippets"]="Shebang Snippets"
code_exts["tylim88.folder-hide"]="Hide Folders and Files"
code_exts["usernamehw.errorlens"]="Error Lens"

code_sets["1"]="User settings applied"

terminal_task "
GREEN='\e[32m'
BOLD='\e[1m'
RESET='\e[0m'

installed=\$(code --list-extensions)
for ext in "${!code_exts[@]}"; do
    if !(echo \$installed | grep -q \$ext); then
        code --install-extension \$ext
    fi
    echo -e "\$ext: \${BOLD}\${GREEN}Installed\${RESET}"
done
"
curl -Lsf "https://raw.githubusercontent.com/SeshuTarapatla/configs/refs/heads/main/vscode/settings.json" > "${HOME}/.config/Code/User/settings.json"

task_complete
sub_tasks "+" code_exts code_sets


# 11. Android Emulator
task_init "Android Emulator"
emulator_name="emulator"

declare -A android

android["1"]="SDK Tools"
android["2"]="Licenses"
android["3"]="Android 14 [api 34]"
android["4"]="Pixel 8 Pro AVD"

if !(avdmanager list avd 2>/dev/null | grep emulator 1>/dev/null 2>&1); then
    terminal_task '
    update_bashrc() {
        if !(cat ~/.bashrc | grep -q "${1}"); then
            echo $1 >> ~/.bashrc
        fi
    }
    export ANDROID_HOME="$HOME/.local/android"
    update_bashrc "export ANDROID_HOME=$ANDROID_HOME"
    update_bashrc "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$PATH\""
    source ~/.bashrc

    if !(which sdkmanager 2>/dev/null); then
        echo "1. Fetching latest download url for SDK tools"
        home_page="https://developer.android.com/studio#command-tools"
        download_url=$(curl $home_page | grep -oP "https://dl.google.com/android/repository/commandlinetools-linux-[0-9]+_latest.zip" | head -n 1)
        echo -e "URL: $download_url\n"
        echo "2. Downloading latest SDK tools"
        temp=$(mktemp -d)
        trap "rm -rfv $temp" EXIT
        cd $temp
        wget $download_url
        unzip commandlinetools*_latest.zip
        mkdir -p $ANDROID_HOME/cmdline-tools/latest
        mv -fv cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest
        yes | sdkmanager --licenses
    fi

    sdkmanager_install() {
        package=${*}
        if !(sdkmanager --list_installed | grep $package 1>/dev/null 2>&1); then
            sdkmanager --install "${package}"
        fi
    }
    sdkmanager_install "build-tools;35.0.0"
    sdkmanager_install "emulator"
    sdkmanager_install "platform-tools"
    sdkmanager_install "platforms;android-35"
    sdkmanager_install "system-images;android-35;google_apis;x86_64"

    if !(avdmanager list avd | grep emulator); then
        echo "Creating avd: emulator"
        avdmanager create avd -f -n emulator \
            -k "system-images;android-35;google_apis;x86_64" \
            -d "pixel_9_pro"
        sed -i "s/^hw.keyboard=no/hw.keyboard=yes/" "/home/seshu/.android/avd/emulator.avd/config.ini"
    fi
    '
fi

task_complete
sub_tasks "+" android
