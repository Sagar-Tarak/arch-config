#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GIT_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GIT_UNINSTALL_INCLUDED=1

# @description Removes the git global config dotfile. The git binary itself
#              is not removed as it may be required by other tools.
# @exit 0 on success
git::uninstall() {
    log::step "Uninstalling Git Module" "GIT"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove: ~/.gitconfig symlink" "GIT"
        return 0
    fi

    log::info "Git uninstall (Phase 3+ implementation)" "GIT"
    return 0
}
