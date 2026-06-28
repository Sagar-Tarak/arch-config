#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_WAYBAR_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_WAYBAR_INSTALL_INCLUDED=1

# @description Installs Waybar status bar for Hyprland.
# @exit 0 on success
waybar::install() {
    log::step "Waybar" "WAYBAR"

    local -a _pacman_pkgs=( waybar )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "WAYBAR"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Waybar installed" "WAYBAR"
    return 0
}
