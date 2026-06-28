#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_VERIFY_INCLUDED=1

# ==============================================================================
# Module: core — Verification
# Purpose: Confirms that the runtime directory structure is fully initialized,
#          all metadata JSON files are present and valid, and the core module
#          is registered as installed.
# ==============================================================================

# @description Verifies the core runtime is healthy.
# @exit 0 if all checks pass, 1 if any fail
core::verify() {
    local failed=0

    # ------------------------------------------------------------------
    # Check 1: Runtime directory structure
    # ------------------------------------------------------------------
    local -a required_dirs=(
        "${RUNTIME_DIR}"
        "${RUNTIME_BACKUPS_DIR}"
        "${RUNTIME_CACHE_DIR}"
        "${RUNTIME_LOGS_DIR}"
        "${RUNTIME_RUNTIME_DIR}"
        "${RUNTIME_STATE_DIR}"
        "${RUNTIME_TRANSACTIONS_DIR}"
    )

    local dirs_ok=true
    local dir
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            log::error "Missing runtime directory: ${dir}" "CORE"
            dirs_ok=false
        fi
    done

    if [[ "${dirs_ok}" == "true" ]]; then
        log::success "Runtime initialized" "CORE"
    else
        failed=$(( failed + 1 ))
    fi

    # ------------------------------------------------------------------
    # Check 2: Metadata files exist and contain valid JSON
    # ------------------------------------------------------------------
    local metadata_ok=true
    local json_file
    for json_file in "${STATE_INSTALL_JSON}" "${STATE_MODULES_JSON}" "${STATE_HISTORY_JSON}"; do
        if [[ ! -f "${json_file}" ]]; then
            log::error "Missing metadata file: ${json_file}" "CORE"
            metadata_ok=false
        elif ! state::validate_json "${json_file}"; then
            log::error "Invalid JSON in: ${json_file}" "CORE"
            metadata_ok=false
        fi
    done

    if [[ "${metadata_ok}" == "true" ]]; then
        log::success "Metadata valid" "CORE"
    else
        failed=$(( failed + 1 ))
    fi

    # ------------------------------------------------------------------
    # Check 3: Core module is registered
    # ------------------------------------------------------------------
    if state::is_module_installed "core"; then
        log::success "Core module installed" "CORE"
    else
        log::error "Core module not registered in state" "CORE"
        failed=$(( failed + 1 ))
    fi

    # ------------------------------------------------------------------
    # Check 4: Runtime directories are writable
    # ------------------------------------------------------------------
    if [[ -w "${RUNTIME_DIR}" && -w "${RUNTIME_STATE_DIR}" ]]; then
        log::success "Runtime directories writable" "CORE"
    else
        log::error "Runtime directories are not writable" "CORE"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
