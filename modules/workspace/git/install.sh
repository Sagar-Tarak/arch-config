#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GIT_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GIT_INSTALL_INCLUDED=1

# @description Installs Git and the GitHub CLI.
# @exit 0 on success
git::install() {
    log::step "Git" "GIT"

    local -a _pacman_pkgs=( git github-cli )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "GIT"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Git installed" "GIT"
    return 0
}
