#!/usr/bin/env bash
set -euo pipefail

# --- YOUR GITHUB REPO ---
GITHUB_USER="ttmeticks-source"
GITHUB_REPO="yesure"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main"
VERSION="version-b09c93298b5d4cd1"

# Colors
G='\033[0;32m'; C='\033[0;36m'; R='\033[0m'; B='\033[1m'
CHECK="${G}✔${R}"

banner() {
    clear
    echo -e "${C}${B}"
    echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
    echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
    echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
    echo -e "${R}"
    echo -e "${C}Made By: C0oled!${R}\n"
}

# Percentage loader
loader() {
    local msg="$1"
    echo -ne "  ${C}➜${R} $msg"
    for i in {1..20}; do
        sleep 0.05
        echo -ne "\r  ${C}➜${R} $msg ${B}$((i * 5))%${R}"
    done
    echo -e "\r\033[K  ${G}✔${R} $msg ${B}100%${R}"
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

    echo -e "\n${G}${B}Installation Complete. Launching...${R}"
    sleep 1
    
    # THIS OPENS BOTH APPS
    open ~/Applications/Roblox.app
    open ~/Applications/BozoExecuter.app
    
    rm -rf "$TEMP"
}

main
