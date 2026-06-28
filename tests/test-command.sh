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
# Arch Linux Configuration Framework - command.sh Unit Test Suite
# File: tests/test-command.sh
# Purpose: Verifies execution helpers, command availability queries, error exits,
#          and quiet log-capturing features.
# Dependencies: lib/command.sh
# ==============================================================================

# Source the command library
source "${SCRIPT_DIR}/../lib/command.sh"

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

# Verifies that importing command.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/command.sh"
    return 0
}

# Verifies that command_exists works for valid/invalid executables.
test_command_exists() {
    # 'bash' must exist
    if ! command::command_exists "bash"; then
        echo "Error: Expected 'bash' command to exist" >&2
        return 1
    fi
    # Delegate check
    if ! command_exists "bash"; then
        echo "Error: Expected delegate command_exists to succeed for 'bash'" >&2
        return 1
    fi

    # Non-existent command check
    if command::command_exists "non_existent_command_12345_xyz"; then
        echo "Error: Expected command 'non_existent_command_12345_xyz' to not exist" >&2
        return 1
    fi
    return 0
}

# Verifies that require_command succeeds when it exists, and exits with 10 when it doesn't.
test_require_command() {
    # Checking existing command
    if ! command::require_command "bash"; then
        echo "Error: Expected require_command for 'bash' to succeed" >&2
        return 1
    fi

    # Checking missing command in subshell (to catch the exit 10)
    local exit_code=0
    ( command::require_command "non_existent_command_xyz" ) 2>/dev/null || exit_code=$?
    if [[ "${exit_code}" -ne 10 ]]; then
        echo "Error: Expected require_command for missing utility to exit with status 10, got ${exit_code}" >&2
        return 1
    fi
    return 0
}

# Verifies basic run command success and dry-run toggle output simulation.
test_run_success() {
    local output
    output="$(command::run echo "hello")"
    if [[ "${output}" != "hello" ]]; then
        echo "Error: Command run output mismatch: '${output}'" >&2
        return 1
    fi

    # Test with dry-run active
    output="$(export ARCH_CFG_DRY_RUN=true; command::run echo "hello")"
    if [[ "${output}" == "hello" ]]; then
        echo "Error: Expected command to be bypassed when ARCH_CFG_DRY_RUN is true" >&2
        return 1
    fi
    return 0
}

# Verifies run_quiet hides output on success, but dumps outputs on command failures.
test_run_quiet() {
    local output
    # Successful run should hide stdout/stderr
    output="$(command::run_quiet echo "should be hidden" 2>&1)"
    if [[ -n "${output}" ]]; then
        echo "Error: Successful run_quiet did not hide stdout: '${output}'" >&2
        return 1
    fi

    # Failing run should print output to stderr
    # We execute a subshell printing an error and returning non-zero status
    local exit_code=0
    output="$(command::run_quiet bash -c "echo 'error log' >&2; exit 42" 2>&1)" || exit_code=$?
    if [[ "${exit_code}" -ne 42 ]]; then
        echo "Error: Expected exit code 42 from failing quiet command, got ${exit_code}" >&2
        return 1
    fi
    if [[ ! "${output}" =~ "error log" ]]; then
        echo "Error: Expected error log output to be printed to stderr, got: '${output}'" >&2
        return 1
    fi
    return 0
}

# Verifies run_checked succeeds on success, and halts/exits the process on failure.
test_run_checked() {
    if ! command::run_checked echo "checked ok" >/dev/null; then
        echo "Error: Expected run_checked to succeed for echo" >&2
        return 1
    fi

    local exit_code=0
    ( command::run_checked false ) 2>/dev/null || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected run_checked to exit on command failure" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-command.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_command_exists
run_test test_require_command
run_test test_run_success
run_test test_run_quiet
run_test test_run_checked

echo "All test-command.sh tests passed!"
echo "============================================================"
