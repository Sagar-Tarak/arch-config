#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_ENVIRONMENT_SH_INCLUDED:-}" ]]; then
    return 0
fi
_ENVIRONMENT_SH_INCLUDED=1

# ==============================================================================
# Forge - Environment Detection Library
# File: bootstrap/environment.sh
# Purpose: Provides pure detection helper functions for the host environment.
#          Exposes query functions only — no installation or mutation logic.
# Dependencies: lib/logger.sh (must be loaded via loader.sh first)
# Public API:
#   environment::is_arch_linux        - Returns 0 if running on Arch Linux
#   environment::detect_shell         - Prints the user's login shell name
#   environment::is_root              - Returns 0 if EUID is 0
#   environment::is_sudo              - Returns 0 if invoked under sudo
#   environment::detect_terminal      - Prints the terminal emulator name
#   environment::detect_package_manager - Prints the available package manager
#   environment::detect_aur_helper    - Prints the available AUR helper
#   environment::has_internet         - Returns 0 if internet is reachable
#   environment::detect_cpu_arch      - Prints the CPU architecture
#   environment::detect_display_server - Prints "wayland", "x11", or "none"
#   environment::detect               - Runs all detections and exports results
# Usage Example:
#   source bootstrap/loader.sh && loader::load_libs
#   source bootstrap/environment.sh
#   if environment::is_arch_linux; then echo "Arch detected"; fi
#   environment::detect
#   echo "${ENV_DISPLAY_SERVER}"
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Checks whether the current OS is Arch Linux by inspecting
#              /etc/os-release (the portable standard for Linux ID detection).
# @noargs
# @exit 0 if Arch Linux, 1 otherwise.
environment::is_arch_linux() {
    local os_id=""
    if [[ -f /etc/os-release ]]; then
        # Source only the ID field — avoid polluting global namespace
        os_id="$(. /etc/os-release 2>/dev/null && echo "${ID:-}")"
    fi
    [[ "${os_id}" == "arch" ]]
}

# @description Resolves the name of the login shell for the current user.
#              Uses SHELL env var first, then falls back to passwd entry.
# @noargs
# @stdout The shell name (e.g. "bash", "zsh", "fish")
# @exit 0 Always
environment::detect_shell() {
    local shell_path="${SHELL:-}"
    if [[ -z "${shell_path}" ]]; then
        shell_path="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || echo "")"
    fi
    basename "${shell_path:-unknown}"
}

# @description Checks if the current process is running as root (EUID == 0).
# @noargs
# @exit 0 if root, 1 otherwise.
environment::is_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

# @description Checks if the current process was invoked via sudo.
# @noargs
# @exit 0 if running under sudo, 1 otherwise.
environment::is_sudo() {
    [[ -n "${SUDO_USER:-}" ]]
}

# @description Identifies the terminal emulator by inspecting common environment
#              variables set by terminal emulators on startup.
# @noargs
# @stdout Terminal name string (e.g. "kitty", "alacritty", "unknown")
# @exit 0 Always
environment::detect_terminal() {
    # TERM_PROGRAM is set by many modern terminals
    if [[ -n "${TERM_PROGRAM:-}" ]]; then
        echo "${TERM_PROGRAM}"
        return 0
    fi
    # Kitty sets KITTY_WINDOW_ID
    if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
        echo "kitty"
        return 0
    fi
    # Alacritty does not set a unique var but COLORTERM may hint at it
    if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
        echo "${TERM:-unknown}"
        return 0
    fi
    echo "${TERM:-unknown}"
}

# @description Detects the primary package manager available on the system.
#              On Arch Linux this is always pacman; the function is structured
#              for future portability.
# @noargs
# @stdout Package manager name (e.g. "pacman") or "unknown"
# @exit 0 if a known manager is found, 1 otherwise.
environment::detect_package_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
        return 0
    fi
    echo "unknown"
    return 1
}

# @description Detects an available AUR helper, preferring paru over yay.
# @noargs
# @stdout AUR helper name ("paru", "yay") or empty string
# @exit 0 if a helper is found, 1 otherwise.
environment::detect_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
        return 0
    elif command -v yay &>/dev/null; then
        echo "yay"
        return 0
    fi
    return 1
}

# @description Tests internet connectivity by attempting a lightweight HTTPS
#              request to a well-known, stable endpoint. Falls back to ping
#              if curl is unavailable.
# @noargs
# @exit 0 if internet is reachable, 1 otherwise.
environment::has_internet() {
    if command -v curl &>/dev/null; then
        curl --silent --max-time 5 --head "https://archlinux.org" &>/dev/null
        return $?
    elif command -v ping &>/dev/null; then
        ping -c 1 -W 5 archlinux.org &>/dev/null
        return $?
    fi
    # Cannot verify — assume no connectivity
    return 1
}

# @description Detects the CPU architecture using uname.
# @noargs
# @stdout Architecture string (e.g. "x86_64", "aarch64")
# @exit 0 Always
environment::detect_cpu_arch() {
    uname -m
}

# @description Detects whether the active display server is Wayland, X11, or none.
#              Checks well-known environment variables set by each session type.
# @noargs
# @stdout "wayland", "x11", or "none"
# @exit 0 Always
environment::detect_display_server() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        echo "wayland"
    elif [[ -n "${DISPLAY:-}" ]]; then
        echo "x11"
    else
        echo "none"
    fi
}

# @description Runs all environment detection helpers and exports results as
#              ENV_* variables for use by the rest of the bootstrap pipeline.
#              Logs a summary when the logger is available.
# @noargs
# @exit 0 Always
environment::detect() {
    export ENV_IS_ARCH_LINUX="false"
    if environment::is_arch_linux; then
        ENV_IS_ARCH_LINUX="true"
    fi

    export ENV_SHELL
    ENV_SHELL="$(environment::detect_shell)"

    export ENV_IS_ROOT="false"
    if environment::is_root; then
        ENV_IS_ROOT="true"
    fi

    export ENV_IS_SUDO="false"
    if environment::is_sudo; then
        ENV_IS_SUDO="true"
    fi

    export ENV_TERMINAL
    ENV_TERMINAL="$(environment::detect_terminal)"

    export ENV_PACKAGE_MANAGER
    ENV_PACKAGE_MANAGER="$(environment::detect_package_manager 2>/dev/null || echo "unknown")"

    export ENV_AUR_HELPER
    ENV_AUR_HELPER="$(environment::detect_aur_helper 2>/dev/null || echo "none")"

    export ENV_HAS_INTERNET="false"
    if environment::has_internet; then
        ENV_HAS_INTERNET="true"
    fi

    export ENV_CPU_ARCH
    ENV_CPU_ARCH="$(environment::detect_cpu_arch)"

    export ENV_DISPLAY_SERVER
    ENV_DISPLAY_SERVER="$(environment::detect_display_server)"

    # Log summary if the logger is already loaded
    if declare -f log::debug &>/dev/null; then
        log::debug "arch=${ENV_IS_ARCH_LINUX} shell=${ENV_SHELL} root=${ENV_IS_ROOT} sudo=${ENV_IS_SUDO}" "ENV"
        log::debug "terminal=${ENV_TERMINAL} pkg=${ENV_PACKAGE_MANAGER} aur=${ENV_AUR_HELPER}" "ENV"
        log::debug "internet=${ENV_HAS_INTERNET} arch=${ENV_CPU_ARCH} display=${ENV_DISPLAY_SERVER}" "ENV"
    fi

    return 0
}
