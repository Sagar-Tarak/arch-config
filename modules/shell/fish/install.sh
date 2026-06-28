#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_INSTALL_INCLUDED=1

# @description Installs Fish shell and Starship prompt. Sets Fish as the
#              default shell for the current user via chsh.
# @exit 0 on success
fish::install() {
    log::step "Fish Shell" "FISH"

    local -a _pacman_pkgs=( fish starship )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pacman_pkgs[*]}" "FISH"
        log::info "[DRY-RUN] Would set Fish as default shell via chsh" "FISH"
        return 0
    fi

    package::install_list "pacman" "${_pacman_pkgs[@]}" || return 1

    # Set Fish as the default shell if it isn't already
    local _fish_path
    _fish_path="$(command -v fish 2>/dev/null || true)"
    if [[ -n "${_fish_path}" ]]; then
        local _current_shell
        _current_shell="$(getent passwd "${USER}" | cut -d: -f7 2>/dev/null || echo "")"
        if [[ "${_current_shell}" != "${_fish_path}" ]]; then
            # Ensure fish is in /etc/shells
            if ! grep -qxF "${_fish_path}" /etc/shells 2>/dev/null; then
                echo "${_fish_path}" | sudo tee -a /etc/shells &>/dev/null
            fi
            log::info "Setting default shell to Fish for ${USER}..." "FISH"
            chsh -s "${_fish_path}" "${USER}" || log::warn "chsh failed — set shell manually: chsh -s ${_fish_path}" "FISH"
        else
            log::info "Fish is already the default shell" "FISH"
        fi
    fi

    log::success "Fish shell installed" "FISH"
    return 0
}
