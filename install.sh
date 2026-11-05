#!/bin/bash

RED='\033[1;31m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
GREEN='\033[1;32m'
RESET='\033[0m'

clear

echo -e "${RED}"
echo "########################################"
echo "#                                      #"
echo "#          BOZO EXECUTER               #"
echo "#                                      #"
echo "########################################"
echo -e "${RESET}"
echo -e "${WHITE}ROBLOX SERVER TEST CONSOLE${RESET}"
echo -e "${GREY}Created by c0olerishere${RESET}"
echo

progress() {
    percent=$1
    message=$2
    filled=$((percent / 5))
    empty=$((20 - filled))

    printf "${WHITE}LOADING: [${RED}"
    printf '%0.s#' $(seq 1 "$filled")
    printf "${GREY}"
    printf '%0.s-' $(seq 1 "$empty")
    printf "${WHITE}] %s%%${RESET} %s\n" "$percent" "$message"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This application requires macOS."
    exit 1
fi

progress 15 "Checking macOS"

if ! command -v swiftc >/dev/null 2>&1; then
    echo "Swift compiler missing."
    echo "Run: xcode-select --install"
    exit 1
fi

progress 30 "Checking Swift"

mkdir -p "Bozo Executer.app/Contents/MacOS"

progress 45 "Preparing application"

cp macOS/Info.plist "Bozo Executer.app/Contents/Info.plist"

progress 60 "Preparing application settings"

if [[ ! -f main.swift ]]; then
    echo "main.swift is missing!"
    exit 1
fi

progress 75 "Compiling application"

swiftc -O -framework AppKit -framework Foundation \
    main.swift \
    -o "Bozo Executer.app/Contents/MacOS/BozoExecuter" || exit 1

progress 90 "Checking application"

if [[ ! -x "Bozo Executer.app/Contents/MacOS/BozoExecuter" ]]; then
    echo "Build verification failed."
    exit 1
fi

progress 100 "Build complete"

echo -e "${GREEN}"
echo "BOZO EXECUTER INSTALLED SUCCESSFULLY"
echo -e "${RESET}"

open "Bozo Executer.app"
