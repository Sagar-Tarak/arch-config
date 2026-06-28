#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_VERIFY_SH_INCLUDED:-}" ]]; then
    return 0
fi
_VERIFY_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Verification Aggregator
# File: installer/verify.sh
# Purpose: Runs each module's verify() function and aggregates results into a
#          single pass/fail report. Distinct from bootstrap/checks.sh (which
#          runs pre-flight system checks); this file verifies post-install state.
# Dependencies: lib/logger.sh, installer/module_loader.sh
# Public API:
#   verify::run_module    - Verifies one named module and records the result
#   verify::run_selected  - Verifies a given list of module names
#   verify::run_all       - Verifies every discovered module
#   verify::print_report  - Prints the full pass/fail table and final tally
#   verify::has_failures  - Returns 0 if any module failed verification
#   verify::reset         - Clears all recorded results (for test isolation)
# Usage Example:
#   source installer/verify.sh
#   verify::run_selected "git" "nvim" "shell"
#   verify::print_report
#   verify::has_failures && exit 40
# ==============================================================================

# Associative array: module_name → "PASS" | "FAIL"
declare -A _VERIFY_RESULTS=()

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Calls module::verify for a single named module and stores the
#              result (PASS or FAIL) in _VERIFY_RESULTS.
# @arg1 string name Module name
# @exit 0 Always (failures are recorded, not propagated)
verify::run_module() {
    local name="${1:-}"
    if [[ -z "${name}" ]]; then
        log::error "verify::run_module requires a module name" "VERIFY"
        return 1
    fi

    log::info "Verifying: ${name}" "VERIFY"

    if module::verify "${name}"; then
        _VERIFY_RESULTS["${name}"]="PASS"
    else
        _VERIFY_RESULTS["${name}"]="FAIL"
    fi

    return 0
}

# @description Verifies each module in the provided argument list.
# @arg1 string... Module names to verify
# @exit 0 Always
verify::run_selected() {
    local name
    for name in "$@"; do
        verify::run_module "${name}"
    done
}

# @description Discovers all available modules via module_loader::list and
#              runs verification on each.
# @noargs
# @exit 0 Always
verify::run_all() {
    local name
    while IFS= read -r name; do
        verify::run_module "${name}"
    done < <(module_loader::list)
}

# @description Prints the full verification report to stderr: one line per
#              module showing ✔ PASS or ✖ FAIL, followed by a tally.
# @noargs
# @exit 0 Always
verify::print_report() {
    log::step "Verification Report"

    if [[ "${#_VERIFY_RESULTS[@]}" -eq 0 ]]; then
        log::warn "No modules were verified." "VERIFY"
        return 0
    fi

    local pass=0
    local fail=0
    local name

    # Sort module names for deterministic output
    local -a sorted_names=()
    while IFS= read -r name; do
        sorted_names+=("${name}")
    done < <(printf "%s\n" "${!_VERIFY_RESULTS[@]}" | sort)

    for name in "${sorted_names[@]}"; do
        local result="${_VERIFY_RESULTS[${name}]}"
        if [[ "${result}" == "PASS" ]]; then
            printf "  %s✔%s  %s\n" "${BOLD_GREEN:-}" "${RESET:-}" "${name}" >&2
            pass=$(( pass + 1 ))
        else
            printf "  %s✖%s  %s\n" "${BOLD_RED:-}" "${RESET:-}" "${name}" >&2
            fail=$(( fail + 1 ))
        fi
    done

    printf "\n" >&2

    local total=$(( pass + fail ))
    if [[ "${fail}" -eq 0 ]]; then
        log::success "${pass}/${total} module(s) verified successfully." "VERIFY"
    else
        log::warn "${pass}/${total} module(s) passed — ${fail} failed." "VERIFY"
    fi
}

# @description Returns 0 if at least one module recorded a FAIL result.
#              Useful for setting the installer's final exit code.
# @noargs
# @exit 0 if any failures present, 1 if all passed (or no results)
verify::has_failures() {
    local name
    for name in "${!_VERIFY_RESULTS[@]}"; do
        [[ "${_VERIFY_RESULTS[${name}]}" == "FAIL" ]] && return 0
    done
    return 1
}

# @description Clears all recorded verification results. Primarily useful for
#              test isolation when the same shell session runs multiple suites.
# @noargs
# @exit 0 Always
verify::reset() {
    _VERIFY_RESULTS=()
}
