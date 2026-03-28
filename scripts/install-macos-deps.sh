#!/usr/bin/env bash
# install-macos-deps.sh — Install macOS build dependencies via Homebrew
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_macos_deps() {
  if [ "$(detect_os)" != "macos" ]; then
    return 0
  fi

  step "macOS System-Abhängigkeiten"

  if ! has_cmd brew; then
    info "Homebrew nicht gefunden, installiere..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  local deps=(cmake pkg-config)
  local to_install=()

  for dep in "${deps[@]}"; do
    if brew list "$dep" &>/dev/null; then
      success "$dep vorhanden"
    else
      to_install+=("$dep")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    info "Installiere: ${to_install[*]}"
    brew install "${to_install[@]}"
    success "macOS Dependencies installiert"
  else
    success "Alle macOS Dependencies vorhanden"
  fi
}
