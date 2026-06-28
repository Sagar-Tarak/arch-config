#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_AUR_SH_INCLUDED:-}" ]]; then return 0; fi
_AUR_SH_INCLUDED=1

# ==============================================================================
# Forge — AUR Helper Bootstrap Library
# File: lib/aur.sh
# Purpose: Selects, validates, and (if necessary) bootstraps an AUR helper
#          (paru or yay) before any AUR packages are installed.
#
#          The desired helper is read from ARCH_CFG_AUR_HELPER, which is set
#          by --aur-helper <name> or defaults to "paru".
#
# Dependencies: lib/logger.sh, lib/command.sh
# Public API:
#   aur::get_helper      - Returns the configured AUR helper name
#   aur::is_available    - Returns 0 if the configured helper is installed
#   aur::bootstrap       - Installs the helper if missing; idempotent
#   aur::install         - Install AUR packages via the configured helper
# ==============================================================================

_AUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_AUR_DIR}/logger.sh"
source "${_AUR_DIR}/command.sh"

# Supported helpers and their clone URLs
declare -A _AUR_HELPER_URLS=(
    [paru]="https://aur.archlinux.org/paru.git"
    [yay]="https://aur.archlinux.org/yay.git"
)

# ==============================================================================
# Public API
# ==============================================================================

# @description Returns the configured AUR helper name (from ARCH_CFG_AUR_HELPER
#              or defaults to "paru").
# @stdout Helper name: "paru" or "yay"
# @exit 0 always
aur::get_helper() {
    local helper="${ARCH_CFG_AUR_HELPER:-paru}"
    # Validate: only paru and yay are supported
    case "${helper}" in
        paru|yay) echo "${helper}" ;;
        *)
            log::warn "Unsupported AUR helper '${helper}' — falling back to paru" "AUR"
            echo "paru"
            ;;
    esac
}

# @description Returns 0 if the configured AUR helper binary is on PATH.
# @exit 0 if installed, 1 otherwise
aur::is_available() {
    local helper
    helper="$(aur::get_helper)"
    command -v "${helper}" &>/dev/null
}

# @description Bootstraps the configured AUR helper if not already installed.
#              Prerequisites (base-devel, git) are assumed to be installed
#              by the core module before this runs.
#              Steps: clone → makepkg -si --noconfirm → verify.
# @exit 0 on success (or already installed), 1 on failure
aur::bootstrap() {
    local helper
    helper="$(aur::get_helper)"

    if aur::is_available; then
        log::info "AUR helper '${helper}' is already installed — skipping bootstrap" "AUR"
        return 0
    fi

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would bootstrap AUR helper: ${helper}" "AUR"
        log::info "[DRY-RUN] Would clone: ${_AUR_HELPER_URLS[${helper}]}" "AUR"
        log::info "[DRY-RUN] Would build with: makepkg -si --noconfirm" "AUR"
        return 0
    fi

    log::step "AUR Bootstrap" "AUR"
    log::info "Installing AUR helper: ${helper}" "AUR"

    # Verify prerequisites
    if ! command -v git &>/dev/null; then
        log::error "git is required to bootstrap ${helper} but is not installed" "AUR"
        return 1
    fi
    if ! command -v makepkg &>/dev/null; then
        log::error "makepkg is required to bootstrap ${helper} — install base-devel first" "AUR"
        return 1
    fi

    local clone_url="${_AUR_HELPER_URLS[${helper}]:-}"
    if [[ -z "${clone_url}" ]]; then
        log::error "No clone URL configured for helper: ${helper}" "AUR"
        return 1
    fi

    # Build in a temporary directory so we don't pollute the project tree
    local build_dir
    build_dir="$(mktemp -d /tmp/forge-aur-bootstrap.XXXXXX)"

    # Ensure cleanup even on failure
    trap "rm -rf '${build_dir}'" RETURN

    log::info "Cloning ${helper} from AUR..." "AUR"
    if ! git clone --depth=1 "${clone_url}" "${build_dir}/${helper}" 2>&1 | \
         while IFS= read -r line; do log::debug "${line}" "AUR"; done; then
        log::error "Failed to clone ${helper} from ${clone_url}" "AUR"
        return 1
    fi

    log::info "Building ${helper} with makepkg..." "AUR"
    if ! ( cd "${build_dir}/${helper}" && makepkg -si --noconfirm 2>&1 | \
           while IFS= read -r line; do log::info "${line}" "AUR"; done ); then
        log::error "makepkg failed for ${helper}" "AUR"
        return 1
    fi

    # Verify installation succeeded
    if ! command -v "${helper}" &>/dev/null; then
        log::error "Bootstrap appeared to succeed but ${helper} is not in PATH" "AUR"
        return 1
    fi

    log::success "AUR helper '${helper}' installed successfully" "AUR"
    return 0
}

# @description Install one or more AUR packages via the configured helper.
#              Skips packages already installed. Respects ARCH_CFG_DRY_RUN.
# @arg1 string... Package names
# @exit 0 if all succeed, 1 if any fail
aur::install() {
    local -a pkgs=("$@")

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        return 0
    fi

    if ! aur::is_available; then
        log::error "No AUR helper available — run aur::bootstrap first" "AUR"
        return 1
    fi

    local helper
    helper="$(aur::get_helper)"

    # Filter already-installed packages
    local -a missing=()
    local p
    for p in "${pkgs[@]}"; do
        if command -v pacman &>/dev/null && pacman -Qq "${p}" &>/dev/null; then
            log::info "Already installed: ${p}" "AUR"
        else
            missing+=("${p}")
        fi
    done

    if [[ "${#missing[@]}" -eq 0 ]]; then
        log::info "All AUR packages already installed" "AUR"
        return 0
    fi

    log::info "Installing ${#missing[@]} AUR package(s) via ${helper}: ${missing[*]}" "AUR"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        local p
        for p in "${missing[@]}"; do
            log::info "[DRY-RUN] Would install (AUR/${helper}): ${p}" "AUR"
        done
        return 0
    fi

    if ! "${helper}" -S --needed --noconfirm "${missing[@]}"; then
        log::error "AUR install failed via ${helper} for: ${missing[*]}" "AUR"
        return 1
    fi

    log::success "AUR packages installed: ${missing[*]}" "AUR"
    return 0
}
