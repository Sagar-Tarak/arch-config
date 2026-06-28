#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_VERIFY_INCLUDED=1

rofi::verify() {
    if command -v rofi &>/dev/null; then
        log::success "rofi: found in PATH" "ROFI"
        return 0
    fi
    log::error "rofi: not found in PATH" "ROFI"
    return 1
}
