#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve this file's directory so all sourcing is absolute and relocatable
_BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_BOOTSTRAP_SH_INCLUDED:-}" ]]; then
    return 0
fi
_BOOTSTRAP_SH_INCLUDED=1

# ==============================================================================
# Forge - Bootstrap Entry Point
# File: bootstrap/bootstrap.sh
# Purpose: Orchestrates the full bootstrap sequence. Sources the library loader,
#          loads all core libraries, initialises global variables, detects the
#          host environment, and prints the framework banner. This file is the
#          single entry point that any top-level installer script (install.sh)
#          should source before running any module.
# Dependencies: bootstrap/loader.sh, bootstrap/variables.sh,
#               bootstrap/environment.sh, bootstrap/checks.sh
# Public API:
#   bootstrap::init  - Runs the full bootstrap sequence
# Usage Example:
#   source bootstrap/bootstrap.sh
#   bootstrap::init
#   log::info "Bootstrap complete, ready for modules" "INSTALL"
# ==============================================================================

# ==============================================================================
# Step 1 — Load the library loader (must happen before anything else)
# ==============================================================================
if [[ ! -f "${_BOOTSTRAP_DIR}/loader.sh" ]]; then
    echo "Fatal: bootstrap/loader.sh not found at: ${_BOOTSTRAP_DIR}/loader.sh" >&2
    return 1 2>/dev/null || exit 1
fi
# shellcheck source=bootstrap/loader.sh
source "${_BOOTSTRAP_DIR}/loader.sh"

# ==============================================================================
# Step 2 — Source all core libraries through the loader
# ==============================================================================
if ! loader::load_libs; then
    echo "Fatal: Failed to load core libraries." >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Step 3 — Load remaining bootstrap components
# ==============================================================================
_bootstrap_components=(
    "variables.sh"
    "environment.sh"
    "checks.sh"
)

for _bootstrap_file in "${_bootstrap_components[@]}"; do
    _bootstrap_component_path="${_BOOTSTRAP_DIR}/${_bootstrap_file}"
    if [[ ! -f "${_bootstrap_component_path}" ]]; then
        log::fatal "Bootstrap component not found: ${_bootstrap_component_path}" "BOOTSTRAP"
        return 1 2>/dev/null || exit 1
    fi
    # shellcheck disable=SC1090
    source "${_bootstrap_component_path}"
done
unset _bootstrap_file _bootstrap_components _bootstrap_component_path

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Executes the full bootstrap sequence:
#                1. Load global variables
#                2. Detect host environment
#                3. Initialize logger output destination
#                4. Print the framework version banner
# @noargs
# @exit 0 on success, 1 on any fatal setup failure.
bootstrap::init() {
    # Load path variables first — everything else depends on PROJECT_ROOT
    variables::load

    # Detect the host environment and export ENV_* variables
    environment::detect

    # Ensure the log directory exists before writing any log files
    if [[ "${ARCH_CFG_DRY_RUN:-false}" != "true" ]]; then
        mkdir -p "${LOG_DIR}" 2>/dev/null || true
    fi

    # Print the framework banner to stderr so it appears even when stdout is
    # redirected to a log file
    bootstrap::_print_banner

    log::info "Bootstrap complete. PROJECT_ROOT=${PROJECT_ROOT}" "BOOTSTRAP"
    log::debug "VERSION=${VERSION} DRY_RUN=${ARCH_CFG_DRY_RUN:-false} DEBUG=${DEBUG:-0}" "BOOTSTRAP"

    return 0
}

# ==============================================================================
# Internal Helpers
# ==============================================================================

# @description Prints the framework version banner to stderr.
# @noargs
# @exit 0 Always
bootstrap::_print_banner() {
    local divider="════════════════════════════════════════════════════════════"
    if declare -f colors::supports_color &>/dev/null && colors::supports_color; then
        echo "${BOLD_CYAN}${divider}${RESET}" >&2
        echo "${BOLD_WHITE}  Forge  v${VERSION}${RESET}" >&2
        echo "${CYAN}  Project Root : ${PROJECT_ROOT}${RESET}" >&2
        echo "${CYAN}  CPU Arch     : ${ENV_CPU_ARCH}${RESET}" >&2
        echo "${CYAN}  Shell        : ${ENV_SHELL}${RESET}" >&2
        echo "${CYAN}  Display      : ${ENV_DISPLAY_SERVER}${RESET}" >&2
        echo "${CYAN}  AUR Helper   : ${ENV_AUR_HELPER}${RESET}" >&2
        echo "${BOLD_CYAN}${divider}${RESET}" >&2
    else
        echo "${divider}" >&2
        echo "  Forge  v${VERSION}" >&2
        echo "  Project Root : ${PROJECT_ROOT}" >&2
        echo "  CPU Arch     : ${ENV_CPU_ARCH}" >&2
        echo "  Shell        : ${ENV_SHELL}" >&2
        echo "  Display      : ${ENV_DISPLAY_SERVER}" >&2
        echo "  AUR Helper   : ${ENV_AUR_HELPER}" >&2
        echo "${divider}" >&2
    fi
}
