#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_VSCODE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_VSCODE_VERIFY_INCLUDED=1

vscode::verify() {
    if command -v code &>/dev/null; then
        log::success "vscode: found in PATH" "VSCODE"
        return 0
    fi
    log::error "vscode: not found in PATH" "VSCODE"
    return 1
}
