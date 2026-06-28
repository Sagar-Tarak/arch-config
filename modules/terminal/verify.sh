#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_TERMINAL_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_TERMINAL_VERIFY_INCLUDED=1

# @description Verifies kitty terminal is installed.
# @exit 0 if available, 1 otherwise
terminal::verify() {
    if command -v kitty &>/dev/null; then
        local ver
        ver="$(kitty --version 2>/dev/null || echo "unknown")"
        log::success "Terminal: ${ver}" "TERMINAL"
        return 0
    fi
    log::error "Terminal: kitty not found in PATH" "TERMINAL"
    return 1
}
