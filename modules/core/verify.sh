#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_VERIFY_INCLUDED=1

# @description Verifies core utilities are present in PATH.
# @exit 0 if all required commands exist, 1 otherwise
core::verify() {
    local -a required=(git curl wget)
    local missing=()
    local cmd

    for cmd in "${required[@]}"; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        log::error "Core: missing commands: ${missing[*]}" "CORE"
        return 1
    fi

    log::success "Core: all required commands present" "CORE"
    return 0
}
