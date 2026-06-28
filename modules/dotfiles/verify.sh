#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOTFILES_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOTFILES_VERIFY_INCLUDED=1

# @description Verifies that dotfiles symlinks are correctly deployed.
# @exit 0 if links are healthy, 1 otherwise
dotfiles::verify() {
    dotfiles::verify_links "${DOTFILES_DIR}" "${HOME}"
}
