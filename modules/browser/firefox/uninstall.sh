#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FIREFOX_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FIREFOX_UNINSTALL_INCLUDED=1

firefox::uninstall() {
    log::step "Uninstalling firefox" "FIREFOX"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove firefox" "FIREFOX"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "FIREFOX"
    return 0
}
