#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_WAYBAR_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_WAYBAR_VERIFY_INCLUDED=1

# @description Verifies waybar binary is available.
# @exit 0 if found, 1 otherwise
waybar::verify() {
    if command -v waybar &>/dev/null; then
        log::success "Waybar: found in PATH" "WAYBAR"
        return 0
    fi
    log::error "Waybar: not found in PATH" "WAYBAR"
    return 1
}
