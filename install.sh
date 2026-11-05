#!/bin/bash
set -u

RED='\033[1;31m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
GREEN='\033[1;32m'
RESET='\033[0m'

clear
printf "${RED}"
echo "  ____   ___ _____ ___    _____  _____ _____ _   _ _____ ____  "
echo " | __ ) / _ \\_   _/ _ \\  | ____|/ ____| ____| \\ | |_   _|  _ \\ "
echo " |  _ \\| | | || || | | | |  _| | |    |  _| |  \\| | | | | |_) |"
echo " | |_) | |_| || || |_| | | |___| |____| |___| |\\  | | | |  __/ "
echo " |____/ \\___/ |_| \\___/  |______\\_____|_____|_| \\_| |_| |_|    "
printf "${RESET}"
echo -e "${WHITE}       BOZO CONTROL CONSOLE  •  macOS${RESET}"
echo -e "${GREY}       Secure owner-authorized server requests${RESET}"
echo

progress() {
    local percent="$1" message="$2"
    local filled=$((percent / 5)) empty=$((20 - percent / 5))
    printf "\r${WHITE}BUILD [${RED}"
    printf '%*s' "$filled" '' | tr ' ' '#'
    printf "${GREY}"
    printf '%*s' "$empty" '' | tr ' ' '-'
    printf "${WHITE}] %3s%%${RESET}  %s\n" "$percent" "$message"
}

fail() {
    echo -e "\n${RED}BUILD FAILED:${RESET} $1"
    exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer requires macOS."
progress 5 "macOS detected"

command -v xcode-select >/dev/null 2>&1 || fail "Xcode Command Line Tools are missing."
command -v swiftc >/dev/null 2>&1 || fail "Swift compiler missing. Run: xcode-select --install"

DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
SWIFT_VERSION="$(swiftc --version 2>&1 | head -n 1)"
SDK_VERSION="$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || echo unknown)"
SWIFT_PATH="$(xcrun --find swiftc 2>/dev/null || command -v swiftc)"

echo -e "${GREY}Developer directory: ${DEV_DIR}${RESET}"
echo -e "${GREY}Compiler: ${SWIFT_VERSION}${RESET}"
echo -e "${GREY}macOS SDK: ${SDK_VERSION}${RESET}"
echo -e "${GREY}Compiler path: ${SWIFT_PATH}${RESET}"
progress 15 "Toolchain detected"

[[ -f macOS/Info.plist ]] || fail "macOS/Info.plist is missing."
[[ -f main.swift ]] || fail "main.swift is missing."

mkdir -p "Bozo Executer.app/Contents/MacOS" || fail "Could not create app folder."
cp macOS/Info.plist "Bozo Executer.app/Contents/Info.plist" || fail "Could not copy app metadata."
progress 25 "App bundle prepared"

echo -e "${WHITE}COMPILING — LIVE ESTIMATED PROGRESS${RESET}"
echo -e "${GREY}Swift does not report exact compile percentage; this bar is an estimate and only completes after a successful build.${RESET}"
OUT="Bozo Executer.app/Contents/MacOS/BozoExecuter"
LOG="$(mktemp -t bozo-build)"
swiftc -O -framework AppKit -framework Foundation main.swift -o "$OUT" >"$LOG" 2>&1 &
BUILD_PID=$!
start=$SECONDS
estimate=30
spin='|/-\\'
i=0

while kill -0 "$BUILD_PID" 2>/dev/null; do
    elapsed=$((SECONDS - start))
    estimate=$((30 + elapsed * 2))
    [[ "$estimate" -gt 78 ]] && estimate=78
    filled=$((estimate / 5))
    empty=$((20 - filled))
    printf "\r${WHITE}BUILD [${RED}"
    printf '%*s' "$filled" '' | tr ' ' '#'
    printf "${GREY}"
    printf '%*s' "$empty" '' | tr ' ' '-'
    printf "${WHITE}] %3s%%${RESET}  EST. COMPILING %ss  %s" "$estimate" "$elapsed" "${spin:i++%4:1}"
    sleep 0.25
done

wait "$BUILD_PID"
BUILD_STATUS=$?
printf "\r\033[K"

if [[ "$BUILD_STATUS" -ne 0 ]]; then
    cat "$LOG"
    if grep -qE "SDK is not supported by the compiler|redefinition of module 'SwiftBridging'|Please select a toolchain which matches the SDK" "$LOG"; then
        rm -f "$LOG"
        fail "Your Swift compiler and macOS SDK do not match. If full Xcode is installed, run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer . Otherwise install/update Xcode Command Line Tools, then reopen Terminal and rerun ./install.sh."
    fi
    rm -f "$LOG"
    fail "Swift compilation failed. See the compiler output above."
fi
rm -f "$LOG"
progress 85 "Swift compilation succeeded"

[[ -x "$OUT" ]] || fail "Compiled app executable was not created."
/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "Bozo Executer.app/Contents/Info.plist" >/dev/null 2>&1 || fail "App metadata check failed."
progress 95 "App bundle verified"

chmod +x "$OUT"
progress 100 "Build complete"

echo -e "\n${GREEN}BOZO CONTROL BUILT SUCCESSFULLY${RESET}"
echo "Opening Bozo Executer.app..."
open "Bozo Executer.app"
