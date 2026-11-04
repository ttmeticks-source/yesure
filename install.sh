#!/usr/bin/env bash
set -euo pipefail
APP="$HOME/Applications/BozoExecuter.app"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/BozoExecuter.app/Contents/MacOS"

cat > "$T/main.swift" << 'SWIFT'
import SwiftUI
import Network

final class Bridge: ObservableObject {
    @Published var status = "Disconnected"
    @Published var output = ""
    private var conn: NWConnection?

    func connect(port: UInt16) {
        conn?.cancel()
        guard let p = NWEndpoint.Port(rawValue: port) else { return }
        let c = NWConnection(host: "127.0.0.1", port: p, using: .tcp)
        c.stateUpdateHandler = { [weak self] s in
            DispatchQueue.main.async {
                switch s {
                case .ready: self?.status = "Connected :\(port)"; self?.conn = c; self?.recv(c)
                case .failed, .cancelled, .waiting: self?.status = "Disconnected"; self?.conn = nil
                default: break
                }
            }
        }
        c.start(queue: .global())
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
        guard let c = conn, let d = s.data(using: .utf8) else { output += "\nNot connected.\n"; return }
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
                Circle().fill(b.status.hasPrefix("Connected") ? Color.green : Color.red).frame(width: 10, height: 10)
                Text(b.status).font(.caption).foregroundColor(.secondary)
                Button(b.status.hasPrefix("Connected") ? "Reconnect" : "Connect") {
                    b.connect(port: UInt16(portStr) ?? 5599)
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
                    .disabled(!b.status.hasPrefix("Connected"))
                Spacer()
                Button("Clear") { b.output = "" }
            }.padding()
        }
        .onAppear { b.connect(port: UInt16(portStr) ?? 5599) }
    }
}
SWIFT

swiftc -parse-as-library "$T/main.swift" -o "$T/BozoExecuter.app/Contents/MacOS/BozoExecuter"
mkdir -p "$T/BozoExecuter.app/Contents/Resources"

cat > "$T/BozoExecuter.app/Contents/Info.plist" << 'PLIST'
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

rm -rf "$APP"
mv "$T/BozoExecuter.app" "$HOME/Applications/"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
open "$APP"
