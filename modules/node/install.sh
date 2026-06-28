#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_NODE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_NODE_INSTALL_INCLUDED=1

# @description Installs nvm and the Node.js LTS release.
# @exit 0 on success
node::install() {
    log::step "Node Module" "NODE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: nvm (AUR)" "NODE"
        log::info "[DRY-RUN] Would run: nvm install --lts" "NODE"
        return 0
    fi

    log::info "Node module installation (Phase 3+ implementation)" "NODE"
    return 0
}
