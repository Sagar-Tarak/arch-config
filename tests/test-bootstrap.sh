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
# Arch Linux Configuration Framework - bootstrap.sh Unit Test Suite
# File: tests/test-bootstrap.sh
# Purpose: Verifies that bootstrap/bootstrap.sh correctly orchestrates the full
#          bootstrap sequence: sourcing libs, loading variables, detecting the
#          environment, and printing the version banner. Also verifies the
#          bootstrap is idempotent and that bootstrap::init is callable.
# Dependencies: bootstrap/bootstrap.sh
# ==============================================================================

source "${SCRIPT_DIR}/../bootstrap/bootstrap.sh"

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

# Verifies bootstrap.sh can be sourced without error.
test_bootstrap_sources_cleanly() {
    source "${SCRIPT_DIR}/../bootstrap/bootstrap.sh"
    return 0
}

# Verifies double-sourcing bootstrap.sh is idempotent.
test_bootstrap_double_source_idempotent() {
    source "${SCRIPT_DIR}/../bootstrap/bootstrap.sh"
    source "${SCRIPT_DIR}/../bootstrap/bootstrap.sh"
    return 0
}

# Verifies bootstrap::init is callable and succeeds.
test_bootstrap_init_succeeds() {
    bootstrap::init
}

# Verifies bootstrap::init exports PROJECT_ROOT.
test_bootstrap_init_exports_project_root() {
    bootstrap::init
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        echo "Error: PROJECT_ROOT is not set after bootstrap::init" >&2
        return 1
    fi
    if [[ ! -d "${PROJECT_ROOT}" ]]; then
        echo "Error: PROJECT_ROOT is not a valid directory: ${PROJECT_ROOT}" >&2
        return 1
    fi
    return 0
}

# Verifies bootstrap::init exports VERSION.
test_bootstrap_init_exports_version() {
    bootstrap::init
    if [[ -z "${VERSION:-}" ]]; then
        echo "Error: VERSION is not set after bootstrap::init" >&2
        return 1
    fi
    return 0
}

# Verifies bootstrap::init exports ENV_CPU_ARCH.
test_bootstrap_init_exports_env_cpu_arch() {
    bootstrap::init
    if [[ -z "${ENV_CPU_ARCH:-}" ]]; then
        echo "Error: ENV_CPU_ARCH is not set after bootstrap::init" >&2
        return 1
    fi
    return 0
}

# Verifies all six core library guards are set after sourcing bootstrap.sh.
test_bootstrap_all_libs_loaded() {
    source "${SCRIPT_DIR}/../bootstrap/bootstrap.sh"
    local -a guards=(
        "_COLORS_SH_INCLUDED"
        "_LOGGER_SH_INCLUDED"
        "_COMMAND_SH_INCLUDED"
        "_FILESYSTEM_SH_INCLUDED"
        "_PACKAGE_SH_INCLUDED"
        "_UTILS_SH_INCLUDED"
    )
    local guard
    for guard in "${guards[@]}"; do
        if [[ -z "${!guard:-}" ]]; then
            echo "Error: Library guard not set after sourcing bootstrap.sh: ${guard}" >&2
            return 1
        fi
    done
    return 0
}

# Verifies that log::info is available after bootstrap::init.
test_bootstrap_logger_available_after_init() {
    bootstrap::init
    if ! declare -f log::info &>/dev/null; then
        echo "Error: log::info is not available after bootstrap::init" >&2
        return 1
    fi
    return 0
}

# Verifies bootstrap::init is idempotent (safe to call twice).
test_bootstrap_init_idempotent() {
    bootstrap::init
    bootstrap::init
    return 0
}

# Verifies LOG_DIR is set to a non-empty value after bootstrap::init.
test_bootstrap_init_sets_log_dir() {
    bootstrap::init
    if [[ -z "${LOG_DIR:-}" ]]; then
        echo "Error: LOG_DIR is not set after bootstrap::init" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-bootstrap.sh"
echo "============================================================"

run_test test_bootstrap_sources_cleanly
run_test test_bootstrap_double_source_idempotent
run_test test_bootstrap_init_succeeds
run_test test_bootstrap_init_exports_project_root
run_test test_bootstrap_init_exports_version
run_test test_bootstrap_init_exports_env_cpu_arch
run_test test_bootstrap_all_libs_loaded
run_test test_bootstrap_logger_available_after_init
run_test test_bootstrap_init_idempotent
run_test test_bootstrap_init_sets_log_dir

echo "All test-bootstrap.sh tests passed!"
echo "============================================================"
