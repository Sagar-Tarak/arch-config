#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_INSTALL_INCLUDED=1

# @description Installs Ghostty terminal emulator from the AUR.
# @exit 0 on success
ghostty::install() {
    log::step "Ghostty" "GHOSTTY"

    local -a _aur_pkgs=( ghostty )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "GHOSTTY"
        return 0
    fi

    local _aur
    if ! _aur="$(package::detect_aur_helper 2>/dev/null)"; then
        log::error "No AUR helper found — cannot install ghostty" "GHOSTTY"
        return 1
    fi

    package::install_list "${_aur}" "${_aur_pkgs[@]}" || return 1

    log::success "Ghostty installed" "GHOSTTY"
    return 0
}
