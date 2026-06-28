#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_VERIFY_INCLUDED=1

# @description Verifies fish and starship are in PATH.
# @exit 0 if both found, 1 otherwise
fish::verify() {
    local failed=0
    if command -v fish &>/dev/null; then
        log::success "fish: found in PATH" "FISH"
    else
        log::error "fish: not found in PATH" "FISH"
        failed=$(( failed + 1 ))
    fi
    if command -v starship &>/dev/null; then
        log::success "starship: found in PATH" "FISH"
    else
        log::error "starship: not found in PATH" "FISH"
        failed=$(( failed + 1 ))
    fi
    [[ "${failed}" -eq 0 ]]
}
