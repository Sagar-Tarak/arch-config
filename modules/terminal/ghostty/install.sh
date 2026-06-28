#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GHOSTTY_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GHOSTTY_INSTALL_INCLUDED=1

# @description Installs Ghostty terminal emulator from the AUR.
# @exit 0 on success
ghostty::install() {
    log::step "Ghostty" "GHOSTTY"

    if [[ "${FORGE_AUR_AVAILABLE:-true}" == "false" ]]; then
        log::warn "Skipped: AUR unavailable (paru/yay could not be bootstrapped)." "GHOSTTY"
        return 3
    fi

    local -a _pkgs=( ghostty )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "GHOSTTY"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "Ghostty installed" "GHOSTTY"
    return 0
}
