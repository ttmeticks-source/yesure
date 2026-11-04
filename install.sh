#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
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
    echo -ne "  ${CYAN}➜${NC} $msg "
    for i in {1..20}; do
        sleep 0.03
        echo -ne "\b\b\b\b${BOLD}${GREEN}$((i * 5))%${NC} "
    done
    echo -e "${GREEN}✔${NC}"
}

main() {
    banner
    
    loader "Modifying Roblox Client..."
    killall -9 RobloxPlayer 2>/dev/null || true
    
    TEMP=$(mktemp -d)
    curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
    unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
    
    mkdir -p ~/Applications
    rm -rf ~/Applications/Roblox.app
    mv "$TEMP/RobloxPlayer.app" ~/Applications/Roblox.app
    xattr -cr ~/Applications/Roblox.app

    loader "Fetching Bozo Dylib..."
    # This downloads YOUR dylib from YOUR repo and puts it INSIDE Roblox
    curl -sL "$BASE_URL/libBozoExecuter.dylib" -o "$TEMP/libBozoExecuter.dylib"
    cp "$TEMP/libBozoExecuter.dylib" ~/Applications/Roblox.app/Contents/Resources/

    loader "Fetching Injector..."
    curl -sL "$BASE_URL/insert_dylib" -o "$TEMP/insert_dylib"
    chmod +x "$TEMP/insert_dylib"

    loader "Modifying Roblox Executable..."
    # THIS IS THE ACTUAL MODIFICATION
    codesign --remove-signature ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer >/dev/null 2>&1 || true
    
    "$TEMP/insert_dylib" --strip-codesig --all-yes \
      "@executable_path/../Resources/libBozoExecuter.dylib" \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer \
      ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched >/dev/null 2>&1

    mv ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched ~/Applications/Roblox.app/Contents/MacOS/RobloxPlayer

    loader "Signing Modified Client..."
    codesign --force --deep --sign - ~/Applications/Roblox.app >/dev/null 2>&1

    echo -e "\n${GREEN}${BOLD}Installation Complete. Launching...${NC}"
    sleep 1
    open ~/Applications/Roblox.app
    
    # Launching the UI. The Cancel button acts as the X.
    osascript -e 'repeat
        set robloxStatus to "Not Found"
        try
            -- This is the CORRECT way to check if Roblox is running
            do shell script "pgrep -x RobloxPlayer > /dev/null"
            set robloxStatus to "Roblox Detected"
        on error
            set robloxStatus to "Not Found"
        end try
        
        tell application "System Events"
            -- "Cancel" button acts as the X
            set dialogResult to display dialog "Status: " & robloxStatus & return & return & "Paste your script below:" default answer "require(14168421377).tyymenu(\"Tyuiss_RBLX\")" buttons {"X", "Clear", "Execute"} default button "Execute" cancel button "X" with icon note with title "Bozo Executer"
        end tell
        
        if button returned of dialogResult is "X" then
            exit repeat
        end if
        
        if button returned of dialogResult is "Execute" then
            set userScript to text returned of dialogResult
            try
                -- Sends the script to your dylib
                do shell script "echo " & quoted form of userScript & " | nc -w 1 127.0.0.1 5599 &"
                display dialog "Executed successfully!" buttons {"OK"} default button "OK" with icon note
            on error errMsg
                display dialog "Connection failed. Is Roblox injected?" buttons {"OK"} default button "OK" with icon stop
            end try
        end if
        delay 5
    end repeat' &
    
    rm -rf "$TEMP"
}

main
