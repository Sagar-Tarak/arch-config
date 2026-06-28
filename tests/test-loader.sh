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
# Arch Linux Configuration Framework - loader.sh Unit Test Suite
# File: tests/test-loader.sh
# Purpose: Verifies that bootstrap/loader.sh correctly resolves the lib/
#          directory, sources all six core libraries, and is safe to load
#          multiple times (idempotent).
# Dependencies: bootstrap/loader.sh
# ==============================================================================

source "${SCRIPT_DIR}/../bootstrap/loader.sh"

# @description Runs a test case, printing pass/fail status.
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

# Verifies loader.sh can be sourced without error.
test_loader_sources_cleanly() {
    source "${SCRIPT_DIR}/../bootstrap/loader.sh"
    return 0
}

# Verifies that double-sourcing loader.sh is idempotent (guard works).
test_loader_double_source_idempotent() {
    source "${SCRIPT_DIR}/../bootstrap/loader.sh"
    source "${SCRIPT_DIR}/../bootstrap/loader.sh"
    return 0
}

# Verifies loader::lib_path returns a non-empty absolute path.
test_loader_lib_path_non_empty() {
    local path
    path="$(loader::lib_path)"
    if [[ -z "${path}" ]]; then
        echo "Error: loader::lib_path returned empty string" >&2
        return 1
    fi
    if [[ ! -d "${path}" ]]; then
        echo "Error: loader::lib_path returned a path that is not a directory: ${path}" >&2
        return 1
    fi
    return 0
}

# Verifies loader::load_libs successfully loads all six core libraries.
test_loader_load_libs_success() {
    loader::load_libs
    # All six sourcing guard vars must be set after loading
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
            echo "Error: Library guard not set after load_libs: ${guard}" >&2
            return 1
        fi
    done
    return 0
}

# Verifies that calling loader::load_libs a second time does not error.
test_loader_load_libs_idempotent() {
    loader::load_libs
    loader::load_libs
    return 0
}

# Verifies that key functions from each library are callable after loading.
test_loader_functions_available() {
    loader::load_libs
    local -a fns=(
        "colors::enable_colors"
        "log::info"
        "command::command_exists"
        "fs::ensure_directory"
        "package::has_manager"
        "utils::is_root"
    )
    local fn
    for fn in "${fns[@]}"; do
        if ! declare -f "${fn}" &>/dev/null; then
            echo "Error: Function not available after load_libs: ${fn}" >&2
            return 1
        fi
    done
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-loader.sh"
echo "============================================================"

run_test test_loader_sources_cleanly
run_test test_loader_double_source_idempotent
run_test test_loader_lib_path_non_empty
run_test test_loader_load_libs_success
run_test test_loader_load_libs_idempotent
run_test test_loader_functions_available

echo "All test-loader.sh tests passed!"
echo "============================================================"
