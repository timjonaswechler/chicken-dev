#!/usr/bin/env bash
# ensure-git.sh — Ensure git is installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_git() {
  if has_cmd git; then
    success "git $(git --version | awk '{print $3}')"
    return 0
  fi

  info "git not found, attempting installation..."

  if [ "$(detect_os)" = "macos" ]; then
    if has_cmd brew; then
      brew install git
    else
      fail "Homebrew not found. Please install git manually."
    fi
  else
    install_pkg git
  fi

  success "git $(git --version | awk '{print $3}')"
}
