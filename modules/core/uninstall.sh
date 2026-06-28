#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_CORE_UNINSTALL_INCLUDED:-}" ]]; then return 0; fi
_MODULE_CORE_UNINSTALL_INCLUDED=1

# @description Core utilities are not removed on uninstall — they are required
#              by the OS and other modules. This is intentionally a no-op.
# @exit 0 Always
core::uninstall() {
    log::warn "Core module is not uninstalled — system utilities are OS-managed." "CORE"
    return 0
}
