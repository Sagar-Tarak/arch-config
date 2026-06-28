#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ZEN_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ZEN_VERIFY_INCLUDED=1

zen::verify() {
    if command -v zen &>/dev/null; then
        log::success "zen: found in PATH" "ZEN"
        return 0
    fi
    log::error "zen: not found in PATH" "ZEN"
    return 1
}
