#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_VERIFY_INCLUDED=1

# @description Verifies ghostty terminal is in PATH.
# @exit 0 if found, 1 otherwise
ghostty::verify() {
    if command -v ghostty &>/dev/null; then
        log::success "ghostty: found in PATH" "GHOSTTY"
        return 0
    fi
    log::error "ghostty: not found in PATH" "GHOSTTY"
    return 1
}
