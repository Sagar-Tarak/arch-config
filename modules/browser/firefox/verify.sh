#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_FIREFOX_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_FIREFOX_VERIFY_INCLUDED=1

firefox::verify() {
    if package::is_installed "firefox" "pacman" 2>/dev/null; then
        log::success "firefox: package installed" "FIREFOX"
        return 0
    fi
    log::error "firefox: package not installed" "FIREFOX"
    return 1
}
