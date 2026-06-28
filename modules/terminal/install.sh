#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_TERMINAL_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_TERMINAL_INSTALL_INCLUDED=1

# @description Installs Kitty terminal and deploys its config.
# @exit 0 on success
terminal::install() {
    log::step "Terminal Module" "TERMINAL"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: kitty (AUR)" "TERMINAL"
        log::info "[DRY-RUN] Would deploy: ~/.config/kitty/kitty.conf" "TERMINAL"
        return 0
    fi

    log::info "Terminal module installation (Phase 3+ implementation)" "TERMINAL"
    return 0
}
