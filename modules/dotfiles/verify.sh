#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_VERIFY_INCLUDED=1

# @description Dotfile deployment is not yet implemented (Phase 6).
# @exit 2 NOT_IMPLEMENTED — tells the verification report to display ○ NOT IMPLEMENTED
dotfiles::verify() {
    log::info "Dotfile deployment not yet implemented — Phase 6" "DOTFILES"
    return 2
}
