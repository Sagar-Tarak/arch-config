#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_MATUGEN_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_MATUGEN_UNINSTALL_INCLUDED=1

# @description Removes matugen-generated color files. The matugen binary and
#              wallpaper are left intact. Config/template symlinks are removed
#              by the dotfiles module.
# @exit 0 on success
matugen::uninstall() {
    log::step "Uninstalling Matugen" "MATUGEN"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove generated color files" "MATUGEN"
        log::info "[DRY-RUN] Package removal: run pacman -Rs matugen-bin if desired" "MATUGEN"
        return 0
    fi

    local -a _generated=(
        "${HOME}/.config/hypr/colors.conf"
        "${HOME}/.config/waybar/colors.css"
        "${HOME}/.config/rofi/colors.rasi"
        "${HOME}/.config/swaync/colors.css"
        "${HOME}/.config/hyprlock/colors.conf"
        "${HOME}/.config/ghostty/colors"
        "${HOME}/.config/fish/conf.d/colors.fish"
    )

    local file
    for file in "${_generated[@]}"; do
        if [[ -f "${file}" && ! -L "${file}" ]]; then
            rm -f "${file}"
            log::info "Removed: ${file}" "MATUGEN"
        fi
    done

    log::info "Package removal is intentional — use pacman -Rs matugen-bin if needed" "MATUGEN"
    return 0
}
