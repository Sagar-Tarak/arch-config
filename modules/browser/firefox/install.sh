#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FIREFOX_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FIREFOX_INSTALL_INCLUDED=1

# @description Installs Firefox from the official Arch repositories.
# @exit 0 on success
firefox::install() {
    log::step "Firefox" "FIREFOX"

    local -a _pkgs=( firefox )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: ${_pkgs[*]}" "FIREFOX"
        return 0
    fi

    package::install_manifest "${_pkgs[@]}" || return 1

    log::success "Firefox installed" "FIREFOX"
    return 0
}
