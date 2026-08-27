#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 6: Install Minimal X11 + Fluxbox Desktop
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Installs and configures the standard Xedra desktop environment (X11,
#   Fluxbox window manager, and xterm) inside ~/XedraGoSysInit/build/rootfs.
#
# Target Components:
#   - X11 Server: xserver-xorg-core, xserver-xorg-video-all, xinit
#   - Window Manager: fluxbox
#   - Terminal: xterm
#   - Default session: /etc/skel/.xinitrc & /etc/skel/.fluxbox/
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOTFS_DIR="${1:-${REPO_ROOT}/build/rootfs}"
CONFIG_DIR="${REPO_ROOT}/config"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Minimal Desktop Setup (X11 + Fluxbox) ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Target Rootfs: ${ROOTFS_DIR}"
    echo "Components:    X11 (xorg-core) + Fluxbox + xterm"
    echo ""
}

verify_environment() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${COLOR_RED}Error: This script must be run as root (e.g. sudo $0)${COLOR_RESET}" >&2
        exit 1
    fi

    if [[ ! -d "${ROOTFS_DIR}" ]] || [[ ! -f "${ROOTFS_DIR}/etc/os-release" ]]; then
        echo -e "${COLOR_RED}Error: Rootfs not found at '${ROOTFS_DIR}'.${COLOR_RESET}" >&2
        exit 1
    fi
}

cleanup_mounts() {
    local target="$1"
    echo "Cleaning up mount bindings..."
    for mnt in "${target}/dev/pts" "${target}/dev" "${target}/sys" "${target}/proc"; do
        if mountpoint -q "${mnt}" 2>/dev/null; then
            umount "${mnt}" 2>/dev/null || true
        fi
    done
}

mount_pseudo_filesystems() {
    echo -e "${COLOR_BOLD}--- 1. Binding Pseudo-Filesystems ---${COLOR_RESET}"
    mkdir -p "${ROOTFS_DIR}/proc" "${ROOTFS_DIR}/sys" "${ROOTFS_DIR}/dev" "${ROOTFS_DIR}/dev/pts"
    
    if ! mountpoint -q "${ROOTFS_DIR}/proc"; then mount -t proc proc "${ROOTFS_DIR}/proc"; fi
    if ! mountpoint -q "${ROOTFS_DIR}/sys"; then mount -t sysfs sysfs "${ROOTFS_DIR}/sys"; fi
    if ! mountpoint -q "${ROOTFS_DIR}/dev"; then mount --bind /dev "${ROOTFS_DIR}/dev"; fi
    if ! mountpoint -q "${ROOTFS_DIR}/dev/pts"; then mount -t devpts devpts "${ROOTFS_DIR}/dev/pts"; fi

    trap 'cleanup_mounts "${ROOTFS_DIR}"' EXIT INT TERM
    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Pseudo-filesystems mounted"
    echo ""
}

install_desktop_packages() {
    echo -e "${COLOR_BOLD}--- 2. Installing X11, Fluxbox & xterm ---${COLOR_RESET}"
    export DEBIAN_FRONTEND=noninteractive

    echo "Installing minimal X11 server and drivers..."
    chroot "${ROOTFS_DIR}" apt-get install -y --no-install-recommends \
        xserver-xorg-core \
        xserver-xorg-video-all \
        xserver-xorg-input-all \
        xinit \
        x11-xserver-utils \
        x11-utils \
        xauth

    echo "Installing Fluxbox and xterm..."
    chroot "${ROOTFS_DIR}" apt-get install -y --no-install-recommends \
        fluxbox \
        xterm \
        dbus-x11

    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Desktop packages installed successfully"
    echo ""
}

configure_desktop_defaults() {
    echo -e "${COLOR_BOLD}--- 3. Installing Default Desktop Configurations ---${COLOR_RESET}"
    
    # Create default user skeleton directories
    mkdir -p "${ROOTFS_DIR}/etc/skel/.fluxbox" "${ROOTFS_DIR}/root/.fluxbox"

    # Install .xinitrc
    if [[ -f "${CONFIG_DIR}/xinitrc" ]]; then
        cp "${CONFIG_DIR}/xinitrc" "${ROOTFS_DIR}/etc/skel/.xinitrc"
        cp "${CONFIG_DIR}/xinitrc" "${ROOTFS_DIR}/root/.xinitrc"
        chmod 755 "${ROOTFS_DIR}/etc/skel/.xinitrc" "${ROOTFS_DIR}/root/.xinitrc"
        echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] .xinitrc installed to /etc/skel and /root"
    fi

    # Install Fluxbox menu
    if [[ -f "${CONFIG_DIR}/fluxbox/menu" ]]; then
        cp "${CONFIG_DIR}/fluxbox/menu" "${ROOTFS_DIR}/etc/skel/.fluxbox/menu"
        cp "${CONFIG_DIR}/fluxbox/menu" "${ROOTFS_DIR}/root/.fluxbox/menu"
        echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Fluxbox root menu installed"
    fi
    echo ""
}

verify_installation() {
    echo -e "${COLOR_BOLD}--- 4. Verifying Desktop Binaries in Rootfs ---${COLOR_RESET}"
    
    local bins=("usr/bin/Xorg" "usr/bin/xinit" "usr/bin/fluxbox" "usr/bin/xterm")
    for b in "${bins[@]}"; do
        if [[ -f "${ROOTFS_DIR}/${b}" || -L "${ROOTFS_DIR}/${b}" ]]; then
            echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] /${b} exists"
        else
            echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] /${b} is missing"
        fi
    done

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  X11 + Fluxbox Desktop Successfully Configured!       ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
}

main() {
    print_header
    verify_environment
    mount_pseudo_filesystems
    install_desktop_packages
    configure_desktop_defaults
    verify_installation
}

main "$@"
