#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_UNINSTALL_INCLUDED=1

swaync::uninstall() {
    log::step "Uninstalling swaync" "SWAYNC"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove swaync config" "SWAYNC"
        return 0
    fi

    log::info "swaync uninstall (Phase 5+ implementation)" "SWAYNC"
    return 0
}
