# BOZO EXECUTER

A dark macOS server-control console for sending approved requests to an HTTPS bridge you own.

Created by c0olerishere.

## What's included

- Native macOS interface built with Swift and AppKit
- Dark red / charcoal control-console design
- HTTPS connection field and token entry
- JSON command editor
- Live installer status with elapsed compile time
- Allowlisted server-validation actions

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

## Important limitations

The interface is presented as a server-control console, but the currently included server actions are validation checks. The repository does not include the HTTPS bridge or a live Roblox connection, so those must be configured separately.

The app deliberately does not execute arbitrary Luau, inject scripts into Roblox, or bypass Roblox security. Only the listed request IDs can be sent.
