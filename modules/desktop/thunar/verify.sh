#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_THUNAR_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_THUNAR_VERIFY_INCLUDED=1

thunar::verify() {
    if command -v thunar &>/dev/null; then
        log::success "thunar: found in PATH" "THUNAR"
        return 0
    fi
    log::error "thunar: not found in PATH" "THUNAR"
    return 1
}
