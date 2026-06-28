#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FONTS_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FONTS_VERIFY_INCLUDED=1

# @description Verifies that the Forge font packages are installed.
#              Uses pacman -Qq (reliable) rather than parsing fc-list output
#              (which is slow and depends on exact font family name strings).
# @exit 0 if all font packages installed, 1 otherwise
fonts::verify() {
    local -a _required=(
        ttf-jetbrains-mono-nerd
        ttf-noto-nerd
        noto-fonts
        noto-fonts-emoji
        ttf-font-awesome
    )

    local failed=0
    local pkg
    for pkg in "${_required[@]}"; do
        if package::is_installed "${pkg}" "pacman" 2>/dev/null; then
            log::success "Font package installed: ${pkg}" "FONTS"
        else
            log::error "Font package missing: ${pkg}" "FONTS"
            failed=$(( failed + 1 ))
        fi
    done

    [[ "${failed}" -eq 0 ]]
}
