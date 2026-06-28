#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_INSTALL_INCLUDED=1

# ==============================================================================
# Module: core — Installation
# Purpose: Installs foundational system utilities that every other module
#          depends on. Must run before any other module.
# ==============================================================================

# @description Installs core system utilities via pacman.
# @exit 0 on success
core::install() {
    log::step "Core Module" "CORE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: base-devel curl wget git openssh rsync unzip zip" "CORE"
        return 0
    fi

    log::info "Core module installation (Phase 3+ implementation)" "CORE"
    return 0
}
