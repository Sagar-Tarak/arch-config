#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_NVIM_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_NVIM_INSTALL_INCLUDED=1

# @description Installs Neovim. Lazy.nvim bootstraps itself on first launch.
# @exit 0 on success
nvim::install() {
    log::step "Neovim" "NVIM"

    local -a _pacman_pkgs=( neovim )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "NVIM"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Neovim installed" "NVIM"
    return 0
}
