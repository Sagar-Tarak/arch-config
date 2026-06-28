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
# Arch Linux Configuration Framework - package.sh Unit Test Suite
# File: tests/test-package.sh
# Purpose: Verifies package manager abstraction layer (has_manager, detect_aur_helper,
#          is_installed, and install interface) by mocking package command line utilities.
# Dependencies: lib/package.sh
# ==============================================================================

# Setup transient mock directory for binaries
MOCK_BIN_DIR="$(mktemp -d /tmp/arch_cfg_test_pkg_bin.XXXXXX)"
readonly MOCK_BIN_DIR

# Prepend mock directory to PATH to override system packages
export PATH="${MOCK_BIN_DIR}:${PATH}"

# Source the package library
source "${SCRIPT_DIR}/../lib/package.sh"

# Ensure cleanup on exit
cleanup() {
    rm -rf "${MOCK_BIN_DIR}"
}
trap cleanup EXIT

# Helper to dynamically mock binaries
# @arg1 string name Binary name (e.g. pacman)
# @arg2 string code The script contents to execute
mock_bin() {
    local name="${1}"
    local code="${2}"
    echo -e "#!/bin/sh\n${code}" > "${MOCK_BIN_DIR}/${name}"
    chmod +x "${MOCK_BIN_DIR}/${name}"
}

# Helper to remove a mock
# @arg1 string name Binary name
unmock_bin() {
    local name="${1}"
    rm -f "${MOCK_BIN_DIR}/${name}"
}

# @description Runs a test case, printing colored output indicating status.
# @arg1 string test_name The name of the test function.
run_test() {
    local test_name="${1}"
    printf "Running %s... " "${test_name}"
    
    # Run test in subshell to isolate mocked paths
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

# Verifies that importing package.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/package.sh"
    return 0
}

# Verifies manager availability checks
test_has_manager() {
    # Mock a fake manager command
    mock_bin "myfakeinstaller" "exit 0"
    
    if ! package::has_manager "myfakeinstaller"; then
        echo "Error: Expected has_manager to return true for myfakeinstaller" >&2
        return 1
    fi

    unmock_bin "myfakeinstaller"
    if package::has_manager "myfakeinstaller"; then
        echo "Error: Expected has_manager to return false after removing mock" >&2
        return 1
    fi
    return 0
}

# Verifies AUR helper preference detection
test_detect_aur_helper() {
    local detected

    # Case 1: Both paru and yay exist -> Should prefer paru
    mock_bin "paru" "exit 0"
    mock_bin "yay" "exit 0"
    detected="$(package::detect_aur_helper)"
    if [[ "${detected}" != "paru" ]]; then
        echo "Error: Expected 'paru' as preferred AUR helper, got '${detected}'" >&2
        return 1
    fi

    # Case 2: Only yay exists
    unmock_bin "paru"
    detected="$(package::detect_aur_helper)"
    if [[ "${detected}" != "yay" ]]; then
        echo "Error: Expected 'yay' when paru is missing, got '${detected}'" >&2
        return 1
    fi

    # Case 3: Neither exists
    unmock_bin "yay"
    local exit_code=0
    package::detect_aur_helper >/dev/null 2>&1 || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected detect_aur_helper to return error when no helper exists" >&2
        return 1
    fi
    return 0
}

# Verifies query results for pacman and flatpak under mock environments
test_is_installed() {
    # Mock pacman query behavior
    # Pacman exits 0 if package found, exits 1 otherwise
    mock_bin "pacman" '
        if [ "$1" = "-Qq" ] && [ "$2" = "neovim" ]; then
            echo "neovim 0.9.0"
            exit 0
        else
            exit 1
        fi
    '

    # Mock flatpak query behavior
    mock_bin "flatpak" '
        if [ "$1" = "info" ] && [ "$2" = "org.gimp.GIMP" ]; then
            echo "GIMP paint program"
            exit 0
        else
            exit 1
        fi
    '

    # Check pacman installed package
    if ! package::is_installed "neovim" "pacman"; then
        echo "Error: Expected 'neovim' to be reported as installed" >&2
        return 1
    fi

    # Check pacman non-installed package
    if package::is_installed "emacs" "pacman"; then
        echo "Error: Expected 'emacs' to be reported as not installed" >&2
        return 1
    fi

    # Check flatpak installed package (auto-detected via domain style app id)
    if ! package::is_installed "org.gimp.GIMP"; then
        echo "Error: Expected 'org.gimp.GIMP' flatpak app to be reported as installed" >&2
        return 1
    fi

    # Check flatpak non-installed package
    if package::is_installed "org.blender.Blender" "flatpak"; then
        echo "Error: Expected 'org.blender.Blender' flatpak app to be reported as not installed" >&2
        return 1
    fi
    return 0
}

# Verifies that installer helper prevents double installations and handles dry-run configs
test_install_simulation() {
    # Mock pacman query to indicate "neovim" is installed, but "emacs" is not
    mock_bin "pacman" '
        if [ "$1" = "-Qq" ] && [ "$2" = "neovim" ]; then
            exit 0
        else
            exit 1
        fi
    '

    local output

    # Case 1: Already installed package -> Should skip
    output="$(export NO_COLOR=1; package::install "neovim" "pacman" 2>&1)"
    if [[ ! "${output}" =~ [Aa]lready\ installed ]]; then
        echo "Error: Expected installation to skip for already installed package. Output: '${output}'" >&2
        return 1
    fi

    # Case 2: Dry-run for new package (avoids calling real pacman)
    output="$(export NO_COLOR=1; export ARCH_CFG_DRY_RUN=true; package::install "emacs" "pacman" 2>&1)"
    if [[ ! "${output}" =~ [Ii]nstall ]]; then
        echo "Error: Expected install log. Output: '${output}'" >&2
        return 1
    fi

    # Case 3: Dry-run log includes package name
    output="$(export NO_COLOR=1; export ARCH_CFG_DRY_RUN=true; package::install "emacs" "pacman" 2>&1)"
    if [[ ! "${output}" =~ "emacs" ]]; then
        echo "Error: Expected dry-run install log to mention package. Output: '${output}'" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-package.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_has_manager
run_test test_detect_aur_helper
run_test test_is_installed
run_test test_install_simulation

echo "All test-package.sh tests passed!"
echo "============================================================"
