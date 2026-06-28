#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_VSCODE_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_VSCODE_UNINSTALL_INCLUDED=1

vscode::uninstall() {
    log::step "Uninstalling vscode" "VSCODE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove vscode config" "VSCODE"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "VSCODE"
    return 0
}
