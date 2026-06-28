#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRLOCK_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRLOCK_INSTALL_INCLUDED=1

# @description Installs Hyprlock screen locker.
# @exit 0 on success
hyprlock::install() {
    log::step "Hyprlock" "HYPRLOCK"

    local -a _pkgs=( hyprlock )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "HYPRLOCK"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "Hyprlock installed" "HYPRLOCK"
    return 0
}
