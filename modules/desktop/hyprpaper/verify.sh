#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRPAPER_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRPAPER_VERIFY_INCLUDED=1

hyprpaper::verify() {
    local failed=0

    if command -v hyprpaper &>/dev/null; then
        log::success "hyprpaper: binary found in PATH" "HYPRPAPER"
    else
        log::error "hyprpaper: binary not found in PATH" "HYPRPAPER"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/hyprpaper/hyprpaper.conf"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "hyprpaper: config deployed (${config})" "HYPRPAPER"
    else
        log::error "hyprpaper: config not found at ${config}" "HYPRPAPER"
        failed=$(( failed + 1 ))
    fi

    local wallpaper="${HOME}/Pictures/Wallpapers/current.jpg"
    if [[ -L "${wallpaper}" || -f "${wallpaper}" ]]; then
        log::success "hyprpaper: wallpaper present (${wallpaper})" "HYPRPAPER"
    else
        log::warn "hyprpaper: no wallpaper at ${wallpaper} — run set-wallpaper.sh" "HYPRPAPER"
    fi

    [[ "${failed}" -eq 0 ]]
}
