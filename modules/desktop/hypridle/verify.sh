#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRIDLE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRIDLE_VERIFY_INCLUDED=1

hypridle::verify() {
    local failed=0

    if command -v hypridle &>/dev/null; then
        log::success "hypridle: binary found in PATH" "HYPRIDLE"
    else
        log::error "hypridle: binary not found in PATH" "HYPRIDLE"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/hypridle/hypridle.conf"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "hypridle: config deployed (${config})" "HYPRIDLE"
    else
        log::error "hypridle: config not found at ${config}" "HYPRIDLE"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
