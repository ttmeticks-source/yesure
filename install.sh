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
echo -e "${WHITE}       SERVER CONTROL CONSOLE  •  macOS${RESET}"
echo -e "${GREY}       Created by c0olerishere${RESET}"
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
progress 10 "macOS detected"

command -v swiftc >/dev/null 2>&1 || fail "Swift compiler missing. Run: xcode-select --install"
progress 20 "Swift compiler found"

[[ -f macOS/Info.plist ]] || fail "macOS/Info.plist is missing."
[[ -f main.swift ]] || fail "main.swift is missing."
mkdir -p "Bozo Executer.app/Contents/MacOS" || fail "Could not create app folder."
cp macOS/Info.plist "Bozo Executer.app/Contents/Info.plist" || fail "Could not copy app metadata."
progress 35 "App bundle prepared"

echo -e "${WHITE}COMPILING SWIFT APP — LIVE STATUS${RESET}"
OUT="Bozo Executer.app/Contents/MacOS/BozoExecuter"
LOG="$(mktemp -t bozo-build)"
swiftc -O -framework AppKit -framework Foundation main.swift -o "$OUT" >"$LOG" 2>&1 &
BUILD_PID=$!
spin='|/-\\'
i=0
start=$SECONDS
while kill -0 "$BUILD_PID" 2>/dev/null; do
    elapsed=$((SECONDS - start))
    printf "\r${RED}%s${RESET} Compiling… %ss elapsed (compiler does not provide a true percentage)" "${spin:i++%4:1}" "$elapsed"
    sleep 0.2
done
wait "$BUILD_PID"
BUILD_STATUS=$?
printf "\r\033[K"
if [[ "$BUILD_STATUS" -ne 0 ]]; then
    cat "$LOG"
    rm -f "$LOG"
    fail "Swift compilation failed. See errors above."
fi
rm -f "$LOG"
progress 80 "Compilation finished"

[[ -x "$OUT" ]] || fail "Compiled app executable was not created."
/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "Bozo Executer.app/Contents/Info.plist" >/dev/null 2>&1 || fail "App metadata check failed."
progress 92 "Verifying app bundle"

chmod +x "$OUT"
progress 100 "Build complete"

echo -e "\n${GREEN}BOZO EXECUTER BUILT SUCCESSFULLY${RESET}"
echo "Opening Bozo Executer.app..."
open "Bozo Executer.app"
