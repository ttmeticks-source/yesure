#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
GITHUB_USER="ttmeticks-source"
GITHUB_REPO="yesure"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main"
VERSION="version-b09c93298b5d4cd1"

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
    echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
    echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e "${CYAN}Made By: C0oled!${NC}\n"
}

progress_bar() {
    local msg="$1"
    echo -ne "${CYAN}➜${NC} $msg "
    for i in {1..15}; do
        echo -ne "${BOLD}${GREEN}#${NC}"
        sleep 0.04
    done
    echo -e " ${GREEN}✔${NC}"
}

main() {
    banner

    # 1. Kill Roblox
    progress_bar "Killing Roblox Processes..."
    killall -9 RobloxPlayer 2>/dev/null || true

    # 2. Download Roblox
    progress_bar "Downloading Roblox Client..."
    TEMP=$(mktemp -d)
    curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
    unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
    
    # Ensure Applications folder exists
    mkdir -p ~/Applications
    rm -rf ~/Applications/Roblox.app
    mv "$TEMP/RobloxPlayer.app" ~/Applications/Roblox.app
    xattr -cr ~/Applications/Roblox.app

    # 3. Download Dylib from your GitHub
    progress_bar "Fetching Bozo Dylib..."
    # Looks for the dylib in the root of the repo, not /bin/
    curl -sL "$BASE_URL/libBozoExecuter.dylib" -o "$TEMP/libBozoExecuter.dylib"
    cp "$TEMP/libBozoExecuter.dylib" ~/Applications/Roblox.app/Contents/Resources/

    # 4. Download Injector from your GitHub
    progress_bar "Fetching Injector..."
    # Looks for insert_dylib in the root of the repo
    curl -sL "$BASE_URL/insert_dylib" -o "$TEMP/insert_dylib"
    chmod +x "$TEMP/insert_dylib"

    # 5. Inject
    progress_bar "Injecting Dylib into Roblox..."
    codesign --remove-signature ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer >/dev/null 2>&1 || true
    
    "$TEMP/insert_dylib" --strip-codesig --all-yes \
      "@executable_path/../Resources/libBozoExecuter.dylib" \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched >/dev/null 2>&1

    mv ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer

    # 6. Sign
    progress_bar "Signing Modified Client..."
    codesign --force --deep --sign - ~/Applications/Roblox.app >/dev/null 2>&1

    # 7. Launch
    echo -e "\n${GREEN}${BOLD}Installation Complete.${R}"
    sleep 1
    open ~/Applications/Roblox.app
    rm -rf "$TEMP"
}

main
