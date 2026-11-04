#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
APP="$HOME/Applications/BozoExecuter.app"
ICON_SRC="$HOME/Desktop/icon.png"

loader() {
    local msg="$1"
    echo -ne "  ${CYAN}➜${NC} $msg "
    for i in {1..20}; do sleep 0.02; echo -ne "\b\b\b\b${BOLD}${GREEN}$((i * 5))%${NC} "; done
    echo -e "${GREEN}✔${NC}"
}

clear
echo -e "${CYAN}${BOLD}"
echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
echo -e "      ${CYAN}>>> BOZO EXECUTER UI <<<${NC}"
echo -e "          ${CYAN}Made By: C0oled!${NC}\n"

if [ ! -f "$ICON_SRC" ]; then
    echo -e "${RED}✘ Missing $ICON_SRC${NC}"
    echo -e "  Save your image as icon.png on your Desktop first."
    exit 1
fi

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/BozoExecuter.app/Contents/MacOS"
mkdir -p "$T/BozoExecuter.app/Contents/Resources"

loader "Building .icns..."
ICONSET="$T/AppIcon.iconset"
mkdir -p "$ICONSET"
sips -z 16 16     "$ICON_SRC" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64     "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$ICON_SRC" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$ICON_SRC" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$T/BozoExecuter.app/Contents/Resources/AppIcon.icns"

loader "Compiling Swift app..."
cat > "$T/main.swift" << 'SWIFT'
import SwiftUI
import Network

final class Bridge: ObservableObject {
    @Published var status = "Disconnected"
    @Published var output = "Ready. Ensure your executor is running.\n"
    private var conn: NWConnection?
    private var timeoutTask: DispatchWorkItem?

    func connect(port: UInt16) {
        disconnect()
        status = "Connecting..."
        guard let p = NWEndpoint.Port(rawValue: port) else { return }
        let c = NWConnection(host: "127.0.0.1", port: p, using: .tcp)
        
        let task = DispatchWorkItem { [weak self] in
            if self?.conn != nil {
                self?.status = "Timeout (No listener)"
                self?.conn?.cancel()
                self?.conn = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
        self.timeoutTask = task

        c.stateUpdateHandler = { [weak self] s in
            DispatchQueue.main.async {
                switch s {
                case .ready: 
                    self?.timeoutTask?.cancel()
                    self?.status = "Connected :\(port)"
                    self?.conn = c
                    self?.recv(c)
                case .failed, .cancelled:
                    self?.status = "Disconnected"
                    self?.conn = nil
                case .waiting:
                    self?.status = "Waiting for port \(port)..."
                default: 
                    break
                }
            }
        }
        c.start(queue: .global())
    }

    func disconnect() {
        timeoutTask?.cancel()
        conn?.cancel()
        conn = nil
        status = "Disconnected"
    }

    private func recv(_ c: NWConnection) {
        c.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] d, _, _, e in
            if let d = d, let t = String(data: d, encoding: .utf8) {
                DispatchQueue.main.async { self?.output += t }
            }
            if e == nil { self?.recv(c) }
        }
    }

    func send(_ s: String, port: UInt16) {
        if conn == nil { connect(port: port) }
        guard let c = conn, let d = s.data(using: .utf8) else { 
            output += "\nCannot send: Not connected.\n"
            return 
        }
        c.send(content: d, completion: .contentProcessed { [weak self] e in
            if let e = e { DispatchQueue.main.async { self?.output += "\nSend: \(e.localizedDescription)\n" } }
        })
    }
}

@main
struct BozoApp: App {
    var body: some Scene {
        WindowGroup { ContentView().frame(minWidth: 680, minHeight: 500) }
    }
}

struct ContentView: View {
    @StateObject private var b = Bridge()
    @State private var script = "print(\"hello from Bozo\")"
    @State private var portStr = "5599"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bozo Executer").font(.headline)
                Spacer()
                Text("Port").font(.caption).foregroundColor(.secondary)
                TextField("", text: $portStr).frame(width: 70).textFieldStyle(.roundedBorder)
                
                Circle().fill(b.status.contains("Connected") ? Color.green : (b.status == "Connecting..." ? Color.orange : Color.red))
                    .frame(width: 10, height: 10)
                Text(b.status).font(.caption).foregroundColor(.secondary)
                
                Button(b.status.contains("Connected") ? "Disconnect" : "Connect") {
                    if b.status.contains("Connected") {
                        b.disconnect()
                    } else {
                        b.connect(port: UInt16(portStr) ?? 5599)
                    }
                }
            }.padding()

            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                .padding(.horizontal)

            ScrollView {
                Text(b.output).font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(8)
            }
            .frame(height: 160)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6).padding(.horizontal)

            HStack {
                Button("Execute") { b.send(script, port: UInt16(portStr) ?? 5599) }
                    .disabled(!b.status.contains("Connected"))
                Spacer()
                Button("Clear") { b.output = "" }
            }.padding()
        }
        .onAppear { b.connect(port: UInt16(portStr) ?? 5599) }
    }
}
SWIFT

swiftc -parse-as-library "$T/main.swift" -o "$T/BozoExecuter.app/Contents/MacOS/BozoExecuter"

cat > "$T/BozoExecuter.app/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BozoExecuter</string>
<key>CFBundleIdentifier</key><string>com.c0oled.bozo</string>
<key>CFBundleName</key><string>Bozo Executer</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

loader "Bundling and signing..."
rm -rf "$APP"
mv "$T/BozoExecuter.app" "$HOME/Applications/"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

loader "Launching..."
open "$APP"

echo -e "\n${GREEN}${BOLD}Done.${NC}"
echo -e "  App: $APP"
echo -e "  Note: It will timeout in 2 seconds if nothing is listening on the port."
