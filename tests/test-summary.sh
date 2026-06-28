#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Unit Test: installer/summary.sh
# Covers: print_environment survives with and without FORGE_BASE_MODULES.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../bootstrap/loader.sh"
loader::load_libs

export VERSION="0.1.0" ARCH_CFG_DRY_RUN="false" DEBUG="0"
source "${SCRIPT_DIR}/../bootstrap/variables.sh" && variables::load
source "${SCRIPT_DIR}/../installer/module_loader.sh"
source "${SCRIPT_DIR}/../installer/packages.sh"
source "${SCRIPT_DIR}/../installer/summary.sh"

_PASS=0
_FAIL=0

run_test() {
    local name="${1}"
    printf "Running %s... " "${name}"
    if ( "${name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
        _PASS=$(( _PASS + 1 ))
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# ---- Tests ----

# summary.sh must not crash when FORGE_BASE_MODULES is defined
test_print_environment_with_base_modules() {
    FORGE_BASE_MODULES=("core" "desktop/hyprland" "shell/fish")
    local out
    out="$(NO_COLOR=1 summary::print_environment 2>&1)"
    unset FORGE_BASE_MODULES
    # Should contain the module count (3)
    echo "${out}" | grep -q "3 modules"
}

# summary.sh must not crash when FORGE_BASE_MODULES is not set
test_print_environment_without_base_modules() {
    unset FORGE_BASE_MODULES 2>/dev/null || true
    local out
    out="$(NO_COLOR=1 summary::print_environment 2>&1)"
    # Should show 0 modules, not crash
    echo "${out}" | grep -q "0 modules"
}

# Calling print_environment twice (with and without the array) must not error
test_print_environment_idempotent_across_states() {
    FORGE_BASE_MODULES=("core")
    NO_COLOR=1 summary::print_environment 2>/dev/null
    unset FORGE_BASE_MODULES
    NO_COLOR=1 summary::print_environment 2>/dev/null
}

# The specific bad substitution ${#arr[@]:-0} would have caused "bad substitution"
# in the output. Verify the word "bad" does not appear in any error output.
test_no_bad_substitution_error() {
    unset FORGE_BASE_MODULES 2>/dev/null || true
    local out
    out="$(NO_COLOR=1 summary::print_environment 2>&1)"
    ! echo "${out}" | grep -qi "bad substitution"
}

# ---- Execution ----
echo "============================================================"
echo "Starting test suite: test-summary.sh"
echo "============================================================"
run_test test_print_environment_with_base_modules
run_test test_print_environment_without_base_modules
run_test test_print_environment_idempotent_across_states
run_test test_no_bad_substitution_error

if [[ "${_FAIL}" -eq 0 ]]; then
    echo "All test-summary.sh tests passed!"
else
    printf "\e[31m%d test(s) failed.\e[0m\n" "${_FAIL}"
    exit 1
fi
echo "============================================================"
