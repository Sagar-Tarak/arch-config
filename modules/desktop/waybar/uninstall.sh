#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_WAYBAR_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_WAYBAR_UNINSTALL_INCLUDED=1

# @description Removes Waybar config symlinks.
# @exit 0 on success
waybar::uninstall() {
    log::step "Uninstalling Waybar Module" "WAYBAR"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove ~/.config/waybar symlink" "WAYBAR"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "WAYBAR"
    return 0
}
