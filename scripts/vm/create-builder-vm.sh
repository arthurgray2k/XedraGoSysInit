#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Create Authoritative Debian 13 'xedra-builder' VM
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Creates the 'xedra-builder' Debian 13 (Trixie) virtual machine using
#   virt-install and UEFI firmware on libvirt system instance (qemu:///system).
#
# Safety:
#   - Does NOT format, repartition, or modify any physical host disks.
#   - Creates a virtual disk solely inside the libvirt 'default' storage pool.
#   - Refuses to overwrite an existing 'xedra-builder' VM.
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
readonly VM_RAM_MB=4096
readonly VM_VCPUS=2
readonly VM_DISK_SIZE_GB=35
readonly STORAGE_POOL="default"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Create 'xedra-builder' Debian VM       ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "VM Name:          ${VM_NAME}"
    echo "vCPUs:            ${VM_VCPUS}"
    echo "RAM:              ${VM_RAM_MB} MB (4 GB)"
    echo "Virtual Disk:     ${VM_DISK_SIZE_GB} GB (Storage Pool: ${STORAGE_POOL})"
    echo "Firmware:         UEFI"
    echo "Network:          NAT (network=default)"
    echo "Hypervisor URI:   ${LIBVIRT_URI}"
    echo ""
}

validate_arguments() {
    local iso_path="${1:-}"

    if [[ -z "${iso_path}" ]]; then
        echo -e "${COLOR_RED}Error: Path to Debian 13 Trixie Netinst ISO must be provided as the first argument.${COLOR_RESET}" >&2
        echo ""
        echo "Usage:"
        echo "  $0 /path/to/debian-13-netinst-amd64.iso"
        echo ""
        exit 1
    fi

    if [[ ! -f "${iso_path}" || ! -r "${iso_path}" ]]; then
        echo -e "${COLOR_RED}Error: ISO file '${iso_path}' does not exist or is not readable.${COLOR_RESET}" >&2
        exit 1
    fi

    # Check if VM already exists in libvirt
    if virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Error: Virtual machine '${VM_NAME}' already exists in libvirt.${COLOR_RESET}" >&2
        echo "If you wish to recreate it, use:"
        echo "  ./scripts/vm/destroy-builder-vm.sh"
        exit 1
    fi
}

create_vm() {
    local iso_path="$1"

    echo -e "${COLOR_BOLD}--- Executing virt-install ---${COLOR_RESET}"
    echo "Command to run:"
    echo ""
    echo -e "  ${COLOR_CYAN}virt-install \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --connect \"${LIBVIRT_URI}\" \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --name \"${VM_NAME}\" \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --vcpus ${VM_VCPUS} \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --memory ${VM_RAM_MB} \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --disk pool=${STORAGE_POOL},size=${VM_DISK_SIZE_GB},format=qcow2,bus=virtio \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --cdrom \"${iso_path}\" \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --osinfo debian12 \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --boot uefi \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --network network=default,model=virtio \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --graphics spice,listen=none \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --video qxl \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --channel spicevmc \\${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}    --noautoconsole${COLOR_RESET}"
    echo ""

    virt-install \
        --connect "${LIBVIRT_URI}" \
        --name "${VM_NAME}" \
        --vcpus "${VM_VCPUS}" \
        --memory "${VM_RAM_MB}" \
        --disk pool="${STORAGE_POOL}",size="${VM_DISK_SIZE_GB}",format=qcow2,bus=virtio \
        --cdrom "${iso_path}" \
        --osinfo debian12 \
        --boot uefi \
        --network network=default,model=virtio \
        --graphics spice,listen=none \
        --video qxl \
        --channel spicevmc \
        --noautoconsole

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  '${VM_NAME}' VM Created and Started Successfully!    ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
    echo "Next steps to complete Debian installation:"
    echo "  1. Open Virtual Machine Manager GUI: virt-manager"
    echo "     (or run: virt-manager --connect qemu:///system --show-domain-console ${VM_NAME})"
    echo "  2. Complete the Debian 13 Trixie installer interactively."
    echo "  3. After first boot into Debian, run the post-install bootstrap:"
    echo "     scripts/vm/bootstrap-builder.sh"
    echo ""
}

main() {
    print_header
    validate_arguments "${1:-}"
    create_vm "$1"
}

main "$@"
