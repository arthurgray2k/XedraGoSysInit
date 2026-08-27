#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Container Runtime Inspection Script
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Inspects the host machine for container engines (Podman / Docker)
#   and reports available capabilities for building the isolated Debian container.
#
# Safety:
#   - Read-only inspection script.
#   - Does NOT install or modify container runtimes or host settings.
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Container Runtime Inspection          ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Inspecting host system for available container runtimes..."
    echo ""
}

main() {
    print_header

    local runtime_found=0
    local preferred_runtime=""

    # 1. Check Podman
    if command -v podman >/dev/null 2>&1; then
        local podman_ver
        podman_ver="$(podman --version 2>/dev/null || echo 'unknown')"
        echo -e "  [ ${COLOR_GREEN}AVAILABLE${COLOR_RESET} ] ${COLOR_BOLD}Podman${COLOR_RESET} -> ${podman_ver}"
        runtime_found=1
        preferred_runtime="podman"
    else
        echo -e "  [ ${COLOR_RED}MISSING${COLOR_RESET}   ] ${COLOR_BOLD}Podman${COLOR_RESET} -> Command 'podman' not found in PATH"
    fi

    # 2. Check Docker
    if command -v docker >/dev/null 2>&1; then
        local docker_ver
        docker_ver="$(docker --version 2>/dev/null || echo 'unknown')"
        echo -e "  [ ${COLOR_GREEN}AVAILABLE${COLOR_RESET} ] ${COLOR_BOLD}Docker${COLOR_RESET} -> ${docker_ver}"
        runtime_found=1
        if [[ -z "${preferred_runtime}" ]]; then
            preferred_runtime="docker"
        fi
    else
        echo -e "  [ ${COLOR_RED}MISSING${COLOR_RESET}   ] ${COLOR_BOLD}Docker${COLOR_RESET} -> Command 'docker' not found in PATH"
    fi

    echo ""
    echo -e "${COLOR_BOLD}--- Runtime Assessment ---${COLOR_RESET}"
    if [[ "${preferred_runtime}" == "podman" ]]; then
        echo -e "  ${COLOR_GREEN}Recommendation:${COLOR_RESET} Use ${COLOR_BOLD}Podman${COLOR_RESET} (daemonless, rootless-friendly, standard on Linux)."
    elif [[ "${preferred_runtime}" == "docker" ]]; then
        echo -e "  ${COLOR_GREEN}Recommendation:${COLOR_RESET} Use ${COLOR_BOLD}Docker${COLOR_RESET}."
    else
        echo -e "  ${COLOR_RED}Status: No container engine detected.${COLOR_RESET}"
        echo "  Please install podman to proceed with the isolated build environment."
        exit 1
    fi
    echo ""
}

main "$@"
