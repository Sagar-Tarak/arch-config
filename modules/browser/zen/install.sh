#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ZEN_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ZEN_INSTALL_INCLUDED=1

# @description Installs Zen Browser (privacy-focused Firefox fork) from the AUR.
# @exit 0 on success
zen::install() {
    log::step "Zen Browser" "ZEN"

    if [[ "${FORGE_AUR_AVAILABLE:-true}" == "false" ]]; then
        log::warn "Skipped: AUR unavailable (paru/yay could not be bootstrapped)." "ZEN"
        return 3
    fi

    local -a _pkgs=( zen-browser )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "ZEN"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "Zen Browser installed" "ZEN"
    return 0
}
