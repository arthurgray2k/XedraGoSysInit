#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Check Host Readiness for 'xedra-builder' VM
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Validates that the host hypervisor (libvirt/QEMU/KVM),
#   storage pool, and UEFI firmware are ready to instantiate the
#   authoritative 'xedra-builder' Debian 13 VM.
#
# Safety:
#   - Strictly read-only inspection script.
#   - Does NOT format, repartition, or modify any host disk or libvirt domain.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

readonly LIBVIRT_URI="qemu:///system"
readonly VM_NAME="xedra-builder"
readonly STORAGE_POOL="default"
readonly REQUIRED_FREE_GB=35

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Builder VM Host Readiness Inspection   ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Hypervisor URI:   ${LIBVIRT_URI}"
    echo "Target VM Name:   ${VM_NAME}"
    echo "Storage Pool:     ${STORAGE_POOL}"
    echo ""
}

# 1. Check libvirt connection
check_hypervisor() {
    echo -e "${COLOR_BOLD}--- 1. Hypervisor & Tooling ---${COLOR_RESET}"
    if ! command -v virsh >/dev/null 2>&1; then
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] 'virsh' CLI command not found."
        exit 1
    fi
    if ! command -v virt-install >/dev/null 2>&1; then
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] 'virt-install' command not found."
        exit 1
    fi

    if virsh --connect "${LIBVIRT_URI}" uri >/dev/null 2>&1; then
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] libvirt system connection active (${LIBVIRT_URI})"
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] Cannot connect to libvirt at ${LIBVIRT_URI}"
        exit 1
    fi
}

# 2. Check if VM already exists
check_existing_vm() {
    echo ""
    echo -e "${COLOR_BOLD}--- 2. Virtual Machine Status ---${COLOR_RESET}"
    if virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
        local state
        state="$(virsh --connect "${LIBVIRT_URI}" domstate "${VM_NAME}" 2>/dev/null || echo 'unknown')"
        echo -e "  [ ${COLOR_YELLOW}EXISTS${COLOR_RESET} ] VM '${VM_NAME}' is already defined in libvirt (State: ${state})"
    else
        echo -e "  [ ${COLOR_GREEN}OK${COLOR_RESET} ] VM '${VM_NAME}' is not yet defined (ready to create)"
    fi
}

# 3. Check storage pool
check_storage_pool() {
    echo ""
    echo -e "${COLOR_BOLD}--- 3. Storage Pool Capacity ---${COLOR_RESET}"
    if ! virsh --connect "${LIBVIRT_URI}" pool-info "${STORAGE_POOL}" >/dev/null 2>&1; then
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] Storage pool '${STORAGE_POOL}' not found in libvirt."
        echo "  Available pools:"
        virsh --connect "${LIBVIRT_URI}" pool-list --all
        exit 1
    fi

    local avail_bytes avail_gb
    avail_bytes="$(virsh --connect "${LIBVIRT_URI}" pool-dumpxml "${STORAGE_POOL}" | grep -o '<available[^>]*>[0-9]*' | grep -o '[0-9]*' || true)"
    if [[ -n "${avail_bytes}" && "${avail_bytes}" -gt 0 ]]; then
        avail_gb="$(( avail_bytes / 1024 / 1024 / 1024 ))"
        if [[ "${avail_gb}" -ge "${REQUIRED_FREE_GB}" ]]; then
            echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] Pool '${STORAGE_POOL}': ${avail_gb} GiB available (Required: ${REQUIRED_FREE_GB} GiB)"
        else
            echo -e "  [ ${COLOR_YELLOW}WARN${COLOR_RESET} ] Pool '${STORAGE_POOL}': ${avail_gb} GiB available (Recommended: ${REQUIRED_FREE_GB}+ GiB)"
        fi
    else
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] Storage pool '${STORAGE_POOL}' is active."
    fi
}

# 4. Check UEFI firmware
check_uefi_firmware() {
    echo ""
    echo -e "${COLOR_BOLD}--- 4. UEFI Firmware Support ---${COLOR_RESET}"
    if [[ -f /usr/share/OVMF/OVMF_CODE_4M.fd || -f /usr/share/OVMF/OVMF_CODE.fd || -f /usr/share/ovmf/OVMF.fd || -d /usr/share/OVMF ]]; then
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] OVMF UEFI firmware files detected on host"
    else
        echo -e "  [ ${COLOR_YELLOW}WARN${COLOR_RESET} ] Standard OVMF paths not found in /usr/share/OVMF. (libvirt may manage firmware automatically)"
    fi
}

# 5. Check optional ISO argument
check_iso_argument() {
    local iso_path="${1:-}"
    echo ""
    echo -e "${COLOR_BOLD}--- 5. Installation ISO File ---${COLOR_RESET}"
    if [[ -n "${iso_path}" ]]; then
        if [[ -f "${iso_path}" && -r "${iso_path}" ]]; then
            local iso_size
            iso_size="$(du -h "${iso_path}" | awk '{print $1}')"
            echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] Specified ISO exists: ${iso_path} (${iso_size})"
        else
            echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] Specified ISO path '${iso_path}' is inaccessible or does not exist."
        fi
    else
        echo -e "  [ ${COLOR_YELLOW}INFO${COLOR_RESET} ] No ISO path passed as argument. Pass ISO path to verify:"
        echo "         ./scripts/vm/check-builder-vm-host.sh /path/to/debian-13-netinst.iso"
    fi
}

main() {
    print_header
    check_hypervisor
    check_existing_vm
    check_storage_pool
    check_uefi_firmware
    check_iso_argument "${1:-}"

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Host Inspection Complete.${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo ""
}

main "$@"
