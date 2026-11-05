# BOZO EXECUTER

A dark macOS server-control console for sending approved requests to an HTTPS bridge you own.

Created by c0olerishere.

## What's included

- Native macOS interface built with Swift and AppKit
- Dark red / charcoal control-console design
- HTTPS connection field and token entry
- JSON request editor
- Installer with live estimated progress and elapsed compile time
- A small allowlist of server-validation request IDs

## Build on macOS

Paste these commands into Terminal:

```sh
curl -L -o BozoExecuter.zip https://github.com/ttmeticks-source/yesure/archive/refs/heads/main.zip
unzip -o BozoExecuter.zip
cd yesure-main
chmod +x install.sh
./install.sh
```

The installer creates and opens `Bozo Executer.app`.

### If Swift compilation fails

The installer prints the selected developer directory, Swift compiler version, and macOS SDK version. If the error says the SDK is not supported by the compiler or mentions a duplicate `SwiftBridging` module, the installed compiler and SDK do not match.

If full Xcode is already installed in /Applications, select its toolchain:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Then rerun `./install.sh`. If that Xcode path does not exist, install or update the Xcode Command Line Tools through Apple's Software Update / Developer Downloads, then reopen Terminal and try again.

The percentage shown while Swift compiles is explicitly an estimate: Apple's Swift compiler does not expose a true compile percentage. The installer only reports 100% after compilation succeeds and the app bundle passes its checks.

## Connection setup

You need an HTTPS bridge that you own and operate. Enter its HTTPS endpoint and bearer token in the app. The bridge must accept a JSON POST request with an `Authorization: Bearer <token>` header.

Example payload:

```json
{
  "test": "remote_validation"
}
```

Allowed request IDs are:

- `remote_validation`
- `movement_validation`
- `rate_limit_validation`
- `permission_validation`

## Current limitations

The included Roblox dispatcher currently contains placeholder validation responses. It is not a finished anti-cheat monitor and does not provide a live Roblox connection by itself. The HTTPS bridge and real server-side validation logic still need to be implemented and configured.

The app deliberately does not execute arbitrary Luau, inject scripts into Roblox, or bypass Roblox security. Only the listed request IDs can be sent.
