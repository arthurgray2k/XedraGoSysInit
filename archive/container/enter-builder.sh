#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Enter Isolated Debian Build Environment
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Launches an interactive bash session inside the isolated Debian Trixie
#   container with the Xedra repository mounted at /workspace.
#
# Security / Isolation:
#   - Only mounts the Xedra repository (~/XedraLinux).
#   - Does NOT mount /, /boot, /etc, /usr, or the entire /home.
#   - Runs rootless with default minimal container capabilities.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_RED="\033[31m"
readonly COLOR_CYAN="\033[36m"

# Path validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_NAME="xedra-builder:trixie"

# 1. Verify Podman availability
if ! command -v podman >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: Podman not found in PATH.${COLOR_RESET}" >&2
    exit 1
fi

# 2. Check if builder image exists
if ! podman image exists "${IMAGE_NAME}" 2>/dev/null && ! podman image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: Container image '${IMAGE_NAME}' not found.${COLOR_RESET}" >&2
    echo "Please build the image first using: ./scripts/build-builder-image.sh"
    exit 1
fi

echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}  Entering Xedra Isolated Debian Build Environment     ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
echo "Mounted Repository: ${REPO_ROOT} -> /workspace"
echo "Container Image:    ${IMAGE_NAME}"
echo "Type 'exit' to return to Linux Mint host."
echo ""

# 3. Launch container session
INTERACTIVE_FLAG=""
if [[ -t 0 && -t 1 ]]; then
    INTERACTIVE_FLAG="-it"
else
    INTERACTIVE_FLAG="-i"
fi

if [[ $# -gt 0 ]]; then
    exec podman run --rm ${INTERACTIVE_FLAG} \
        -v "${REPO_ROOT}:/workspace:rw" \
        -w "/workspace" \
        "${IMAGE_NAME}" "$@"
else
    exec podman run --rm ${INTERACTIVE_FLAG} \
        -v "${REPO_ROOT}:/workspace:rw" \
        -w "/workspace" \
        "${IMAGE_NAME}" /bin/bash
fi
