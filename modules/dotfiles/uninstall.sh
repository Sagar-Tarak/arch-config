#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_UNINSTALL_INCLUDED=1

# @description Removes dotfile symlinks; restores backups if present.
# @exit 0 on success
dotfiles::uninstall() {
    log::step "Uninstalling Dotfiles Module" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove dotfile symlinks from: ${HOME}" "DOTFILES"
        return 0
    fi

    log::info "Dotfiles uninstall (Phase 5+ implementation)" "DOTFILES"
    return 0
}
