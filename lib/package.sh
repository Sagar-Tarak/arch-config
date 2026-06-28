#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "${_PACKAGE_SH_INCLUDED:-}" ]]; then return 0; fi
_PACKAGE_SH_INCLUDED=1

# ==============================================================================
# Forge — Package Manager Abstraction Library
# File: lib/package.sh
# Purpose: Real package installation via pacman, paru/yay, and flatpak.
#          All operations are idempotent: already-installed packages are skipped.
#          All operations respect ARCH_CFG_DRY_RUN.
# Dependencies: lib/logger.sh, lib/command.sh
# Public API:
#   package::has_manager          - Checks if a package manager executable exists
#   package::detect_aur_helper    - Returns paru or yay if available
#   package::is_installed         - Checks if a package is installed
#   package::install              - Installs one package (auto-detects manager)
#   package::remove               - Removes one package
#   package::install_list         - Batch install via a specific manager
#   package::install_manifest     - Install all packages listed in a file
#   package::verify_manifest      - Check all packages in a file are installed
#   package::missing_from_manifest- Print packages in a file that are not installed
#   package::count_manifest       - Count installable entries in a file
# ==============================================================================

_PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${_PACKAGE_DIR}/logger.sh" ]]; then
    source "${_PACKAGE_DIR}/logger.sh"
else
    echo "Error: logger.sh not found at: ${_PACKAGE_DIR}/logger.sh" >&2
    return 1 2>/dev/null || exit 1
fi

if [[ -f "${_PACKAGE_DIR}/command.sh" ]]; then
    source "${_PACKAGE_DIR}/command.sh"
else
    echo "Error: command.sh not found at: ${_PACKAGE_DIR}/command.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Manager detection
# ==============================================================================

package::has_manager() {
    local manager="${1:-}"
    command::command_exists "${manager}"
}

package::detect_aur_helper() {
    if package::has_manager "paru"; then
        echo "paru"; return 0
    elif package::has_manager "yay"; then
        echo "yay"; return 0
    fi
    return 1
}

# ==============================================================================
# Query
# ==============================================================================

# @description Checks if a package is currently installed.
# @arg1 string package  Package name (or Flatpak application ID)
# @arg2 string manager  Optional: pacman | paru | yay | flatpak (auto-detected)
# @exit 0 if installed, 1 otherwise
package::is_installed() {
    local pkg="${1:-}"
    local manager="${2:-}"

    if [[ -z "${pkg}" ]]; then
        log::error "package::is_installed: package name required" "PKG"
        return 1
    fi

    if [[ -z "${manager}" ]]; then
        if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]] \
           && package::has_manager "flatpak"; then
            manager="flatpak"
        else
            manager="pacman"
        fi
    fi

    case "${manager}" in
        pacman|paru|yay)
            package::has_manager "pacman" && pacman -Qq "${pkg}" &>/dev/null
            ;;
        flatpak)
            package::has_manager "flatpak" && flatpak info "${pkg}" &>/dev/null
            ;;
        *)
            log::error "Unsupported package manager: ${manager}" "PKG"
            return 1
            ;;
    esac
}

# ==============================================================================
# Install / Remove
# ==============================================================================

# @description Installs a single package. Skips if already installed.
# @arg1 string package  Package name
# @arg2 string manager  Optional: pacman | paru | yay | flatpak (auto-detected)
# @exit 0 on success or already installed, 1 on failure
package::install() {
    local pkg="${1:-}"
    local manager="${2:-}"

    if [[ -z "${pkg}" ]]; then
        log::error "package::install: package name required" "PKG"
        return 1
    fi

    if [[ -z "${manager}" ]]; then
        if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]] \
           && package::has_manager "flatpak"; then
            manager="flatpak"
        elif package::detect_aur_helper &>/dev/null; then
            manager="$(package::detect_aur_helper)"
        else
            manager="pacman"
        fi
    fi

    if package::is_installed "${pkg}" "${manager}"; then
        log::info "Already installed: ${pkg}" "PKG"
        return 0
    fi

    log::info "Installing: ${pkg} (${manager})" "PKG"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would install: ${pkg} via ${manager}" "PKG"
        return 0
    fi

    case "${manager}" in
        pacman)
            sudo pacman -S --needed --noconfirm "${pkg}"
            ;;
        paru|yay)
            "${manager}" -S --needed --noconfirm "${pkg}"
            ;;
        flatpak)
            flatpak install --noninteractive "${pkg}"
            ;;
        *)
            log::error "Unsupported package manager: ${manager}" "PKG"
            return 1
            ;;
    esac

    local rc=$?
    if [[ "${rc}" -ne 0 ]]; then
        log::error "Failed to install '${pkg}' via ${manager} (exit ${rc})" "PKG"
        return 1
    fi

    log::success "Installed: ${pkg}" "PKG"
    return 0
}

# @description Removes a single package.
# @arg1 string package  Package name
# @arg2 string manager  Optional: pacman | flatpak (auto-detected)
# @exit 0 on success or not installed, 1 on failure
package::remove() {
    local pkg="${1:-}"
    local manager="${2:-pacman}"

    if [[ -z "${pkg}" ]]; then
        log::error "package::remove: package name required" "PKG"
        return 1
    fi

    if ! package::is_installed "${pkg}" "${manager}"; then
        log::info "Not installed, nothing to remove: ${pkg}" "PKG"
        return 0
    fi

    log::info "Removing: ${pkg} (${manager})" "PKG"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove: ${pkg} via ${manager}" "PKG"
        return 0
    fi

    case "${manager}" in
        pacman|paru|yay)
            sudo pacman -Rns --noconfirm "${pkg}"
            ;;
        flatpak)
            flatpak uninstall --noninteractive "${pkg}"
            ;;
        *)
            log::error "Unsupported package manager: ${manager}" "PKG"
            return 1
            ;;
    esac

    local rc=$?
    if [[ "${rc}" -ne 0 ]]; then
        log::error "Failed to remove '${pkg}' via ${manager} (exit ${rc})" "PKG"
        return 1
    fi

    log::success "Removed: ${pkg}" "PKG"
    return 0
}

# @description Batch-installs a list of packages via one manager.
#              Uses --needed so already-installed packages are skipped by pacman.
#              Falls back to individual installs for flatpak.
# @arg1 string manager  pacman | paru | yay | flatpak
# @arg2 string... packages
# @exit 0 if all succeed, 1 if any fail
package::install_list() {
    local manager="${1:-}"; shift
    local -a pkgs=("$@")

    if [[ -z "${manager}" ]]; then
        log::error "package::install_list: manager required as first argument" "PKG"
        return 1
    fi

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        return 0
    fi

    # Filter out already-installed packages (flatpak handles its own idempotency
    # but pacman --needed also covers it; pre-filter for cleaner logs)
    local -a missing=()
    local p
    for p in "${pkgs[@]}"; do
        if ! package::is_installed "${p}" "${manager}"; then
            missing+=("${p}")
        else
            log::info "Already installed: ${p}" "PKG"
        fi
    done

    if [[ "${#missing[@]}" -eq 0 ]]; then
        log::info "All packages already installed (${manager})" "PKG"
        return 0
    fi

    log::info "Installing ${#missing[@]} package(s) via ${manager}: ${missing[*]}" "PKG"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        local p
        for p in "${missing[@]}"; do
            log::info "[DRY-RUN] Would install: ${p} via ${manager}" "PKG"
        done
        return 0
    fi

    case "${manager}" in
        pacman)
            sudo pacman -S --needed --noconfirm "${missing[@]}"
            ;;
        paru|yay)
            "${manager}" -S --needed --noconfirm "${missing[@]}"
            ;;
        flatpak)
            local p
            local failed=0
            for p in "${missing[@]}"; do
                flatpak install --noninteractive "${p}" || failed=$(( failed + 1 ))
            done
            [[ "${failed}" -eq 0 ]]
            ;;
        *)
            log::error "Unsupported package manager: ${manager}" "PKG"
            return 1
            ;;
    esac

    local rc=$?
    if [[ "${rc}" -ne 0 ]]; then
        log::error "Batch install failed via ${manager} (exit ${rc})" "PKG"
        return 1
    fi
    return 0
}

# ==============================================================================
# Manifest-based operations
# ==============================================================================

# @description Parses a package manifest file: strips comments (#...) and
#              blank lines, prints one package name per line.
# @arg1 string file  Absolute path to a package manifest file
# @stdout Package names, one per line
# @exit 0 always (missing file is warned, not fatal)
_package::parse_manifest() {
    local file="${1:-}"

    if [[ -z "${file}" ]]; then
        log::error "_package::parse_manifest: file path required" "PKG"
        return 1
    fi

    if [[ ! -f "${file}" ]]; then
        log::warn "Package manifest not found: ${file}" "PKG"
        return 0
    fi

    local line
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%%#*}"             # strip inline comments
        line="${line#"${line%%[![:space:]]*}"}"  # ltrim
        line="${line%"${line##*[![:space:]]}"}"  # rtrim
        [[ -z "${line}" ]] && continue
        printf "%s\n" "${line}"
    done < "${file}"
}

# @description Counts installable entries in a manifest file.
# @arg1 string file  Manifest file path
# @stdout Integer count
package::count_manifest() {
    local file="${1:-}"
    local count=0
    local pkg
    while IFS= read -r pkg; do
        count=$(( count + 1 ))
    done < <(_package::parse_manifest "${file}")
    printf "%d" "${count}"
}

# @description Installs every package listed in a manifest file.
# @arg1 string file     Manifest file path
# @arg2 string manager  Optional: pacman | paru | yay | flatpak (auto-detected per package)
# @exit 0 if all succeed, 1 if any fail
package::install_manifest() {
    local file="${1:-}"
    local manager="${2:-}"

    if [[ -z "${file}" ]]; then
        log::error "package::install_manifest: file path required" "PKG"
        return 1
    fi

    if [[ ! -f "${file}" ]]; then
        log::warn "Package manifest not found: ${file}" "PKG"
        return 0
    fi

    log::info "Installing packages from: ${file}" "PKG"

    local -a pkgs=()
    local pkg
    while IFS= read -r pkg; do
        pkgs+=("${pkg}")
    done < <(_package::parse_manifest "${file}")

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        log::info "No packages in manifest: ${file}" "PKG"
        return 0
    fi

    local failed=0
    for pkg in "${pkgs[@]}"; do
        package::install "${pkg}" "${manager}" || failed=$(( failed + 1 ))
    done

    if [[ "${failed}" -gt 0 ]]; then
        log::error "${failed} package(s) failed to install from: ${file}" "PKG"
        return 1
    fi
    return 0
}

# @description Checks that every package in a manifest file is installed.
# @arg1 string file     Manifest file path
# @arg2 string manager  Optional: auto-detected per package
# @exit 0 if all installed, 1 if any missing
package::verify_manifest() {
    local file="${1:-}"
    local manager="${2:-}"

    if [[ ! -f "${file}" ]]; then
        log::warn "Package manifest not found: ${file}" "PKG"
        return 1
    fi

    local failed=0
    local pkg
    while IFS= read -r pkg; do
        local mgr="${manager}"
        if [[ -z "${mgr}" ]]; then
            if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]]; then
                mgr="flatpak"
            else
                mgr="pacman"
            fi
        fi
        if package::is_installed "${pkg}" "${mgr}"; then
            log::success "Verified: ${pkg}" "PKG"
        else
            log::error "Missing: ${pkg}" "PKG"
            failed=$(( failed + 1 ))
        fi
    done < <(_package::parse_manifest "${file}")

    [[ "${failed}" -eq 0 ]]
}

# @description Prints the names of packages in a manifest that are not installed.
# @arg1 string file     Manifest file path
# @arg2 string manager  Optional: auto-detected per package
# @stdout Missing package names, one per line
# @exit 0 if none missing, 1 if any missing
package::missing_from_manifest() {
    local file="${1:-}"
    local manager="${2:-}"

    if [[ ! -f "${file}" ]]; then
        log::warn "Package manifest not found: ${file}" "PKG"
        return 1
    fi

    local found_missing=0
    local pkg
    while IFS= read -r pkg; do
        local mgr="${manager}"
        if [[ -z "${mgr}" ]]; then
            if [[ "${pkg}" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+ ]]; then
                mgr="flatpak"
            else
                mgr="pacman"
            fi
        fi
        if ! package::is_installed "${pkg}" "${mgr}"; then
            printf "%s\n" "${pkg}"
            found_missing=1
        fi
    done < <(_package::parse_manifest "${file}")

    [[ "${found_missing}" -eq 0 ]]
}

# ==============================================================================
# Compatibility delegates (kept for backward compatibility with existing tests)
# ==============================================================================

has_manager()      { package::has_manager "$@"; }
detect_aur_helper(){ package::detect_aur_helper "$@"; }
is_installed()     { package::is_installed "$@"; }
install_package()  { package::install "$@"; }
pkg::is_installed(){ package::is_installed "$@"; }
pkg::install()     { package::install "$@"; }
