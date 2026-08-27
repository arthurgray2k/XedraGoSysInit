#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Safely Destroy 'xedra-builder' VM
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Gracefully removes the 'xedra-builder' VM definition and its allocated
#   virtual disk file from libvirt.
#
# Safety:
#   - Strictly restricted to domain 'xedra-builder'.
#   - Requires confirmation or explicit '--force' flag.
#   - NEVER touches physical host disks, partitions, or other VMs (xedra-lab).
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_GREEN="\033[32m"

readonly LIBVIRT_URI="qemu:///system"
readonly VM_NAME="xedra-builder"

if ! virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
    echo "Virtual machine '${VM_NAME}' does not exist in libvirt. Nothing to destroy."
    exit 0
fi

force_flag="${1:-}"
if [[ "${force_flag}" != "--force" && "${force_flag}" != "-f" ]]; then
    echo -e "${COLOR_BOLD}${COLOR_RED}WARNING: You are about to destroy the virtual machine '${VM_NAME}' and delete its virtual disk.${COLOR_RESET}"
    echo "Host physical disks will NOT be touched."
    echo ""
    read -r -p "Are you sure you want to proceed? [y/N]: " confirmation
    if [[ "${confirmation}" != "y" && "${confirmation}" != "Y" ]]; then
        echo "Aborted by user."
        exit 0
    fi
fi

# Stop if running
state="$(virsh --connect "${LIBVIRT_URI}" domstate "${VM_NAME}" 2>/dev/null || echo 'unknown')"
if [[ "${state}" == "running" ]]; then
    echo "Force stopping '${VM_NAME}'..."
    virsh --connect "${LIBVIRT_URI}" destroy "${VM_NAME}" 2>/dev/null || true
fi

# Undefine domain with nvram and storage cleanup
echo "Undefining '${VM_NAME}' and deleting its virtual disk volume..."
virsh --connect "${LIBVIRT_URI}" undefine "${VM_NAME}" --nvram --remove-all-storage

echo -e "${COLOR_GREEN}Success: '${VM_NAME}' has been removed.${COLOR_RESET}"
