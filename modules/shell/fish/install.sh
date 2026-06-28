#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_INSTALL_INCLUDED=1

# @description Installs Fish shell and Starship prompt, deploys Forge config.
# @exit 0 on success
fish::install() {
    log::step "Fish Shell Module" "FISH"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: fish starship" "FISH"
        log::info "[DRY-RUN] Would set Fish as default shell via chsh" "FISH"
        log::info "[DRY-RUN] Would deploy: ~/.config/fish/config.fish" "FISH"
        log::info "[DRY-RUN] Would deploy: ~/.config/starship.toml" "FISH"
        return 0
    fi

    log::info "Fish shell module (Phase 5+ implementation)" "FISH"
    return 0
}
