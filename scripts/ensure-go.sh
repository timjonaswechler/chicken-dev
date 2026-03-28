#!/usr/bin/env bash
# ensure-go.sh — Ensure Go toolchain is installed (for bastion-tui)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_go() {
  if has_cmd go; then
    success "Go $(go version | awk '{print $3}')"
    return 0
  fi

  info "Go nicht gefunden, versuche Installation..."

  if [ "$(detect_os)" = "macos" ]; then
    if has_cmd brew; then
      brew install go
    else
      fail "Homebrew nicht gefunden. Bitte Go manuell installieren: https://go.dev/dl/"
    fi
  else
    local pm
    pm="$(detect_pkg_manager)"
    case "$pm" in
      apt)    sudo apt-get update -qq && sudo apt-get install -y golang ;;
      dnf)    sudo dnf install -y golang ;;
      pacman) sudo pacman -Sy --noconfirm go ;;
      *)
        warn "Paketmanager '$pm' nicht unterstützt für Go. Installiere von go.dev..."
        local go_version="1.24.1"
        local arch
        arch="$(detect_arch)"
        local go_tar="go${go_version}.linux-${arch}.tar.gz"
        curl -fsSL "https://go.dev/dl/${go_tar}" -o "/tmp/${go_tar}"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "/tmp/${go_tar}"
        rm "/tmp/${go_tar}"
        export PATH="/usr/local/go/bin:$PATH"
        ;;
    esac
  fi

  success "Go $(go version | awk '{print $3}') installiert"
}
