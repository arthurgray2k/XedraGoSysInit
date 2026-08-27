#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 3: Educational chroot into Debian Root Filesystem
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Enters the bootstrapped root filesystem (/workspace/build/rootfs) via chroot
#   for educational inspection and command testing.
#
# Educational Note:
#   chroot (Change Root) alters the apparent root directory for the current
#   process and its children. It does NOT:
#     - Boot a Linux kernel (it uses the host/container kernel).
#     - Start an init system (PID 1).
#     - Provide hardware virtualization or a virtual machine.
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
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Educational chroot into Rootfs        ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Target Rootfs: ${ROOTFS_DIR}"
    echo ""
}

# 1. Environment Verification
verify_environment() {
    if [[ ! -d "${ROOTFS_DIR}" ]] || [[ ! -f "${ROOTFS_DIR}/etc/os-release" ]]; then
        echo -e "${COLOR_RED}Error: Bootstrapped rootfs not found at '${ROOTFS_DIR}'.${COLOR_RESET}" >&2
        echo "Please run /workspace/scripts/bootstrap-rootfs.sh first."
        exit 1
    fi

    # Verify chroot command
    if ! command -v chroot >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Error: 'chroot' command not found.${COLOR_RESET}" >&2
        exit 1
    fi
}

print_educational_notice() {
    echo -e "${COLOR_BOLD}--- What chroot is (and is NOT) ---${COLOR_RESET}"
    echo "  1. What chroot DOES:"
    echo "     - Resets the filesystem root '/' to ${ROOTFS_DIR} for the shell."
    echo "     - Uses the binaries, libraries (/lib, /usr/lib), and configs (/etc) inside the rootfs."
    echo ""
    echo "  2. What chroot DOES NOT do:"
    echo "     - Does NOT boot a kernel (it shares the running Linux kernel)."
    echo "     - Does NOT start an init system or daemon management (PID 1)."
    echo "     - Does NOT create a VM or isolate hardware."
    echo ""
    echo "Type 'exit' to leave the chroot."
    echo ""
}

cleanup_mounts() {
    local target="$1"
    # Unmount in reverse order if mounted
    if mountpoint -q "${target}/dev/pts" 2>/dev/null; then
        umount "${target}/dev/pts" 2>/dev/null || true
    fi
    if mountpoint -q "${target}/dev" 2>/dev/null; then
        umount "${target}/dev" 2>/dev/null || true
    fi
    if mountpoint -q "${target}/proc" 2>/dev/null; then
        umount "${target}/proc" 2>/dev/null || true
    fi
    if mountpoint -q "${target}/sys" 2>/dev/null; then
        umount "${target}/sys" 2>/dev/null || true
    fi
}

main() {
    print_header
    verify_environment
    print_educational_notice

    local mount_pseudo=0
    if [[ "${1:-}" == "--mount" || "${1:-}" == "-m" ]]; then
        mount_pseudo=1
    fi

    if [[ ${mount_pseudo} -eq 1 ]]; then
        echo "Mounting pseudo-filesystems (/proc, /sys, /dev)..."
        mkdir -p "${ROOTFS_DIR}/proc" "${ROOTFS_DIR}/sys" "${ROOTFS_DIR}/dev"
        mount -t proc proc "${ROOTFS_DIR}/proc" 2>/dev/null || true
        mount -t sysfs sysfs "${ROOTFS_DIR}/sys" 2>/dev/null || true
        mount --bind /dev "${ROOTFS_DIR}/dev" 2>/dev/null || true

        # Trap cleanup on exit
        trap 'cleanup_mounts "${ROOTFS_DIR}"' EXIT INT TERM
    fi

    # Set custom prompt and execute chroot shell
    echo -e "${COLOR_GREEN}Entering chroot session...${COLOR_RESET}"
    echo ""

    if [[ $# -gt 0 && "${1:-}" != "--mount" && "${1:-}" != "-m" ]]; then
        # Execute specific command in chroot
        chroot "${ROOTFS_DIR}" "$@"
    else
        # Interactive chroot shell with distinct prompt
        env -i \
            HOME=/root \
            TERM="${TERM:-xterm}" \
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
            PS1="\[\033[1;33m\][XEDRA-ROOTFS]\[\033[0m\] \u@builder:\w# " \
            chroot "${ROOTFS_DIR}" /bin/bash --norc -i
    fi

    echo ""
    echo -e "${COLOR_GREEN}Exited chroot session.${COLOR_RESET}"
}

main "$@"
