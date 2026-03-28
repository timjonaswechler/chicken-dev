#!/usr/bin/env bash
# setup-bastion.sh — Bastion-specific setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEMPLATES_DIR="${TEMPLATES_DIR:-$(dirname "$SCRIPT_DIR")/templates}"

setup_bastion() {
  local app_dir="$WORKSPACE_ROOT/fos/bastion"

  step "Bastion Setup"

  if [ ! -d "$app_dir" ]; then
    warn "bastion nicht gefunden unter $app_dir (wird vom Bootstrap geklont)"
    return 0
  fi

  # Copy .env from template if missing
  cp_if_missing "$TEMPLATES_DIR/bastion.env.example" "$app_dir/.env"

  # Ensure Go modules are downloaded for bastion-tui
  if [ -d "$app_dir/bastion-tui" ] && has_cmd go; then
    info "Lade Go-Module für bastion-tui..."
    go mod download -C "$app_dir/bastion-tui"
    success "Go-Module geladen"
  fi

  success "Bastion Setup abgeschlossen"
}
