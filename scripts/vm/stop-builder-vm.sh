#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Gracefully Stop 'xedra-builder' VM
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Sends a graceful ACPI shutdown signal to the 'xedra-builder' VM via virsh.
# ==============================================================================

set -euo pipefail

readonly LIBVIRT_URI="qemu:///system"
readonly VM_NAME="xedra-builder"

if ! virsh --connect "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
    echo "Error: Virtual machine '${VM_NAME}' is not defined in libvirt." >&2
    exit 1
fi

state="$(virsh --connect "${LIBVIRT_URI}" domstate "${VM_NAME}" 2>/dev/null || echo 'unknown')"
if [[ "${state}" != "running" ]]; then
    echo "VM '${VM_NAME}' is not running (Current State: ${state})."
else
    echo "Sending shutdown signal to '${VM_NAME}'..."
    virsh --connect "${LIBVIRT_URI}" shutdown "${VM_NAME}"
    echo "Shutdown signal sent."
fi
