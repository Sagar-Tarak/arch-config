#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_NODE_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_NODE_VERIFY_INCLUDED=1

# @description Verifies node and npm are available in PATH.
# @exit 0 if both present, 1 otherwise
node::verify() {
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        local node_ver npm_ver
        node_ver="$(node --version 2>/dev/null || echo "unknown")"
        npm_ver="$(npm --version 2>/dev/null || echo "unknown")"
        log::success "Node: node ${node_ver}, npm ${npm_ver}" "NODE"
        return 0
    fi
    log::error "Node: node or npm not found in PATH" "NODE"
    return 1
}
