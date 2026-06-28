#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLAND_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLAND_VERIFY_INCLUDED=1

# @description Verifies hyprctl is available (the Hyprland IPC client).
# @exit 0 if hyprctl found, 1 otherwise
hyprland::verify() {
    if command -v hyprctl &>/dev/null; then
        log::success "Hyprland: hyprctl found in PATH" "HYPRLAND"
        return 0
    fi
    log::error "Hyprland: hyprctl not found in PATH" "HYPRLAND"
    return 1
}
