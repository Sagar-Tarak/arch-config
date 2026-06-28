#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ZEN_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ZEN_INSTALL_INCLUDED=1

# @description Installs Zen Browser (privacy-focused Firefox fork) from the AUR.
# @exit 0 on success
zen::install() {
    log::step "Zen Browser" "ZEN"

    local -a _aur_pkgs=( zen-browser )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "ZEN"
        return 0
    fi

    local _aur
    if ! _aur="$(package::detect_aur_helper 2>/dev/null)"; then
        log::error "No AUR helper found — cannot install zen-browser" "ZEN"
        return 1
    fi

    package::install_list "${_aur}" "${_aur_pkgs[@]}" || return 1

    log::success "Zen Browser installed" "ZEN"
    return 0
}
