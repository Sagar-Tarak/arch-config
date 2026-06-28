#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_VERIFY_INCLUDED=1

rofi::verify() {
    local failed=0

    if command -v rofi &>/dev/null; then
        log::success "rofi: binary found in PATH" "ROFI"
    else
        log::error "rofi: binary not found in PATH" "ROFI"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/rofi/config.rasi"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "rofi: config deployed (${config})" "ROFI"
    else
        log::error "rofi: config not found at ${config}" "ROFI"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
