#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="ttmeticks-source"
GITHUB_REPO="yesure"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main"
VERSION="version-b09c93298b5d4cd1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
    echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
    echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
    echo -e "      ${CYAN}>>> CLIENT-SIDED EXECUTOR <<<${NC}"
    echo -e "          ${CYAN}Made By: C0oled!${NC}\n"
}

loader() {
    local msg="$1"
    for i in {1..20}; do
        echo -ne "\r  ${CYAN}➜${NC} $msg ${BOLD}$((i * 5))%${NC}   "
        sleep 0.05
    done
    echo -e "\r\033[K  ${GREEN}✔${NC} $msg ${BOLD}100%${NC}"
}

main() {
    banner
    loader "Modifying Roblox Client"
    killall -9 RobloxPlayer 2>/dev/null || true
    
    TEMP=$(mktemp -d)
    curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
    unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
    
    mkdir -p ~/Applications
    rm -rf ~/Applications/Roblox.app
    mv "$TEMP/RobloxPlayer.app" ~/Applications/Roblox.app
    xattr -cr ~/Applications/Roblox.app

    loader "Downloading Bozo Payloads"
    curl -sL "$BASE_URL/libBozoExecuter.dylib" -o "$TEMP/libBozoExecuter.dylib"
    cp "$TEMP/libBozoExecuter.dylib" ~/Applications/Roblox.app/Contents/Resources/

    curl -sL "$BASE_URL/insert_dylib" -o "$TEMP/insert_dylib"
    chmod +x "$TEMP/insert_dylib"

    loader "Injecting Client Modification"
    codesign --remove-signature ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer >/dev/null 2>&1 || true
    "$TEMP/insert_dylib" --strip-codesig --all-yes \
      "@executable_path/../Resources/libBozoExecuter.dylib" \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched >/dev/null 2>&1

    mv ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer

    loader "Signing Modified Client"
    codesign --force --deep --sign - ~/Applications/Roblox.app >/dev/null 2>&1

    echo -e "\n${GREEN}${BOLD}Installation Complete. Launching...${NC}"
    sleep 1
    open ~/Applications/Roblox.app
    open ~/Applications/BozoExecuter.app
    rm -rf "$TEMP"
}

main
