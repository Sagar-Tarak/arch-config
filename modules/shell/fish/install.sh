#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_INSTALL_INCLUDED=1

# @description Installs Fish shell, Starship prompt, and Atuin shell history.
#              Does NOT change the default shell automatically — chsh requires
#              interactive confirmation and breaks unattended installation.
# @exit 0 on success
fish::install() {
    log::step "Fish Shell" "FISH"

    local -a _pacman_pkgs=( fish starship )
    local -a _aur_pkgs=( atuin )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "FISH"
        log::info "[DRY-RUN] Would install (AUR): ${_aur_pkgs[*]}" "FISH"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1
    aur::install "${_aur_pkgs[@]}" || log::warn "atuin (AUR) install failed — shell history sync unavailable" "FISH"

    local _fish_path
    _fish_path="$(command -v fish 2>/dev/null || true)"

    if [[ -n "${_fish_path}" ]]; then
        local _current_shell
        _current_shell="$(getent passwd "${USER:-root}" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-unknown}")"

        if [[ "${_current_shell}" == "${_fish_path}" ]]; then
            log::info "Fish is already the default shell." "FISH"
        else
            log::info "To set Fish as default shell: chsh -s ${_fish_path}" "FISH"
        fi
    fi

    log::success "Fish + Starship + Atuin installed" "FISH"
    return 0
}
