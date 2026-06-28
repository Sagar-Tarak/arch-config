#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FISH_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FISH_VERIFY_INCLUDED=1

# @description Verifies fish and starship are installed and fish config is deployed.
# @exit 0 if all checks pass, 1 otherwise
fish::verify() {
    local failed=0

    if command -v fish &>/dev/null; then
        log::success "fish: binary found in PATH" "FISH"
    else
        log::error "fish: binary not found in PATH" "FISH"
        failed=$(( failed + 1 ))
    fi

    if command -v starship &>/dev/null; then
        log::success "starship: binary found in PATH" "FISH"
    else
        log::error "starship: not found in PATH" "FISH"
        failed=$(( failed + 1 ))
    fi

    local config="${HOME}/.config/fish/config.fish"
    if [[ -L "${config}" || -f "${config}" ]]; then
        log::success "fish: config deployed (${config})" "FISH"
    else
        log::error "fish: config not found at ${config}" "FISH"
        failed=$(( failed + 1 ))
    fi

    # Warn (not fail) if fish is not the login shell
    local fish_path
    fish_path="$(command -v fish 2>/dev/null || true)"
    if [[ -n "${fish_path}" ]]; then
        local current_shell
        current_shell="$(getent passwd "${USER}" 2>/dev/null | cut -d: -f7 || true)"
        if [[ "${current_shell}" == "${fish_path}" ]]; then
            log::success "fish: set as login shell" "FISH"
        else
            log::warn "fish: not set as login shell (run: chsh -s ${fish_path})" "FISH"
        fi
    fi

    [[ "${failed}" -eq 0 ]]
}
