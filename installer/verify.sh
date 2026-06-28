#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_VERIFY_SH_INCLUDED:-}" ]]; then return 0; fi
_VERIFY_SH_INCLUDED=1

# ==============================================================================
# Forge — Verification Aggregator
# File: installer/verify.sh
# Purpose: Runs each module's verify() function and aggregates results into a
#          structured report. Four possible states per module:
#
#            PASS            — verify function ran and returned 0
#            FAIL            — verify function ran and returned non-zero
#            SKIPPED         — verify function returned exit code 3
#                              (module not applicable on this system)
#            NOT_IMPLEMENTED — module has no verify function, or returned 2
#                              (feature planned but not yet deployable)
#
# Dependencies: lib/logger.sh, installer/module_loader.sh
# Public API:
#   verify::run_module        - Verifies one module and records the result
#   verify::run_selected      - Verifies a list of modules
#   verify::run_all           - Verifies every discovered module
#   verify::print_report      - Prints the full result table and tally
#   verify::has_failures      - Returns 0 if any module recorded FAIL
#   verify::reset             - Clears all results (for test isolation)
# Exit-code contract for module verify functions:
#   0  → PASS
#   2  → NOT_IMPLEMENTED  (planned but not yet done)
#   3  → SKIPPED          (intentionally not applicable)
#   *  → FAIL
# ==============================================================================

# Associative array: module_name → "PASS" | "FAIL" | "SKIPPED" | "NOT_IMPLEMENTED"
declare -A _VERIFY_RESULTS=()

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Calls module::verify for a single named module and stores the
#              result in _VERIFY_RESULTS using the four-state scheme above.
# @arg1 string name Module name
# @exit 0 Always (failures are recorded, not propagated)
verify::run_module() {
    local name="${1:-}"
    if [[ -z "${name}" ]]; then
        log::error "verify::run_module requires a module name" "VERIFY"
        return 1
    fi

    log::info "Verifying: ${name}" "VERIFY"

    local rc=0
    module::verify "${name}" || rc=$?

    case "${rc}" in
        0)  _VERIFY_RESULTS["${name}"]="PASS" ;;
        2)  _VERIFY_RESULTS["${name}"]="NOT_IMPLEMENTED" ;;
        3)  _VERIFY_RESULTS["${name}"]="SKIPPED" ;;
        *)  _VERIFY_RESULTS["${name}"]="FAIL" ;;
    esac

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

# @description Prints the full verification report to stderr.
#              ✔ PASS, ✖ FAIL, ⊘ SKIPPED, ○ NOT_IMPLEMENTED
# @noargs
# @exit 0 Always
verify::print_report() {
    log::step "Verification Report"

    if [[ "${#_VERIFY_RESULTS[@]}" -eq 0 ]]; then
        log::warn "No modules were verified." "VERIFY"
        return 0
    fi

    local pass=0 fail=0 skipped=0 not_impl=0
    local name

    # Sort for deterministic output
    local -a sorted_names=()
    while IFS= read -r name; do
        sorted_names+=("${name}")
    done < <(printf "%s\n" "${!_VERIFY_RESULTS[@]}" | sort)

    for name in "${sorted_names[@]}"; do
        local result="${_VERIFY_RESULTS[${name}]}"
        case "${result}" in
            PASS)
                printf "  %s✔%s  %-30s %s\n" \
                    "${BOLD_GREEN:-}" "${RESET:-}" "${name}" "PASS" >&2
                pass=$(( pass + 1 ))
                ;;
            FAIL)
                printf "  %s✖%s  %-30s %s\n" \
                    "${BOLD_RED:-}" "${RESET:-}" "${name}" "FAIL" >&2
                fail=$(( fail + 1 ))
                ;;
            SKIPPED)
                printf "  %s⊘%s  %-30s %s\n" \
                    "${BOLD_YELLOW:-}" "${RESET:-}" "${name}" "SKIPPED" >&2
                skipped=$(( skipped + 1 ))
                ;;
            NOT_IMPLEMENTED)
                printf "  %s○%s  %-30s %s\n" \
                    "${DIM:-}" "${RESET:-}" "${name}" "NOT IMPLEMENTED" >&2
                not_impl=$(( not_impl + 1 ))
                ;;
        esac
    done

    printf "\n" >&2

    local total=$(( pass + fail + skipped + not_impl ))
    if [[ "${fail}" -eq 0 ]]; then
        log::success "${pass}/${total} passed  |  ${skipped} skipped  |  ${not_impl} not implemented" "VERIFY"
    else
        log::warn "${pass}/${total} passed  |  ${fail} FAILED  |  ${skipped} skipped  |  ${not_impl} not implemented" "VERIFY"
    fi
}

# @description Returns 0 if at least one module recorded a FAIL result.
# @exit 0 if any failures present, 1 if all passed/skipped/not-implemented
verify::has_failures() {
    local name
    for name in "${!_VERIFY_RESULTS[@]}"; do
        [[ "${_VERIFY_RESULTS[${name}]}" == "FAIL" ]] && return 0
    done
    return 1
}

# @description Clears all recorded verification results.
# @exit 0 Always
verify::reset() {
    _VERIFY_RESULTS=()
}
