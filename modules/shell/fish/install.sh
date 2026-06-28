#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_INSTALL_INCLUDED=1

# @description Installs Fish shell and Starship prompt.
#              Does NOT change the default shell automatically — that would
#              require an interactive prompt (chsh). Instead, a recommendation
#              is logged. A future `forge shell set fish` command will handle this.
# @exit 0 on success
fish::install() {
    log::step "Fish Shell" "FISH"

    local -a _pkgs=( fish starship )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (pacman): ${_pkgs[*]}" "FISH"
        return 0
    fi

    package::install_list "pacman" "${_pkgs[@]}" || return 1

    # Report current shell and recommend Fish if it is not already the default.
    # We never call chsh automatically — it would require interactive confirmation
    # and may prompt for a password, breaking unattended installation.
    local _fish_path
    _fish_path="$(command -v fish 2>/dev/null || true)"

    if [[ -n "${_fish_path}" ]]; then
        local _current_shell
        _current_shell="$(getent passwd "${USER:-root}" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-unknown}")"

        if [[ "${_current_shell}" == "${_fish_path}" ]]; then
            log::info "Fish is already the default shell for ${USER:-root}" "FISH"
        else
            log::info "Current shell: ${_current_shell}" "FISH"
            log::info "To set Fish as default: chsh -s ${_fish_path}" "FISH"
        fi
    fi

    log::success "Fish shell installed" "FISH"
    return 0
}
