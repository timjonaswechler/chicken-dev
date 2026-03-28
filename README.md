# chicken-dev

Bootstrap repo for the chicken-stack development environment.

## What is this?

Central setup for the repositories [chicken](https://github.com/timjonaswechler/chicken), [campfire](https://github.com/timjonaswechler/campfire) and [bastion](https://github.com/timjonaswechler/bastion). One command installs all tools, clones the repos and sets up local configuration.

## Quick Start

```bash
# Set up everything
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash

# Only campfire (Game Client)
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash -s -- --apps campfire

# Only bastion (Headless Server, includes Go)
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash -s -- --apps bastion
```

## What gets installed?

| Tool | When | Description |
|------|------|-------------|
| git | always | Version control |
| rustup + Rust | always | Rust toolchain (stable, clippy, rustfmt) |
| just | always | Task runner |
| Go | bastion only | For bastion-tui (Go TUI) |
| Linux system libs | Linux only | Bevy dependencies (libudev, Vulkan, etc.) |
| macOS deps | macOS only | cmake, pkg-config via Homebrew |

## Repositories

The script clones repos into the current directory (or `WORKSPACE_ROOT` if set):

```
./
├── chicken/          → Game Library (always)
├── fos/
│   ├── campfire/     → Game Client (--apps campfire)
│   └── bastion/      → Headless Server (--apps bastion)
```

Or with a custom path:

```bash
mkdir ~/dev && cd ~/dev
curl -fsSL ... | bash
```

Local development uses `[patch]` in `.cargo/config.toml` so campfire and bastion compile against the local chicken development version.

## Options

```
--apps <list>       Comma-separated list: campfire, bastion, all (default: all)
--skip-doctor       Skip final environment verification
--help              Show help
```

## Idempotent

The script can be run multiple times:

- Existing repos are updated via `git pull --ff-only`
- Tools are only installed if missing
- `.env` files are only created if they don't already exist

## SSH / HTTPS

The script automatically detects if SSH to GitHub works. If no SSH key is configured, it falls back to HTTPS. For push access you still need an SSH key or HTTPS token.

## Manual Steps

After bootstrap these steps are still needed:

1. Add SSH key to [GitHub](https://github.com/settings/keys)
2. Set `STEAM_APP_ID` in `fos/campfire/.env` (optional, default: 480)
3. Set up your editor/IDE ([rust-analyzer](https://rust-analyzer.github.io/) recommended)

## Structure

```
chicken-dev/
├── bootstrap.sh              # Main entry point
├── manifest.json             # Repo definitions
├── justfile                  # just bootstrap / doctor / update
├── scripts/
│   ├── common.sh             # Logging, OS detection, helpers
│   ├── ensure-git.sh
│   ├── ensure-rust.sh
│   ├── ensure-just.sh
│   ├── ensure-go.sh          # only if bastion selected
│   ├── install-linux-deps.sh # Bevy system libs
│   ├── install-macos-deps.sh # cmake, pkg-config
│   ├── setup-campfire.sh     # copy .env
│   ├── setup-bastion.sh      # copy .env + Go modules
│   └── doctor.sh             # Final verification
└── templates/
    ├── campfire.env.example
    └── bastion.env.example
```

## License

MIT
