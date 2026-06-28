#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_VERIFY_INCLUDED=1

swaync::verify() {
    if command -v swaync &>/dev/null; then
        log::success "swaync: found in PATH" "SWAYNC"
        return 0
    fi
    log::error "swaync: not found in PATH" "SWAYNC"
    return 1
}
