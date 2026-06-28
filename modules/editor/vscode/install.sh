#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_VSCODE_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_VSCODE_INSTALL_INCLUDED=1

# @description Installs Visual Studio Code from the AUR.
# @exit 0 on success
vscode::install() {
    log::step "Visual Studio Code" "VSCODE"

    local -a _pkgs=( visual-studio-code-bin )

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install (AUR): ${_pkgs[*]}" "VSCODE"
        return 0
    fi

    aur::install "${_pkgs[@]}" || return 1

    log::success "Visual Studio Code installed" "VSCODE"
    return 0
}
