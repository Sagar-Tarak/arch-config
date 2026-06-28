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
#   aur::get_helper   - Returns the validated, configured AUR helper name
#   aur::is_available - Returns 0 if the configured helper is on PATH
#   aur::bootstrap    - Installs the helper if missing; idempotent
#   aur::install      - Install AUR packages via the configured helper
#
# NOTE: This file intentionally avoids declare -A (associative arrays).
#       When sourced from inside a function (as loader::load_libs does),
#       bash scopes 'declare' to the calling function — the array vanishes
#       once that function returns. URL lookups use 'case' instead.
# ==============================================================================

_AUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_AUR_DIR}/logger.sh"
source "${_AUR_DIR}/command.sh"

# Supported helpers — extend here and in _aur::clone_url together.
readonly _AUR_SUPPORTED_HELPERS="paru yay"

# ==============================================================================
# Internal helpers
# ==============================================================================

# @description Returns the AUR clone URL for a supported helper.
# @arg1 string helper  "paru" or "yay"
# @stdout Clone URL
# @exit 0 on success, 1 if the helper is unknown
_aur::clone_url() {
    local helper="${1:-}"
    case "${helper}" in
        paru) echo "https://aur.archlinux.org/paru.git" ;;
        yay)  echo "https://aur.archlinux.org/yay.git"  ;;
        *)
            log::error "No clone URL for unknown AUR helper: '${helper}'" "AUR"
            return 1
            ;;
    esac
}

# @description Validates that a helper name is non-empty and supported.
# @arg1 string helper
# @exit 0 if valid, 1 otherwise
_aur::validate_helper() {
    local helper="${1:-}"
    if [[ -z "${helper}" ]]; then
        log::error "AUR helper name is empty — set ARCH_CFG_AUR_HELPER or use --aur-helper" "AUR"
        return 1
    fi
    case "${helper}" in
        paru|yay) return 0 ;;
        *)
            log::error "Unsupported AUR helper '${helper}' — supported: ${_AUR_SUPPORTED_HELPERS}" "AUR"
            return 1
            ;;
    esac
}

# ==============================================================================
# Public API
# ==============================================================================

# @description Returns the validated, configured AUR helper name.
#              Reads ARCH_CFG_AUR_HELPER; defaults to "paru" if unset/empty.
#              Exits 1 (does not fall back silently) if the value is invalid.
# @stdout Helper name: "paru" or "yay"
# @exit 0 on success, 1 if ARCH_CFG_AUR_HELPER holds an unsupported value
aur::get_helper() {
    local helper="${ARCH_CFG_AUR_HELPER:-paru}"
    _aur::validate_helper "${helper}" || return 1
    echo "${helper}"
}

# @description Returns 0 if the configured AUR helper binary is on PATH.
# @exit 0 if installed, 1 otherwise
aur::is_available() {
    local helper
    helper="$(aur::get_helper)" || return 1
    command -v "${helper}" &>/dev/null
}

# @description Bootstraps the configured AUR helper if not already installed.
#              Prerequisites (base-devel, git) must be installed first by the
#              core / package installation step.
#              Steps: validate → clone → makepkg -si --noconfirm → verify.
# @exit 0 on success (or already installed), 1 on failure
aur::bootstrap() {
    local helper
    helper="$(aur::get_helper)" || return 1

    if aur::is_available; then
        log::info "AUR helper '${helper}' already installed — skipping bootstrap" "AUR"
        return 0
    fi

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        local dry_url
        dry_url="$(_aur::clone_url "${helper}")" || return 1
        log::info "[DRY-RUN] Would bootstrap AUR helper: ${helper}" "AUR"
        log::info "[DRY-RUN] Would clone: ${dry_url}" "AUR"
        log::info "[DRY-RUN] Would build with: makepkg -si --noconfirm" "AUR"
        return 0
    fi

    log::step "AUR Bootstrap" "AUR"
    log::info "Installing AUR helper: ${helper}" "AUR"

    # Verify prerequisites
    if ! command -v git &>/dev/null; then
        log::error "git is required to bootstrap ${helper} but is not installed" "AUR"
        log::error "Ensure base-devel and git are installed before running bootstrap" "AUR"
        return 1
    fi
    if ! command -v makepkg &>/dev/null; then
        log::error "makepkg is required to bootstrap ${helper} — install base-devel first" "AUR"
        return 1
    fi

    local clone_url
    clone_url="$(_aur::clone_url "${helper}")" || return 1

    # Build in a temporary directory
    local build_dir
    build_dir="$(mktemp -d /tmp/forge-aur-bootstrap.XXXXXX)"
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

    if ! command -v "${helper}" &>/dev/null; then
        log::error "Bootstrap appeared to succeed but '${helper}' is not in PATH" "AUR"
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

    local helper
    helper="$(aur::get_helper)" || return 1

    if ! command -v "${helper}" &>/dev/null; then
        log::error "AUR helper '${helper}' is not installed — run aur::bootstrap first" "AUR"
        return 1
    fi

    # Filter already-installed packages (pacman -Qq is authoritative for both
    # official and AUR packages once installed)
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
        local pkg
        for pkg in "${missing[@]}"; do
            log::info "[DRY-RUN] Would install (AUR/${helper}): ${pkg}" "AUR"
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
