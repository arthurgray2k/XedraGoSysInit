#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 3B: Complete Rootfs Package Configuration (Second Stage)
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Completes the second stage of debootstrap inside /workspace/build/rootfs.
#   Configures all unpacked Debian base packages in dependency order and
#   finalizes the DPKG database (/var/lib/dpkg/status).
#
# Safety:
#   - Confirms execution environment is the isolated Debian builder.
#   - Verifies Stage 3A (unpacked rootfs) is present before running.
#   - Does NOT use --privileged or modify the Linux Mint host.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

# Path definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOTFS_DIR="${REPO_ROOT}/build/rootfs"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Stage 3B: Complete Rootfs Packages    ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Phase:           Stage 3B (debootstrap --second-stage)"
    echo "Target Location: ${ROOTFS_DIR}"
    echo ""
}

# 1. Environment Verification
verify_builder_environment() {
    if [[ ! -f /etc/os-release ]] || ! grep -qi 'ID=debian' /etc/os-release || [[ ! -d /workspace ]]; then
        echo -e "${COLOR_RED}Error: This script must be run INSIDE the isolated Debian builder container.${COLOR_RESET}" >&2
        echo ""
        echo "Please execute this script via:"
        echo "  ./scripts/enter-builder.sh /workspace/scripts/complete-rootfs.sh"
        exit 1
    fi

    if [[ ! -d "${ROOTFS_DIR}" ]] || [[ ! -d "${ROOTFS_DIR}/debootstrap" ]]; then
        echo -e "${COLOR_RED}Error: Stage 3A debootstrap directory not found at '${ROOTFS_DIR}/debootstrap'.${COLOR_RESET}" >&2
        echo ""
        echo "Please run Stage 3A first to download and unpack the packages:"
        echo "  /workspace/scripts/bootstrap-rootfs.sh"
        exit 1
    fi

    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Execution environment: Debian builder container ($(dpkg --print-architecture))"
    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Stage 3A unpacked files detected at: ${ROOTFS_DIR}"
    echo ""
}

# 2. Stage 3B Execution
run_second_stage() {
    echo -e "${COLOR_BOLD}--- Executing Stage 3B: In-Chroot Second Stage Configuration ---${COLOR_RESET}"
    echo "Running package configuration scripts inside the target rootfs..."
    echo ""

    # Run second-stage debootstrap inside the chroot
    chroot "${ROOTFS_DIR}" /bin/bash -c "export container=lxc; /debootstrap/debootstrap --second-stage"

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  Debian Trixie Root Filesystem Successfully Completed!${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
    echo "What just happened:"
    echo "  - Package maintainer scripts (*.postinst) configured base packages in dependency order."
    echo "  - DPKG status database was initialized at ${ROOTFS_DIR}/var/lib/dpkg/status."
    echo "  - Temporary installer files in ${ROOTFS_DIR}/debootstrap/ were cleaned up."
    echo ""
    echo "Next step: Inspect the completed root filesystem using:"
    echo "  /workspace/scripts/inspect-rootfs.sh"
    echo ""
}

main() {
    print_header
    verify_builder_environment
    run_second_stage
}

main "$@"
