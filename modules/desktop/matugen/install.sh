#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_MATUGEN_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_MATUGEN_INSTALL_INCLUDED=1

# @description Installs the matugen binary and creates the wallpaper directory.
#              Color scheme generation runs AFTER dotfiles deploy (see
#              modules/dotfiles/install.sh) so the templates are already linked.
# @exit 0 on success, 1 on failure
matugen::install() {
    log::step "Matugen" "MATUGEN"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: matugen-bin (AUR)" "MATUGEN"
        log::info "[DRY-RUN] Would create: ~/Pictures/Wallpapers/" "MATUGEN"
        log::info "[DRY-RUN] Would copy: default wallpaper if none exists" "MATUGEN"
        return 0
    fi

    aur::install matugen-bin || return 1

    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    fs::ensure_directory "${wallpaper_dir}"

    local wallpaper="${wallpaper_dir}/current.jpg"
    if [[ ! -f "${wallpaper}" ]]; then
        local assets_dir="${PROJECT_ROOT}/assets/wallpapers"
        local default_wallpaper
        default_wallpaper="$(find "${assets_dir}" -maxdepth 1 -type f \
            \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) \
            ! -name ".gitkeep" | sort | head -1)"

        if [[ -n "${default_wallpaper}" ]]; then
            cp "${default_wallpaper}" "${wallpaper}"
            log::info "Installed default wallpaper to: ${wallpaper}" "MATUGEN"
        else
            log::warn "No wallpaper found in: ${assets_dir}" "MATUGEN"
            log::warn "Run scripts/set-wallpaper.sh <path> before colors will generate." "MATUGEN"
        fi
    else
        log::info "Wallpaper already exists: ${wallpaper}" "MATUGEN"
    fi

    return 0
}
