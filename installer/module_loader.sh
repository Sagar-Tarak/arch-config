#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_MODULE_LOADER_SH_INCLUDED:-}" ]]; then
    return 0
fi
_MODULE_LOADER_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Module Loader
# File: installer/module_loader.sh
# Purpose: Dynamically discovers, loads, and dispatches lifecycle calls for
#          framework modules. Prevents duplicate loading, resolves declared
#          dependencies before loading each module, and provides a clean
#          public API that hides all module-internal naming conventions.
# Dependencies: lib/logger.sh, bootstrap/variables.sh (MODULES_DIR)
# Public API:
#   module_loader::load     - Loads a module (manifest + all lifecycle files)
#   module_loader::exists   - Returns 0 if the named module directory exists
#   module_loader::list     - Prints all discovered module names to stdout
#   module_loader::is_loaded - Returns 0 if the module has already been loaded
#   module::install         - Loads module and calls <name>::install
#   module::verify          - Loads module and calls <name>::verify
#   module::uninstall       - Loads module and calls <name>::uninstall
# Usage Example:
#   source installer/module_loader.sh
#   module_loader::load "git"
#   module::install "git"
#   module::verify  "git"
# ==============================================================================

# Associative array tracking which modules have been fully loaded.
# Declared at file scope so it persists across calls.
declare -A _MODULE_LOADER_LOADED=()

# ==============================================================================
# Namespaced API — module_loader::*
# ==============================================================================

# @description Returns 0 if a module directory exists under MODULES_DIR.
# @arg1 string name Module name (directory basename under modules/)
# @exit 0 if exists, 1 otherwise
module_loader::exists() {
    local name="${1:-}"
    [[ -n "${name}" && -d "${MODULES_DIR}/${name}" ]]
}

# @description Returns 0 if the named module has already been loaded in this
#              session (prevents duplicate sourcing of lifecycle scripts).
# @arg1 string name Module name
# @exit 0 if already loaded, 1 otherwise
module_loader::is_loaded() {
    local name="${1:-}"
    [[ -n "${_MODULE_LOADER_LOADED[${name}]:-}" ]]
}

# @description Prints each discovered module name to stdout, one per line.
#              Iterates over immediate subdirectories of MODULES_DIR.
# @noargs
# @stdout Module names, one per line
# @exit 0 Always
module_loader::list() {
    if [[ ! -d "${MODULES_DIR}" ]]; then
        log::warn "MODULES_DIR does not exist: ${MODULES_DIR}" "LOADER"
        return 0
    fi

    local module_path
    for module_path in "${MODULES_DIR}"/*/; do
        # Skip if glob matched nothing
        [[ -d "${module_path}" ]] || continue
        # Trim trailing slash and extract basename without a fork
        local name="${module_path%/}"
        name="${name##*/}"
        echo "${name}"
    done
}

# @description Sources a module's manifest, resolves its declared dependencies
#              (recursively and in order), then sources all lifecycle files
#              (install.sh, verify.sh, uninstall.sh). Idempotent: calling it
#              a second time for the same module is a no-op.
# @arg1 string name Module name to load
# @exit 0 on success, 1 if the module directory is not found
module_loader::load() {
    local name="${1:-}"

    if [[ -z "${name}" ]]; then
        log::error "module_loader::load requires a module name" "LOADER"
        return 1
    fi

    # Idempotency guard
    if module_loader::is_loaded "${name}"; then
        log::debug "Module '${name}' already loaded — skipping" "LOADER"
        return 0
    fi

    if ! module_loader::exists "${name}"; then
        log::error "Module '${name}' not found at: ${MODULES_DIR}/${name}" "LOADER"
        return 1
    fi

    local module_dir="${MODULES_DIR}/${name}"

    # --- Read manifest (if present) and resolve dependencies first ---
    local manifest_file="${module_dir}/manifest.sh"
    if [[ -f "${manifest_file}" ]]; then
        # Unset module-scoped variables before sourcing to avoid stale values
        # from a previously loaded module leaking into this manifest.
        unset MODULE_NAME MODULE_DESCRIPTION MODULE_VERSION \
              MODULE_DEPENDENCIES MODULE_ARCHITECTURES MODULE_ENABLED_BY_DEFAULT

        # shellcheck source=/dev/null
        source "${manifest_file}"

        # Capture dependency list immediately before loading anything else,
        # so recursive calls do not corrupt the array contents.
        local -a _deps=()
        if [[ -n "${MODULE_DEPENDENCIES[*]+x}" ]]; then
            _deps=("${MODULE_DEPENDENCIES[@]}")
        fi

        local dep
        for dep in "${_deps[@]:-}"; do
            [[ -z "${dep}" ]] && continue
            log::debug "Module '${name}' depends on '${dep}' — loading first" "LOADER"
            module_loader::load "${dep}" || return 1
        done
    fi

    # --- Source lifecycle scripts ---
    local lifecycle_file
    for lifecycle_file in install.sh verify.sh uninstall.sh; do
        local full_path="${module_dir}/${lifecycle_file}"
        if [[ -f "${full_path}" ]]; then
            # shellcheck source=/dev/null
            source "${full_path}"
        else
            log::debug "Module '${name}' has no ${lifecycle_file}" "LOADER"
        fi
    done

    _MODULE_LOADER_LOADED["${name}"]=1
    log::debug "Module loaded: ${name}" "LOADER"
    return 0
}

# ==============================================================================
# Namespaced API — module::* (public dispatch layer)
# ==============================================================================

# @description Loads a module and calls its <name>::install function.
#              The installer calls this and never invokes module internals directly.
# @arg1 string name Module name
# @exit 0 on success, 1 if module cannot be loaded or has no install function
module::install() {
    local name="${1:-}"
    module_loader::load "${name}" || return 1

    local fn="${name}::install"
    if ! declare -f "${fn}" &>/dev/null; then
        log::warn "Module '${name}' does not define ${fn} — skipping install" "MODULE"
        return 0
    fi

    "${fn}"
}

# @description Loads a module and calls its <name>::verify function.
# @arg1 string name Module name
# @exit 0 if verification passes, 1 otherwise
module::verify() {
    local name="${1:-}"
    module_loader::load "${name}" || return 1

    local fn="${name}::verify"
    if ! declare -f "${fn}" &>/dev/null; then
        log::warn "Module '${name}' does not define ${fn} — marking unverified" "MODULE"
        return 1
    fi

    "${fn}"
}

# @description Loads a module and calls its <name>::uninstall function.
# @arg1 string name Module name
# @exit 0 on success, 1 if module cannot be loaded
module::uninstall() {
    local name="${1:-}"
    module_loader::load "${name}" || return 1

    local fn="${name}::uninstall"
    if ! declare -f "${fn}" &>/dev/null; then
        log::warn "Module '${name}' does not define ${fn} — skipping uninstall" "MODULE"
        return 0
    fi

    "${fn}"
}
