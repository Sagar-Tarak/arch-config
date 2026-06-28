#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_VERIFY_INCLUDED=1

# @description Verifies that all dotfiles in dotfiles/ have corresponding
#              correct symlinks in ~/.config/, and that the critical generated
#              color files exist (they are created by matugen, not by deployment).
# @exit 0 all links correct and colors generated (PASS)
# @exit 1 one or more links missing/broken or colors not generated (FAIL)
dotfiles::verify() {
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log::warn "Dotfiles directory not found: ${DOTFILES_DIR} — skipping verify" "DOTFILES"
        return 3  # SKIPPED
    fi

    local failed=0
    dotfiles::verify_links "${DOTFILES_DIR}" "${HOME}/.config" || failed=1

    # Verify critical generated color files exist (created by matugen, not deployment)
    local -a _colors=(
        "${HOME}/.config/hypr/colors.conf"
        "${HOME}/.config/waybar/colors.css"
        "${HOME}/.config/rofi/colors.rasi"
        "${HOME}/.config/swaync/colors.css"
        "${HOME}/.config/hyprlock/colors.conf"
        "${HOME}/.config/ghostty/colors"
        "${HOME}/.config/fish/conf.d/colors.fish"
    )

    local color_file
    for color_file in "${_colors[@]}"; do
        if [[ ! -f "${color_file}" ]]; then
            log::error "Generated color file missing: ${color_file}" "DOTFILES"
            log::error "  → Run: matugen image ~/Pictures/Wallpapers/current.jpg" "DOTFILES"
            failed=1
        fi
    done

    [[ "${failed}" -eq 0 ]]
}
