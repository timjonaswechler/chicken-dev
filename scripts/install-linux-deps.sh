#!/usr/bin/env bash
# install-linux-deps.sh — Install Bevy system dependencies on Linux
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_linux_deps() {
  if [ "$(detect_os)" != "linux" ]; then
    return 0
  fi

  step "Linux System Dependencies"

  local pm
  pm="$(detect_pkg_manager)"

  case "$pm" in
    apt)
      info "Installing Bevy dependencies via apt..."
      sudo apt-get update -qq
      sudo apt-get install -y \
        libasound2-dev \
        libudev-dev \
        libx11-dev \
        libxcursor-dev \
        libxrandr-dev \
        libxi-dev \
        libvulkan-dev \
        libwayland-dev \
        libxkbcommon-dev \
        pkg-config
      ;;
    dnf)
      info "Installing Bevy dependencies via dnf..."
      sudo dnf install -y \
        alsa-lib-devel \
        systemd-devel \
        libX11-devel \
        libXcursor-devel \
        libXrandr-devel \
        libXi-devel \
        vulkan-devel \
        wayland-devel \
        libxkbcommon-devel \
        pkg-config
      ;;
    pacman)
      info "Installing Bevy dependencies via pacman..."
      sudo pacman -Sy --noconfirm \
        alsa-lib \
        systemd \
        libx11 \
        libxcursor \
        libxrandr \
        libxi \
        vulkan-devel \
        wayland \
        libxkbcommon \
        pkg-config
      ;;
    *)
      warn "Package manager '$pm' not recognized. Please install manually:"
      warn "  libasound2-dev libudev-dev libx11-dev libxcursor-dev libxrandr-dev"
      warn "  libxi-dev libvulkan-dev libwayland-dev libxkbcommon-dev pkg-config"
      ;;
  esac

  success "Linux system dependencies installed"
}
