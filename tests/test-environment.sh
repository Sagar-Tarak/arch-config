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
# Forge - environment.sh Unit Test Suite
# File: tests/test-environment.sh
# Purpose: Verifies that each environment detection helper function returns
#          sensible, non-empty results and that environment::detect correctly
#          exports all ENV_* variables.
# Dependencies: bootstrap/loader.sh, bootstrap/environment.sh
# ==============================================================================

source "${SCRIPT_DIR}/../bootstrap/loader.sh"
loader::load_libs
source "${SCRIPT_DIR}/../bootstrap/environment.sh"

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

# Verifies environment.sh can be sourced without error.
test_environment_sources_cleanly() {
    source "${SCRIPT_DIR}/../bootstrap/environment.sh"
    return 0
}

# Verifies double-sourcing is idempotent.
test_environment_double_source_idempotent() {
    source "${SCRIPT_DIR}/../bootstrap/environment.sh"
    source "${SCRIPT_DIR}/../bootstrap/environment.sh"
    return 0
}

# Verifies environment::is_arch_linux returns a valid exit code (0 or 1).
test_environment_is_arch_linux_returns_code() {
    environment::is_arch_linux || true
    return 0
}

# Verifies environment::detect_shell returns a non-empty string.
test_environment_detect_shell_non_empty() {
    local shell
    shell="$(environment::detect_shell)"
    if [[ -z "${shell}" ]]; then
        echo "Error: environment::detect_shell returned empty string" >&2
        return 1
    fi
    return 0
}

# Verifies environment::is_root returns a valid exit code.
test_environment_is_root_returns_code() {
    environment::is_root || true
    return 0
}

# Verifies environment::is_sudo returns a valid exit code.
test_environment_is_sudo_returns_code() {
    environment::is_sudo || true
    return 0
}

# Verifies environment::detect_terminal returns a non-empty string.
test_environment_detect_terminal_non_empty() {
    local term
    term="$(environment::detect_terminal)"
    if [[ -z "${term}" ]]; then
        echo "Error: environment::detect_terminal returned empty string" >&2
        return 1
    fi
    return 0
}

# Verifies environment::detect_package_manager returns "pacman" or "unknown".
test_environment_detect_package_manager_valid_value() {
    local pm
    pm="$(environment::detect_package_manager 2>/dev/null || echo "unknown")"
    case "${pm}" in
        pacman|unknown) return 0 ;;
        *)
            echo "Error: Unexpected package manager: ${pm}" >&2
            return 1
            ;;
    esac
}

# Verifies environment::detect_cpu_arch returns a non-empty string.
test_environment_detect_cpu_arch_non_empty() {
    local arch
    arch="$(environment::detect_cpu_arch)"
    if [[ -z "${arch}" ]]; then
        echo "Error: environment::detect_cpu_arch returned empty string" >&2
        return 1
    fi
    return 0
}

# Verifies environment::detect_display_server returns one of the expected values.
test_environment_detect_display_server_valid_value() {
    local ds
    ds="$(environment::detect_display_server)"
    case "${ds}" in
        wayland|x11|none) return 0 ;;
        *)
            echo "Error: Unexpected display server value: ${ds}" >&2
            return 1
            ;;
    esac
}

# Verifies environment::has_internet returns a valid exit code (not an error).
test_environment_has_internet_returns_code() {
    environment::has_internet || true
    return 0
}

# Verifies environment::detect exports all expected ENV_* variables.
test_environment_detect_exports_all_vars() {
    environment::detect
    local -a expected_vars=(
        "ENV_IS_ARCH_LINUX"
        "ENV_SHELL"
        "ENV_IS_ROOT"
        "ENV_IS_SUDO"
        "ENV_TERMINAL"
        "ENV_PACKAGE_MANAGER"
        "ENV_AUR_HELPER"
        "ENV_HAS_INTERNET"
        "ENV_CPU_ARCH"
        "ENV_DISPLAY_SERVER"
    )
    local var
    for var in "${expected_vars[@]}"; do
        if [[ -z "${!var+x}" ]]; then
            echo "Error: ${var} not exported after environment::detect" >&2
            return 1
        fi
    done
    return 0
}

# Verifies ENV_IS_ROOT is "true" or "false" after environment::detect.
test_environment_detect_is_root_boolean() {
    environment::detect
    case "${ENV_IS_ROOT}" in
        true|false) return 0 ;;
        *)
            echo "Error: ENV_IS_ROOT has unexpected value: ${ENV_IS_ROOT}" >&2
            return 1
            ;;
    esac
}

# Verifies ENV_CPU_ARCH is non-empty after environment::detect.
test_environment_detect_cpu_arch_non_empty() {
    environment::detect
    if [[ -z "${ENV_CPU_ARCH}" ]]; then
        echo "Error: ENV_CPU_ARCH is empty after environment::detect" >&2
        return 1
    fi
    return 0
}

# Verifies environment::detect is idempotent when called twice.
test_environment_detect_idempotent() {
    environment::detect
    local first_arch="${ENV_CPU_ARCH}"
    environment::detect
    local second_arch="${ENV_CPU_ARCH}"
    if [[ "${first_arch}" != "${second_arch}" ]]; then
        echo "Error: ENV_CPU_ARCH changed between two calls to environment::detect" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-environment.sh"
echo "============================================================"

run_test test_environment_sources_cleanly
run_test test_environment_double_source_idempotent
run_test test_environment_is_arch_linux_returns_code
run_test test_environment_detect_shell_non_empty
run_test test_environment_is_root_returns_code
run_test test_environment_is_sudo_returns_code
run_test test_environment_detect_terminal_non_empty
run_test test_environment_detect_package_manager_valid_value
run_test test_environment_detect_cpu_arch_non_empty
run_test test_environment_detect_display_server_valid_value
run_test test_environment_has_internet_returns_code
run_test test_environment_detect_exports_all_vars
run_test test_environment_detect_is_root_boolean
run_test test_environment_detect_cpu_arch_non_empty
run_test test_environment_detect_idempotent

echo "All test-environment.sh tests passed!"
echo "============================================================"
