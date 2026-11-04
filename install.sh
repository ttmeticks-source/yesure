#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
EXECUTOR_APP="$HOME/Applications/BozoExecuter.app"

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
    echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
    echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
    echo -e "      ${CYAN}>>> BOZO EXECUTER (Opiumware Bridge) <<<${NC}"
    echo -e "          ${CYAN}Made By: C0oled!${NC}\n"
}

loader() {
    local msg="$1"
    echo -ne "  ${CYAN}➜${NC} $msg "
    for i in {1..20}; do sleep 0.02; echo -ne "\b\b\b\b${BOLD}${GREEN}$((i * 5))%${NC} "; done
    echo -e "${GREEN}✔${NC}"
}

fail() { echo -e "${RED}✘ $1${NC}" >&2; exit 1; }

banner

loader "Checking for Opiumware..."
if [ ! -d "/Applications/Opiumware.app" ] && [ ! -d "$HOME/Applications/Opiumware.app" ]; then
    echo -e "\n  ${RED}${BOLD}Opiumware not found.${NC}"
    echo -e "  Install it from opiumware.com first, launch it once, then re-run this script."
    echo -e "  This script only builds a custom UI that talks to Opiumware's bridge.\n"
    exit 1
fi
echo -e "  ${GREEN}Opiumware found.${NC}"

loader "Building Swift frame..."
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT

cat > "$TEMP/main.swift" << 'ENDOFSWIFT'
import SwiftUI
import Network

struct ExecutorBridge: ObservableObject {
    @Published var status = "Disconnected"
    @Published var output = ""
    @Published var port: UInt16 = 8390

    private var connection: NWConnection?

    func connect() {
        disconnect()
        guard let p = NWEndpoint.Port(rawValue: port) else {
            status = "Bad port"
            return
        }
        let conn = NWConnection(host: "127.0.0.1", port: p, using: .tcp)
        conn.stateUpdateHandler = { [weak self] s in
            DispatchQueue.main.async {
                switch s {
                case .ready:
                    self?.status = "Connected :\(self?.port ?? 0)"
                    self?.connection = conn
                    self?.receive(on: conn)
                case .failed, .cancelled, .waiting:
                    self?.status = "Disconnected"
                    self?.connection = nil
                default:
                    break
                }
            }
        }
        conn.start(queue: .global())
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        status = "Disconnected"
    }

    private func receive(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, err in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self?.output += text }
            }
            if err == nil {
                self?.receive(on: conn)
            }
        }
    }

    func execute(_ script: String) {
        guard let conn = connection, let data = script.data(using: .utf8) else {
            output += "\nNot connected.\n"
            return
        }
        conn.send(content: data, completion: .contentProcessed { [weak self] err in
            if let err = err {
                DispatchQueue.main.async { self?.output += "\nSend error: \(err.localizedDescription)\n" }
            }
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
    @StateObject private var bridge = ExecutorBridge()
    @State private var script = "print(\"hello from Bozo\")"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bozo Executer").font(.headline)
                Spacer()
                Text("Port").font(.caption).foregroundColor(.secondary)
                TextField("", value: $bridge.port, formatter: NumberFormatter())
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                Circle()
                    .fill(bridge.status.hasPrefix("Connected") ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(bridge.status).font(.caption).foregroundColor(.secondary)
                Button(bridge.status.hasPrefix("Connected") ? "Reconnect" : "Connect") {
                    bridge.connect()
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
                Text(bridge.output)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 160)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)

            HStack {
                Button("Execute") { bridge.execute(script) }
                    .disabled(!bridge.status.hasPrefix("Connected"))
                Spacer()
                Button("Clear") { bridge.output = "" }
            }.padding()
        }
        .onAppear { bridge.connect() }
    }
}
ENDOFSWIFT

swiftc -parse-as-library "$TEMP/main.swift" -o "$TEMP/BozoExecuter" 2>&1 | grep -v "warning:" || fail "Swift build failed."

mkdir -p "$TEMP/BozoExecuter.app/Contents/MacOS"
mkdir -p "$TEMP/BozoExecuter.app/Contents/Resources"
mv "$TEMP/BozoExecuter" "$TEMP/BozoExecuter.app/Contents/MacOS/"

cat > "$TEMP/BozoExecuter.app/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BozoExecuter</string>
<key>CFBundleIdentifier</key><string>com.c0oled.bozo</string>
<key>CFBundleName</key><string>Bozo Executer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

rm -rf "$EXECUTOR_APP"
mv "$TEMP/BozoExecuter.app" "$HOME/Applications/"
codesign --force --deep --sign - "$EXECUTOR_APP" >/dev/null 2>&1 || true

loader "Launching..."
sleep 1
open "$EXECUTOR_APP"

echo -e "\n${GREEN}${BOLD}Done.${NC}"
echo -e "  App: $EXECUTOR_APP"
echo -e "  Bridge: Opiumware on 127.0.0.1:8390-8399"
