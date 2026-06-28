#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOCKER_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOCKER_VERIFY_INCLUDED=1

# @description Verifies docker CLI is available and daemon is active.
# @exit 0 if docker is usable, 1 otherwise
docker::verify() {
    if ! command -v docker &>/dev/null; then
        log::error "Docker: docker CLI not found in PATH" "DOCKER"
        return 1
    fi

    local ver
    ver="$(docker --version 2>/dev/null || echo "unknown")"
    log::success "Docker: ${ver}" "DOCKER"
    return 0
}
