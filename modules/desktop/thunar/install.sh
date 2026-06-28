#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_THUNAR_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_THUNAR_INSTALL_INCLUDED=1

# @description Installs Thunar file manager and GVFS for trash and MTP support.
# @exit 0 on success
thunar::install() {
    log::step "Thunar" "THUNAR"

    local -a _pacman_pkgs=(
        thunar
        thunar-volman
        tumbler
    )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "THUNAR"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Thunar installed" "THUNAR"
    return 0
}
