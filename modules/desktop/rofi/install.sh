#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_INSTALL_INCLUDED=1

# @description Installs rofi-wayland application launcher.
# @exit 0 on success
rofi::install() {
    log::step "Rofi" "ROFI"

    local -a _pkgs=( rofi-wayland )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "ROFI"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "Rofi installed" "ROFI"
    return 0
}
