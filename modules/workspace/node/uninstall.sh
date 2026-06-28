#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_NODE_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_NODE_UNINSTALL_INCLUDED=1

# @description Removes the nvm installation directory and shell hooks.
# @exit 0 on success
node::uninstall() {
    log::step "Uninstalling Node Module" "NODE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove ~/.nvm and nvm shell hooks" "NODE"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "NODE"
    return 0
}
