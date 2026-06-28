#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_GIT_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_GIT_VERIFY_INCLUDED=1

# @description Verifies git is installed and reports its version.
# @exit 0 if git is available, 1 otherwise
git::verify() {
    if command -v git &>/dev/null; then
        local ver
        ver="$(git --version 2>/dev/null || echo "unknown")"
        log::success "Git: ${ver}" "GIT"
        return 0
    fi
    log::error "Git: not found in PATH" "GIT"
    return 1
}
