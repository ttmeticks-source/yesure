#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
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
    echo -e "      ${CYAN}>>> BOZO EXECUTER <<<${NC}"
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

# --- SIP check ---
SIP_STATUS=$(csrutil status 2>/dev/null | tr -d '\n' || echo "unknown")
echo -e "  ${CYAN}SIP:${NC} $SIP_STATUS"
if echo "$SIP_STATUS" | grep -q "enabled"; then
    echo -e "  ${RED}${BOLD}WARNING:${NC} SIP is enabled. Injection may be blocked by the OS."
    echo -e "  ${CYAN}If injection fails, disable SIP in Recovery Mode and re-run.${NC}"
fi

loader "Killing Roblox..."
killall -9 RobloxPlayer 2>/dev/null || true
killall -9 Roblox 2>/dev/null || true

loader "Resolving Roblox Mac build..."
VERSION_JSON=$(curl -sL "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
VERSION=$(echo "$VERSION_JSON" | grep -o '"clientVersionUpload":"[^"]*"' | cut -d'"' -f4)
[ -z "$VERSION" ] && fail "Could not resolve Roblox version."
echo -e "  ${CYAN}Build:${NC} $VERSION"

loader "Downloading Roblox $VERSION..."
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT
curl -sL "https://setup.rbxcdn.com/mac/$VERSION-RobloxPlayer.zip" -o "$TEMP/rbx.zip"
[ -s "$TEMP/rbx.zip" ] || fail "Download failed."
unzip -oq "$TEMP/rbx.zip" -d "$TEMP"
mkdir -p "$HOME/Applications"
rm -rf "$ROBLOX_APP"
mv "$TEMP/RobloxPlayer.app" "$ROBLOX_APP"
xattr -cr "$ROBLOX_APP"

loader "Compiling Bozo dylib..."
cat > "$TEMP/executor.m" << 'ENDOFDYLIB'
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <dispatch/dispatch.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <pthread.h>
#include <string.h>
#include <stdio.h>

typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State*);
typedef int (*luaL_loadstring_t)(lua_State*, const char*);
typedef int (*lua_pcall_t)(lua_State*, int, int, int);
typedef void (*lua_settop_t)(lua_State*, int);
typedef const char* (*lua_tolstring_t)(lua_State*, int, size_t*);
typedef void (*lua_pushcclosure_t)(lua_State*, lua_CFunction, int);
typedef void (*lua_setglobal_t)(lua_State*, const char*);
typedef void (*lua_getglobal_t)(lua_State*, const char*);
typedef int (*lua_gettop_t)(lua_State*);

static lua_State *g_L = NULL;
static luaL_loadstring_t p_load = NULL;
static lua_pcall_t p_pcall = NULL;
static lua_settop_t p_settop = NULL;
static lua_tolstring_t p_tolstring = NULL;
static lua_pushcclosure_t p_pushc = NULL;
static lua_setglobal_t p_setglobal = NULL;
static lua_getglobal_t p_getglobal = NULL;
static lua_gettop_t p_gettop = NULL;

static char g_out[65536];
static size_t g_out_len = 0;

static int bozo_print(lua_State *L) {
    int n = p_gettop ? p_gettop(L) : 0;
    for (int i = 1; i <= n; i++) {
        size_t len = 0;
        const char *s = p_tolstring ? p_tolstring(L, i, &len) : NULL;
        if (s && g_out_len + len < sizeof(g_out) - 2) {
            memcpy(g_out + g_out_len, s, len);
            g_out_len += len;
            g_out[g_out_len++] = '\t';
        }
    }
    if (g_out_len < sizeof(g_out) - 1) g_out[g_out_len++] = '\n';
    g_out[g_out_len] = '\0';
    return 0;
}

static lua_State *find_lua_state(void) {
    return NULL;
}

static int resolve_luau_api(void) {
    void *h = dlopen(NULL, RTLD_LAZY);
    if (!h) return -1;
    p_load     = (luaL_loadstring_t)dlsym(h, "luaL_loadstring");
    p_pcall    = (lua_pcall_t)dlsym(h, "lua_pcall");
    p_settop   = (lua_settop_t)dlsym(h, "lua_settop");
    p_tolstring= (lua_tolstring_t)dlsym(h, "lua_tolstring");
    p_pushc    = (lua_pushcclosure_t)dlsym(h, "lua_pushcclosure");
    p_setglobal= (lua_setglobal_t)dlsym(h, "lua_setglobal");
    p_getglobal= (lua_getglobal_t)dlsym(h, "lua_getglobal");
    p_gettop   = (lua_gettop_t)dlsym(h, "lua_gettop");
    return (p_load && p_pcall) ? 0 : -1;
}

static void execute(const char *src, char *out, size_t out_size) {
    g_out_len = 0; g_out[0] = '\0';
    if (!g_L) {
        snprintf(out, out_size,
                 "BRIDGE OK - lua_State not attached yet.\n"
                 "Script received (%zu bytes). Transport works; VM hook pending.\n", strlen(src));
        return;
    }
    if (p_getglobal && p_pushc && p_setglobal) {
        p_getglobal(g_L, "print");
        p_pushc(g_L, bozo_print, 0);
        p_setglobal(g_L, "print");
    }
    int st = p_load(g_L, src);
    if (st != 0) {
        const char *e = p_tolstring ? p_tolstring(g_L, -1, NULL) : "load error";
        snprintf(out, out_size, "LOAD ERROR: %s\n", e ? e : "?");
        if (p_settop) p_settop(g_L, 0);
        return;
    }
    st = p_pcall(g_L, 0, 0, 0);
    if (st != 0) {
        const char *e = p_tolstring ? p_tolstring(g_L, -1, NULL) : "runtime error";
        snprintf(out, out_size, "RUNTIME ERROR: %s\n%s", e ? e : "?", g_out);
        if (p_settop) p_settop(g_L, 0);
        return;
    }
    snprintf(out, out_size, "%s", g_out_len ? g_out : "OK\n");
    if (p_settop) p_settop(g_L, 0);
}

static int g_client_fd = -1;
static void send_resp(const char *m) { if (g_client_fd >= 0) send(g_client_fd, m, strlen(m), 0); }

static void *client_thread(void *arg) {
    int fd = *(int *)arg;
    g_client_fd = fd;
    char buf[65536];
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf) - 1)) > 0) {
        buf[n] = '\0';
        char result[65536];
        execute(buf, result, sizeof(result));
        send_resp(result);
    }
    close(fd);
    g_client_fd = -1;
    return NULL;
}

__attribute__((constructor))
static void bozo_init(void) {
    if (resolve_luau_api() == 0) { g_L = find_lua_state(); }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int sfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sfd < 0) return;
        int opt = 1;
        setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
        struct sockaddr_in a = {0};
        a.sin_family = AF_INET;
        a.sin_port = htons(5599);
        a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (bind(sfd, (struct sockaddr*)&a, sizeof(a)) < 0) return;
        if (listen(sfd, 4) < 0) return;
        while (1) {
            int c = accept(sfd, NULL, NULL);
            if (c < 0) continue;
            pthread_t t;
            pthread_create(&t, NULL, client_thread, &c);
            pthread_detach(t);
        }
    });
}
ENDOFDYLIB

clang -dynamiclib -arch arm64 -arch x86_64 \
    -framework Foundation \
    -o "$TEMP/$DYLIB_NAME" "$TEMP/executor.m" || fail "Dylib compile failed."

loader "Fetching insert_dylib..."
curl -sL "https://github.com/tyilo/insert_dylib/releases/download/v1.0.0/insert_dylib" -o "$TEMP/insert_dylib"
chmod +x "$TEMP/insert_dylib"

RBX_BIN="$ROBLOX_APP/Contents/MacOS/RobloxPlayer"
[ -f "$RBX_BIN" ] || fail "RobloxPlayer binary missing at $RBX_BIN"

loader "Injecting into RobloxPlayer..."
codesign --remove-signature "$RBX_BIN" 2>/dev/null || true

echo -e "  ${CYAN}insert_dylib output:${NC}"
"$TEMP/insert_dylib" --strip-codesig --all-yes \
    "@executable_path/../Resources/$DYLIB_NAME" \
    "$RBX_BIN" "${RBX_BIN}_patched" || fail "insert_dylib failed (see output above)."

mv "${RBX_BIN}_patched" "$RBX_BIN"
cp "$TEMP/$DYLIB_NAME" "$ROBLOX_APP/Contents/Resources/"

loader "Re-signing binary..."
codesign -f -s - --all-architectures "$RBX_BIN" 2>&1 || fail "Binary re-sign failed."

loader "Re-signing app bundle..."
codesign --force --deep --sign - "$ROBLOX_APP" 2>&1 || fail "App re-sign failed."

loader "Building Swift frame..."
cat > "$TEMP/main.swift" << 'ENDOFSWIFT'
import SwiftUI
import Network

@main
struct BozoApp: App {
    var body: some Scene {
        WindowGroup { ContentView().frame(minWidth: 640, minHeight: 480) }
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
                Text("Bozo Executer").font(.headline)
                Spacer()
                Circle().fill(status == "Connected" ? Color.green : Color.red).frame(width: 10, height: 10)
                Text(status).font(.caption).foregroundColor(.secondary)
            }.padding()
            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                .padding(.horizontal)
            ScrollView {
                Text(output).font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(8)
            }
            .frame(height: 140)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6).padding(.horizontal)
            HStack {
                Button("Connect") { connect() }
                Button("Execute") { execute() }.disabled(connection == nil)
                Spacer()
                Button("Clear") { output = "" }
            }.padding()
        }
        .onAppear { connect() }
    }

    func connect() {
        let conn = NWConnection(host: "127.0.0.1", port: 5599, using: .tcp)
        conn.stateUpdateHandler = { s in
            DispatchQueue.main.async {
                switch s {
                case .ready: status = "Connected"; connection = conn; receive(conn)
                case .failed, .cancelled: status = "Disconnected"; connection = nil
                default: break
                }
            }
        }
        conn.start(queue: .global())
    }

    func receive(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { d, _, _, e in
            if let d = d, let t = String(data: d, encoding: .utf8) {
                DispatchQueue.main.async { output += t }
            }
            if e == nil { receive(conn) }
        }
    }

    func execute() {
        guard let c = connection, let d = script.data(using: .utf8) else { return }
        c.send(content: d, completion: .contentProcessed { e in
            if let e = e { DispatchQueue.main.async { output += "\nSend: \(e.localizedDescription)\n" } }
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
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BozoExecuter</string>
<key>CFBundleIdentifier</key><string>com.c0oled.bozo</string>
<key>CFBundleName</key><string>Bozo Executer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
PLIST

rm -rf "$EXECUTOR_APP"
mv "$TEMP/BozoExecuter.app" "$HOME/Applications/"
codesign --force --deep --sign - "$EXECUTOR_APP" >/dev/null 2>&1

loader "Launching..."
sleep 1
open "$ROBLOX_APP"
sleep 3
open "$EXECUTOR_APP"

echo -e "\n${GREEN}${BOLD}Done.${NC}"
echo -e "  Bridge: 127.0.0.1:$PORT"
