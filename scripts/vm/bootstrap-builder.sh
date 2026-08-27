#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Builder VM Bootstrap Script
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Runs INSIDE the 'xedra-builder' Debian 13 (Trixie) virtual machine to
#   install the graphical development environment (Fluxbox, Firefox-ESR, xterm)
#   and the complete, authoritative Debian distro-building toolchain.
#
# Note:
#   Fluxbox, Firefox, and development tools installed here belong to the
#   BUILDER VM. They are NOT Xedra packages and will not pollute Xedra.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_CYAN="\033[36m"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - 'xedra-builder' Toolchain Bootstrap    ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Environment: Debian 13 (Trixie) Builder VM"
    echo ""
}

check_environment() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${COLOR_RED}Error: This script must be run with root privileges (e.g. sudo $0)${COLOR_RESET}" >&2
        exit 1
    fi

    if [[ ! -f /etc/os-release ]] || ! grep -qi 'ID=debian' /etc/os-release; then
        echo -e "${COLOR_RED}Error: This script must be run INSIDE a Debian system.${COLOR_RESET}" >&2
        exit 1
    fi
}

install_packages() {
    echo -e "${COLOR_BOLD}--- 1. Updating Debian Package Lists ---${COLOR_RESET}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update

    echo ""
    echo -e "${COLOR_BOLD}--- 2. Installing Developer Desktop Environment ---${COLOR_RESET}"
    echo "  • fluxbox: Lightweight, minimal window manager"
    echo "  • xorg: X11 display server stack"
    echo "  • xterm: Terminal emulator"
    echo "  • firefox-esr: Web browser for reading documentation/specs"
    echo "  • git: Version control for ~/XedraLinux repository"
    echo "  • curl, ca-certificates, sudo, rsync: Core developer tools"
    
    apt-get install -y --no-install-recommends \
        xorg \
        fluxbox \
        xterm \
        firefox-esr \
        git \
        curl \
        ca-certificates \
        sudo \
        rsync \
        procps \
        coreutils \
        util-linux \
        vim-tiny \
        nano

    echo ""
    echo -e "${COLOR_BOLD}--- 3. Installing Distro Engineering Toolchain ---${COLOR_RESET}"
    echo "  • debootstrap: Debian base rootfs bootstrapping engine"
    echo "  • live-build: Debian standard live ISO generation framework"
    echo "  • squashfs-tools: mksquashfs compressor for compressed rootfs"
    echo "  • xorriso: ISO-9660 filesystem creator with hybrid MBR/EFI support"
    echo "  • grub-pc-bin, grub-efi-amd64-bin: Bootloader binaries for BIOS & UEFI"
    echo "  • mtools, dosfstools: FAT16/FAT32 tools for EFI System Partitions (ESP)"
    
    apt-get install -y --no-install-recommends \
        debootstrap \
        live-build \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        mtools \
        dosfstools

    echo ""
    echo -e "${COLOR_BOLD}--- 4. Cleaning APT Cache ---${COLOR_RESET}"
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

verify_toolchain() {
    echo ""
    echo -e "${COLOR_BOLD}--- 5. Verifying Installed Build Tools ---${COLOR_RESET}"
    
    local tools=("debootstrap" "lb" "mksquashfs" "xorriso" "grub-mkstandalone" "mkfs.vfat" "git" "fluxbox" "xterm")
    local count_pass=0

    for tool in "${tools[@]}"; do
        if command -v "${tool}" >/dev/null 2>&1; then
            echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${tool} -> $(command -v "${tool}")"
            ((count_pass++)) || true
        else
            echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${tool} -> missing"
        fi
    done

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  'xedra-builder' VM is Now Fully Configured!          ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
    echo "Next steps inside the VM:"
    echo "  1. Clone the Xedra repository:"
    echo "     git clone git@github.com:arthurgray2k/XedraGoSysInit.git ~/XedraGoSysInit"
    echo "  2. Start the graphical desktop:"
    echo "     startx"
    echo "  3. Proceed with Xedra distribution builds in ~/XedraGoSysInit."
    echo ""
}

main() {
    print_header
    check_environment
    install_packages
    verify_toolchain
}

main "$@"
