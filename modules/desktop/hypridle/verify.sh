#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRIDLE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRIDLE_VERIFY_INCLUDED=1

hypridle::verify() {
    if command -v hypridle &>/dev/null; then
        log::success "hypridle: found in PATH" "HYPRIDLE"
        return 0
    fi
    log::error "hypridle: not found in PATH" "HYPRIDLE"
    return 1
}
