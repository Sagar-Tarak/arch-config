#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLAND_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLAND_VERIFY_INCLUDED=1

# @description Verifies Hyprland is installed and its config is deployed.
# @exit 0 if all checks pass, 1 otherwise
hyprland::verify() {
    local failed=0

    if command -v hyprctl &>/dev/null; then
        log::success "Hyprland: hyprctl found in PATH" "HYPRLAND"
    else
        log::error "Hyprland: hyprctl not found in PATH" "HYPRLAND"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/hypr/hyprland.conf"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "Hyprland: config deployed (${config})" "HYPRLAND"
    else
        log::error "Hyprland: config not found at ${config}" "HYPRLAND"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
