#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Stage 9: Destroy 'xedra-lab' Test Virtual Machine
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Gracefully stops and undefines the ephemeral 'xedra-lab' test VM.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

VM_NAME="xedra-lab"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Destroy 'xedra-lab' Test VM           ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Domain: ${VM_NAME}"
    echo ""
}

destroy_lab_vm() {
    if ! virsh --connect qemu:///system dominfo "${VM_NAME}" >/dev/null 2>&1; then
        echo "Domain '${VM_NAME}' does not exist. Nothing to clean up."
        exit 0
    fi

    local state
    state="$(virsh --connect qemu:///system domstate "${VM_NAME}" 2>/dev/null || echo "shut off")"

    if [[ "${state}" == "running" || "${state}" == "paused" ]]; then
        echo "Stopping running domain '${VM_NAME}'..."
        virsh --connect qemu:///system destroy "${VM_NAME}" >/dev/null 2>&1 || true
    fi

    echo "Undefining domain '${VM_NAME}' and removing NVRAM variables..."
    virsh --connect qemu:///system undefine "${VM_NAME}" --nvram >/dev/null 2>&1 || true

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  'xedra-lab' VM Cleaned Up Successfully!             ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}======================================================${COLOR_RESET}"
    echo ""
}

main() {
    print_header
    destroy_lab_vm
}

main "$@"
