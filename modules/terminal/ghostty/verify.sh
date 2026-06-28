#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_VERIFY_INCLUDED=1

# @description Verifies ghostty is installed and its config is deployed.
# @exit 0 if all checks pass, 1 otherwise
ghostty::verify() {
    local failed=0

    if command -v ghostty &>/dev/null; then
        log::success "ghostty: binary found in PATH" "GHOSTTY"
    else
        log::error "ghostty: binary not found in PATH" "GHOSTTY"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/ghostty/config"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "ghostty: config deployed (${config})" "GHOSTTY"
    else
        log::error "ghostty: config not found at ${config}" "GHOSTTY"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
