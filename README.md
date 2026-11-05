# BOZO EXECUTER

Roblox Server Test Console for macOS.

Created by c0olerishere.

## Features

- Native macOS application
- Dark red, black and white interface
- Luau test editor
- INJECT TEST button
- CLEAR button
- Authenticated HTTPS bridge
- Server-side anti-cheat testing
- Installation progress display

## Requirements

- macOS
- Apple's Swift compiler
- An authorized HTTPS testing bridge
- Roblox HttpService enabled for your experience

## Installation

Download the repository:

    curl -L -o BozoExecuter.zip https://github.com/USERNAME/Bozo-Executer/archive/refs/heads/main.zip

Extract it:

    unzip BozoExecuter.zip

Enter the project:

    cd Bozo-Executer-main

Run the installer:

    chmod +x install.sh
    ./install.sh

## Roblox setup

Place ServerTestDispatcher.lua in ServerScriptService
inside your own Roblox experience.

Configure your authorized HTTPS bridge separately.

This project uses allowlisted test requests.
It does not execute arbitrary code on live Roblox servers.
