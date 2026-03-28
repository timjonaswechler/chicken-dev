#!/usr/bin/env bash
# setup-campfire.sh — Campfire-specific setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEMPLATES_DIR="${TEMPLATES_DIR:-$(dirname "$SCRIPT_DIR")/templates}"

setup_campfire() {
  local app_dir="$WORKSPACE_ROOT/fos/campfire"

  step "Campfire Setup"

  if [ ! -d "$app_dir" ]; then
    warn "campfire nicht gefunden unter $app_dir (wird vom Bootstrap geklont)"
    return 0
  fi

  # Copy .env from template if missing
  cp_if_missing "$TEMPLATES_DIR/campfire.env.example" "$app_dir/.env"

  success "Campfire Setup abgeschlossen"
}
