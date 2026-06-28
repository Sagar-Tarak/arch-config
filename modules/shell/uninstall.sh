#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SHELL_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SHELL_UNINSTALL_INCLUDED=1

# @description Removes shell config dotfile symlinks.
# @exit 0 on success
shell::uninstall() {
    log::step "Uninstalling Shell Module" "SHELL"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove shell config symlinks" "SHELL"
        return 0
    fi

    log::info "Shell uninstall (Phase 3+ implementation)" "SHELL"
    return 0
}
