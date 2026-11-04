#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- CONFIG ---
ROBLOX_APP="$HOME/Applications/Roblox.app"
EXECUTOR_APP="$HOME/Applications/BozoExecuter.app"
DYLIB_NAME="libBozoExecuter.dylib"
PORT=5599

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗  ██████╗ ███████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══███╔╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║  ███╔╝ ██║   ██║"
    echo "  ██╔══██╗██║   ██║ ███╔╝  ██║   ██║"
    echo "  ██████╔╝╚██████╔╝███████╗╚██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝ "
    echo -e "      ${CYAN}>>> INJECTOR PIPELINE <<<${NC}"
    echo -e "          ${CYAN}Made By: C0oled!${NC}\n"
}

loader() {
    local msg="$1"
    echo -ne "  ${CYAN}➜${NC} $msg "
    for i in {1..20}; do
        sleep 0.02
        echo -ne "\b\b\b\b${BOLD}${GREEN}$((i * 5))%${NC} "
    done
    echo -e "${GREEN}✔${NC}"
}

fail() {
    echo -e "${RED}✘ $1${NC}" >&2
    exit 1
}

# --- 1. Kill Roblox ---
banner
loader "Killing Roblox processes..."
killall -9 RobloxPlayer 2>/dev/null || true
killall -9 Roblox 2>/dev/null || true

# --- 2. Fetch current Roblox version dynamically ---
loader "Resolving current Roblox Mac build..."
VERSION_JSON=$(curl -sL "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
VERSION=$(echo "$VERSION_JSON" | grep -o '"clientVersionUpload":"[^"]*"' | cut -d'"' -f4)
if [ -z "$VERSION" ]; then
    fail "Could not resolve Roblox version. Check your network."
fi
echo -e "  ${CYAN}Build:${NC} $VERSION"

# --- 3. Download & install Roblox ---
loader "Downloading Roblox $VERSION..."
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT

curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
if [ ! -s "$TEMP/rbx.zip" ]; then
    fail "Download failed. CDN may be stale."
fi

loader "Installing Roblox..."
unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
mkdir -p "$HOME/Applications"
rm -rf "$ROBLOX_APP"
mv "$TEMP/RobloxPlayer.app" "$ROBLOX_APP"
xattr -cr "$ROBLOX_APP"

# --- 4. Compile the executor dylib ---
loader "Compiling executor dylib..."
cat > "$TEMP/executor.m" << 'ENDOFDYLIB'
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <dispatch/dispatch.h>

// Executor socket — receives Luau source from the Swift app.
// In a real executor this is where you'd hook into the Luau VM
// (e.g., via Roblox's lua_State) and call luaL_loadstring + lua_pcall.
// This scaffold gives you the transport layer + a response channel.

static int server_fd = -1;
static int client_fd = -1;

static void send_response(const char *msg) {
    if (client_fd >= 0) {
        send(client_fd, msg, strlen(msg), 0);
    }
}

static void *handle_client(void *arg) {
    int fd = *(int *)arg;
    client_fd = fd;

    char buf[65536];
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf) - 1)) > 0) {
        buf[n] = '\0';

        // --- STUB: replace with real Luau execution ---
        // Expected: char *output = execute_luau(buf);
        // send_response(output);
        // For now, echo back a status so the Swift app can confirm the bridge works.
        const char *ack = "OK: received\n";
        send_response(ack);
    }

    close(fd);
    client_fd = -1;
    return NULL;
}

__attribute__((constructor))
static void BozoInit(void) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        server_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd < 0) return;

        int opt = 1;
        setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        struct sockaddr_in addr = {0};
        addr.sin_family = AF_INET;
        addr.sin_port = htons(5599);
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

        if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) return;
        if (listen(server_fd, 1) < 0) return;

        while (1) {
            int c = accept(server_fd, NULL, NULL);
            if (c < 0) continue;
            pthread_t t;
            pthread_create(&t, NULL, handle_client, &c);
            pthread_detach(t);
        }
    });
}
ENDOFDYLIB

clang -dynamiclib -arch arm64 -arch x86_64 \
    -framework Foundation -framework Cocoa \
    -o "$TEMP/$DYLIB_NAME" "$TEMP/executor.m" 2>&1 | grep -v "warning:" || true

if [ ! -f "$TEMP/$DYLIB_NAME" ]; then
    fail "Dylib compile failed."
fi

# --- 5. Inject into RobloxPlayer (not mimalloc) ---
loader "Fetching insert_dylib..."
curl -sL "https://github.com/tyilo/insert_dylib/releases/download/v1.0.0/insert_dylib" \
    -o "$TEMP/insert_dylib"
chmod +x "$TEMP/insert_dylib"

ROBLOX_BIN="$ROBLOX_APP/Contents/MacOS/RobloxPlayer"
if [ ! -f "$ROBLOX_BIN" ]; then
    fail "RobloxPlayer binary not found. Roblox app may be corrupted."
fi

loader "Injecting dylib into RobloxPlayer..."
# Strip signature first — insert_dylib will fail on signed binaries otherwise.
codesign --remove-signature "$ROBLOX_BIN" 2>/dev/null || true

"$TEMP/insert_dylib" --strip-codesig --all-yes \
    "@executable_path/../Resources/$DYLIB_NAME" \
    "$ROBLOX_BIN" \
    "${ROBLOX_BIN}_patched" >/dev/null 2>&1 || fail "insert_dylib failed."

mv "${ROBLOX_BIN}_patched" "$ROBLOX_BIN"
cp "$TEMP/$DYLIB_NAME" "$ROBLOX_APP/Contents/Resources/"

loader "Re-signing Roblox..."
codesign --force --deep --sign - "$ROBLOX_APP" >/dev/null 2>&1

# --- 6. Build Swift app ---
loader "Building Swift frame..."
cat > "$TEMP/main.swift" << 'ENDOFSWIFT'
import SwiftUI
import Network

@main
struct BozoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 640, minHeight: 480)
        }
    }
}

struct ContentView: View {
    @State private var script = "print(\"hello from Bozo\")"
    @State private var output = ""
    @State private var status = "Disconnected"
    @State private var connection: NWConnection?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bozo Executer")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(status == "Connected" ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                .padding(.horizontal)

            ScrollView {
                Text(output)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 120)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)

            HStack {
                Button("Connect") { connect() }
                Button("Execute") { execute() }
                    .disabled(connection == nil)
                Spacer()
                Button("Clear") { output = "" }
            }
            .padding()
        }
        .onAppear { connect() }
    }

    func connect() {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(rawValue: 5599)!
        let conn = NWConnection(host: host, port: port, using: .tcp)
        conn.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    status = "Connected"
                    connection = conn
                    receive(on: conn)
                case .failed, .cancelled:
                    status = "Disconnected"
                    connection = nil
                default:
                    break
                }
            }
        }
        conn.start(queue: .global())
    }

    func receive(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { output += text }
            }
            if error == nil {
                receive(on: conn)
            }
        }
    }

    func execute() {
        guard let conn = connection, let data = script.data(using: .utf8) else { return }
        conn.send(content: data, completion: .contentProcessed { error in
            DispatchQueue.main.async {
                if let error = error {
                    output += "\nSend error: \(error.localizedDescription)\n"
                }
            }
        })
    }
}
ENDOFSWIFT

swiftc -parse-as-library "$TEMP/main.swift" -o "$TEMP/BozoExecuter" 2>&1 | grep -v "warning:" || true

mkdir -p "$TEMP/BozoExecuter.app/Contents/MacOS"
mkdir -p "$TEMP/BozoExecuter.app/Contents/Resources"
mv "$TEMP/BozoExecuter" "$TEMP/BozoExecuter.app/Contents/MacOS/"

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
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

rm -rf "$EXECUTOR_APP"
mv "$TEMP/BozoExecuter.app" "$HOME/Applications/"
codesign --force --deep --sign - "$EXECUTOR_APP" >/dev/null 2>&1

# --- 7. Launch ---
loader "Launching..."
sleep 1
open "$ROBLOX_APP"
sleep 3
open "$EXECUTOR_APP"

echo -e "\n${GREEN}${BOLD}Done.${NC}"
echo -e "  Roblox: $ROBLOX_APP"
echo -e "  Executor: $EXECUTOR_APP"
echo -e "  Bridge: 127.0.0.1:$PORT"
