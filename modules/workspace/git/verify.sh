#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GIT_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GIT_VERIFY_INCLUDED=1

# @description Verifies git tooling: system git, GitHub CLI, and Lazygit.
#              git itself is expected from archinstall; gh and lazygit are
#              installed by this module.
# @exit 0 if all present, 1 otherwise
git::verify() {
    local failed=0

    if command -v git &>/dev/null; then
        local ver
        ver="$(git --version 2>/dev/null || echo "unknown")"
        log::success "git: ${ver}" "GIT"
    else
        log::error "git: not found in PATH (expected from archinstall)" "GIT"
        failed=$(( failed + 1 ))
    fi

    if command -v gh &>/dev/null; then
        log::success "gh: $(gh --version 2>/dev/null | head -1 || echo 'found')" "GIT"
    else
        log::error "gh: GitHub CLI not found in PATH" "GIT"
        failed=$(( failed + 1 ))
    fi

    if command -v lazygit &>/dev/null; then
        log::success "lazygit: found in PATH" "GIT"
    else
        log::error "lazygit: not found in PATH" "GIT"
        failed=$(( failed + 1 ))
    fi

    [[ "${failed}" -eq 0 ]]
}
