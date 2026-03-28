#!/usr/bin/env bash
# ensure-rust.sh — Ensure rustup, Rust stable, clippy, rustfmt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_rust() {
  if has_cmd rustup && has_cmd rustc && has_cmd cargo; then
    success "Rust $(rustc --version | awk '{print $2}')"
  else
    info "Rust not found, installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    success "Rust $(rustc --version | awk '{print $2}') installed"
  fi

  # Ensure stable toolchain is default
  rustup default stable &>/dev/null

  # Ensure components
  for component in clippy rustfmt; do
    if rustup component list --installed 2>/dev/null | grep -q "$component"; then
      success "$component present"
    else
      info "Installing $component..."
      rustup component add "$component"
      success "$component installed"
    fi
  done

  # Ensure cargo is on PATH for subsequent scripts
  export PATH="$HOME/.cargo/bin:$PATH"
}
