#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_UNINSTALL_INCLUDED=1

# @description Removes Ghostty config symlinks.
# @exit 0 on success
ghostty::uninstall() {
    log::step "Uninstalling Ghostty Terminal Module" "GHOSTTY"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove ~/.config/ghostty/ symlinks" "GHOSTTY"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "GHOSTTY"
    return 0
}
