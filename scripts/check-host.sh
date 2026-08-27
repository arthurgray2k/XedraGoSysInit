#!/usr/bin/env bash
# ==============================================================================
# Xedra Linux - Host & Build Environment Validation Script
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Purpose:
#   Inspects the Linux Mint development host to ensure all prerequisite
#   tools and virtualization capabilities needed for Xedra development and
#   testing are understood and verified.
#
# Safety:
#   - Read-only inspection script.
#   - Does NOT install, remove, or modify any system files or settings.
# ==============================================================================

set -euo pipefail

# ANSI Color codes for clean, human-readable terminal output
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_RED="\033[31m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_CYAN="\033[36m"

# Counters for summary report
COUNT_AVAILABLE=0
COUNT_MISSING=0
COUNT_NOT_REQUIRED=0

print_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  Xedra Linux 0.1 - Host Environment Inspection       ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo "Inspecting host system configuration, virtualization, and build prerequisites..."
    echo ""
}

# Helper to print standardized status tags
report_available() {
    local item="$1"
    local details="$2"
    echo -e "  [ ${COLOR_GREEN}AVAILABLE${COLOR_RESET}        ] ${COLOR_BOLD}${item}${COLOR_RESET} -> ${details}"
    ((COUNT_AVAILABLE++)) || true
}

report_missing() {
    local item="$1"
    local details="$2"
    echo -e "  [ ${COLOR_RED}MISSING${COLOR_RESET}          ] ${COLOR_BOLD}${item}${COLOR_RESET} -> ${details}"
    ((COUNT_MISSING++)) || true
}

report_not_required() {
    local item="$1"
    local details="$2"
    echo -e "  [ ${COLOR_YELLOW}NOT REQUIRED YET${COLOR_RESET} ] ${COLOR_BOLD}${item}${COLOR_RESET} -> ${details}"
    ((COUNT_NOT_REQUIRED++)) || true
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${COLOR_BOLD}--- ${title} ---${COLOR_RESET}"
}

# ------------------------------------------------------------------------------
# 1. Host Operating System & Architecture
# ------------------------------------------------------------------------------
check_host_os_and_arch() {
    print_section "Host System & Architecture"

    # OS Identification
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        report_available "Host OS" "${PRETTY_NAME:-Linux} (ID: ${ID:-unknown}, Base: ${ID_LIKE:-none})"
    else
        report_missing "Host OS" "Unable to locate /etc/os-release"
    fi

    # CPU Architecture
    local arch
    arch="$(uname -m)"
    if [[ "${arch}" == "x86_64" ]]; then
        report_available "Host Architecture" "${arch} (amd64 compatible)"
    else
        report_missing "Host Architecture" "Detected ${arch} (Xedra 0.1 requires x86_64/amd64)"
    fi

    # Kernel Version
    report_available "Host Kernel" "$(uname -r)"
}

# ------------------------------------------------------------------------------
# 2. Hardware Virtualization & KVM
# ------------------------------------------------------------------------------
check_virtualization() {
    print_section "Hardware Virtualization & KVM"

    # CPU Virtualization Extensions (Intel VMX or AMD SVM)
    if [[ -f /proc/cpuinfo ]]; then
        if grep -Eq '(vmx|svm)' /proc/cpuinfo; then
            local flags
            flags="$(grep -E -m1 '(vmx|svm)' /proc/cpuinfo | grep -o -E '(vmx|svm)')"
            report_available "CPU Virtualization" "Hardware support detected (${flags^^})"
        else
            report_missing "CPU Virtualization" "Neither Intel VMX nor AMD SVM found in /proc/cpuinfo"
        fi
    else
        report_missing "CPU Virtualization" "/proc/cpuinfo is inaccessible"
    fi

    # /dev/kvm Device Node and Permissions
    if [[ -e /dev/kvm ]]; then
        if [[ -r /dev/kvm && -w /dev/kvm ]]; then
            report_available "/dev/kvm" "Device exists and is accessible with read/write permissions"
        else
            report_missing "/dev/kvm" "Device exists but lacks RW permissions for current user (check 'kvm' group membership)"
        fi
    else
        report_missing "/dev/kvm" "/dev/kvm does not exist (KVM module might not be loaded or hardware disabled in BIOS)"
    fi

    # KVM Kernel Module
    local kvm_mod
    kvm_mod="$(lsmod 2>/dev/null | awk '$1 ~ /^(kvm_intel|kvm_amd)$/ {print $1}' | head -n1 || true)"
    if [[ -n "${kvm_mod}" ]]; then
        report_available "KVM Kernel Module" "Loaded (${kvm_mod})"
    elif lsmod 2>/dev/null | awk '$1 == "kvm" {found=1} END {exit !found}'; then
        report_available "KVM Kernel Module" "Generic kvm module loaded"
    elif [[ -e /dev/kvm ]]; then
        report_available "KVM Kernel Module" "KVM active via kernel device (/dev/kvm)"
    else
        report_missing "KVM Kernel Module" "No kvm module found loaded in kernel"
    fi
}

# ------------------------------------------------------------------------------
# 3. Virtual Machine Management (QEMU / libvirt / virt-manager)
# ------------------------------------------------------------------------------
check_vm_stack() {
    print_section "Virtual Machine Stack (xedra-lab VM)"

    # QEMU System Emulator
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
        local qemu_ver
        qemu_ver="$(qemu-system-x86_64 --version | head -n1)"
        report_available "QEMU (x86_64)" "${qemu_ver}"
    else
        report_missing "QEMU (x86_64)" "qemu-system-x86_64 binary not found in PATH"
    fi

    # libvirt / virsh command
    if command -v virsh >/dev/null 2>&1; then
        local virsh_ver
        virsh_ver="$(virsh --version 2>/dev/null || echo 'installed')"
        report_available "virsh" "libvirt CLI available (v${virsh_ver})"
        
        # Test connection to libvirt daemon
        if virsh uri >/dev/null 2>&1; then
            report_available "libvirt daemon" "Active connection to $(virsh uri 2>/dev/null)"
        else
            report_missing "libvirt daemon" "Cannot connect to hypervisor daemon via default URI"
        fi
    else
        report_missing "virsh" "virsh command not found in PATH"
        report_missing "libvirt daemon" "virsh not available to verify libvirt"
    fi

    # virt-manager GUI
    if command -v virt-manager >/dev/null 2>&1; then
        report_available "virt-manager" "Graphical VM manager found ($(command -v virt-manager))"
    else
        report_missing "virt-manager" "virt-manager not found in PATH"
    fi
}

# ------------------------------------------------------------------------------
# 4. Host Core Tools & Packaging Utilities
# ------------------------------------------------------------------------------
check_host_tools() {
    print_section "Host Core Tools"

    # Git
    if command -v git >/dev/null 2>&1; then
        report_available "git" "$(git --version)"
    else
        report_missing "git" "git binary not found in PATH"
    fi

    # APT on host
    if command -v apt >/dev/null 2>&1; then
        report_available "apt" "Host APT package manager available"
    else
        report_missing "apt" "apt not found"
    fi

    # DPKG on host
    if command -v dpkg >/dev/null 2>&1; then
        report_available "dpkg" "Host DPKG available ($(dpkg --version | head -n1))"
    else
        report_missing "dpkg" "dpkg not found"
    fi
}

# ------------------------------------------------------------------------------
# 5. Distro Construction Tools (Distinguishing Active vs Future Needs)
# ------------------------------------------------------------------------------
check_distro_build_tools() {
    print_section "Debian Distro Build Utilities"

    # debootstrap
    if command -v debootstrap >/dev/null 2>&1; then
        report_available "debootstrap" "Installed on host ($(command -v debootstrap))"
    else
        report_not_required "debootstrap" "Not installed on Mint host. Will be installed inside the isolated Debian build environment or host when bootstrapping base rootfs."
    fi

    # live-build
    if command -v lb >/dev/null 2>&1; then
        report_available "live-build (lb)" "Installed on host ($(command -v lb))"
    else
        report_not_required "live-build (lb)" "Not installed on Mint host. Live-build will execute inside the isolated Debian build environment to prevent host contamination."
    fi
}

# ------------------------------------------------------------------------------
# 6. System Resources (RAM & Storage)
# ------------------------------------------------------------------------------
check_resources() {
    print_section "System Resources"

    # Memory Check
    if [[ -f /proc/meminfo ]]; then
        local mem_total_kb mem_avail_kb mem_total_gb mem_avail_gb
        mem_total_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        mem_avail_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
        mem_total_gb="$(( mem_total_kb / 1024 / 1024 ))"
        mem_avail_gb="$(( mem_avail_kb / 1024 / 1024 ))"

        if [[ ${mem_total_gb} -ge 2 ]]; then
            report_available "Host Memory (RAM)" "Total: ${mem_total_gb} GB, Available: ${mem_avail_gb} GB (Adequate for build & 2GB xedra-lab VM)"
        else
            report_missing "Host Memory (RAM)" "Total: ${mem_total_gb} GB (At least 2 GB recommended for testing)"
        fi
    else
        report_missing "Host Memory (RAM)" "Unable to read /proc/meminfo"
    fi

    # Disk Space Check
    local script_target_dir
    script_target_dir="$(pwd)"
    local free_space_kb free_space_gb
    free_space_kb="$(df -k --output=avail "${script_target_dir}" | tail -n1 | tr -d ' ')"
    free_space_gb="$(( free_space_kb / 1024 / 1024 ))"

    if [[ ${free_space_gb} -ge 8 ]]; then
        report_available "Disk Space" "${free_space_gb} GB available on $(df --output=target "${script_target_dir}" | tail -n1) (Sufficient for Debian rootfs & live image generation)"
    elif [[ ${free_space_gb} -ge 4 ]]; then
        report_available "Disk Space" "${free_space_gb} GB available (Sufficient for minimal build, 8+ GB recommended)"
    else
        report_missing "Disk Space" "${free_space_gb} GB available (Low disk space; building ISOs may fail if storage runs out)"
    fi
}

# ------------------------------------------------------------------------------
# 7. Summary & Next Steps
# ------------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Summary Results:${COLOR_RESET}"
    echo -e "    ${COLOR_GREEN}Available:${COLOR_RESET}        ${COUNT_AVAILABLE}"
    echo -e "    ${COLOR_RED}Missing:${COLOR_RESET}          ${COUNT_MISSING}"
    echo -e "    ${COLOR_YELLOW}Not Required Yet:${COLOR_RESET} ${COUNT_NOT_REQUIRED}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================${COLOR_RESET}"
    echo ""

    if [[ ${COUNT_MISSING} -eq 0 ]]; then
        echo -e "${COLOR_GREEN}Status: Host is ready for setting up the isolated Debian build environment.${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}Status: Please review missing items above before proceeding with VM testing or builds.${COLOR_RESET}"
    fi
    echo ""
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
main() {
    print_header
    check_host_os_and_arch
    check_virtualization
    check_vm_stack
    check_host_tools
    check_distro_build_tools
    check_resources
    print_summary
}

main "$@"
