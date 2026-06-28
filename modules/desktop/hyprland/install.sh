#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLAND_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLAND_INSTALL_INCLUDED=1

# @description Installs the Hyprland Wayland compositor and its supporting stack.
# @exit 0 on success
hyprland::install() {
    log::step "Hyprland" "HYPRLAND"

    local -a _pacman_pkgs=(
        hyprland
        hyprutils
        xdg-desktop-portal-hyprland
        xdg-utils
        xdg-user-dirs
        grim
        slurp
        wl-clipboard
    )
    local -a _aur_pkgs=( hyprpicker )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "HYPRLAND"
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "HYPRLAND"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1
    aur::install "${_aur_pkgs[@]}" || return 1

    # Initialize XDG user directories on first install
    if command -v xdg-user-dirs-update &>/dev/null; then
        xdg-user-dirs-update &>/dev/null || true
    fi

    log::success "Hyprland installed" "HYPRLAND"
    return 0
}
