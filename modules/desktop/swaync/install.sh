#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_INSTALL_INCLUDED=1

swaync::install() {
    log::step "SwayNotificationCenter notification daemon" "SWAYNC"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: swaync" "SWAYNC"
        return 0
    fi

    log::info "swaync module (Phase 5+ implementation)" "SWAYNC"
    return 0
}
