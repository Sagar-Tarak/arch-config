#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_UNINSTALL_INCLUDED=1

# @description Removes managed dotfile symlinks from ~/.config/. Unmanaged
#              files (those not pointing into DOTFILES_DIR) are left untouched.
#              Does NOT automatically restore backups — use
#              dotfiles::restore_backup if needed.
# @exit 0 on success
dotfiles::uninstall() {
    log::step "Uninstalling Dotfiles" "DOTFILES"

    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log::warn "Dotfiles directory not found — nothing to remove." "DOTFILES"
        return 0
    fi

    local target_dir="${HOME}/.config"

    dotfiles::remove_links "${DOTFILES_DIR}" "${target_dir}"

    log::info "Backups (if any) are preserved at: ${BACKUP_DIR}" "DOTFILES"
    log::info "Run dotfiles::restore_backup <path> to restore them." "DOTFILES"

    return 0
}
