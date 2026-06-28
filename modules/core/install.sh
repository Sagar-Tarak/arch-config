#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_INSTALL_INCLUDED=1

# ==============================================================================
# Module: core — Installation
# Purpose: Initializes the framework runtime directory structure under
#          RUNTIME_DIR (~/.local/share/arch-config/). Must run before any
#          other module. Idempotent — safe to call multiple times.
# ==============================================================================

# @description Creates the runtime directory layout, metadata JSON files,
#              registers the core module, and records the run in history.
# @exit 0 on success, 1 on failure
core::install() {
    log::step "Core Module" "CORE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would create runtime directory: ${RUNTIME_DIR}/" "CORE"
        log::info "[DRY-RUN] Would create subdirs: backups/ cache/ logs/ runtime/ state/ transactions/" "CORE"
        log::info "[DRY-RUN] Would initialize: install.json, modules.json, history.json" "CORE"
        log::info "[DRY-RUN] Would register: core v${MODULE_VERSION:-1.0.0}" "CORE"
        return 0
    fi

    # ------------------------------------------------------------------
    # Idempotency: log if already initialized, but continue to ensure
    # all dirs/files exist (handles partial installs gracefully).
    # ------------------------------------------------------------------
    if state::is_module_installed "core" 2>/dev/null; then
        log::info "Core already installed — verifying runtime layout is complete." "CORE"
    fi

    # ------------------------------------------------------------------
    # Lock: prevent concurrent installer runs
    # ------------------------------------------------------------------
    if ! state::lock_acquire; then
        log::error "Could not acquire lock. Aborting core install." "CORE"
        return 1
    fi

    # Ensure lock is always released, even on error
    trap 'state::lock_release' RETURN

    # ------------------------------------------------------------------
    # Transaction: record every operation
    # ------------------------------------------------------------------
    local tx_id
    tx_id="$(transaction::begin)"

    # ------------------------------------------------------------------
    # Step 1: Create runtime directories
    # ------------------------------------------------------------------
    local -a runtime_dirs=(
        "${RUNTIME_DIR}"
        "${RUNTIME_BACKUPS_DIR}"
        "${RUNTIME_CACHE_DIR}"
        "${RUNTIME_LOGS_DIR}"
        "${RUNTIME_RUNTIME_DIR}"
        "${RUNTIME_STATE_DIR}"
        "${RUNTIME_TRANSACTIONS_DIR}"
        "${RUNTIME_STATE_DIR}/modules"
    )

    local dir
    for dir in "${runtime_dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}"
            chmod 700 "${dir}"
            log::info "Created: ${dir}" "CORE"
            transaction::record "mkdir" "${dir}"
        fi
    done

    # ------------------------------------------------------------------
    # Step 2: Initialize metadata JSON files
    # ------------------------------------------------------------------
    state::init_install_json
    transaction::record "create" "${STATE_INSTALL_JSON}"

    state::init_modules_json
    transaction::record "create" "${STATE_MODULES_JSON}"

    state::init_history_json
    transaction::record "create" "${STATE_HISTORY_JSON}"

    # ------------------------------------------------------------------
    # Step 3: Register core as installed
    # ------------------------------------------------------------------
    state::register_module "core" "${MODULE_VERSION:-1.0.0}"
    transaction::record "register" "core"

    # ------------------------------------------------------------------
    # Step 4: Append run to history
    # ------------------------------------------------------------------
    state::append_history "${0:-install.sh} --module core" "success"
    transaction::record "history" "append"

    # ------------------------------------------------------------------
    # Commit
    # ------------------------------------------------------------------
    transaction::commit

    log::success "Core runtime initialized at: ${RUNTIME_DIR}" "CORE"
    return 0
}
