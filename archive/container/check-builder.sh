#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Validate Debian Build Container Environment
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Validates that the isolated Debian Trixie (Debian 13) build container
#   contains the expected minimal Debian tools and that the Xedra repository
#   is correctly mounted at /workspace.
#
# Usage:
#   - From Host:      ./scripts/check-builder.sh
#   - From Container: ./scripts/check-builder.sh
# ==============================================================================

set -euo pipefail

# ANSI color codes
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

# Path validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Function to run internal checks inside the container
run_container_checks() {
    local count_pass=0
    local count_fail=0

    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux - Debian Build Environment Validation   ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Environment: Isolated Debian Container (Debian 13 Trixie)"
    echo ""

    # 1. Debian Release (Trixie / Debian 13)
    echo -e "${COLOR_BOLD}--- Operating System & Architecture ---${COLOR_RESET}"
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        if [[ "${ID:-}" == "debian" && ("${VERSION_CODENAME:-}" == "trixie" || "${VERSION_ID:-}" == "13" || "${PRETTY_NAME:-}" =~ [Tt]rixie) ]]; then
            echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}Debian Version${COLOR_RESET} -> ${PRETTY_NAME} (Codename: ${VERSION_CODENAME:-trixie})"
            ((count_pass++)) || true
        else
            echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}Debian Version${COLOR_RESET} -> Expected Debian 13 (trixie), found: ${PRETTY_NAME:-unknown}"
            ((count_fail++)) || true
        fi
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}Debian Version${COLOR_RESET} -> /etc/os-release missing"
        ((count_fail++)) || true
    fi

    # 2. Architecture
    local arch
    arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
    if [[ "${arch}" == "amd64" ]]; then
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}Architecture${COLOR_RESET}   -> ${arch} (amd64 / x86_64)"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}Architecture${COLOR_RESET}   -> ${arch} (Expected amd64)"
        ((count_fail++)) || true
    fi

    # 3. Toolchain & Utilities
    echo ""
    echo -e "${COLOR_BOLD}--- Required Build Tools ---${COLOR_RESET}"

    # dpkg
    if command -v dpkg >/dev/null 2>&1; then
        local dpkg_v
        dpkg_v="$(dpkg --version | head -n1)"
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}dpkg${COLOR_RESET}           -> ${dpkg_v}"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}dpkg${COLOR_RESET}           -> dpkg not found"
        ((count_fail++)) || true
    fi

    # apt / apt-get
    if command -v apt-get >/dev/null 2>&1; then
        local apt_v
        apt_v="$(apt-get --version | head -n1)"
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}apt-get${COLOR_RESET}        -> ${apt_v}"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}apt-get${COLOR_RESET}        -> apt-get not found"
        ((count_fail++)) || true
    fi

    # git
    if command -v git >/dev/null 2>&1; then
        local git_v
        git_v="$(git --version)"
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}git${COLOR_RESET}            -> ${git_v}"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}git${COLOR_RESET}            -> git not found"
        ((count_fail++)) || true
    fi

    # debootstrap
    if command -v debootstrap >/dev/null 2>&1; then
        local deb_v
        deb_v="$(debootstrap --version 2>/dev/null || echo 'installed')"
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}debootstrap${COLOR_RESET}    -> ${deb_v}"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}debootstrap${COLOR_RESET}    -> debootstrap not found"
        ((count_fail++)) || true
    fi

    # 4. Workspace Mount Verification
    echo ""
    echo -e "${COLOR_BOLD}--- Workspace Mount Verification ---${COLOR_RESET}"
    if [[ -d "/workspace" && -f "/workspace/README.md" && -f "/workspace/LICENSE" ]]; then
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}/workspace Mount${COLOR_RESET} -> Successfully mounted Xedra repository"
        ((count_pass++)) || true
    else
        echo -e "  [ ${COLOR_RED}FAIL${COLOR_RESET} ] ${COLOR_BOLD}/workspace Mount${COLOR_RESET} -> /workspace does not contain expected Xedra files"
        ((count_fail++)) || true
    fi

    # 5. Resources inside Container
    echo ""
    echo -e "${COLOR_BOLD}--- Container Resources ---${COLOR_RESET}"
    if [[ -f /proc/meminfo ]]; then
        local mem_kb
        mem_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo || awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        local mem_gb="$(( mem_kb / 1024 / 1024 ))"
        echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}Available Memory${COLOR_RESET} -> ${mem_gb} GB"
        ((count_pass++)) || true
    fi

    local disk_avail_kb
    disk_avail_kb="$(df -k --output=avail /workspace | tail -n1 | tr -d ' ')"
    local disk_avail_gb="$(( disk_avail_kb / 1024 / 1024 ))"
    echo -e "  [ ${COLOR_GREEN}PASS${COLOR_RESET} ] ${COLOR_BOLD}Disk on /workspace${COLOR_RESET} -> ${disk_avail_gb} GB available"
    ((count_pass++)) || true

    # Summary
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Validation Summary:${COLOR_RESET}  ${COLOR_GREEN}Pass:${COLOR_RESET} ${count_pass}  |  ${COLOR_RED}Fail:${COLOR_RESET} ${count_fail}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo ""

    if [[ ${count_fail} -eq 0 ]]; then
        echo -e "${COLOR_GREEN}Status: Isolated Debian Build Environment is healthy and verified.${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}Status: Environment validation failed.${COLOR_RESET}"
        return 1
    fi
}

main() {
    # Check if we are running inside the container or on the host
    if [[ -f "/.dockerenv" || -f "/run/.containerenv" || ( -f "/etc/os-release" && $(grep -c 'ID=debian' /etc/os-release || true) -gt 0 && -d "/workspace" ) ]]; then
        run_container_checks
    else
        echo "Running check-builder.sh inside container via Podman..."
        "${REPO_ROOT}/scripts/enter-builder.sh" /workspace/scripts/check-builder.sh
    fi
}

main "$@"
