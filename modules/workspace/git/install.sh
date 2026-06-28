#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GIT_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GIT_INSTALL_INCLUDED=1

# @description Installs workstation Git tools.
#              git itself is assumed to be installed by archinstall.
#              This module adds the GitHub CLI and the Lazygit terminal UI.
# @exit 0 on success
git::install() {
    log::step "Git Tools" "GIT"

    if ! command -v git &>/dev/null; then
        log::warn "git not found in PATH — install it with: sudo pacman -S git" "GIT"
    else
        local _ver
        _ver="$(git --version 2>/dev/null || echo "unknown")"
        log::info "Using system git: ${_ver}" "GIT"
    fi

    local -a _pacman_pkgs=( github-cli lazygit )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "GIT"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    log::success "Git tools installed (gh, lazygit)" "GIT"
    return 0
}
