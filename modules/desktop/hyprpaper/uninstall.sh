#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRPAPER_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRPAPER_UNINSTALL_INCLUDED=1

hyprpaper::uninstall() {
    log::step "Uninstalling hyprpaper" "HYPRPAPER"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove hyprpaper config" "HYPRPAPER"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "HYPRPAPER"
    return 0
}
