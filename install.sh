#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
GITHUB_USER="ttmeticks-source"
GITHUB_REPO="yesure"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main"

# LOCKED VERSION
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
    
    loader "Downloading Roblox Client ($VERSION)..."
    TEMP=$(mktemp -d)
    curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
    unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
    
    mkdir -p ~/Applications
    rm -rf ~/Applications/Roblox.app
    mv "$TEMP/RobloxPlayer.app" ~/Applications/Roblox.app
    xattr -cr ~/Applications/Roblox.app

    loader "Building Bozo UI (Native Swift)..."
    # This builds a REAL Swift app with a resizable window
    cat > "$TEMP/main.swift" << 'ENDOFSWIFT'
import SwiftUI
import Network

@main
struct BozoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth: 600, minHeight: 400)
        }
    }
}

struct ContentView: View {
    @State private var script = "require(14168421377).tyymenu(\"Tyuiss_RBLX\")"
    @State private var status = "Ready"
    @State private var isRobloxRunning = false
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Bozo Executer").font(.headline).foregroundColor(.white)
                Spacer()
                Circle().fill(isRobloxRunning ? Color.green : Color.red).frame(width: 10, height: 10)
                Text(isRobloxRunning ? "Roblox Detected" : "Not Found").font(.caption).foregroundColor(.gray)
            }
            .padding(.horizontal)

            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(8)
                .background(Color(white: 0.15))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.3), lineWidth: 1))
                .padding(.horizontal)

            HStack {
                Text(status).font(.caption).foregroundColor(.gray)
                Spacer()
                Button("Clear") { script = "" }
                Button("Execute") { executeScript() }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(white: 0.1))
        .onAppear { checkRoblox(); checkVersion() }
        .onReceive(timer) { _ in checkRoblox() }
    }

    func checkRoblox() {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-x", "RobloxPlayer"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        isRobloxRunning = task.terminationStatus == 0
    }

    func checkVersion() {
        guard let url = URL(string: "https://raw.githubusercontent.com/ttmeticks-source/yesure/main/version.txt") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let latest = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                DispatchQueue.main.async { if latest != "1.0.0" { status = "Out of Date!" } }
            }
        }.resume()
    }

    func executeScript() {
        status = "Connecting..."
        let conn = NWConnection(host: "127.0.0.1", port: 5599, using: .tcp)
        conn.stateUpdateHandler = { st in
            if case .ready = st {
                conn.send(content: script.data(using: .utf8), completion: .contentProcessed { error in
                    DispatchQueue.main.async { status = error == nil ? "Executed!" : "Failed." }
                    conn.cancel()
                })
            } else if case .failed = st { DispatchQueue.main.async { status = "Connection failed." }; conn.cancel() }
        }
        conn.start(queue: .global())
    }
}
ENDOFSWIFT

    # Compile the Swift app (No -O flag to prevent hangs)
    swiftc -parse-as-library "$TEMP/main.swift" -o "$TEMP/BozoExecuter" 2>/dev/null || true
    
    # Build the .app bundle
    mkdir -p "$TEMP/BozoExecuter.app/Contents/MacOS"
    mkdir -p "$TEMP/BozoExecuter.app/Contents/Resources"
    mv "$TEMP/BozoExecuter" "$TEMP/BozoExecuter.app/Contents/MacOS/BozoExecuter"
    
    cat > "$TEMP/BozoExecuter.app/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>BozoExecuter</string>
    <key>CFBundleIdentifier</key><string>com.c0oled.bozo</string>
    <key>CFBundleName</key><string>Bozo Executer</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
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
    clang -dynamiclib -arch arm64 -arch x86_64 -framework Cocoa -framework Foundation -o "$TEMP/libBozoExecuter.dylib" "$TEMP/dylib.m"
    cp "$TEMP/libBozoExecuter.dylib" ~/Applications/Roblox.app/Contents/Resources/

    loader "Fetching Injector..."
    curl -sL "https://github.com/tyilo/insert_dylib/releases/download/v1.0.0/insert_dylib" -o "$TEMP/insert_dylib"
    chmod +x "$TEMP/insert_dylib"

    loader "Injecting into libmimalloc.3.dylib (Real Modification)..."
    # THIS IS THE ACTUAL OPIUMWARE METHOD
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
