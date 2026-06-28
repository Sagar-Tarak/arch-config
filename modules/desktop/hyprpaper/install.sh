#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRPAPER_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRPAPER_INSTALL_INCLUDED=1

# @description Installs Hyprpaper wallpaper daemon (pacman).
# @exit 0 on success
hyprpaper::install() {
    log::step "Hyprpaper" "HYPRPAPER"

    local -a _pacman_pkgs=( hyprpaper )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "HYPRPAPER"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Hyprpaper installed" "HYPRPAPER"
    return 0
}
