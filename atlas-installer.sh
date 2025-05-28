#!/usr/bin/env bash
# Sixty's Atlas Auto Installer - Downloads and installs kiwix, Ollama, VLC, MSTY, and jDownloader

set -uuo pipefail
IFS=$'\n\t'

# helper to run a step and keep going on error
run_step() {
  local desc="$1"; shift
  echo -e "\n=== $desc ==="
  if "$@"; then
    echo "✔️  Success: $desc"
  else
    echo "⚠️  Warning: '$desc' failed, continuing..." >&2
  fi
}

# ensure we’re root
if (( EUID != 0 )); then
  echo "⚠️  Please run as root (sudo)." >&2
  exit 1
fi

run_step "Updating APT repositories and upgrading" apt update -y
run_step "Upgrading installed packages"       apt upgrade -y

KIWIX_DIR="/home/${SUDO_USER}/Documents/Kiwix-zims"
run_step "Creating Kiwix-zims directory" mkdir -p "$KIWIX_DIR" && chown "$SUDO_USER:$SUDO_USER" "$KIWIX_DIR"

QL_FILE="/home/${SUDO_USER}/Desktop/Quick Links.txt"
run_step "Writing Quick Links file" bash -c "cat > '$QL_FILE' <<EOF
Download zims from here: library.kiwix.org
Download websites and turn them into zims here: zimit.kiwix.org/
When downloading zims, place them into the Kiwix-zims folder in your Documents
Open Kiwix > Select the three dots in the top right hand corner > Settings > Browse > Documents > Kiwix-zims
Select Ok
Now Kiwix will look at that folder for any new zim's you add!
EOF" && chown "$SUDO_USER:$SUDO_USER" "$QL_FILE"

run_step "Installing UFW"          apt install ufw -y
run_step "Enabling UFW"            ufw --force enable
run_step "Allowing port 8080/tcp"  ufw allow 8080/tcp

run_step "Installing Ollama"       bash -c "curl -fsSL https://ollama.com/install.sh | sh"
export PATH="$HOME/.ollama/bin:$PATH"  # best-effort

run_step "Pulling Ollama model qwen2.5:0.5b" sudo -u "$SUDO_USER" ollama pull qwen2.5:0.5b

MSTY_URL="https://assets.msty.app/prod/latest/linux/amd64/Msty_amd64_amd64.deb"
TMP_DEB="/tmp/$(basename "$MSTY_URL")"
run_step "Downloading Msty"        wget -qO "$TMP_DEB" "$MSTY_URL"
run_step "Installing Msty"         apt install -y "$TMP_DEB"

DESKTOP_FILE="/home/${SUDO_USER}/Desktop/Msty.desktop"
run_step "Creating Msty desktop shortcut" bash -c "cat > '$DESKTOP_FILE' <<EOF
[Desktop Entry]
Type=Application
Name=Msty
Exec=/usr/bin/msty
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF" && chmod +x "$DESKTOP_FILE" && chown "$SUDO_USER:$SUDO_USER" "$DESKTOP_FILE"

run_step "Installing VLC"          apt install vlc -y
run_step "Installing Kiwix"        apt install kiwix -y

# JDownloader via snap
run_step "Installing snapd"        apt install snapd -y
run_step "Installing core snap"    snap install core
run_step "Installing JDownloader"  snap install jdownloader2

echo -e "Completed! Thank you, and God Bless! -SixtyAteWhiskey \nStop the Killing, Stop the Dying" 
