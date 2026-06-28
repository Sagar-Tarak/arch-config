#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_INSTALL_INCLUDED=1

# @description Installs SwayNotificationCenter notification daemon (AUR).
# @exit 0 on success
swaync::install() {
    log::step "SwayNC" "SWAYNC"

    local -a _aur_pkgs=( swaync )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "SWAYNC"
        return 0
    fi

    local _aur
    if ! _aur="$(package::detect_aur_helper 2>/dev/null)"; then
        log::error "No AUR helper found — cannot install swaync" "SWAYNC"
        return 1
    fi

    package::install_list "${_aur}" "${_aur_pkgs[@]}" || return 1

    log::success "SwayNC installed" "SWAYNC"
    return 0
}
