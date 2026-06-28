#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_SUMMARY_SH_INCLUDED:-}" ]]; then
    return 0
fi
_SUMMARY_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Installer Summary Output
# File: installer/summary.sh
# Purpose: Formats and displays the pre-installation environment summary and
#          the post-installation completion report. Uses the existing logger
#          and color libraries for consistent output.
# Dependencies: lib/logger.sh, lib/colors.sh, bootstrap/variables.sh,
#               bootstrap/environment.sh (ENV_* vars), installer/packages.sh
# Public API:
#   summary::print_environment - Prints detected environment as a table
#   summary::print_modules     - Prints the list of modules scheduled to run
#   summary::print_packages    - Prints package counts per manager
#   summary::print_final       - Prints the post-installation completion banner
# Usage Example:
#   source installer/summary.sh
#   summary::print_environment
#   summary::print_modules
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Prints a formatted table of the detected environment to stderr.
#              Covers: framework version, project root, CPU arch, shell,
#              display server, package manager, AUR helper, and active flags.
# @noargs
# @exit 0 Always
summary::print_environment() {
    log::step "Installation Environment"

    _summary::row "Framework Version" "v${VERSION:-unknown}"
    _summary::row "Project Root"      "${PROJECT_ROOT:-unknown}"
    _summary::row "Architecture"      "${ENV_CPU_ARCH:-unknown}"
    _summary::row "Shell"             "${ENV_SHELL:-unknown}"
    _summary::row "Display Server"    "${ENV_DISPLAY_SERVER:-unknown}"
    _summary::row "Package Manager"   "${ENV_PACKAGE_MANAGER:-unknown}"
    _summary::row "AUR Helper"        "${ENV_AUR_HELPER:-none}"
    _summary::row "Internet"          "${ENV_HAS_INTERNET:-unknown}"
    _summary::row "Dry-Run Mode"      "${ARCH_CFG_DRY_RUN:-false}"
    _summary::row "Auto-Confirm"      "${ARCH_CFG_FLAG_YES:-false}"
    _summary::row "Verbose"           "${ARCH_CFG_FLAG_VERBOSE:-false}"

    if [[ -n "${ARCH_CFG_FLAG_MODULE:-}" ]]; then
        _summary::row "Target Module" "${ARCH_CFG_FLAG_MODULE}"
    fi

    printf "\n" >&2
}

# @description Prints the list of modules that will be installed, reading
#              each manifest.sh to display name and description. Marks modules
#              that are enabled by default.
# @noargs
# @exit 0 Always
summary::print_modules() {
    log::step "Modules Scheduled for Installation"

    if [[ ! -d "${MODULES_DIR}" ]]; then
        log::warn "No modules directory found at: ${MODULES_DIR}" "SUMMARY"
        return 0
    fi

    local name
    while IFS= read -r name; do
        _summary::print_module_row "${name}"
    done < <(module_loader::list)

    printf "\n" >&2
}

# @description Prints per-manager package counts read from the package lists.
# @noargs
# @exit 0 Always
summary::print_packages() {
    log::step "Package Summary"
    packages::show_summary
    printf "\n" >&2
}

# @description Prints the post-installation completion banner to stderr.
#              In dry-run mode, emphasises that no changes were made.
# @noargs
# @exit 0 Always
summary::print_final() {
    log::step "Installation Summary"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "Dry-run complete — no changes were made to the system." "SUMMARY"
        log::info "Remove --dry-run and re-run to apply the installation." "SUMMARY"
    else
        log::success "Installation complete." "SUMMARY"
    fi

    printf "\n" >&2
}

# ==============================================================================
# Internal helpers
# ==============================================================================

# @description Prints one key-value row in the environment table to stderr.
# @arg1 string label Left column label
# @arg2 string value Right column value
_summary::row() {
    local label="${1}"
    local value="${2}"
    printf "  %-25s %s\n" "${label}:" "${value}" >&2
}

# @description Reads a module's manifest and prints one summary row.
# @arg1 string name Module name
_summary::print_module_row() {
    local name="${1}"
    local manifest_file="${MODULES_DIR}/${name}/manifest.sh"
    local desc="(no description)"
    local marker=""

    if [[ -f "${manifest_file}" ]]; then
        # Unset before sourcing to avoid stale values from a prior module
        unset MODULE_DESCRIPTION MODULE_ENABLED_BY_DEFAULT
        # shellcheck source=/dev/null
        source "${manifest_file}"
        desc="${MODULE_DESCRIPTION:-${desc}}"
        if [[ "${MODULE_ENABLED_BY_DEFAULT:-true}" == "true" ]]; then
            marker="${BOLD_GREEN:-}●${RESET:-}"
        else
            marker="${YELLOW:-}○${RESET:-}"
        fi
    fi

    # If --module flag is set, only highlight the selected module
    if [[ -n "${ARCH_CFG_FLAG_MODULE:-}" ]]; then
        if [[ "${name}" == "${ARCH_CFG_FLAG_MODULE}" ]]; then
            marker="${BOLD_GREEN:-}→${RESET:-}"
        else
            marker=" "
        fi
    fi

    printf "  %s %-18s %s\n" "${marker}" "${name}" "${desc}" >&2
}
