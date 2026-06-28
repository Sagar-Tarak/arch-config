#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_VERIFY_INCLUDED=1

swaync::verify() {
    local failed=0

    if command -v swaync &>/dev/null; then
        log::success "swaync: binary found in PATH" "SWAYNC"
    else
        log::error "swaync: binary not found in PATH" "SWAYNC"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/swaync/config.json"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "swaync: config deployed (${config})" "SWAYNC"
    else
        log::error "swaync: config not found at ${config}" "SWAYNC"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
