#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_THUNAR_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_THUNAR_INSTALL_INCLUDED=1

thunar::install() {
    log::step "Thunar graphical file manager" "THUNAR"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: thunar" "THUNAR"
        return 0
    fi

    log::info "thunar module (Phase 5+ implementation)" "THUNAR"
    return 0
}
