#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLOCK_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLOCK_VERIFY_INCLUDED=1

hyprlock::verify() {
    local failed=0

    if command -v hyprlock &>/dev/null; then
        log::success "hyprlock: binary found in PATH" "HYPRLOCK"
    else
        log::error "hyprlock: binary not found in PATH" "HYPRLOCK"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/hyprlock/hyprlock.conf"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "hyprlock: config deployed (${config})" "HYPRLOCK"
    else
        log::error "hyprlock: config not found at ${config}" "HYPRLOCK"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
