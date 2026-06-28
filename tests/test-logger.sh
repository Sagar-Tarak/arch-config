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
# Forge - logger.sh Unit Test Suite
# File: tests/test-logger.sh
# Purpose: Verifies structured log formats, multiline log expansion, and level toggles.
# Dependencies: lib/logger.sh
# ==============================================================================

# Source the logger library
source "${SCRIPT_DIR}/../lib/logger.sh"

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

# Verifies that importing logger.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/logger.sh"
    return 0
}

# Verifies that INFO logs have the correct structure: timestamp, level, namespace, message.
test_info_log_format() {
    local output
    # Force NO_COLOR to simplify regex match
    output=$(export NO_COLOR=1; log::info "Testing logger info" "UNIT" 2>&1)
    
    # Example expected match: [2026-06-28 15:37:32] [INFO]   [UNIT]: Testing logger info
    local expected_regex='^\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[INFO\] *\[UNIT\]: Testing logger info$'
    
    if [[ ! "${output}" =~ $expected_regex ]]; then
        echo "Error: Unexpected output format: '${output}'" >&2
        return 1
    fi
    return 0
}

# Verifies that multiline strings are split and each line is formatted and logged separately.
test_multiline_logging() {
    local output
    output=$(export NO_COLOR=1; log::info $'Line 1 of log\nLine 2 of log' "UNIT" 2>&1)
    
    local line_count
    line_count=$(echo "${output}" | grep -c "\[UNIT\]:")
    if [[ "${line_count}" -ne 2 ]]; then
        echo "Error: Expected 2 log lines, but got ${line_count}. Output: '${output}'" >&2
        return 1
    fi
    return 0
}

# Verifies that DEBUG messages are muted when DEBUG environment variable is not 1.
test_debug_disabled_by_default() {
    local output
    output=$(export NO_COLOR=1; export DEBUG=0; log::debug "Hidden debug" "UNIT" 2>&1)
    if [[ -n "${output}" ]]; then
        echo "Error: Expected empty output when DEBUG=0, but got: '${output}'" >&2
        return 1
    fi
    return 0
}

# Verifies that DEBUG messages are logged when DEBUG environment variable is 1.
test_debug_enabled() {
    local output
    output=$(export NO_COLOR=1; export DEBUG=1; log::debug "Show debug" "UNIT" 2>&1)
    
    local expected_regex='^\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[DEBUG\] *\[UNIT\]: Show debug$'
    if [[ ! "${output}" =~ $expected_regex ]]; then
        echo "Error: Debug message was not logged or structured correctly. Output: '${output}'" >&2
        return 1
    fi
    return 0
}

# Verifies that step messages contain horizontal dividers and bold headers.
test_step_log() {
    local output
    output=$(export NO_COLOR=1; log::step "Section Header Title" 2>&1)
    
    if [[ ! "${output}" =~ ──── ]]; then
        echo "Error: Expected horizontal dividers (────) in step output. Output: '${output}'" >&2
        return 1
    fi
    if [[ ! "${output}" =~ "Section Header Title" ]]; then
        echo "Error: Title not found in step output. Output: '${output}'" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-logger.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_info_log_format
run_test test_multiline_logging
run_test test_debug_disabled_by_default
run_test test_debug_enabled
run_test test_step_log

echo "All test-logger.sh tests passed!"
echo "============================================================"
