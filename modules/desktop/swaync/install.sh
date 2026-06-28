#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_SWAYNC_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_SWAYNC_INSTALL_INCLUDED=1

# @description Installs SwayNotificationCenter notification daemon.
# @exit 0 on success
swaync::install() {
    log::step "SwayNC" "SWAYNC"

    if [[ "${FORGE_AUR_AVAILABLE:-true}" == "false" ]]; then
        log::warn "Skipped: AUR unavailable (paru/yay could not be bootstrapped)." "SWAYNC"
        return 3
    fi

    local -a _pkgs=( swaync )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "SWAYNC"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "SwayNC installed" "SWAYNC"
    return 0
}
