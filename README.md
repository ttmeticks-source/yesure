# BOZO EXECUTER

Roblox server test console for macOS.

Created by c0olerishere.

## Features

- Native macOS app built with Swift and AppKit
- Dark red, black and white interface
- HTTPS request sender
- Allowlisted test IDs only
- INJECT TEST and CLEAR buttons
- Bridge token entered at runtime and not saved by the app

## Requirements

- macOS
- Apple's Swift compiler (install with `xcode-select --install` if needed)
- An HTTPS bridge that you own and operate
- A Roblox experience you own, with any required server-side test code configured

## Download and install

Run these commands in Terminal:

```sh
curl -L -o BozoExecuter.zip https://github.com/ttmeticks-source/yesure/archive/refs/heads/main.zip
unzip -o BozoExecuter.zip
cd yesure-main
chmod +x install.sh
./install.sh
```

The installer creates and opens `Bozo Executer.app`.

## Sending a test

The app accepts JSON with one of these test IDs:

- `remote_validation`
- `movement_validation`
- `rate_limit_validation`
- `permission_validation`

Example request:

```json
{
  "test": "remote_validation"
}
```

Enter your own HTTPS endpoint and bridge token in the app. The bridge must accept a POST request with a JSON body and a `Authorization: Bearer <token>` header, then safely route the allowlisted test ID to your own Roblox test setup.

## Important

This repository includes the macOS request-sender app and a basic Roblox-side allowlist dispatcher. It does **not** include or host an HTTPS bridge, and the dispatcher is not automatically connected to Roblox or to this app. You must build and secure that bridge before the INJECT TEST button can reach your experience.

This is a test-request console, not an arbitrary Luau executor. It does not bypass Roblox security or run arbitrary code on live servers.
