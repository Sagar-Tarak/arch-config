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
# Arch Linux Configuration Framework - checks.sh Unit Test Suite
# File: tests/test-checks.sh
# Purpose: Verifies that each pre-flight check function returns the correct
#          exit code for both passing and failing conditions. Tests use
#          controlled environments (mocked functions, temp directories) to
#          exercise all code paths without relying on live system state.
# Dependencies: bootstrap/loader.sh, bootstrap/variables.sh,
#               bootstrap/environment.sh, bootstrap/checks.sh
# ==============================================================================

source "${SCRIPT_DIR}/../bootstrap/loader.sh"
loader::load_libs
source "${SCRIPT_DIR}/../bootstrap/variables.sh"
variables::load
source "${SCRIPT_DIR}/../bootstrap/environment.sh"
source "${SCRIPT_DIR}/../bootstrap/checks.sh"

run_test() {
    local test_name="${1}"
    printf "Running %s... " "${test_name}"
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

# Verifies checks.sh sources cleanly.
test_checks_sources_cleanly() {
    source "${SCRIPT_DIR}/../bootstrap/checks.sh"
    return 0
}

# Verifies double-sourcing is idempotent.
test_checks_double_source_idempotent() {
    source "${SCRIPT_DIR}/../bootstrap/checks.sh"
    source "${SCRIPT_DIR}/../bootstrap/checks.sh"
    return 0
}

# --- checks::check_arch ---

# Simulates Arch Linux and expects check_arch to pass.
test_checks_check_arch_passes_on_arch() {
    environment::is_arch_linux() { return 0; }
    checks::check_arch
}

# Simulates a non-Arch OS and expects check_arch to fail.
test_checks_check_arch_fails_on_non_arch() {
    environment::is_arch_linux() { return 1; }
    if checks::check_arch; then
        echo "Error: check_arch should have failed on a non-Arch OS" >&2
        return 1
    fi
    return 0
}

# --- checks::check_internet ---

# Simulates connectivity and expects check_internet to pass.
test_checks_check_internet_passes_when_connected() {
    environment::has_internet() { return 0; }
    checks::check_internet
}

# Simulates no connectivity and expects check_internet to fail.
test_checks_check_internet_fails_when_disconnected() {
    environment::has_internet() { return 1; }
    if checks::check_internet; then
        echo "Error: check_internet should have failed when disconnected" >&2
        return 1
    fi
    return 0
}

# --- checks::check_disk_space ---

# Verifies check_disk_space passes with a 0 GiB minimum (always enough).
test_checks_check_disk_space_passes_zero_minimum() {
    checks::check_disk_space 0 /
}

# Verifies check_disk_space fails when requirement exceeds available space.
test_checks_check_disk_space_fails_on_huge_requirement() {
    if checks::check_disk_space 9999999 /; then
        echo "Error: check_disk_space should have failed for 9999999 GiB requirement" >&2
        return 1
    fi
    return 0
}

# --- checks::check_ram ---

# Verifies check_ram passes with a 0 MiB minimum.
test_checks_check_ram_passes_zero_minimum() {
    checks::check_ram 0
}

# Verifies check_ram fails when requirement exceeds available RAM.
test_checks_check_ram_fails_on_huge_requirement() {
    if checks::check_ram 9999999; then
        echo "Error: check_ram should have failed for 9999999 MiB requirement" >&2
        return 1
    fi
    return 0
}

# --- checks::check_root ---

# Simulates non-root user and expects check_root to pass.
test_checks_check_root_passes_when_not_root() {
    environment::is_root() { return 1; }
    checks::check_root
}

# Simulates root user and expects check_root to fail.
test_checks_check_root_fails_when_root() {
    environment::is_root() { return 0; }
    if checks::check_root; then
        echo "Error: check_root should have failed when running as root" >&2
        return 1
    fi
    return 0
}

# --- checks::check_supported_shell ---

# Simulates a supported shell and expects check to pass.
test_checks_check_supported_shell_passes_for_bash() {
    environment::detect_shell() { echo "bash"; }
    checks::check_supported_shell
}

test_checks_check_supported_shell_passes_for_zsh() {
    environment::detect_shell() { echo "zsh"; }
    checks::check_supported_shell
}

test_checks_check_supported_shell_passes_for_fish() {
    environment::detect_shell() { echo "fish"; }
    checks::check_supported_shell
}

# Simulates an unsupported shell and expects check to fail.
test_checks_check_supported_shell_fails_for_unknown() {
    environment::detect_shell() { echo "tcsh"; }
    if checks::check_supported_shell; then
        echo "Error: check_supported_shell should have failed for tcsh" >&2
        return 1
    fi
    return 0
}

# --- checks::check_required_commands ---

# Verifies check passes when all commands are present.
test_checks_check_required_commands_passes_for_existing() {
    # bash is always present in the test environment
    checks::check_required_commands bash
}

# Verifies check fails for a deliberately non-existent command.
test_checks_check_required_commands_fails_for_missing() {
    if checks::check_required_commands "__nonexistent_cmd_xyz__"; then
        echo "Error: check_required_commands should have failed for missing command" >&2
        return 1
    fi
    return 0
}

# Verifies partial failure: one present + one missing = fail.
test_checks_check_required_commands_fails_on_partial_missing() {
    if checks::check_required_commands bash "__nonexistent_cmd_xyz__"; then
        echo "Error: check_required_commands should fail when any command is missing" >&2
        return 1
    fi
    return 0
}

# --- checks::check_project_structure ---

# Verifies check passes when PROJECT_ROOT contains expected dirs.
test_checks_check_project_structure_passes_on_valid_root() {
    # The real project root has both lib/ and bootstrap/ directories
    checks::check_project_structure
}

# Verifies check fails when PROJECT_ROOT points to a temp directory lacking structure.
test_checks_check_project_structure_fails_on_invalid_root() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    PROJECT_ROOT="${tmp_dir}"
    local result=0
    if checks::check_project_structure; then
        echo "Error: check_project_structure should have failed for empty temp dir" >&2
        result=1
    fi
    rm -rf "${tmp_dir}"
    return "${result}"
}

# Verifies check fails when PROJECT_ROOT is unset.
test_checks_check_project_structure_fails_when_root_unset() {
    local saved="${PROJECT_ROOT}"
    unset PROJECT_ROOT
    local result=0
    if checks::check_project_structure; then
        echo "Error: check_project_structure should have failed when PROJECT_ROOT is unset" >&2
        result=1
    fi
    export PROJECT_ROOT="${saved}"
    return "${result}"
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-checks.sh"
echo "============================================================"

run_test test_checks_sources_cleanly
run_test test_checks_double_source_idempotent
run_test test_checks_check_arch_passes_on_arch
run_test test_checks_check_arch_fails_on_non_arch
run_test test_checks_check_internet_passes_when_connected
run_test test_checks_check_internet_fails_when_disconnected
run_test test_checks_check_disk_space_passes_zero_minimum
run_test test_checks_check_disk_space_fails_on_huge_requirement
run_test test_checks_check_ram_passes_zero_minimum
run_test test_checks_check_ram_fails_on_huge_requirement
run_test test_checks_check_root_passes_when_not_root
run_test test_checks_check_root_fails_when_root
run_test test_checks_check_supported_shell_passes_for_bash
run_test test_checks_check_supported_shell_passes_for_zsh
run_test test_checks_check_supported_shell_passes_for_fish
run_test test_checks_check_supported_shell_fails_for_unknown
run_test test_checks_check_required_commands_passes_for_existing
run_test test_checks_check_required_commands_fails_for_missing
run_test test_checks_check_required_commands_fails_on_partial_missing
run_test test_checks_check_project_structure_passes_on_valid_root
run_test test_checks_check_project_structure_fails_on_invalid_root
run_test test_checks_check_project_structure_fails_when_root_unset

echo "All test-checks.sh tests passed!"
echo "============================================================"
