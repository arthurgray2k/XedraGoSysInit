#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 3A: Bootstrap Debian Trixie Rootfs (First Stage / Foreign)
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Downloads and extracts the minimal Debian 13 (Trixie) base packages into
#   /workspace/build/rootfs using 'debootstrap --foreign' inside the rootless
#   Podman builder container.
#
# Safety:
#   - Confirms execution environment is the isolated Debian builder.
#   - Refuses to overwrite an existing rootfs unless '--clean' is specified.
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

# Configuration parameters
readonly TARGET_RELEASE="trixie"
readonly TARGET_ARCH="amd64"
readonly DEBIAN_MIRROR="https://deb.debian.org/debian"

# Path definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build"
ROOTFS_DIR="${BUILD_DIR}/rootfs"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Stage 3A: Rootfs Download & Extract   ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Phase:               Stage 3A (debootstrap --foreign)"
    echo "Target Distribution: Debian 13 (${TARGET_RELEASE})"
    echo "Target Architecture: ${TARGET_ARCH}"
    echo "Debian Mirror:       ${DEBIAN_MIRROR}"
    echo "Target Location:     ${ROOTFS_DIR}"
    echo ""
}

# 1. Environment Verification
verify_builder_environment() {
    if [[ ! -f /etc/os-release ]] || ! grep -qi 'ID=debian' /etc/os-release || [[ ! -d /workspace ]]; then
        echo -e "${COLOR_RED}Error: This script must be run INSIDE the isolated Debian builder container.${COLOR_RESET}" >&2
        echo ""
        echo "Please execute this script via:"
        echo "  ./scripts/enter-builder.sh /workspace/scripts/bootstrap-rootfs.sh"
        exit 1
    fi

    if ! command -v debootstrap >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Error: 'debootstrap' command not found inside the builder environment.${COLOR_RESET}" >&2
        exit 1
    fi

    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Execution environment: Debian builder container ($(dpkg --print-architecture))"
    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] debootstrap utility: $(debootstrap --version 2>/dev/null || echo 'installed')"
}

# 2. Overwrite Safety Check
check_existing_rootfs() {
    local clean_flag="${1:-}"

    mkdir -p "${BUILD_DIR}"

    if [[ -d "${ROOTFS_DIR}" && -n "$(ls -A "${ROOTFS_DIR}" 2>/dev/null || true)" ]]; then
        if [[ "${clean_flag}" == "--clean" ]]; then
            echo -e "  [ ${COLOR_YELLOW}WARN${COLOR_RESET} ] Existing rootfs detected at '${ROOTFS_DIR}'."
            echo "  '--clean' option supplied: removing existing contents..."
            if [[ "${ROOTFS_DIR}" == *"/build/rootfs" && "${ROOTFS_DIR}" != "/" && "${ROOTFS_DIR}" != "/root" ]]; then
                rm -rf "${ROOTFS_DIR}"
                mkdir -p "${ROOTFS_DIR}"
            else
                echo -e "${COLOR_RED}Error: Refusing to delete safety-violating path: ${ROOTFS_DIR}${COLOR_RESET}" >&2
                exit 1
            fi
        else
            echo -e "${COLOR_RED}Error: Target rootfs directory '${ROOTFS_DIR}' already exists and is not empty.${COLOR_RESET}" >&2
            echo ""
            echo "To perform a clean rebuild, pass the '--clean' flag:"
            echo "  /workspace/scripts/bootstrap-rootfs.sh --clean"
            echo ""
            echo "Or remove it manually with:"
            echo "  rm -rf ${ROOTFS_DIR}"
            exit 1
        fi
    else
        mkdir -p "${ROOTFS_DIR}"
    fi

    echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] Target directory initialized: ${ROOTFS_DIR}"
    echo ""
}

# 3. Stage 3A Execution
run_foreign_bootstrap() {
    echo -e "${COLOR_BOLD}--- Executing Stage 3A: debootstrap --foreign ---${COLOR_RESET}"
    echo "Informing debootstrap of unprivileged container user namespace (container=lxc)..."
    export container=lxc

    echo "Running debootstrap with explicit parameters:"
    echo ""
    echo -e "  ${COLOR_CYAN}debootstrap \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --foreign \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --arch=${TARGET_ARCH} \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    ${TARGET_RELEASE} \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    ${ROOTFS_DIR} \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    ${DEBIAN_MIRROR}${COLOR_RESET}"
    echo ""

    # Execute first stage of debootstrap
    debootstrap \
        --foreign \
        --arch="${TARGET_ARCH}" \
        "${TARGET_RELEASE}" \
        "${ROOTFS_DIR}" \
        "${DEBIAN_MIRROR}"

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  Stage 3A Complete: Package Archives Unpacked!        ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
    echo "What just happened:"
    echo "  - Debian Trixie .deb archives were downloaded into ${ROOTFS_DIR}/var/cache/apt/archives/"
    echo "  - Package files were extracted into ${ROOTFS_DIR}/"
    echo "  - Second-stage scripts were copied to ${ROOTFS_DIR}/debootstrap/"
    echo ""
    echo "Next step: Run Stage 3B to complete package configuration:"
    echo "  /workspace/scripts/complete-rootfs.sh"
    echo ""
}

main() {
    print_header
    verify_builder_environment
    check_existing_rootfs "${1:-}"
    run_foreign_bootstrap
}

main "$@"
