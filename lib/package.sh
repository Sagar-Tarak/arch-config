#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_PACKAGE_SH_INCLUDED:-}" ]]; then
    return 0
fi
_PACKAGE_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Package Manager Abstraction Library
# File: lib/package.sh
# Purpose: Provides reusable helper functions and interfaces for querying and
#          managing packages using pacman, yay, paru, and flatpak.
# Dependencies: lib/logger.sh, lib/command.sh
# Public API:
#   package::has_manager      - Checks if a package manager executable exists
#   package::detect_aur_helper- Detects which AUR helper (paru/yay) is installed
#   package::is_installed     - Checks if a package is installed under a manager
#   package::install          - Simulation interface for installing a package
#   has_manager               - Delegate for package::has_manager
#   detect_aur_helper         - Delegate for package::detect_aur_helper
#   is_installed              - Delegate for package::is_installed
#   install_package           - Safe delegate for package::install
#   install                   - Delegate for package::install (collides with coreutils install, use with care)
#   pkg::is_installed         - Compatibility namespace delegate
#   pkg::install              - Compatibility namespace delegate
# ==============================================================================

# Import dependencies
_PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_PACKAGE_DIR}/logger.sh" ]]; then
    # shellcheck disable=SC1091
    source "${_PACKAGE_DIR}/logger.sh"
else
    echo "Error: logger.sh not found relative to package.sh at: ${_PACKAGE_DIR}/logger.sh" >&2
    return 1 2>/dev/null || exit 1
fi

if [[ -f "${_PACKAGE_DIR}/command.sh" ]]; then
    # shellcheck disable=SC1091
    source "${_PACKAGE_DIR}/command.sh"
else
    echo "Error: command.sh not found relative to package.sh at: ${_PACKAGE_DIR}/command.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Checks if the given package manager's command line client is installed.
# @arg1 string manager Name of the manager executable (e.g. pacman, yay, paru, flatpak)
# @exit 0 if manager exists, 1 otherwise.
package::has_manager() {
    local manager="${1:-}"
    command::command_exists "${manager}"
}

# @description Detects whether 'paru' or 'yay' is available in the environment,
#              preferring 'paru'.
# @noargs
# @stdout Name of the detected helper (paru or yay)
# @exit 0 if a helper is found, 1 otherwise.
package::detect_aur_helper() {
    if package::has_manager "paru"; then
        echo "paru"
        return 0
    elif package::has_manager "yay"; then
        echo "yay"
        return 0
    fi
    return 1
}

# @description Checks if a package is currently active/installed on the system.
# @arg1 string package The name of the package.
# @arg2 string manager Optional manager to check (pacman, yay, paru, flatpak).
#                     Auto-detects pacman or flatpak if empty.
# @exit 0 if installed, 1 otherwise.
package::is_installed() {
    local pkg="${1:-}"
    local manager="${2:-}"

    if [[ -z "${pkg}" ]]; then
        log::error "Package name is required" "PKG"
        return 1
    fi

    # Auto-detect manager: flatpak apps usually have 3 components (e.g. org.domain.App)
    if [[ -z "${manager}" ]]; then
        if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]] && package::has_manager "flatpak"; then
            manager="flatpak"
        else
            manager="pacman"
        fi
    fi

    case "${manager}" in
        pacman|yay|paru)
            if package::has_manager "pacman"; then
                pacman -Qq "${pkg}" &>/dev/null
                return $?
            fi
            ;;
        flatpak)
            if package::has_manager "flatpak"; then
                flatpak info "${pkg}" &>/dev/null
                return $?
            fi
            ;;
        *)
            log::error "Unsupported package manager: ${manager}" "PKG"
            return 1
            ;;
    esac
    return 1
}

# @description Simulates installing a package. Checks if already installed first.
#              Does not modify the host system; serves as a pipeline interface.
# @arg1 string package The package to install.
# @arg2 string manager Optional package manager. Auto-detects if empty.
# @exit 0 if package is installed or simulation succeeds.
package::install() {
    local pkg="${1:-}"
    local manager="${2:-}"

    if [[ -z "${pkg}" ]]; then
        log::error "Package name is required" "PKG"
        return 1
    fi

    # Auto-detect manager
    if [[ -z "${manager}" ]]; then
        if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]] && package::has_manager "flatpak"; then
            manager="flatpak"
        else
            local aur_helper
            if aur_helper="$(package::detect_aur_helper 2>/dev/null)"; then
                manager="${aur_helper}"
            else
                manager="pacman"
            fi
        fi
    fi

    # Idempotency check
    if package::is_installed "${pkg}" "${manager}"; then
        log::info "Package '${pkg}' is already installed via ${manager} (skipping)" "PKG"
        return 0
    fi

    log::info "Installing package: ${pkg} via ${manager}" "PKG"
    if [[ "${ARCH_CFG_DRY_RUN:-}" == "true" ]]; then
        log::info "[DRY-RUN] Would install package: ${pkg} using ${manager}" "PKG"
        return 0
    fi

    # As per prompt, package installation command execution is deferred.
    # We log the action to establish the standard interface pipeline.
    log::info "[INTERFACE] Package installation simulated for: ${pkg} via ${manager}" "PKG"
    return 0
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for package::has_manager
has_manager() {
    package::has_manager "$@"
}

# @description Delegate for package::detect_aur_helper
detect_aur_helper() {
    package::detect_aur_helper "$@"
}

# @description Delegate for package::is_installed
is_installed() {
    package::is_installed "$@"
}

# @description Delegate for package::install
install_package() {
    package::install "$@"
}

# @description Delegate for package::install (Warning: shadows coreutils 'install')
install() {
    package::install "$@"
}

# ==============================================================================
# Compatibility Namespaced Delegates
# ==============================================================================

# @description Compatibility namespace delegate
pkg::is_installed() {
    package::is_installed "$@"
}

# @description Compatibility namespace delegate
pkg::install() {
    package::install "$@"
}
