#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_VSCODE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_VSCODE_INSTALL_INCLUDED=1

vscode::install() {
    log::step "Visual Studio Code editor" "VSCODE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: vscode" "VSCODE"
        return 0
    fi

    log::info "vscode module (Phase 5+ implementation)" "VSCODE"
    return 0
}
