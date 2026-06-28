#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLOCK_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLOCK_VERIFY_INCLUDED=1

hyprlock::verify() {
    if command -v hyprlock &>/dev/null; then
        log::success "hyprlock: found in PATH" "HYPRLOCK"
        return 0
    fi
    log::error "hyprlock: not found in PATH" "HYPRLOCK"
    return 1
}
