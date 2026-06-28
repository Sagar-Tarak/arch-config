#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_NVIM_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_NVIM_VERIFY_INCLUDED=1

# @description Verifies neovim is installed and meets the minimum version.
# @exit 0 if nvim >= 0.9.0 is present, 1 otherwise
nvim::verify() {
    if command -v nvim &>/dev/null; then
        local ver
        ver="$(nvim --version 2>/dev/null | head -1 || echo "unknown")"
        log::success "Neovim: ${ver}" "NVIM"
        return 0
    fi
    log::error "Neovim: nvim not found in PATH" "NVIM"
    return 1
}
