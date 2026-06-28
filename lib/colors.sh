#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_COLORS_SH_INCLUDED:-}" ]]; then
    return 0
fi
_COLORS_SH_INCLUDED=1

# ==============================================================================
# Forge - Terminal Color Management Library
# File: lib/colors.sh
# Purpose: Provides terminal color support detection and initialization.
#          Highly portable, independent, and compliant with the NO_COLOR standard.
# Dependencies: None
# Public API:
#   colors::supports_color - Returns 0 if color is supported/forced, 1 otherwise
#   colors::enable_colors  - Populates color variables with ANSI codes
#   colors::disable_colors - Clears color variables to empty strings
#   supports_color         - Delegate for colors::supports_color
#   enable_colors          - Delegate for colors::enable_colors
#   disable_colors         - Delegate for colors::disable_colors
# Usage Example:
#   source lib/colors.sh
#   if colors::supports_color; then echo "Colors on"; fi
#   enable_colors
#   printf "%s%s%s\n" "${BOLD_GREEN}" "OK" "${RESET}"
# ==============================================================================

# shellcheck disable=SC2034  # Color variables are used by consumers of this library

# @description Reset text attributes to default
RESET=""

# @description Bold text modifier
BOLD=""

# @description Regular foreground colors
BLACK=""
RED=""
GREEN=""
YELLOW=""
BLUE=""
MAGENTA=""
CYAN=""
WHITE=""

# @description Bold foreground colors
BOLD_BLACK=""
BOLD_RED=""
BOLD_GREEN=""
BOLD_YELLOW=""
BOLD_BLUE=""
BOLD_MAGENTA=""
BOLD_CYAN=""
BOLD_WHITE=""

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Checks if the current environment supports color output.
#              Considers stdout terminal status, TERM value, NO_COLOR, and FORCE_COLOR.
# @noargs
# @exit 0 If color is supported/forced
# @exit 1 If color is not supported/disabled
colors::supports_color() {
    # NO_COLOR environment variable takes precedence over all other settings.
    # If NO_COLOR is set (regardless of its value), colors must be disabled.
    # See https://no-color.org/
    if [[ -v NO_COLOR ]]; then
        return 1
    fi

    # FORCE_COLOR environment variable forces color output if set and not "0".
    if [[ -v FORCE_COLOR && "${FORCE_COLOR}" != "0" ]]; then
        return 0
    fi

    # Otherwise, enable colors only if stdout (FD 1) is a terminal
    # and the terminal type is not "dumb".
    if [[ -t 1 && "${TERM:-}" != "dumb" ]]; then
        return 0
    fi

    return 1
}

# @description Initializes color variables with ANSI escape codes.
#              Safe to call multiple times.
# @noargs
# @exit 0 Always succeeds
colors::enable_colors() {
    RESET=$'\e[0m'
    BOLD=$'\e[1m'

    BLACK=$'\e[30m'
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BLUE=$'\e[34m'
    MAGENTA=$'\e[35m'
    CYAN=$'\e[36m'
    WHITE=$'\e[37m'

    BOLD_BLACK=$'\e[1;30m'
    BOLD_RED=$'\e[1;31m'
    BOLD_GREEN=$'\e[1;32m'
    BOLD_YELLOW=$'\e[1;33m'
    BOLD_BLUE=$'\e[1;34m'
    BOLD_MAGENTA=$'\e[1;35m'
    BOLD_CYAN=$'\e[1;36m'
    BOLD_WHITE=$'\e[1;37m'

    return 0
}

# @description Clears all color variables, turning them into empty strings.
#              Safe to call multiple times.
# @noargs
# @exit 0 Always succeeds
colors::disable_colors() {
    RESET=""
    BOLD=""

    BLACK=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""

    BOLD_BLACK=""
    BOLD_RED=""
    BOLD_GREEN=""
    BOLD_YELLOW=""
    BOLD_BLUE=""
    BOLD_MAGENTA=""
    BOLD_CYAN=""
    BOLD_WHITE=""

    return 0
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for colors::supports_color
supports_color() {
    colors::supports_color "$@"
}

# @description Delegate for colors::enable_colors
enable_colors() {
    colors::enable_colors "$@"
}

# @description Delegate for colors::disable_colors
disable_colors() {
    colors::disable_colors "$@"
}

# ==============================================================================
# Automatic Initialization
# Automatically determine color support and initialize on library import.
# ==============================================================================
if colors::supports_color; then
    colors::enable_colors
else
    colors::disable_colors
fi
