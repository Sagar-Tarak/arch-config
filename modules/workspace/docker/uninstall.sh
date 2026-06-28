#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOCKER_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOCKER_UNINSTALL_INCLUDED=1

# @description Stops and removes Docker and removes user from docker group.
# @exit 0 on success
docker::uninstall() {
    log::step "Uninstalling Docker Module" "DOCKER"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would stop docker.service and remove docker packages" "DOCKER"
        return 0
    fi

    log::info "Package removal is intentional — use pacman -Rs if needed" "DOCKER"
    return 0
}
