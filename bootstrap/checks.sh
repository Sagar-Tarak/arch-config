#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_CHECKS_SH_INCLUDED:-}" ]]; then
    return 0
fi
_CHECKS_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Pre-flight Validation Library
# File: bootstrap/checks.sh
# Purpose: Reusable validation functions that gate the installer from running
#          in an unsupported or unprepared environment. Every function returns
#          a status code — none call exit() so callers decide how to handle
#          failures (abort, warn, or continue).
# Dependencies: lib/logger.sh, bootstrap/environment.sh
# Public API:
#   checks::check_arch              - Verifies the OS is Arch Linux
#   checks::check_internet          - Verifies internet connectivity
#   checks::check_disk_space        - Verifies minimum free disk space (GiB)
#   checks::check_ram               - Verifies minimum available RAM (MiB)
#   checks::check_root              - Verifies the script is NOT running as root
#   checks::check_supported_shell   - Verifies the user shell is supported
#   checks::check_required_commands - Verifies a list of commands exist in PATH
#   checks::check_project_structure - Verifies expected project directories exist
#   checks::run_all                 - Runs all checks; logs each result
# Usage Example:
#   source bootstrap/loader.sh && loader::load_libs
#   source bootstrap/environment.sh
#   source bootstrap/checks.sh
#   checks::check_arch || { log::fatal "Arch Linux required"; return 1; }
#   checks::run_all
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Verifies the current OS is Arch Linux.
# @noargs
# @exit 0 if Arch Linux, 1 otherwise.
checks::check_arch() {
    if ! environment::is_arch_linux; then
        log::error "This framework requires Arch Linux. Detected OS is not Arch." "CHECKS"
        return 1
    fi
    log::debug "OS check passed: Arch Linux confirmed." "CHECKS"
    return 0
}

# @description Verifies internet connectivity is available.
# @noargs
# @exit 0 if reachable, 1 otherwise.
checks::check_internet() {
    if ! environment::has_internet; then
        log::error "No internet connectivity detected. An active connection is required." "CHECKS"
        return 1
    fi
    log::debug "Internet check passed." "CHECKS"
    return 0
}

# @description Verifies that the filesystem has at least the required free space.
# @arg1 integer min_gib Minimum free space in GiB (default: 10).
# @exit 0 if sufficient space, 1 otherwise.
checks::check_disk_space() {
    local min_gib="${1:-10}"
    local mount_point="${2:-/}"

    # df -BG outputs sizes in gibibytes; awk extracts the Available column
    local available_gib
    available_gib="$(df -BG "${mount_point}" 2>/dev/null | awk 'NR==2{gsub("G",""); print $4}')"

    if [[ -z "${available_gib}" ]]; then
        log::error "Could not determine available disk space on ${mount_point}." "CHECKS"
        return 1
    fi

    if [[ "${available_gib}" -lt "${min_gib}" ]]; then
        log::error "Insufficient disk space: ${available_gib}GiB available, ${min_gib}GiB required on ${mount_point}." "CHECKS"
        return 1
    fi

    log::debug "Disk space check passed: ${available_gib}GiB available (>= ${min_gib}GiB required)." "CHECKS"
    return 0
}

# @description Verifies that the system has at least the required available RAM.
# @arg1 integer min_mib Minimum available RAM in MiB (default: 512).
# @exit 0 if sufficient RAM, 1 otherwise.
checks::check_ram() {
    local min_mib="${1:-512}"

    # /proc/meminfo is the standard source for memory info on Linux
    if [[ ! -f /proc/meminfo ]]; then
        log::error "Cannot read /proc/meminfo to determine available RAM." "CHECKS"
        return 1
    fi

    local available_mib
    available_mib="$(awk '/^MemAvailable:/{printf "%d", $2/1024}' /proc/meminfo)"

    if [[ -z "${available_mib}" ]]; then
        log::error "Could not parse MemAvailable from /proc/meminfo." "CHECKS"
        return 1
    fi

    if [[ "${available_mib}" -lt "${min_mib}" ]]; then
        log::error "Insufficient RAM: ${available_mib}MiB available, ${min_mib}MiB required." "CHECKS"
        return 1
    fi

    log::debug "RAM check passed: ${available_mib}MiB available (>= ${min_mib}MiB required)." "CHECKS"
    return 0
}

# @description Verifies the installer is NOT running as root.
#              The framework must be executed as a regular user; privilege
#              escalation is handled per-operation via sudo.
# @noargs
# @exit 0 if NOT root, 1 if running as root.
checks::check_root() {
    if environment::is_root; then
        log::error "Do not run the installer as root. Run as your regular user; sudo will be used when required." "CHECKS"
        return 1
    fi
    log::debug "Root check passed: running as non-root user." "CHECKS"
    return 0
}

# @description Verifies the user's login shell is among the supported shells.
# @noargs
# @exit 0 if shell is supported, 1 otherwise.
checks::check_supported_shell() {
    local -a supported=("bash" "zsh" "fish")
    local current_shell
    current_shell="$(environment::detect_shell)"

    local shell
    for shell in "${supported[@]}"; do
        if [[ "${current_shell}" == "${shell}" ]]; then
            log::debug "Shell check passed: ${current_shell} is supported." "CHECKS"
            return 0
        fi
    done

    log::error "Unsupported shell: '${current_shell}'. Supported shells: ${supported[*]}." "CHECKS"
    return 1
}

# @description Verifies that every command in the provided list exists in PATH.
# @arg1 string... commands Space-separated list or individual arguments of command names.
# @exit 0 if all commands exist, 1 if any are missing.
checks::check_required_commands() {
    local missing=()
    local cmd
    for cmd in "$@"; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        log::error "Missing required commands: ${missing[*]}" "CHECKS"
        return 1
    fi

    log::debug "Required commands check passed: all present." "CHECKS"
    return 0
}

# @description Detects whether the installer is running inside a virtual machine
#              and prints guidance if so. Hyprland requires DRM/KMS which many
#              VM configurations do not provide out of the box.
# @noargs
# @exit 0 Always (informational only — does not block installation)
checks::check_vm_environment() {
    local virt_type
    virt_type="$(systemd-detect-virt 2>/dev/null || echo "none")"

    if [[ "${virt_type}" == "none" ]]; then
        log::debug "VM check: running on bare metal." "CHECKS"
        return 0
    fi

    log::warn "Virtual machine detected: ${virt_type}" "CHECKS"
    log::warn "Hyprland requires DRM/KMS. Depending on your VM configuration:" "CHECKS"

    case "${virt_type}" in
        kvm|qemu)
            log::warn "  QEMU/KVM: use virtio-vga or virtio-vga-gl display device." "CHECKS"
            log::warn "  For software rendering: WLR_RENDERER_ALLOW_SOFTWARE=1 Hyprland" "CHECKS"
            ;;
        oracle)
            log::warn "  VirtualBox: enable VMSVGA display + 3D Acceleration in VM settings." "CHECKS"
            log::warn "  Install package: virtualbox-guest-utils" "CHECKS"
            ;;
        vmware)
            log::warn "  VMware: install open-vm-tools and enable 3D acceleration." "CHECKS"
            ;;
        *)
            log::warn "  If Hyprland fails: WLR_RENDERER_ALLOW_SOFTWARE=1 Hyprland" "CHECKS"
            ;;
    esac

    return 0
}

# @description Verifies that expected top-level project directories exist.
#              Reads PROJECT_ROOT from the environment (set by variables::load).
# @noargs
# @exit 0 if structure is valid, 1 if any directory is missing.
checks::check_project_structure() {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        log::error "PROJECT_ROOT is not set. Run variables::load first." "CHECKS"
        return 1
    fi

    local -a required_dirs=(
        "lib"
        "bootstrap"
    )

    local missing=()
    local dir
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "${PROJECT_ROOT}/${dir}" ]]; then
            missing+=("${dir}")
        fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        log::error "Project structure validation failed. Missing directories under ${PROJECT_ROOT}: ${missing[*]}" "CHECKS"
        return 1
    fi

    log::debug "Project structure check passed." "CHECKS"
    return 0
}

# @description Runs all pre-flight checks in sequence. Logs a PASS/FAIL summary
#              for each check. Does NOT abort on failure — returns 1 if any
#              check fails so the caller can decide the response.
# @noargs
# @exit 0 if all checks pass, 1 if any check fails.
checks::run_all() {
    local overall=0

    _checks::run_one "OS is Arch Linux"       checks::check_arch            || overall=1
    _checks::run_one "Internet connectivity"  checks::check_internet         || overall=1
    _checks::run_one "Disk space (>= 10 GiB)" checks::check_disk_space       || overall=1
    _checks::run_one "RAM (>= 512 MiB)"       checks::check_ram              || overall=1
    _checks::run_one "Not running as root"    checks::check_root             || overall=1
    _checks::run_one "Supported shell"        checks::check_supported_shell  || overall=1
    _checks::run_one "Project structure"      checks::check_project_structure || overall=1
    # VM detection is informational — always passes, prints guidance if in a VM
    checks::check_vm_environment

    return "${overall}"
}

# ==============================================================================
# Internal Helpers
# ==============================================================================

# @description Runs a single named check and logs the outcome.
# @arg1 string label Human-readable check name for log output.
# @arg2 string fn    The check function to call.
# @exit Passes through the check function's exit code.
_checks::run_one() {
    local label="${1}"
    local fn="${2}"

    if "${fn}"; then
        log::success "PASS: ${label}" "CHECKS"
        return 0
    else
        log::error "FAIL: ${label}" "CHECKS"
        return 1
    fi
}
