#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ==============================================================================
# Arch Linux Configuration Framework - colors.sh Unit Test Suite
# File: tests/test-colors.sh
# Purpose: Demonstrates and verifies terminal color capabilities detection
#          and ANSI constant controls. Does not modify the host system.
# Dependencies: lib/colors.sh
# ==============================================================================

# Source the colors library
source "${SCRIPT_DIR}/../lib/colors.sh"

# @description Runs a test case, printing colored output indicating status.
# @arg1 string test_name The name of the test function.
run_test() {
    local test_name="${1}"
    printf "Running %s... " "${test_name}"
    
    # Run test in subshell to isolate environment variables
    if ( "${test_name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        exit 1
    fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

# Verifies that importing colors.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/colors.sh"
    return 0
}

# Verifies that enabling colors populates ANSI constants.
test_color_constants_populated() {
    colors::enable_colors
    if [[ -z "${RED:-}" || -z "${RESET:-}" || -z "${BOLD_GREEN:-}" ]]; then
        echo "Error: ANSI variables are empty after colors::enable_colors" >&2
        return 1
    fi
    return 0
}

# Verifies that disabling colors clears ANSI constants.
test_color_constants_cleared() {
    colors::disable_colors
    if [[ -n "${RED:-}" || -n "${RESET:-}" || -n "${BOLD_GREEN:-}" ]]; then
        echo "Error: ANSI variables are not empty after colors::disable_colors" >&2
        return 1
    fi
    return 0
}

# Verifies that NO_COLOR environment variable disables color support.
test_no_color_env() {
    export NO_COLOR=1
    # Check both namespaced and delegate functions
    if colors::supports_color; then
        echo "Error: colors::supports_color returned 0 when NO_COLOR was set" >&2
        return 1
    fi
    if supports_color; then
        echo "Error: supports_color returned 0 when NO_COLOR was set" >&2
        return 1
    fi
    return 0
}

# Verifies that FORCE_COLOR environment variable overrides auto-detection.
test_force_color_env() {
    unset NO_COLOR
    export FORCE_COLOR=1
    if ! colors::supports_color; then
        echo "Error: colors::supports_color returned 1 when FORCE_COLOR was set" >&2
        return 1
    fi
    if ! supports_color; then
        echo "Error: supports_color returned 1 when FORCE_COLOR was set" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-colors.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_color_constants_populated
run_test test_color_constants_cleared
run_test test_no_color_env
run_test test_force_color_env

echo "All test-colors.sh tests passed!"
echo "============================================================"
