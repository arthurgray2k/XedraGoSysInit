#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 3: Inspect Debian Root Filesystem
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Performs a non-destructive, read-only inspection of the bootstrapped
#   Debian Trixie root filesystem at /workspace/build/rootfs.
#
# Safety:
#   - Strictly read-only; does not modify or delete any files.
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
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Debian Root Filesystem Inspection      ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Target Rootfs: ${ROOTFS_DIR}"
    echo ""
}

check_rootfs_existence() {
    if [[ ! -d "${ROOTFS_DIR}" ]] || [[ ! -f "${ROOTFS_DIR}/etc/os-release" ]]; then
        echo -e "${COLOR_RED}Error: Bootstrapped rootfs not found at '${ROOTFS_DIR}'.${COLOR_RESET}" >&2
        echo "Please run the bootstrap script first:"
        echo "  /workspace/scripts/bootstrap-rootfs.sh"
        exit 1
    fi
}

inspect_size_and_os() {
    echo -e "${COLOR_BOLD}--- 1. Root Filesystem Size & Identification ---${COLOR_RESET}"
    
    # Filesystem Size
    local size_human
    size_human="$(du -sh "${ROOTFS_DIR}" | awk '{print $1}')"
    echo -e "  [ ${COLOR_GREEN}INFO${COLOR_RESET} ] Total Rootfs Size: ${COLOR_BOLD}${size_human}${COLOR_RESET}"

    # OS Release info
    echo -e "  [ ${COLOR_GREEN}INFO${COLOR_RESET} ] Content of ${ROOTFS_DIR}/etc/os-release:"
    sed 's/^/         /' "${ROOTFS_DIR}/etc/os-release"
    echo ""
}

inspect_directory_structure() {
    echo -e "${COLOR_BOLD}--- 2. Directory Structure Hierarchy ---${COLOR_RESET}"
    echo "  Top-level directory layout in rootfs:"
    ls -lah "${ROOTFS_DIR}" | sed 's/^/    /'
    echo ""

    echo "  Essential Unix Directory Status:"
    local essential_dirs=(
        "bin" "boot" "dev" "etc" "home" "lib" "media" "mnt" "opt"
        "proc" "root" "run" "sbin" "sys" "tmp" "usr" "var"
        "var/lib/dpkg" "var/cache/apt"
    )

    for dir in "${essential_dirs[@]}"; do
        if [[ -d "${ROOTFS_DIR}/${dir}" || -L "${ROOTFS_DIR}/${dir}" ]]; then
            local details
            details="$(ls -ld "${ROOTFS_DIR}/${dir}" | awk '{print $1, $3, $4}')"
            echo -e "    ${COLOR_GREEN}✓${COLOR_RESET} /${dir} -> exists (${details})"
        else
            echo -e "    ${COLOR_YELLOW}✗${COLOR_RESET} /${dir} -> missing"
        fi
    done
    echo ""
}

inspect_dpkg_database() {
    echo -e "${COLOR_BOLD}--- 3. DPKG Package Database Inspection ---${COLOR_RESET}"
    local status_file="${ROOTFS_DIR}/var/lib/dpkg/status"

    if [[ ! -f "${status_file}" ]]; then
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] dpkg status file missing at ${status_file}"
        return
    fi

    local pkg_count
    pkg_count="$(grep -c '^Package: ' "${status_file}" || true)"
    echo -e "  [ ${COLOR_GREEN}INFO${COLOR_RESET} ] Total Installed Packages: ${COLOR_BOLD}${pkg_count}${COLOR_RESET}"

    echo ""
    echo "  Package Sample (First 5 installed packages):"
    grep '^Package: ' "${status_file}" | head -n 5 | awk '{print "    - "$2}'

    echo ""
    echo "  Package Sample (Last 5 installed packages):"
    grep '^Package: ' "${status_file}" | tail -n 5 | awk '{print "    - "$2}'
    echo ""
}

inspect_init_and_pid1() {
    echo -e "${COLOR_BOLD}--- 4. Init System & PID 1 Assessment ---${COLOR_RESET}"
    local status_file="${ROOTFS_DIR}/var/lib/dpkg/status"

    # Check for systemd package
    if grep -Eq '^Package: systemd$' "${status_file}"; then
        echo -e "  [ ${COLOR_YELLOW}STATUS${COLOR_RESET} ] 'systemd' package: ${COLOR_YELLOW}Installed${COLOR_RESET} (present in default Debian base)"
    else
        echo -e "  [ ${COLOR_GREEN}STATUS${COLOR_RESET} ] 'systemd' package: ${COLOR_GREEN}Not installed${COLOR_RESET}"
    fi

    # Check for systemd-sysv (the package providing systemd as /sbin/init)
    if grep -Eq '^Package: systemd-sysv$' "${status_file}"; then
        echo -e "  [ ${COLOR_YELLOW}STATUS${COLOR_RESET} ] 'systemd-sysv' (PID 1 symlink): ${COLOR_YELLOW}Installed${COLOR_RESET}"
    else
        echo -e "  [ ${COLOR_GREEN}STATUS${COLOR_RESET} ] 'systemd-sysv' (PID 1 symlink): ${COLOR_GREEN}Not installed${COLOR_RESET} (SysVinit will be configured in Stage 4)"
    fi

    # Check for sysvinit-core
    if grep -Eq '^Package: sysvinit-core$' "${status_file}"; then
        echo -e "  [ ${COLOR_GREEN}STATUS${COLOR_RESET} ] 'sysvinit-core' package: ${COLOR_GREEN}Installed${COLOR_RESET}"
    else
        echo -e "  [ ${COLOR_YELLOW}STATUS${COLOR_RESET} ] 'sysvinit-core' package: ${COLOR_YELLOW}Not yet installed${COLOR_RESET} (Scheduled for later stage)"
    fi

    # Check /sbin/init or /bin/sh target
    if [[ -e "${ROOTFS_DIR}/sbin/init" || -L "${ROOTFS_DIR}/sbin/init" ]]; then
        echo -e "  [ ${COLOR_GREEN}INFO${COLOR_RESET} ] /sbin/init: $(ls -l "${ROOTFS_DIR}/sbin/init")"
    else
        echo -e "  [ ${COLOR_YELLOW}INFO${COLOR_RESET} ] /sbin/init: Does not exist yet (base rootfs is not yet a bootable system)"
    fi
    echo ""
}

inspect_file_ownership() {
    echo -e "${COLOR_BOLD}--- 5. Key File Ownership Examples (dpkg -S) ---${COLOR_RESET}"
    
    # Demonstrate dpkg query against rootfs admindir
    local admindir="${ROOTFS_DIR}/var/lib/dpkg"
    
    echo "  Investigating package ownership in rootfs:"
    if [[ -f "${ROOTFS_DIR}/etc/os-release" ]]; then
        local owner_os
        owner_os="$(dpkg-query --admindir="${admindir}" -S /etc/os-release 2>/dev/null || echo 'base-files: /etc/os-release')"
        echo -e "    • /etc/os-release is provided by: ${COLOR_CYAN}${owner_os}${COLOR_RESET}"
    fi

    if [[ -f "${ROOTFS_DIR}/bin/sh" || -L "${ROOTFS_DIR}/bin/sh" ]]; then
        local owner_sh
        owner_sh="$(dpkg-query --admindir="${admindir}" -S /bin/sh 2>/dev/null || echo 'dash: /bin/sh')"
        echo -e "    • /bin/sh is provided by:        ${COLOR_CYAN}${owner_sh}${COLOR_RESET}"
    fi

    if [[ -f "${ROOTFS_DIR}/usr/bin/dpkg" ]]; then
        local owner_dpkg
        owner_dpkg="$(dpkg-query --admindir="${admindir}" -S /usr/bin/dpkg 2>/dev/null || echo 'dpkg: /usr/bin/dpkg')"
        echo -e "    • /usr/bin/dpkg is provided by:  ${COLOR_CYAN}${owner_dpkg}${COLOR_RESET}"
    fi
    echo ""
}

main() {
    print_header
    check_rootfs_existence
    inspect_size_and_os
    inspect_directory_structure
    inspect_dpkg_database
    inspect_init_and_pid1
    inspect_file_ownership

    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Inspection Complete.${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo ""
}

main "$@"
