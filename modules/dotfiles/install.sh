#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_INSTALL_INCLUDED=1

# @description Deploys Forge dotfiles by backing up any conflicting configs
#              in ~/.config/, then creating per-file symlinks from dotfiles/
#              into ~/.config/. Idempotent — already-correct symlinks are
#              skipped. Existing regular files are backed up automatically by
#              fs::create_symlink before being replaced.
# @exit 0 on success, 1 on deployment failure
dotfiles::install() {
    log::step "Dotfiles" "DOTFILES"

    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log::error "Dotfiles directory not found: ${DOTFILES_DIR}" "DOTFILES"
        log::error "Ensure the repository contains a dotfiles/ directory." "DOTFILES"
        return 1
    fi

    local target_dir="${HOME}/.config"

    # Explicit pre-deploy backup pass (in addition to the per-symlink auto-backup
    # in fs::create_symlink) so the user has one consistent snapshot directory.
    dotfiles::backup_existing "${DOTFILES_DIR}" "${target_dir}" || true

    dotfiles::deploy "${DOTFILES_DIR}" "${target_dir}" || return 1

    # Regenerate XDG user directories after linking fish/git configs
    xdg-user-dirs-update 2>/dev/null || true

    return 0
}
