#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Inspect 'xedra-builder' VM Configuration & State
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Displays domain information, hardware resources, disks, and network status
#   for the 'xedra-builder' Debian 13 VM.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_CYAN="\033[36m"

readonly LIBVIRT_URI="qemu:///system"
readonly VM_NAME="xedra-builder"

echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - 'xedra-builder' VM Inspection          ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"

if ! virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Status: Virtual machine '${VM_NAME}' is not defined in libvirt.${COLOR_RESET}"
    exit 1
fi

echo -e "${COLOR_BOLD}--- Domain Summary ---${COLOR_RESET}"
virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" | sed 's/^/  /'

echo ""
echo -e "${COLOR_BOLD}--- Virtual Disks ---${COLOR_RESET}"
virsh --connect "${LIBVIRT_URI}" domblklist "${VM_NAME}" --details | sed 's/^/  /'

echo ""
echo -e "${COLOR_BOLD}--- Network Interfaces ---${COLOR_RESET}"
virsh --connect "${LIBVIRT_URI}" domiflist "${VM_NAME}" | sed 's/^/  /'

echo ""
echo -e "${COLOR_BOLD}--- IP Address (if running with guest agent / DHCP) ---${COLOR_RESET}"
virsh --connect "${LIBVIRT_URI}" domifaddr "${VM_NAME}" 2>/dev/null | sed 's/^/  /' || echo "  (Not active or IP not yet assigned)"
echo ""
