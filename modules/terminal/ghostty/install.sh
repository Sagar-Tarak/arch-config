#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_INSTALL_INCLUDED=1

# @description Installs Ghostty terminal emulator and deploys Forge config.
# @exit 0 on success
ghostty::install() {
    log::step "Ghostty Terminal Module" "GHOSTTY"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: ghostty (AUR)" "GHOSTTY"
        log::info "[DRY-RUN] Would deploy: ~/.config/ghostty/config" "GHOSTTY"
        return 0
    fi

    log::info "Ghostty module (Phase 5+ implementation)" "GHOSTTY"
    return 0
}
