# chicken-dev

Bootstrap-Repo für die chicken-stack Entwicklungsumgebung.

## Was ist das?

Zentrales Setup für die Repositories [chicken](https://github.com/timjonaswechler/chicken), [campfire](https://github.com/timjonaswechler/campfire) und [bastion](https://github.com/timjonaswechler/bastion). Ein Befehl installiert alle Tools, klont die Repos und richtet lokale Konfigurationen ein.

## Quick Start

```bash
# Alles einrichten
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash

# Nur campfire (Game Client)
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash -s -- --apps campfire

# Nur bastion (Headless Server, inkl. Go)
curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash -s -- --apps bastion
```

## Was wird installiert?

| Tool | Wann | Beschreibung |
|------|------|--------------|
| git | immer | Versionskontrolle |
| rustup + Rust | immer | Rust-Toolchain (stable, clippy, rustfmt) |
| just | immer | Task Runner |
| Go | nur bastion | Für das bastion-tui (Go TUI) |
| Linux system libs | nur Linux | Bevy-Dependencies (libudev, Vulkan, etc.) |
| macOS deps | nur macOS | cmake, pkg-config via Homebrew |

## Repositories

Das Skript klont die Repos in das aktuelle Verzeichnis (oder `WORKSPACE_ROOT` falls gesetzt):

```
./
├── chicken/          → Game Library (immer)
├── fos/
│   ├── campfire/     → Game Client (--apps campfire)
│   └── bastion/      → Headless Server (--apps bastion)
```

Oder mit eigenem Pfad:

```bash
mkdir ~/dev && cd ~/dev
curl -fsSL ... | bash
```

Lokale Entwicklung nutzt `[patch]` in `.cargo/config.toml`, damit campfire und bastion gegen die lokale chicken-Entwicklungsvariante kompilieren.

## Optionen

```
--apps <list>       Komma-getrennte Liste: campfire, bastion, all (default: all)
--skip-doctor       Überspringt die abschließende Umgebungsprüfung
--help              Hilfe
```

## Idempotent

Das Skript kann mehrfach ausgeführt werden:

- Existierende Repos werden per `git pull --ff-only` aktualisiert
- Tools werden nur installiert wenn sie fehlen
- `.env` Dateien werden nur erzeugt wenn sie noch nicht existieren

## SSH / HTTPS

Das Skript prüft automatisch ob SSH zu GitHub funktioniert. Falls kein SSH-Key eingerichtet ist, wird auf HTTPS umgeschaltet. Für Push-Rechte wird trotzdem ein SSH-Key oder HTTPS-Token benötigt.

## Manuelle Schritte

Nach dem Bootstrap sind diese Schritte noch nötig:

1. SSH-Key zu [GitHub](https://github.com/settings/keys) hinzufügen
2. `STEAM_APP_ID` in `fos/campfire/.env` setzen (optional, default: 480)
3. Editor/IDE einrichten ([rust-analyzer](https://rust-analyzer.github.io/) empfohlen)

## Struktur

```
chicken-dev/
├── bootstrap.sh              # Main Entry Point
├── manifest.json             # Repo-Definitionen
├── justfile                  # just bootstrap / doctor / update
├── scripts/
│   ├── common.sh             # Logging, OS-Erkennung, Helpers
│   ├── ensure-git.sh
│   ├── ensure-rust.sh
│   ├── ensure-just.sh
│   ├── ensure-go.sh          # nur wenn bastion gewählt
│   ├── install-linux-deps.sh # Bevy system libs
│   ├── install-macos-deps.sh # cmake, pkg-config
│   ├── setup-campfire.sh     # .env kopieren
│   ├── setup-bastion.sh      # .env kopieren + Go modules
│   └── doctor.sh             # Abschluss-Verifikation
└── templates/
    ├── campfire.env.example
    └── bastion.env.example
```

## License

MIT
