#!/usr/bin/env bash
# doctor.sh — Verify that the development environment is correctly set up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

doctor() {
  step "Umgebung prüfen"

  local errors=0
  local warnings=0

  # Check tools
  local tools=("git" "rustc" "cargo" "just")
  for tool in "${tools[@]}"; do
    if has_cmd "$tool"; then
      success "$tool: $($tool --version 2>/dev/null | head -1)"
    else
      fail "$tool fehlt!"
      errors=$((errors + 1))
    fi
  done

  # Check Rust components
  if has_cmd rustup; then
    for component in clippy rustfmt; do
      if rustup component list --installed 2>/dev/null | grep -q "$component"; then
        success "rustup: $component installiert"
      else
        warn "rustup: $component fehlt"
        warnings=$((warnings + 1))
      fi
    done
  fi

  # Check repos exist
  local repos=("chicken" "fos/campfire")
  for repo in "${repos[@]}"; do
    if [ -d "$WORKSPACE_ROOT/$repo/.git" ]; then
      success "Repo: $repo vorhanden"
    else
      warn "Repo: $repo fehlt unter $WORKSPACE_ROOT/$repo"
      warnings=$((warnings + 1))
    fi
  done

  # Check chicken patch in campfire
  local campfire_cargo_config="$WORKSPACE_ROOT/fos/campfire/.cargo/config.toml"
  if [ -f "$campfire_cargo_config" ]; then
    if grep -q 'path.*chicken/crates/chicken' "$campfire_cargo_config"; then
      success "chicken patch konfiguriert (campfire)"
    else
      warn "chicken patch nicht in $campfire_cargo_config gefunden"
      warnings=$((warnings + 1))
    fi
  fi

  # Check .env files
  for app_dir in "$WORKSPACE_ROOT/fos/campfire" "$WORKSPACE_ROOT/fos/bastion"; do
    if [ -d "$app_dir" ]; then
      if [ -f "$app_dir/.env" ]; then
        success ".env vorhanden: $app_dir"
      else
        info ".env fehlt: $app_dir (optional)"
      fi
    fi
  done

  # Summary
  echo ""
  if [ $errors -gt 0 ]; then
    fail "$errors Fehler gefunden. Bitte beheben."
  elif [ $warnings -gt 0 ]; then
    warn "$warnings Warnung(en). Setup sollte aber funktionieren."
  else
    success "Alles grün! Entwicklungsumgebung bereit."
  fi
}
