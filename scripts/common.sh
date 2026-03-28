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
    *)      fail "No supported package manager found. Please install '$pkg' manually." ;;
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
    success "Created: $dst"
  else
    info "Already exists: $dst (skipped)"
  fi
}

# Resolve workspace root — default to current directory
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(pwd)}"

# Check if SSH keys for GitHub exist
_has_ssh_keys() {
  # Check for common SSH key files
  for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
    if [ -f "$key" ]; then
      return 0
    fi
  done
  return 1
}

# Test SSH connection to GitHub
_test_ssh_github() {
  # ssh -T returns exit code 1 on success (no shell access)
  # so we check the output, not the exit code
  local output
  output="$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)" || true
  if echo "$output" | grep -q "successfully authenticated"; then
    return 0
  fi
  return 1
}

# Detect git URL style (cached, checked once)
_init_git_urls() {
  if [ -z "${_GIT_URLS_DETECTED:-}" ]; then
    if _has_ssh_keys; then
      if _test_ssh_github; then
        _GIT_SSH_AVAILABLE=true
        info "SSH connection to GitHub: OK"
      else
        _GIT_SSH_AVAILABLE=false
        warn "SSH keys found but GitHub authentication failed, using HTTPS"
      fi
    else
      _GIT_SSH_AVAILABLE=false
      info "No SSH keys found, using HTTPS"
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
