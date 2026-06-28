#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRPAPER_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRPAPER_VERIFY_INCLUDED=1

hyprpaper::verify() {
    if command -v hyprpaper &>/dev/null; then
        log::success "hyprpaper: found in PATH" "HYPRPAPER"
        return 0
    fi
    log::error "hyprpaper: not found in PATH" "HYPRPAPER"
    return 1
}
