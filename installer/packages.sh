#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_PACKAGES_SH_INCLUDED:-}" ]]; then
    return 0
fi
_PACKAGES_SH_INCLUDED=1

# ==============================================================================
# Forge - Package List Parser
# File: installer/packages.sh
# Purpose: Reads and validates the three package list files (pacman, AUR,
#          flatpak), strips comments and blank lines, and provides display
#          helpers for the installer summary. Reuses the existing package
#          library for any live system queries.
# Dependencies: lib/logger.sh, lib/utils.sh, bootstrap/variables.sh (PACKAGES_DIR)
# Public API:
#   packages::parse_file    - Reads a package file; prints one pkg per line
#   packages::count_file    - Returns the number of packages in a file
#   packages::validate      - Checks all three list files exist; returns 0/1
#   packages::show_summary  - Logs per-manager package counts
#   packages::show_list     - Logs the full package list for a given manager
# Usage Example:
#   source installer/packages.sh
#   packages::validate || log::warn "Missing package files" "INSTALL"
#   packages::show_summary
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Reads a package list file and prints each package name, one
#              per line. Strips comment lines (# ...) and blank lines.
#              Inline comments on a package line are also stripped.
# @arg1 string file Absolute path to the package list file
# @stdout Package names, one per line
# @exit 0 Always (missing file produces a warning, not a failure)
packages::parse_file() {
    local file="${1:-}"

    if [[ -z "${file}" ]]; then
        log::error "packages::parse_file requires a file path" "PACKAGES"
        return 1
    fi

    if [[ ! -f "${file}" ]]; then
        log::warn "Package file not found: ${file}" "PACKAGES"
        return 0
    fi

    local line
    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Strip inline comment (everything from # onward)
        line="${line%%#*}"
        # Trim surrounding whitespace using the framework utility
        line="$(utils::trim "${line}")"
        # Skip blank lines
        [[ -z "${line}" ]] && continue
        printf "%s\n" "${line}"
    done < "${file}"
}

# @description Counts the number of installable packages in a package file
#              (i.e. non-comment, non-blank lines).
# @arg1 string file Absolute path to the package list file
# @stdout Integer count
# @exit 0 Always
packages::count_file() {
    local file="${1:-}"
    local count=0
    local pkg
    while IFS= read -r pkg; do
        count=$(( count + 1 ))
    done < <(packages::parse_file "${file}")
    printf "%d" "${count}"
}

# @description Verifies that all three expected package list files exist.
# @noargs
# @exit 0 if all files present, 1 if any are missing
packages::validate() {
    local valid=true
    local -a required_files=(
        "${PACKAGES_DIR}/pacman.txt"
        "${PACKAGES_DIR}/aur.txt"
        "${PACKAGES_DIR}/flatpak.txt"
    )

    local f
    for f in "${required_files[@]}"; do
        if [[ ! -f "${f}" ]]; then
            log::error "Missing package list file: ${f}" "PACKAGES"
            valid=false
        fi
    done

    [[ "${valid}" == "true" ]]
}

# @description Logs a one-line count summary for each package manager.
# @noargs
# @exit 0 Always
packages::show_summary() {
    local pacman_count aur_count flatpak_count
    pacman_count="$(packages::count_file "${PACKAGES_DIR}/pacman.txt")"
    aur_count="$(packages::count_file "${PACKAGES_DIR}/aur.txt")"
    flatpak_count="$(packages::count_file "${PACKAGES_DIR}/flatpak.txt")"

    log::info "  pacman  : ${pacman_count} package(s)" "PACKAGES"
    log::info "  AUR     : ${aur_count} package(s)" "PACKAGES"
    log::info "  flatpak : ${flatpak_count} package(s)" "PACKAGES"
}

# @description Prints the package list for the specified manager to stderr.
#              Accepts "pacman", "aur", "flatpak", or "all".
# @arg1 string manager Package manager name (default: all)
# @exit 0 Always
packages::show_list() {
    local manager="${1:-all}"

    case "${manager}" in
        pacman)
            log::step "pacman packages"
            _packages::print_file "${PACKAGES_DIR}/pacman.txt"
            ;;
        aur)
            log::step "AUR packages"
            _packages::print_file "${PACKAGES_DIR}/aur.txt"
            ;;
        flatpak)
            log::step "Flatpak packages"
            _packages::print_file "${PACKAGES_DIR}/flatpak.txt"
            ;;
        all)
            packages::show_list "pacman"
            packages::show_list "aur"
            packages::show_list "flatpak"
            ;;
        *)
            log::error "Unknown package manager: '${manager}'. Use pacman, aur, flatpak, or all." "PACKAGES"
            return 1
            ;;
    esac
}

# ==============================================================================
# Internal helpers
# ==============================================================================

# @description Prints each package from a file to stderr, indented.
# @arg1 string file Package list file path
_packages::print_file() {
    local file="${1}"
    local pkg
    while IFS= read -r pkg; do
        printf "  %s\n" "${pkg}" >&2
    done < <(packages::parse_file "${file}")
}
