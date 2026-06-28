#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ZEN_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ZEN_UNINSTALL_INCLUDED=1

zen::uninstall() {
    log::step "Uninstalling zen" "ZEN"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove zen config" "ZEN"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "ZEN"
    return 0
}
