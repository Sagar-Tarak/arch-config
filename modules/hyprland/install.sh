#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLAND_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLAND_INSTALL_INCLUDED=1

# @description Installs the Hyprland compositor and supporting Wayland stack.
# @exit 0 on success
hyprland::install() {
    log::step "Hyprland Module" "HYPRLAND"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: hyprland wofi dunst swww grim slurp wl-clipboard" "HYPRLAND"
        log::info "[DRY-RUN] Would install (AUR): hyprpicker hypridle hyprlock" "HYPRLAND"
        log::info "[DRY-RUN] Would deploy: ~/.config/hypr/" "HYPRLAND"
        return 0
    fi

    log::info "Hyprland module installation (Phase 3+ implementation)" "HYPRLAND"
    return 0
}
