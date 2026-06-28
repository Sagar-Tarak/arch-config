#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SHELL_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SHELL_VERIFY_INCLUDED=1

# @description Verifies at least one supported shell (zsh or fish) is installed.
# @exit 0 if found, 1 otherwise
shell::verify() {
    if command -v zsh &>/dev/null; then
        local ver
        ver="$(zsh --version 2>/dev/null | head -1 || echo "unknown")"
        log::success "Shell: ${ver}" "SHELL"
        return 0
    fi
    if command -v fish &>/dev/null; then
        local ver
        ver="$(fish --version 2>/dev/null || echo "unknown")"
        log::success "Shell: ${ver}" "SHELL"
        return 0
    fi
    log::error "Shell: neither zsh nor fish found in PATH" "SHELL"
    return 1
}
