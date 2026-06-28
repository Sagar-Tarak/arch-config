#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_UNINSTALL_INCLUDED=1

rofi::uninstall() {
    log::step "Uninstalling rofi" "ROFI"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove rofi config" "ROFI"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "ROFI"
    return 0
}
