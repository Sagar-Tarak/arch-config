#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FONTS_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FONTS_VERIFY_INCLUDED=1

# @description Verifies fc-list is available and JetBrains Mono Nerd is cached.
# @exit 0 if font tooling is available, 1 otherwise
fonts::verify() {
    if ! command -v fc-list &>/dev/null; then
        log::error "Fonts: fc-list not found (fontconfig missing)" "FONTS"
        return 1
    fi

    if fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
        log::success "Fonts: JetBrainsMono Nerd Font detected in cache" "FONTS"
        return 0
    fi

    log::warn "Fonts: JetBrainsMono Nerd Font not found in font cache" "FONTS"
    return 1
}
