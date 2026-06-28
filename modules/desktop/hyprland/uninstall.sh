#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLAND_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLAND_UNINSTALL_INCLUDED=1

# @description Removes Hyprland config symlinks.
# @exit 0 on success
hyprland::uninstall() {
    log::step "Uninstalling Hyprland Module" "HYPRLAND"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove ~/.config/hypr symlink" "HYPRLAND"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "HYPRLAND"
    return 0
}
