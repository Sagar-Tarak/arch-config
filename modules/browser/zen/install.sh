#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_ZEN_INSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_ZEN_INSTALL_INCLUDED=1

zen::install() {
    log::step "Zen Browser — privacy-focused Firefox fork" "ZEN"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: zen" "ZEN"
        return 0
    fi

    log::info "zen module (Phase 5+ implementation)" "ZEN"
    return 0
}
