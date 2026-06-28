#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_FLOW_SH_INCLUDED:-}" ]]; then
    return 0
fi
_FLOW_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Installer Flow Orchestrator
# File: installer/flow.sh
# Purpose: Implements the top-level installer pipeline. Dispatches early-exit
#          paths (--help, --version, --list-modules, --verify) and runs the
#          full installation sequence for all other invocations.
#          All side-effecting steps check ARCH_CFG_DRY_RUN.
# Dependencies: lib/logger.sh, lib/utils.sh, bootstrap/checks.sh,
#               installer/args.sh, installer/module_loader.sh,
#               installer/packages.sh, installer/summary.sh, installer/verify.sh
# Public API:
#   flow::run - Reads parsed flag globals and executes the correct path
# Usage Example:
#   source installer/flow.sh
#   args::parse "$@"
#   flow::run
# ==============================================================================

# ==============================================================================
# Public API
# ==============================================================================

# @description Main entry point for the installer. Reads ARCH_CFG_FLAG_*
#              globals set by args::parse and dispatches accordingly.
#              Returns a documented exit code (see docs/AI_CONTEXT.md §9).
# @noargs
# @exit 0  Success
# @exit 2  Bad CLI usage (handled in args.sh before this runs)
# @exit 10 Pre-flight validation failure
# @exit 40 Post-install verification failures
flow::run() {
    # --- Early-exit paths (no preflight, no side effects) ---
    if [[ "${ARCH_CFG_FLAG_HELP:-false}" == "true" ]]; then
        args::print_help
        return 0
    fi

    if [[ "${ARCH_CFG_FLAG_VERSION:-false}" == "true" ]]; then
        printf "%s\n" "${VERSION:-0.0.0}"
        return 0
    fi

    if [[ "${ARCH_CFG_FLAG_LIST_MODULES:-false}" == "true" ]]; then
        _flow::list_modules
        return 0
    fi

    # --- Verify-only path ---
    if [[ "${ARCH_CFG_FLAG_VERIFY:-false}" == "true" ]]; then
        _flow::verify_only
        return $?
    fi

    # --- Full installation pipeline ---
    _flow::run_full
    return $?
}

# ==============================================================================
# Internal pipeline stages
# ==============================================================================

# @description Runs the complete installation pipeline:
#              preflight → summary → confirm → install modules → verify → report
# @exit 0 on success, 10 on preflight failure, 1 on module failure
_flow::run_full() {
    # 1. Pre-flight checks
    log::step "Pre-flight Checks"
    if ! checks::run_all; then
        log::fatal "One or more pre-flight checks failed. Resolve the issues above and re-run." "FLOW"
        return 10
    fi

    # 2. Validate package lists (warn only — not a fatal error)
    packages::validate || log::warn "Some package list files are missing." "FLOW"

    # 3. Print installation summary
    summary::print_environment
    summary::print_modules
    summary::print_packages

    # 4. Confirmation prompt (skip when --yes or non-interactive)
    if [[ "${ARCH_CFG_FLAG_YES:-false}" != "true" ]]; then
        if ! utils::confirm "Proceed with installation?" "N"; then
            log::info "Installation cancelled by user." "FLOW"
            return 0
        fi
    else
        log::info "Auto-confirm active (--yes) — skipping prompt." "FLOW"
    fi

    # 5. Execute modules
    log::step "Installing Modules"
    _flow::execute_modules || true   # individual failures logged; continue to verify

    # 6. Post-install verification
    log::step "Post-install Verification"
    _flow::verify

    # 7. Final report
    summary::print_final
    verify::print_report

    if verify::has_failures; then
        return 40
    fi
    return 0
}

# @description Resolves the list of target modules, then calls module::install
#              on each. With --module, installs only that one module. Otherwise
#              installs all modules whose manifest marks them as enabled.
# @exit 0 if all modules succeed, 1 if any fail
_flow::execute_modules() {
    local -a targets=()
    _flow::resolve_target_modules targets

    if [[ "${#targets[@]}" -eq 0 ]]; then
        log::warn "No modules selected for installation." "FLOW"
        return 0
    fi

    local name
    local failed=0
    for name in "${targets[@]}"; do
        log::info "▶ Installing module: ${name}" "FLOW"
        if ! module::install "${name}"; then
            log::error "Module '${name}' installation failed." "FLOW"
            failed=$(( failed + 1 ))
        fi
    done

    if [[ "${failed}" -gt 0 ]]; then
        log::warn "${failed} module(s) reported installation failures." "FLOW"
        return 1
    fi
    return 0
}

# @description Runs post-install verification on the same set of modules that
#              were targeted for installation.
# @exit 0 Always (results captured in verify module)
_flow::verify() {
    local -a targets=()
    _flow::resolve_target_modules targets
    verify::run_selected "${targets[@]}"
}

# @description Verify-only mode (--verify flag). Runs verification on the
#              selected or all modules and prints a report.
# @exit 0 if all pass, 40 if any fail
_flow::verify_only() {
    log::step "Running Verification"

    local -a targets=()
    _flow::resolve_target_modules targets

    if [[ "${#targets[@]}" -eq 0 ]]; then
        log::warn "No modules found to verify." "FLOW"
        return 0
    fi

    verify::run_selected "${targets[@]}"
    verify::print_report

    if verify::has_failures; then
        return 40
    fi
    return 0
}

# @description Lists all discovered modules with their manifest descriptions.
# @exit 0 Always
_flow::list_modules() {
    log::step "Available Modules"

    local header
    printf "  %-20s %-45s %s\n" "NAME" "DESCRIPTION" "DEFAULT" >&2
    printf "  %-20s %-45s %s\n" "----" "-----------" "-------" >&2

    if [[ ! -d "${MODULES_DIR}" ]]; then
        log::warn "No modules directory at: ${MODULES_DIR}" "FLOW"
        return 0
    fi

    local name
    while IFS= read -r name; do
        local manifest_file="${MODULES_DIR}/${name}/manifest.sh"
        local desc="(no description)"
        local default_marker="no"

        if [[ -f "${manifest_file}" ]]; then
            unset MODULE_DESCRIPTION MODULE_ENABLED_BY_DEFAULT
            # shellcheck source=/dev/null
            source "${manifest_file}"
            desc="${MODULE_DESCRIPTION:-${desc}}"
            if [[ "${MODULE_ENABLED_BY_DEFAULT:-true}" == "true" ]]; then
                default_marker="yes"
            fi
        fi

        printf "  %-20s %-45s %s\n" "${name}" "${desc}" "${default_marker}" >&2
    done < <(module_loader::list)
}

# @description Populates the nameref array with the list of modules to act on.
#              With --module <name>, the array contains just that one entry.
#              Without --module, populates with all default-enabled modules.
# @arg1 nameref target_array_name Name of caller's array variable to populate
_flow::resolve_target_modules() {
    # Use a nameref to write back to the caller's array (bash 4.3+)
    local -n _target_array="${1}"
    _target_array=()

    if [[ -n "${ARCH_CFG_FLAG_MODULE:-}" ]]; then
        # Single-module mode
        if ! module_loader::exists "${ARCH_CFG_FLAG_MODULE}"; then
            log::error "Module '${ARCH_CFG_FLAG_MODULE}' not found." "FLOW"
            log::info  "Run --list-modules to see available modules." "FLOW"
            return 1
        fi
        _target_array=("${ARCH_CFG_FLAG_MODULE}")
        return 0
    fi

    # All default-enabled modules
    if [[ ! -d "${MODULES_DIR}" ]]; then
        return 0
    fi

    local name
    while IFS= read -r name; do
        local manifest_file="${MODULES_DIR}/${name}/manifest.sh"
        local enabled="true"

        if [[ -f "${manifest_file}" ]]; then
            unset MODULE_ENABLED_BY_DEFAULT
            # shellcheck source=/dev/null
            source "${manifest_file}"
            enabled="${MODULE_ENABLED_BY_DEFAULT:-true}"
        fi

        if [[ "${enabled}" == "true" ]]; then
            _target_array+=("${name}")
        fi
    done < <(module_loader::list)
}
