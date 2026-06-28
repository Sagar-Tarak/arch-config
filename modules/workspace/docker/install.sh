#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_DOCKER_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_DOCKER_INSTALL_INCLUDED=1

# @description Installs Docker, enables the service, and adds user to the
#              docker group. Only supported on x86_64.
# @exit 0 on success
docker::install() {
    log::step "Docker Module" "DOCKER"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: docker docker-compose" "DOCKER"
        log::info "[DRY-RUN] Would enable: docker.service" "DOCKER"
        log::info "[DRY-RUN] Would add user to docker group" "DOCKER"
        return 0
    fi

    log::warn "Docker module is not yet implemented — install manually: pacman -S docker docker-compose" "DOCKER"
    return 0
}
