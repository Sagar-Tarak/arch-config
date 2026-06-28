#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_INSTALL_INCLUDED=1

rofi::install() {
    log::step "Rofi application launcher (wayland fork)" "ROFI"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: rofi" "ROFI"
        return 0
    fi

    log::info "rofi module (Phase 5+ implementation)" "ROFI"
    return 0
}
