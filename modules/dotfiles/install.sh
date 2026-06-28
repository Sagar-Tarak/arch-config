#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_INSTALL_INCLUDED=1

# @description Deploys Forge dotfiles by creating symlinks from the repo
#              dotfiles/ directory into the user's home directory.
# @exit 0 on success
dotfiles::install() {
    log::step "Dotfiles Module" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would deploy dotfiles from: ${DOTFILES_DIR}" "DOTFILES"
        log::info "[DRY-RUN] Would symlink into: ${HOME}" "DOTFILES"
        return 0
    fi

    log::info "Dotfiles deployment (Phase 5+ implementation)" "DOTFILES"
    return 0
}
