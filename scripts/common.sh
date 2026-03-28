#!/usr/bin/env bash
# common.sh — Shared functions for chicken-dev bootstrap
# Sourced by all other scripts. Do not execute directly.

set -Eeuo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
LOG_FILE="${LOG_FILE:-$HOME/chicken-dev-bootstrap.log}"

info()    { echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[ OK ]${NC} $*" | tee -a "$LOG_FILE"; }
fail()    { echo -e "${RED}[FAIL]${NC} $*" | tee -a "$LOG_FILE"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}==>${NC} ${BOLD}$*${NC}" | tee -a "$LOG_FILE"; }

# OS detection
detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *)             echo "unknown" ;;
  esac
}

# Package manager detection (Linux)
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo "unknown"
  fi
}

# Install package via detected package manager
install_pkg() {
  local pkg="$1"
  local pm
  pm="$(detect_pkg_manager)"

  case "$pm" in
    apt)    sudo apt-get update -qq && sudo apt-get install -y "$pkg" ;;
    dnf)    sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -Sy --noconfirm "$pkg" ;;
    zypper) sudo zypper install -y "$pkg" ;;
    *)      fail "Kein unterstützter Paketmanager. Bitte '$pkg' manuell installieren." ;;
  esac
}

# Check if command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Copy file only if destination does not exist (idempotent)
cp_if_missing() {
  local src="$1"
  local dst="$2"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    success "Erstellt: $dst"
  else
    info "Existiert bereits: $dst (übersprungen)"
  fi
}

# Resolve workspace root — default to current directory
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(pwd)}"

# Pre-detect git URL style (cached, checked once)
_init_git_urls() {
  if [ -z "${_GIT_URLS_DETECTED:-}" ]; then
    if ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
      _GIT_SSH_AVAILABLE=true
      info "SSH-Verbindung zu GitHub: OK"
    else
      _GIT_SSH_AVAILABLE=false
      warn "SSH zu GitHub nicht verfügbar, nutze HTTPS"
    fi
    _GIT_URLS_DETECTED=true
  fi
}

git_repo_url() {
  local repo="$1"
  _init_git_urls
  if [ "$_GIT_SSH_AVAILABLE" = true ]; then
    echo "git@github.com:timjonaswechler/${repo}.git"
  else
    echo "https://github.com/timjonaswechler/${repo}.git"
  fi
}
