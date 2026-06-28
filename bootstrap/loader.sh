#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_LOADER_SH_INCLUDED:-}" ]]; then
    return 0
fi
_LOADER_SH_INCLUDED=1

# ==============================================================================
# Forge - Library Loader
# File: bootstrap/loader.sh
# Purpose: Safely sources all core lib/ libraries in dependency order with
#          duplicate-load protection. All other bootstrap components depend on
#          this file being sourced first.
# Dependencies: lib/colors.sh, lib/logger.sh, lib/command.sh,
#               lib/filesystem.sh, lib/package.sh, lib/utils.sh,
#               lib/state.sh, lib/transaction.sh
# Public API:
#   loader::load_libs  - Sources all six core libraries in correct order
#   loader::lib_path   - Resolves the absolute path to the lib/ directory
# Usage Example:
#   source bootstrap/loader.sh
#   loader::load_libs
# ==============================================================================

# Resolve the lib/ directory relative to this file.
# bootstrap/ and lib/ are siblings under PROJECT_ROOT.
_LOADER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LOADER_LIB_DIR="$(cd "${_LOADER_DIR}/../lib" && pwd)"

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Returns the absolute path to the resolved lib/ directory.
# @noargs
# @stdout Absolute path to lib/
# @exit 0 Always
loader::lib_path() {
    echo "${_LOADER_LIB_DIR}"
}

# @description Sources all core libraries in dependency order.
#              Each library has its own sourcing guard so duplicate calls
#              to this function are harmless.
# @noargs
# @exit 0 on success, 1 if any library file is missing.
loader::load_libs() {
    # Ordered by dependency:
    #   colors → logger → command/filesystem/package/utils → state → transaction
    # state.sh and transaction.sh only reference STATE_* / RUNTIME_* variables
    # inside their function bodies, so they may be sourced before variables::load
    # is called — the variables will be set by the time any function runs.
    local -a _libs=(
        "colors.sh"
        "logger.sh"
        "command.sh"
        "filesystem.sh"
        "package.sh"
        "aur.sh"
        "service.sh"
        "utils.sh"
        "state.sh"
        "transaction.sh"
    )

    local lib
    for lib in "${_libs[@]}"; do
        local lib_path="${_LOADER_LIB_DIR}/${lib}"
        if [[ ! -f "${lib_path}" ]]; then
            echo "Error: Required library not found: ${lib_path}" >&2
            return 1
        fi
        # shellcheck disable=SC1090
        source "${lib_path}"
    done

    return 0
}
