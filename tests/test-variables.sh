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
# Forge - variables.sh Unit Test Suite
# File: tests/test-variables.sh
# Purpose: Verifies that bootstrap/variables.sh exports all expected global
#          variables, computes paths dynamically from PROJECT_ROOT, and is
#          idempotent when called multiple times.
# Dependencies: bootstrap/loader.sh, bootstrap/variables.sh
# ==============================================================================

source "${SCRIPT_DIR}/../bootstrap/loader.sh"
loader::load_libs
source "${SCRIPT_DIR}/../bootstrap/variables.sh"

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

# Verifies variables.sh can be sourced without error.
test_variables_sources_cleanly() {
    source "${SCRIPT_DIR}/../bootstrap/variables.sh"
    return 0
}

# Verifies double-sourcing is idempotent.
test_variables_double_source_idempotent() {
    source "${SCRIPT_DIR}/../bootstrap/variables.sh"
    source "${SCRIPT_DIR}/../bootstrap/variables.sh"
    return 0
}

# Verifies variables::load sets PROJECT_ROOT to an existing directory.
test_variables_project_root_is_directory() {
    variables::load
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        echo "Error: PROJECT_ROOT is empty after variables::load" >&2
        return 1
    fi
    if [[ ! -d "${PROJECT_ROOT}" ]]; then
        echo "Error: PROJECT_ROOT is not a directory: ${PROJECT_ROOT}" >&2
        return 1
    fi
    return 0
}

# Verifies VERSION is a non-empty string after variables::load.
test_variables_version_non_empty() {
    variables::load
    if [[ -z "${VERSION:-}" ]]; then
        echo "Error: VERSION is empty after variables::load" >&2
        return 1
    fi
    return 0
}

# Verifies all expected path variables are exported and non-empty.
test_variables_all_paths_set() {
    variables::load
    local -a expected_vars=(
        "PROJECT_ROOT"
        "CONFIG_DIR"
        "MODULES_DIR"
        "PACKAGES_DIR"
        "THEMES_DIR"
        "DOTFILES_DIR"
        "CACHE_DIR"
        "BACKUP_DIR"
        "LOG_DIR"
        "DEFAULT_PACKAGE_MANAGER"
        "VERSION"
    )
    local var
    for var in "${expected_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Variable ${var} is empty after variables::load" >&2
            return 1
        fi
    done
    return 0
}

# Verifies that path variables are rooted under PROJECT_ROOT (not hardcoded).
test_variables_paths_are_relative_to_root() {
    variables::load
    # CONFIG_DIR should start with PROJECT_ROOT
    if [[ "${CONFIG_DIR}" != "${PROJECT_ROOT}"* ]]; then
        echo "Error: CONFIG_DIR is not under PROJECT_ROOT" >&2
        echo "  PROJECT_ROOT=${PROJECT_ROOT}" >&2
        echo "  CONFIG_DIR=${CONFIG_DIR}" >&2
        return 1
    fi
    if [[ "${MODULES_DIR}" != "${PROJECT_ROOT}"* ]]; then
        echo "Error: MODULES_DIR is not under PROJECT_ROOT" >&2
        return 1
    fi
    return 0
}

# Verifies DEFAULT_PACKAGE_MANAGER is "pacman".
test_variables_default_package_manager() {
    variables::load
    if [[ "${DEFAULT_PACKAGE_MANAGER}" != "pacman" ]]; then
        echo "Error: DEFAULT_PACKAGE_MANAGER is '${DEFAULT_PACKAGE_MANAGER}', expected 'pacman'" >&2
        return 1
    fi
    return 0
}

# Verifies ARCH_CFG_DRY_RUN defaults to "false".
test_variables_dry_run_default() {
    unset ARCH_CFG_DRY_RUN
    variables::load
    if [[ "${ARCH_CFG_DRY_RUN}" != "false" ]]; then
        echo "Error: ARCH_CFG_DRY_RUN defaulted to '${ARCH_CFG_DRY_RUN}', expected 'false'" >&2
        return 1
    fi
    return 0
}

# Verifies that calling variables::load twice produces the same PROJECT_ROOT.
test_variables_load_is_idempotent() {
    variables::load
    local first="${PROJECT_ROOT}"
    variables::load
    local second="${PROJECT_ROOT}"
    if [[ "${first}" != "${second}" ]]; then
        echo "Error: PROJECT_ROOT changed between two calls to variables::load" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-variables.sh"
echo "============================================================"

run_test test_variables_sources_cleanly
run_test test_variables_double_source_idempotent
run_test test_variables_project_root_is_directory
run_test test_variables_version_non_empty
run_test test_variables_all_paths_set
run_test test_variables_paths_are_relative_to_root
run_test test_variables_default_package_manager
run_test test_variables_dry_run_default
run_test test_variables_load_is_idempotent

echo "All test-variables.sh tests passed!"
echo "============================================================"
