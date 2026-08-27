#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 9: Create and Boot 'xedra-lab' Test Virtual Machine
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Creates and launches an ephemeral, UEFI-enabled test virtual machine
#   ('xedra-lab') attached to the compiled Xedra 0.4.3 Live ISO image
#   to test live boot, SysVinit PID 1, and the Fluxbox desktop.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

VM_NAME="xedra-lab"
RAM_MB=2048
VCPUS=2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ISO="${REPO_ROOT}/output/xedra-0.4.3-amd64.iso"
ISO_PATH="${1:-${DEFAULT_ISO}}"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Launch 'xedra-lab' Test VM (v0.4.3)   ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "VM Name:   ${VM_NAME}"
    echo "RAM:       ${RAM_MB} MB"
    echo "vCPUs:     ${VCPUS}"
    echo "Boot ISO:  ${ISO_PATH}"
    echo ""
}

verify_environment() {
    if ! command -v virsh >/dev/null 2>&1 || ! command -v virt-install >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Error: libvirt / virt-install tools not found on host.${COLOR_RESET}" >&2
        exit 1
    fi

    if [[ ! -f "${ISO_PATH}" ]]; then
        echo -e "${COLOR_RED}Error: Xedra Live ISO not found at '${ISO_PATH}'.${COLOR_RESET}" >&2
        echo "Please copy the ISO from xedra-builder to the host:"
        echo "  mkdir -p ${REPO_ROOT}/output"
        echo "  scp builder@192.168.122.180:~/XedraGoSysInit/output/xedra-0.4.3-amd64-gosysvinit.iso ${REPO_ROOT}/output/"
        echo "  (or for minimal: scp builder@192.168.122.180:~/XedraGoSysInit/output/xedra-0.4.3-minimal-amd64-gosysvinit.iso ${REPO_ROOT}/output/)"
        exit 1
    fi

    # Set read permissions for libvirt-qemu access if writable
    chmod 644 "${ISO_PATH}" 2>/dev/null || true
}

check_existing_vm() {
    if virsh --connect qemu:///system dominfo "${VM_NAME}" >/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}Warning: '${VM_NAME}' already exists.${COLOR_RESET}"
        echo "Destroying previous instance before creating a fresh test VM..."
        virsh --connect qemu:///system destroy "${VM_NAME}" >/dev/null 2>&1 || true
        virsh --connect qemu:///system undefine "${VM_NAME}" --nvram --remove-all-storage >/dev/null 2>&1 || \
        virsh --connect qemu:///system undefine "${VM_NAME}" --nvram >/dev/null 2>&1 || true
    fi
}

launch_vm() {
    echo -e "${COLOR_BOLD}--- Launching 'xedra-lab' with UEFI Firmware & 20GB Target Disk ---${COLOR_RESET}"
    
    # Launch ephemeral UEFI VM with 20GB target hard drive and ISO boot media
    virt-install \
        --connect qemu:///system \
        --name "${VM_NAME}" \
        --ram "${RAM_MB}" \
        --vcpus "${VCPUS}" \
        --osinfo generic \
        --disk pool=default,size=20,format=qcow2,bus=virtio \
        --cdrom "${ISO_PATH}" \
        --boot uefi \
        --network network=default,model=virtio \
        --graphics spice \
        --video qxl \
        --channel spicevmc \
        --events on_reboot=restart,on_poweroff=destroy,on_crash=restart \
        --noautoconsole

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  'xedra-lab' VM is Now Running!                      ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
    echo "To view the graphical display in real-time:"
    echo "  virt-manager"
    echo "  (or: virt-viewer --connect qemu:///system xedra-lab &)"
    echo ""
}

main() {
    print_header
    verify_environment
    check_existing_vm
    launch_vm
}

main "$@"
