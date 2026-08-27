#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Build Isolated Debian Container Image
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Builds the 'xedra-builder:trixie' container image containing minimal
#   Debian Trixie build prerequisites using Podman.
#
# Safety:
#   - Operates strictly within user-space container storage.
#   - Does NOT install or modify host packages.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_CYAN="\033[36m"

# Path validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTAINERFILE="${REPO_ROOT}/container/Containerfile"
IMAGE_TAG="xedra-builder:trixie"

echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Build Isolated Debian Container       ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
echo "Repository Root: ${REPO_ROOT}"
echo "Containerfile:   ${CONTAINERFILE}"
echo "Target Image:    ${IMAGE_TAG}"
echo ""

# 1. Validate Containerfile existence
if [[ ! -f "${CONTAINERFILE}" ]]; then
    echo -e "${COLOR_RED}Error: Containerfile not found at '${CONTAINERFILE}'${COLOR_RESET}" >&2
    exit 1
fi

# 2. Verify Podman availability
if ! command -v podman >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: Podman is not installed on the host.${COLOR_RESET}" >&2
    exit 1
fi

echo -e "Using container engine: ${COLOR_BOLD}podman${COLOR_RESET}"
echo "Building image '${IMAGE_TAG}'..."
echo ""

# 3. Build container image safely using Podman
podman build \
    -t "${IMAGE_TAG}" \
    -f "${CONTAINERFILE}" \
    "${REPO_ROOT}"

echo ""
echo -e "${COLOR_GREEN}Success: Container image '${IMAGE_TAG}' built successfully.${COLOR_RESET}"
echo "You can inspect it with: podman images ${IMAGE_TAG}"
