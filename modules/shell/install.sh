#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SHELL_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SHELL_INSTALL_INCLUDED=1

# @description Installs zsh and fish, deploys shell config dotfiles.
# @exit 0 on success
shell::install() {
    log::step "Shell Module" "SHELL"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: zsh fish bash-completion" "SHELL"
        log::info "[DRY-RUN] Would deploy: ~/.zshrc, ~/.config/fish/config.fish" "SHELL"
        return 0
    fi

    log::info "Shell module installation (Phase 3+ implementation)" "SHELL"
    return 0
}
