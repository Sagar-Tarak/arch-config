#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLOCK_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLOCK_UNINSTALL_INCLUDED=1

hyprlock::uninstall() {
    log::step "Uninstalling hyprlock" "HYPRLOCK"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove hyprlock config" "HYPRLOCK"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "HYPRLOCK"
    return 0
}
