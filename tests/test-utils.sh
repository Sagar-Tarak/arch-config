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
# Forge - utils.sh Unit Test Suite
# File: tests/test-utils.sh
# Purpose: Verifies utility functions (trim, join_by, is_root, current_user,
#          timestamp, and confirm) using pure-Bash and simulated environments.
# Dependencies: lib/utils.sh
# ==============================================================================

# Source the utils library
source "${SCRIPT_DIR}/../lib/utils.sh"

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

# Verifies that importing utils.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/utils.sh"
    return 0
}

# Verifies that is_root matches the executing user status (EUID 0).
test_is_root() {
    local root_status=1
    if [[ "${EUID}" -eq 0 ]]; then
        root_status=0
    fi

    local is_root_result=1
    utils::is_root && is_root_result=0 || is_root_result=$?
    
    if [[ "${is_root_result}" -ne "${root_status}" ]]; then
        echo "Error: is_root result (${is_root_result}) does not match EUID-based check (${root_status})" >&2
        return 1
    fi
    return 0
}

# Verifies current_user matches env vars or id -un.
test_current_user() {
    local active_user
    active_user="$(utils::current_user)"
    if [[ -z "${active_user}" ]]; then
        echo "Error: Resolved user is empty" >&2
        return 1
    fi
    
    # Check that it matches either SUDO_USER, USER, or id -un
    local id_user
    id_user="$(id -un)"
    if [[ "${active_user}" != "${SUDO_USER:-}" && "${active_user}" != "${USER:-}" && "${active_user}" != "${id_user}" ]]; then
        echo "Error: Resolved user '${active_user}' does not match expectations" >&2
        return 1
    fi
    return 0
}

# Verifies YYYY-MM-DD HH:MM:SS timestamp structure.
test_timestamp() {
    local ts
    ts="$(utils::timestamp)"
    local expected_regex="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
    if [[ ! "${ts}" =~ ${expected_regex} ]]; then
        echo "Error: Timestamp '${ts}' does not match expected format YYYY-MM-DD HH:MM:SS" >&2
        return 1
    fi
    return 0
}

# Verifies pure-Bash whitespace trimming functions on arguments and stdin.
test_trim() {
    # Trim argument strings
    local trimmed
    trimmed="$(utils::trim "   hello world   ")"
    if [[ "${trimmed}" != "hello world" ]]; then
        echo "Error: Trim of argument failed. Got: '${trimmed}'" >&2
        return 1
    fi

    # Trim stdin
    trimmed="$(echo "   hello from stdin   " | utils::trim)"
    if [[ "${trimmed}" != "hello from stdin" ]]; then
        echo "Error: Trim of stdin failed. Got: '${trimmed}'" >&2
        return 1
    fi
    return 0
}

# Verifies pure-Bash array joins with delimiters.
test_join_by() {
    local joined
    
    # Case 1: Simple join
    joined="$(utils::join_by "," "a" "b" "c")"
    if [[ "${joined}" != "a,b,c" ]]; then
        echo "Error: Join failed. Got: '${joined}'" >&2
        return 1
    fi

    # Case 2: Multi-character delimiter
    joined="$(utils::join_by " - " "one" "two")"
    if [[ "${joined}" != "one - two" ]]; then
        echo "Error: Join failed. Got: '${joined}'" >&2
        return 1
    fi

    # Case 3: Single element join
    joined="$(utils::join_by "," "single")"
    if [[ "${joined}" != "single" ]]; then
        echo "Error: Join of single item failed. Got: '${joined}'" >&2
        return 1
    fi
    return 0
}

# Verifies confirmation prompts for both interactive redirects and non-interactive fallbacks.
test_confirm() {
    local exit_code=0

    # Test interactive emulation by piping input
    echo "yes" | utils::confirm "Proceed?" || exit_code=$?
    if [[ "${exit_code}" -ne 0 ]]; then
        echo "Error: Expected confirmation to pass when feeding 'yes'" >&2
        return 1
    fi

    exit_code=0
    echo "no" | utils::confirm "Proceed?" && exit_code=$? || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected confirmation to fail when feeding 'no'" >&2
        return 1
    fi

    # Test non-interactive default resolution
    # By running in a subshell without a TTY, confirm should return default choice
    exit_code=0
    utils::confirm "Proceed?" "Y" </dev/null || exit_code=$?
    if [[ "${exit_code}" -ne 0 ]]; then
        echo "Error: Expected non-interactive confirm with default Y to succeed" >&2
        return 1
    fi

    exit_code=0
    utils::confirm "Proceed?" "N" </dev/null && exit_code=$? || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected non-interactive confirm with default N to fail" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-utils.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_is_root
run_test test_current_user
run_test test_timestamp
run_test test_trim
run_test test_join_by
run_test test_confirm

echo "All test-utils.sh tests passed!"
echo "============================================================"
