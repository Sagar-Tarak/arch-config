#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FONTS_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FONTS_INSTALL_INCLUDED=1

# @description Installs Nerd Fonts and icon fonts for the Forge desktop.
# @exit 0 on success
fonts::install() {
    log::step "Fonts" "FONTS"

    local -a _pacman_pkgs=(
        ttf-jetbrains-mono-nerd
        ttf-noto-nerd
        noto-fonts
        noto-fonts-emoji
        ttf-font-awesome
    )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "FONTS"
        log::info "[DRY-RUN] Would run: fc-cache -fv" "FONTS"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    if command -v fc-cache &>/dev/null; then
        log::info "Refreshing font cache..." "FONTS"
        fc-cache -fv &>/dev/null || log::warn "fc-cache failed (non-fatal)" "FONTS"
    fi

    log::success "Fonts installed" "FONTS"
    return 0
}
