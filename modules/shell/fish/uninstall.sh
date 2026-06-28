#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_UNINSTALL_INCLUDED=1

# @description Removes Fish shell config symlinks.
# @exit 0 on success
fish::uninstall() {
    log::step "Uninstalling Fish Shell Module" "FISH"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove ~/.config/fish/ symlinks" "FISH"
        log::info "[DRY-RUN] Would remove ~/.config/starship.toml symlink" "FISH"
        return 0
    fi

    log::info "Fish uninstall (Phase 5+ implementation)" "FISH"
    return 0
}
