#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_WAYBAR_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_WAYBAR_VERIFY_INCLUDED=1

# @description Verifies waybar is installed and its config is deployed.
# @exit 0 if all checks pass, 1 otherwise
waybar::verify() {
    local failed=0

    if command -v waybar &>/dev/null; then
        log::success "Waybar: binary found in PATH" "WAYBAR"
    else
        log::error "Waybar: binary not found in PATH" "WAYBAR"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/waybar/config.jsonc"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "Waybar: config deployed (${config})" "WAYBAR"
    else
        log::error "Waybar: config not found at ${config}" "WAYBAR"
        failed=$(( failed + 1 ))
    fi

    local style="${HOME}/.config/waybar/style.css"
    if [[ -L "${style}" || -f "${style}" ]]; then
        log::success "Waybar: stylesheet deployed (${style})" "WAYBAR"
    else
        log::error "Waybar: stylesheet not found at ${style}" "WAYBAR"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
