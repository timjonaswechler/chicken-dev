#!/usr/bin/env bash
# ensure-just.sh — Ensure just command runner is installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_just() {
  if has_cmd just; then
    success "just $(just --version | awk '{print $2}')"
    return 0
  fi

  info "just nicht gefunden, versuche Installation..."

  if [ "$(detect_os)" = "macos" ] && has_cmd brew; then
    brew install just
  elif has_cmd cargo; then
    cargo install just
  else
    fail "Weder cargo noch brew gefunden. Bitte just manuell installieren: https://github.com/casey/just#installation"
  fi

  success "just $(just --version | awk '{print $2}') installiert"
}
