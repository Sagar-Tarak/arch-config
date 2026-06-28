#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_UNINSTALL_INCLUDED=1

# ==============================================================================
# Module: core — Uninstallation
# Purpose: Removes the framework runtime directory (RUNTIME_DIR) including
#          all state, metadata, and transaction logs.
#          Backups are intentionally preserved (RUNTIME_BACKUPS_DIR is kept).
#          This is destructive — all other modules must be uninstalled first.
# ==============================================================================

# @description Removes the core runtime directory structure.
#              Backups are NOT removed.
# @exit 0 on success
core::uninstall() {
    log::step "Uninstalling Core Module" "CORE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove: ${RUNTIME_CACHE_DIR}" "CORE"
        log::info "[DRY-RUN] Would remove: ${RUNTIME_LOGS_DIR}" "CORE"
        log::info "[DRY-RUN] Would remove: ${RUNTIME_RUNTIME_DIR}" "CORE"
        log::info "[DRY-RUN] Would remove: ${RUNTIME_STATE_DIR}" "CORE"
        log::info "[DRY-RUN] Would remove: ${RUNTIME_TRANSACTIONS_DIR}" "CORE"
        log::info "[DRY-RUN] Would remove: ${STATE_INSTALL_JSON}" "CORE"
        log::info "[DRY-RUN] Would remove: ${STATE_MODULES_JSON}" "CORE"
        log::info "[DRY-RUN] Would remove: ${STATE_HISTORY_JSON}" "CORE"
        log::info "[DRY-RUN] Backups preserved: ${RUNTIME_BACKUPS_DIR}" "CORE"
        return 0
    fi

    if [[ ! -d "${RUNTIME_DIR}" ]]; then
        log::warn "Runtime directory does not exist; nothing to uninstall." "CORE"
        return 0
    fi

    # Release stale lock if we own it
    state::lock_release 2>/dev/null || true

    # Remove runtime subdirectories (backups are intentionally skipped)
    local -a remove_dirs=(
        "${RUNTIME_CACHE_DIR}"
        "${RUNTIME_LOGS_DIR}"
        "${RUNTIME_RUNTIME_DIR}"
        "${RUNTIME_STATE_DIR}"
        "${RUNTIME_TRANSACTIONS_DIR}"
    )

    local dir
    for dir in "${remove_dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            rm -rf "${dir}"
            log::info "Removed: ${dir}" "CORE"
        fi
    done

    # Remove metadata JSON files
    local json_file
    for json_file in "${STATE_INSTALL_JSON}" "${STATE_MODULES_JSON}" "${STATE_HISTORY_JSON}"; do
        if [[ -f "${json_file}" ]]; then
            rm -f "${json_file}"
            log::info "Removed: ${json_file}" "CORE"
        fi
    done

    # Remove RUNTIME_DIR itself only if now empty (backups may remain)
    if [[ -d "${RUNTIME_DIR}" ]] && [[ -z "$(ls -A "${RUNTIME_DIR}" 2>/dev/null)" ]]; then
        rmdir "${RUNTIME_DIR}"
        log::info "Removed: ${RUNTIME_DIR}" "CORE"
    else
        log::info "Preserved non-empty runtime root (backups remain): ${RUNTIME_DIR}" "CORE"
    fi

    log::success "Core runtime removed." "CORE"
    return 0
}
