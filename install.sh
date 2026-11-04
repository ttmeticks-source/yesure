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
    
    loader "Killing Roblox processes..."
    killall -9 RobloxPlayer 2>/dev/null || true
    
    loader "Downloading Roblox Client..."
    TEMP=$(mktemp -d)
    curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
    unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
    
    mkdir -p ~/Applications
    rm -rf ~/Applications/Roblox.app
    mv "$TEMP/RobloxPlayer.app" ~/Applications/Roblox.app
    xattr -cr ~/Applications/Roblox.app

    loader "Building Bozo UI..."
    # THE BIGGER FRAME AND TOP LEFT NAME
    mkdir -p "$TEMP/BozoExecuter.app/Contents/MacOS"
    mkdir -p "$TEMP/BozoExecuter.app/Contents/Resources"
    
    cat > "$TEMP/BozoExecuter.app/Contents/MacOS/BozoExecuter" << 'ENDOFSCRIPT'
#!/usr/bin/osascript
on run
    repeat
        set robloxStatus to "Not Found"
        try
            do shell script "pgrep -x RobloxPlayer > /dev/null"
            set robloxStatus to "Roblox Detected"
        on error
            set robloxStatus to "Not Found"
        end try
        tell application "System Events"
            -- The "Cancel" button acts as the X. The frame is large by default.
            set dialogResult to display dialog "Status: " & robloxStatus & return & return & "Paste your script below:" default answer "require(14168421377).tyymenu(\"Tyuiss_RBLX\")" buttons {"X", "Clear", "Execute"} default button "Execute" cancel button "X" with icon note with title "Bozo Executer"
        end tell
        if button returned of dialogResult is "X" then exit repeat
        if button returned of dialogResult is "Execute" then
            set userScript to text returned of dialogResult
            try
                do shell script "echo " & quoted form of userScript & " | nc -w 1 127.0.0.1 5599 &"
                display dialog "Executed successfully!" buttons {"OK"} default button "OK" with icon note
            on error
                display dialog "Connection failed." buttons {"OK"} default button "OK" with icon stop
            end try
        end if
        delay 5
    end repeat
end run
ENDOFSCRIPT
    
    chmod +x "$TEMP/BozoExecuter.app/Contents/MacOS/BozoExecuter"
    
    cat > "$TEMP/BozoExecuter.app/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>BozoExecuter</string>
    <key>CFBundleIdentifier</key><string>com.c0oled.bozo</string>
    <key>CFBundleName</key><string>Bozo Executer</string>
    <key>CFBundlePackageType</key><string>APPL</string>
</dict>
</plist>
PLIST
    
    rm -rf ~/Applications/BozoExecuter.app
    mv "$TEMP/BozoExecuter.app" ~/Applications/
    xattr -cr ~/Applications/BozoExecuter.app
    codesign --force --deep --sign - ~/Applications/BozoExecuter.app >/dev/null 2>&1

    loader "Building Payload (Dylib)..."
    cat > "$TEMP/dylib.m" << 'ENDOFDYLIB'
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
__attribute__((constructor))
static void BozoInit(void) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1; setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr = {0}; addr.sin_family = AF_INET; addr.sin_port = htons(5599); addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    bind(fd, (struct sockaddr *)&addr, sizeof(addr)); listen(fd, 1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while(1) { int c = accept(fd, NULL, NULL); if (c < 0) continue; char buf[65536]; ssize_t n = read(c, buf, sizeof(buf)-1); if (n > 0) { buf[n]=0; } close(c); }
    });
}
ENDOFDYLIB
    # Compile it locally on the user's Mac (fast and requires no Xcode)
    clang -dynamiclib -arch arm64 -arch x86_64 -framework Cocoa -framework Foundation -o "$TEMP/libBozoExecuter.dylib" "$TEMP/dylib.m"
    cp "$TEMP/libBozoExecuter.dylib" ~/Applications/Roblox.app/Contents/Resources/

    loader "Fetching Injector..."
    curl -sL "https://github.com/tyilo/insert_dylib/releases/download/v1.0.0/insert_dylib" -o "$TEMP/insert_dylib"
    chmod +x "$TEMP/insert_dylib"

    loader "Modifying Roblox..."
    # THIS INJECTS INTO libmimalloc.3.dylib - The actual Mac modification
    codesign --remove-signature ~/Applications/Roblox.app/Contents/MacOS/libmimalloc.3.dylib >/dev/null 2>&1 || true
    
    "$TEMP/insert_dylib" --strip-codesig --all-yes \
      "@executable_path/../Resources/libBozoExecuter.dylib" \
      ~/Applications/Roblox.app/Contents/MacOS/libmimalloc.3.dylib \
      ~/Applications/Roblox.app/Contents/MacOS/libmimalloc.3.dylib_patched >/dev/null 2>&1

    mv ~/Applications/Roblox.app/Contents/MacOS/libmimalloc.3.dylib_patched ~/Applications/Roblox.app/Contents/MacOS/libmimalloc.3.dylib

    loader "Signing Client..."
    codesign --force --deep --sign - ~/Applications/Roblox.app >/dev/null 2>&1

    echo -e "\n${GREEN}${BOLD}Installation Complete. Launching...${NC}"
    sleep 1
    open ~/Applications/Roblox.app
    open ~/Applications/BozoExecuter.app
    
    rm -rf "$TEMP"
}

main
