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
  for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
    if [ -f "$key" ]; then
      return 0
    fi
  done
  return 1
}

# Test SSH connection to GitHub
_test_ssh_github() {
  local output
  output="$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)" || true
  if echo "$output" | grep -q "successfully authenticated"; then
    return 0
  fi
  return 1
}

# Verify SSH access to GitHub (required for local dev, skipped in CI)
# Call early in bootstrap to fail fast if SSH is not set up
require_github_ssh() {
  # Skip in CI — GitHub Actions has automatic access via GITHUB_TOKEN
  if [ "${CI:-}" = "true" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
    info "CI detected, skipping SSH check"
    return 0
  fi

  if ! _has_ssh_keys; then
    fail "No SSH keys found. Please set up SSH access to GitHub first:
  1. Generate a key: ssh-keygen -t ed25519 -C \"your@email.com\"
  2. Add to ssh-agent: eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519
  3. Add public key to GitHub: https://github.com/settings/keys"
  fi

  if ! _test_ssh_github; then
    fail "SSH key found but GitHub authentication failed. Please check:
  1. Your SSH key is added to GitHub: https://github.com/settings/keys
  2. You have access to the repositories
  3. ssh -T git@github.com works"
  fi

  success "GitHub SSH access: OK"
}

git_repo_url() {
  local repo="$1"
  # In CI: use HTTPS with GITHUB_TOKEN for authentication
  if [ "${CI:-}" = "true" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      echo "https://x-access-token:${GITHUB_TOKEN}@github.com/timjonaswechler/${repo}.git"
    else
      echo "https://github.com/timjonaswechler/${repo}.git"
    fi
  else
    echo "git@github.com:timjonaswechler/${repo}.git"
  fi
}
