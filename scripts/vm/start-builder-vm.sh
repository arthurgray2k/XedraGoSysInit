#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Start 'xedra-builder' VM
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Powers on the 'xedra-builder' Debian 13 VM via virsh on qemu:///system.
# ==============================================================================

set -euo pipefail

readonly LIBVIRT_URI="qemu:///system"
readonly VM_NAME="xedra-builder"

if ! virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
    echo "Error: Virtual machine '${VM_NAME}' is not defined in libvirt." >&2
    echo "Create it first with: ./scripts/vm/create-builder-vm.sh <iso-path>" >&2
    exit 1
fi

state="$(virsh --connect "${LIBVIRT_URI}" domstate "${VM_NAME}" 2>/dev/null || echo 'unknown')"
if [[ "${state}" == "running" ]]; then
    echo "VM '${VM_NAME}' is already running."
else
    echo "Starting '${VM_NAME}'..."
    virsh --connect "${LIBVIRT_URI}" start "${VM_NAME}"
    echo "VM '${VM_NAME}' started successfully."
fi
