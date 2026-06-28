#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve this script's directory so all relative paths are stable
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Forge — Main Installer Entry Point
# File: install.sh
# Purpose: Thin orchestration entrypoint. Bootstraps the framework, loads all
#          installer components and the Forge base system definition, parses
#          CLI arguments, then delegates to flow::run for the full pipeline.
#          Do not add business logic here — extend installer/ components instead.
# Usage:
#   ./install.sh [OPTIONS]
#   ./install.sh --help
#   ./install.sh --dry-run
#   ./install.sh --module desktop/hyprland
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 1 — Bootstrap: loads all core libraries and initialises global variables
# ------------------------------------------------------------------------------
_bootstrap_entry="${SCRIPT_DIR}/bootstrap/bootstrap.sh"
if [[ ! -f "${_bootstrap_entry}" ]]; then
    printf "Fatal: bootstrap/bootstrap.sh not found at: %s\n" "${_bootstrap_entry}" >&2
    exit 1
fi
# shellcheck source=bootstrap/bootstrap.sh
source "${_bootstrap_entry}"
bootstrap::init

# ------------------------------------------------------------------------------
# Step 2 — Load installer layer (order matters: loader before flow)
# ------------------------------------------------------------------------------
_INSTALLER_DIR="${SCRIPT_DIR}/installer"

_installer_components=(
    "args.sh"
    "module_loader.sh"
    "packages.sh"
    "dotfiles.sh"
    "summary.sh"
    "verify.sh"
    "flow.sh"       # last: depends on all components above
)

for _component in "${_installer_components[@]}"; do
    _component_path="${_INSTALLER_DIR}/${_component}"
    if [[ ! -f "${_component_path}" ]]; then
        log::fatal "Installer component not found: ${_component_path}" "INSTALL"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${_component_path}"
done
unset _component _component_path _installer_components _INSTALLER_DIR _bootstrap_entry

# ------------------------------------------------------------------------------
# Step 2b — Load Forge definitions (base system modules + services)
# ------------------------------------------------------------------------------
_forge_base="${SCRIPT_DIR}/forge/base-system.sh"
if [[ -f "${_forge_base}" ]]; then
    # shellcheck source=forge/base-system.sh
    source "${_forge_base}"
fi
unset _forge_base

_forge_services="${SCRIPT_DIR}/forge/services.sh"
if [[ -f "${_forge_services}" ]]; then
    # shellcheck source=forge/services.sh
    source "${_forge_services}"
fi
unset _forge_services

# ------------------------------------------------------------------------------
# Step 3 — Parse CLI arguments (populates ARCH_CFG_FLAG_* globals)
# ------------------------------------------------------------------------------
args::parse "$@"

# ------------------------------------------------------------------------------
# Step 4 — Run the installer pipeline
# ------------------------------------------------------------------------------
flow::run
exit $?
