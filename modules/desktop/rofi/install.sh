#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ROFI_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ROFI_INSTALL_INCLUDED=1

# @description Installs rofi-wayland application launcher (AUR).
# @exit 0 on success
rofi::install() {
    log::step "Rofi" "ROFI"

    local -a _aur_pkgs=( rofi-wayland )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "ROFI"
        return 0
    fi

    local _aur
    if ! _aur="$(package::detect_aur_helper 2>/dev/null)"; then
        log::error "No AUR helper found — cannot install rofi-wayland" "ROFI"
        return 1
    fi

    package::install_list "${_aur}" "${_aur_pkgs[@]}" || return 1

    log::success "Rofi installed" "ROFI"
    return 0
}
