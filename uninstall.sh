#!/usr/bin/env bash

set -Eeuo pipefail
export LC_ALL=C.UTF-8

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Forge — Uninstall Entry Point
# File: uninstall.sh
# Purpose: Reverses a Forge installation. Runs module::uninstall for every
#          module in FORGE_BASE_MODULES in reverse order (dotfiles first,
#          core last), so dependents are cleaned up before their dependencies.
#          Pass --dry-run to preview without making changes.
#          Pass --yes to skip the confirmation prompt.
# Usage:
#   ./uninstall.sh
#   ./uninstall.sh --dry-run
#   ./uninstall.sh --yes
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 1 — Bootstrap
# ------------------------------------------------------------------------------
_bootstrap_entry="${SCRIPT_DIR}/bootstrap/bootstrap.sh"
if [[ ! -f "${_bootstrap_entry}" ]]; then
    printf "Fatal: bootstrap/bootstrap.sh not found at: %s\n" "${_bootstrap_entry}" >&2
    exit 1
fi
source "${_bootstrap_entry}"
bootstrap::init

# ------------------------------------------------------------------------------
# Step 2 — Load installer components
# ------------------------------------------------------------------------------
_INSTALLER_DIR="${SCRIPT_DIR}/installer"

for _component in args.sh module_loader.sh packages.sh dotfiles.sh summary.sh verify.sh flow.sh; do
    _component_path="${_INSTALLER_DIR}/${_component}"
    if [[ ! -f "${_component_path}" ]]; then
        log::fatal "Installer component not found: ${_component_path}" "UNINSTALL"
        exit 1
    fi
    source "${_component_path}"
done
unset _component _component_path _INSTALLER_DIR _bootstrap_entry

# ------------------------------------------------------------------------------
# Step 2b — Load Forge definitions
# ------------------------------------------------------------------------------
_forge_base="${SCRIPT_DIR}/forge/base-system.sh"
[[ -f "${_forge_base}" ]] && source "${_forge_base}"
unset _forge_base

_forge_services="${SCRIPT_DIR}/forge/services.sh"
[[ -f "${_forge_services}" ]] && source "${_forge_services}"
unset _forge_services

# ------------------------------------------------------------------------------
# Step 3 — Parse flags (--dry-run, --yes)
# ------------------------------------------------------------------------------
_UNINSTALL_DRY_RUN="false"
_UNINSTALL_YES="false"

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run|-d) _UNINSTALL_DRY_RUN="true" ; export ARCH_CFG_DRY_RUN="true" ;;
        --yes|-y)     _UNINSTALL_YES="true" ;;
        --help|-h)
            printf "Usage: %s [--dry-run] [--yes]\n" "$(basename "${BASH_SOURCE[0]}")"
            printf "\n"
            printf "  --dry-run   Preview removals without making changes\n"
            printf "  --yes       Skip the confirmation prompt\n"
            exit 0
            ;;
        *)
            log::error "Unknown flag: ${_arg}" "UNINSTALL"
            exit 2
            ;;
    esac
done
unset _arg

# ------------------------------------------------------------------------------
# Step 4 — Confirm
# ------------------------------------------------------------------------------
log::step "Forge Uninstaller"
log::warn "This will remove dotfile symlinks and unregister Forge modules." "UNINSTALL"
log::warn "Packages and services will NOT be removed automatically." "UNINSTALL"
log::info "Backups of replaced configs are preserved in: ${BACKUP_DIR:-~/.local/state/arch-config/backups}" "UNINSTALL"

if [[ "${_UNINSTALL_YES}" != "true" ]]; then
    if ! utils::confirm "Proceed with uninstall?" "N"; then
        log::info "Uninstall cancelled." "UNINSTALL"
        exit 0
    fi
else
    log::info "Auto-confirm active (--yes) — skipping prompt." "UNINSTALL"
fi

# ------------------------------------------------------------------------------
# Step 5 — Run module::uninstall in reverse order
# ------------------------------------------------------------------------------
if [[ -z "${FORGE_BASE_MODULES[*]+x}" ]]; then
    log::error "FORGE_BASE_MODULES is not defined — cannot determine uninstall order." "UNINSTALL"
    exit 1
fi

# Reverse the module array
_module_count="${#FORGE_BASE_MODULES[@]}"
_reversed=()
for (( _i = _module_count - 1; _i >= 0; _i-- )); do
    _reversed+=( "${FORGE_BASE_MODULES[_i]}" )
done
unset _i _module_count

_failed=0
for _mod in "${_reversed[@]}"; do
    log::info "▶ Uninstalling module: ${_mod}" "UNINSTALL"
    if ! module::uninstall "${_mod}"; then
        log::error "Module '${_mod}' uninstall failed." "UNINSTALL"
        _failed=$(( _failed + 1 ))
    fi
done
unset _mod _reversed

if [[ "${_failed}" -gt 0 ]]; then
    log::warn "${_failed} module(s) reported uninstall failures." "UNINSTALL"
    exit 1
fi

log::success "Forge uninstall complete." "UNINSTALL"
exit 0
