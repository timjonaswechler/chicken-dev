#!/usr/bin/env bash
# bootstrap.sh — chicken-stack development environment setup
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main/bootstrap.sh | bash
#   curl -fsSL ... | bash -s -- --apps campfire
#   curl -fsSL ... | bash -s -- --apps bastion
#   curl -fsSL ... | bash -s -- --apps campfire,bastion

set -Eeuo pipefail

# Determine script directory (works for both local and piped execution)
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
else
  SCRIPT_DIR=""
fi

if [ ! -d "$SCRIPT_DIR" ]; then
  # Piped execution: download scripts to temp dir
  TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT
  SCRIPT_DIR="$TEMP_DIR/scripts"
  REPO_URL="${BOOTSTRAP_REPO_URL:-https://raw.githubusercontent.com/timjonaswechler/chicken-dev/main}"
  mkdir -p "$SCRIPT_DIR"
  for script in common.sh ensure-git.sh ensure-rust.sh ensure-just.sh ensure-go.sh \
                install-linux-deps.sh install-macos-deps.sh \
                setup-campfire.sh setup-bastion.sh doctor.sh; do
    curl -fsSL "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script"
  done
  # Also download templates
  TEMPLATES_DIR="$TEMP_DIR/templates"
  mkdir -p "$TEMPLATES_DIR"
  curl -fsSL "$REPO_URL/templates/campfire.env.example" -o "$TEMPLATES_DIR/campfire.env.example"
  curl -fsSL "$REPO_URL/templates/bastion.env.example" -o "$TEMPLATES_DIR/bastion.env.example"
  export TEMPLATES_DIR
fi

export SCRIPT_DIR
export TEMPLATES_DIR="${TEMPLATES_DIR:-$(dirname "$SCRIPT_DIR")/templates}"
export LOG_FILE="$HOME/chicken-dev-bootstrap.log"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# --- Argument Parsing ---

APPS="all"
SKIP_DOCTOR=false

usage() {
  echo "Usage: bootstrap.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --apps <list>     Comma-separated list of apps to set up"
  echo "                    Options: campfire, bastion, all (default: all)"
  echo "  --skip-doctor     Skip final environment verification"
  echo "  --help            Show this help"
  echo ""
  echo "Examples:"
  echo "  bootstrap.sh                        # Set up everything"
  echo "  bootstrap.sh --apps campfire        # Only campfire"
  echo "  bootstrap.sh --apps campfire,bastion # Both apps"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apps)
      APPS="$2"
      shift 2
      ;;
    --skip-doctor)
      SKIP_DOCTOR=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# --- Main ---

main() {
  echo ""
  echo -e "${BOLD}  chicken-stack bootstrap${NC}"
  echo -e "  Apps: ${CYAN}${APPS}${NC}"
  echo -e "  Root: ${CYAN}${WORKSPACE_ROOT}${NC}"
  echo ""

  : > "$LOG_FILE"
  info "Log: $LOG_FILE"
  info "OS=$(detect_os) ARCH=$(detect_arch)"
  info "Workspace: $WORKSPACE_ROOT"

  # Source and run ensure scripts
  source "$SCRIPT_DIR/ensure-git.sh"
  source "$SCRIPT_DIR/ensure-rust.sh"
  source "$SCRIPT_DIR/ensure-just.sh"

  step "Core Tools"
  ensure_git
  ensure_rust
  ensure_just

  # Go only if bastion requested
  if [[ "$APPS" == *"bastion"* || "$APPS" == "all" ]]; then
    source "$SCRIPT_DIR/ensure-go.sh"
    step "Bastion Tools"
    ensure_go
  fi

  # OS-specific dependencies
  OS="$(detect_os)"
  if [ "$OS" = "linux" ]; then
    source "$SCRIPT_DIR/install-linux-deps.sh"
    install_linux_deps
  elif [ "$OS" = "macos" ]; then
    source "$SCRIPT_DIR/install-macos-deps.sh"
    install_macos_deps
  fi

  # Clone repos
  step "Repositories"

  # chicken is always needed
  clone_or_update_repo "$(git_repo_url chicken)" "$WORKSPACE_ROOT/chicken"

  # campfire
  if [[ "$APPS" == *"campfire"* || "$APPS" == "all" ]]; then
    mkdir -p "$WORKSPACE_ROOT/fos"
    clone_or_update_repo "$(git_repo_url campfire)" "$WORKSPACE_ROOT/fos/campfire"
  fi

  # bastion
  if [[ "$APPS" == *"bastion"* || "$APPS" == "all" ]]; then
    mkdir -p "$WORKSPACE_ROOT/fos"
    clone_or_update_repo "$(git_repo_url bastion)" "$WORKSPACE_ROOT/fos/bastion"
  fi

  # App-specific setup
  source "$SCRIPT_DIR/setup-campfire.sh"
  source "$SCRIPT_DIR/setup-bastion.sh"

  if [[ "$APPS" == *"campfire"* || "$APPS" == "all" ]]; then
    setup_campfire
  fi

  if [[ "$APPS" == *"bastion"* || "$APPS" == "all" ]]; then
    setup_bastion
  fi

  # Doctor check
  if [ "$SKIP_DOCTOR" = false ]; then
    source "$SCRIPT_DIR/doctor.sh"
    doctor
  fi

  # Manual steps
  step "Manual Steps"
  echo -e "  ${YELLOW}1.${NC} Add SSH key to GitHub: ${CYAN}https://github.com/settings/keys${NC}"
  echo -e "  ${YELLOW}2.${NC} Set STEAM_APP_ID in fos/campfire/.env (optional, default: 480)"
  echo -e "  ${YELLOW}3.${NC} Set up your editor/IDE (rust-analyzer recommended)"
  echo ""
  success "Bootstrap complete!"
}

# --- Helper: clone or update ---

clone_or_update_repo() {
  local url="$1"
  local path="$2"
  local name
  name="$(basename "$path")"

  if [ -d "$path/.git" ]; then
    info "Update $name..."
    git -C "$path" pull --ff-only 2>/dev/null || warn "Update for $name failed (local changes?)"
    success "$name updated"
  else
    info "Clone $name..."
    git clone "$url" "$path"
    success "$name cloned to $path"
  fi
}

main
