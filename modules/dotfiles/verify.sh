#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_VERIFY_INCLUDED=1

# @description Verifies that all dotfiles in dotfiles/ have corresponding
#              correct symlinks in ~/.config/. Reports every missing or
#              broken link.
# @exit 0 all links correct (PASS)
# @exit 1 one or more links missing or broken (FAIL)
dotfiles::verify() {
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log::warn "Dotfiles directory not found: ${DOTFILES_DIR} — skipping verify" "DOTFILES"
        return 3  # SKIPPED
    fi

    dotfiles::verify_links "${DOTFILES_DIR}" "${HOME}/.config"
}
