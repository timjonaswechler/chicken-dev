#!/usr/bin/env bash
# doctor.sh — Verify that the development environment is correctly set up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

doctor() {
  step "Checking environment"

  local errors=0
  local warnings=0

  # Check tools
  local tools=("git" "rustc" "cargo" "just")
  for tool in "${tools[@]}"; do
    if has_cmd "$tool"; then
      success "$tool: $($tool --version 2>/dev/null | head -1)"
    else
      fail "$tool missing!"
      errors=$((errors + 1))
    fi
  done

  # Check Rust components
  if has_cmd rustup; then
    for component in clippy rustfmt; do
      if rustup component list --installed 2>/dev/null | grep -q "$component"; then
        success "rustup: $component installed"
      else
        warn "rustup: $component missing"
        warnings=$((warnings + 1))
      fi
    done
  fi

  # Check repos exist
  local repos=("chicken" "fos/campfire")
  for repo in "${repos[@]}"; do
    if [ -d "$WORKSPACE_ROOT/$repo/.git" ]; then
      success "Repo: $repo present"
    else
      warn "Repo: $repo missing at $WORKSPACE_ROOT/$repo"
      warnings=$((warnings + 1))
    fi
  done

  # Check chicken patch in campfire
  local campfire_cargo_config="$WORKSPACE_ROOT/fos/campfire/.cargo/config.toml"
  if [ -f "$campfire_cargo_config" ]; then
    if grep -q 'path.*chicken/crates/chicken' "$campfire_cargo_config"; then
      success "chicken patch configured (campfire)"
    else
      warn "chicken patch not found in $campfire_cargo_config"
      warnings=$((warnings + 1))
    fi
  fi

  # Check .env files
  for app_dir in "$WORKSPACE_ROOT/fos/campfire" "$WORKSPACE_ROOT/fos/bastion"; do
    if [ -d "$app_dir" ]; then
      if [ -f "$app_dir/.env" ]; then
        success ".env present: $app_dir"
      else
        info ".env missing: $app_dir (optional)"
      fi
    fi
  done

  # Summary
  echo ""
  if [ $errors -gt 0 ]; then
    fail "$errors error(s) found. Please fix."
  elif [ $warnings -gt 0 ]; then
    warn "$warnings warning(s). Setup should still work."
  else
    success "All checks passed. Development environment ready."
  fi
}
