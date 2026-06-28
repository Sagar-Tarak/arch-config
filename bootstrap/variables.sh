#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_VARIABLES_SH_INCLUDED:-}" ]]; then
    return 0
fi
_VARIABLES_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Global Variables
# File: bootstrap/variables.sh
# Purpose: Defines and exports all global path and configuration variables for
#          the framework. Every path is computed dynamically from PROJECT_ROOT
#          so the framework is relocatable without changes.
# Dependencies: None (sourced early; logger is not yet available)
# Public API:
#   variables::load  - Computes and exports all global variables
# Usage Example:
#   source bootstrap/variables.sh
#   variables::load
#   echo "${MODULES_DIR}"
# ==============================================================================

# Resolve PROJECT_ROOT: bootstrap/ sits one level inside the project root.
_VARIABLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Computes and exports all global framework variables.
#              Safe to call multiple times; re-exports the same values.
# @noargs
# @exit 0 Always
variables::load() {
    # Root of the entire framework installation
    export PROJECT_ROOT
    PROJECT_ROOT="$(cd "${_VARIABLES_DIR}/.." && pwd)"

    # Framework version — read from VERSION file if present, else use fallback
    export VERSION
    if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
        VERSION="$(< "${PROJECT_ROOT}/VERSION")"
        VERSION="${VERSION//[$'\t\r\n ']/}"
    else
        VERSION="0.1.0"
    fi

    # Primary configuration directory (user-editable)
    export CONFIG_DIR="${PROJECT_ROOT}/config"

    # Modules directory — each subdirectory is an installable module
    export MODULES_DIR="${PROJECT_ROOT}/modules"

    # Package list definitions
    export PACKAGES_DIR="${PROJECT_ROOT}/packages"

    # Theme assets
    export THEMES_DIR="${PROJECT_ROOT}/themes"

    # Managed dotfile sources
    export DOTFILES_DIR="${PROJECT_ROOT}/dotfiles"

    # Runtime cache (temporary data across runs)
    export CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/arch-config"

    # Backup storage for files replaced during installation
    export BACKUP_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/arch-config/backups"

    # Log output directory
    export LOG_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/arch-config/logs"

    # Default package manager for Arch Linux
    export DEFAULT_PACKAGE_MANAGER="pacman"

    # Dry-run mode — set externally with ARCH_CFG_DRY_RUN=true to prevent
    # any filesystem or package mutations
    export ARCH_CFG_DRY_RUN="${ARCH_CFG_DRY_RUN:-false}"

    # Debug logging — set externally with DEBUG=1 to enable verbose output
    export DEBUG="${DEBUG:-0}"

    return 0
}
