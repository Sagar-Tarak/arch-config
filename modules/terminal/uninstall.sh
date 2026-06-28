#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_TERMINAL_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_TERMINAL_UNINSTALL_INCLUDED=1

# @description Removes kitty config symlinks.
# @exit 0 on success
terminal::uninstall() {
    log::step "Uninstalling Terminal Module" "TERMINAL"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove kitty config symlinks" "TERMINAL"
        return 0
    fi

    log::info "Terminal uninstall (Phase 3+ implementation)" "TERMINAL"
    return 0
}
