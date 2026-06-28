#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_HYPRIDLE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_HYPRIDLE_INSTALL_INCLUDED=1

# @description Installs Hypridle idle management daemon (official repos).
# @exit 0 on success
hypridle::install() {
    log::step "Hypridle" "HYPRIDLE"

    local -a _pkgs=( hypridle )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pkgs[*]}" "HYPRIDLE"
        return 0
    fi

    package::install_list "pacman" "${_pkgs[@]}" || return 1

    log::success "Hypridle installed" "HYPRIDLE"
    return 0
}
