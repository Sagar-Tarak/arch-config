#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_UTILS_SH_INCLUDED:-}" ]]; then
    return 0
fi
_UTILS_SH_INCLUDED=1

# ==============================================================================
# Forge - General Utilities Library
# File: lib/utils.sh
# Purpose: Core helper utilities (root check, user query, timestamps, formatting)
#          without external dependencies or project-specific logic.
# Dependencies: None (No log/colors/commands are imported to keep it a leaf library)
# Public API:
#   utils::is_root       - Checks if current effective user is root
#   utils::current_user  - Resolves actual username, including under sudo
#   utils::timestamp     - Returns standard YYYY-MM-DD HH:MM:SS timestamp
#   utils::confirm       - Prompts for confirmation (y/N) with interactive checks
#   utils::trim          - High-performance pure-Bash whitespace trimming
#   utils::join_by       - High-performance pure-Bash array joiner
#   is_root              - Delegate for utils::is_root
#   current_user         - Delegate for utils::current_user
#   timestamp            - Delegate for utils::timestamp
#   confirm              - Delegate for utils::confirm
#   trim                 - Delegate for utils::trim
#   join_by              - Delegate for utils::join_by
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Checks if the current executing user has root privileges.
# @noargs
# @exit 0 if root, 1 otherwise.
utils::is_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

# @description Resolves the actual username of the user invoking the script.
#              Correctly detects the non-root user when executing with sudo.
# @noargs
# @stdout The resolved username
utils::current_user() {
    local user="${SUDO_USER:-}"
    if [[ -z "${user}" ]]; then
        user="${USER:-}"
    fi
    if [[ -z "${user}" ]]; then
        user="$(id -un 2>/dev/null || echo "unknown")"
    fi
    echo "${user}"
}

# @description Returns a standard localized date-time timestamp.
# @noargs
# @stdout The formatted timestamp string
utils::timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

# @description Prompts the user for a y/N confirmation. Handles non-interactive
#              environments gracefully by falling back to default.
# @arg1 string prompt The question to ask the user.
# @arg2 string default The default response if user hits Enter (Y/N, default: N).
# @exit 0 if user confirms (Y), 1 if denied (N).
utils::confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-N}"
    local response

    # Interactive terminal: prompt in a loop until a valid answer is given.
    if [[ -t 0 ]]; then
        while true; do
            if [[ "${default}" =~ ^[Yy]$ ]]; then
                read -r -p "${prompt} [Y/n]: " response
            else
                read -r -p "${prompt} [y/N]: " response
            fi
            [[ -z "${response}" ]] && response="${default}"
            case "${response}" in
                [Yy]* ) return 0 ;;
                [Nn]* ) return 1 ;;
                * ) echo "Please answer yes (y) or no (n)." ;;
            esac
        done
    fi

    # Non-interactive: attempt to read one line from stdin.
    # Piped input (echo "yes" | confirm) satisfies the read; /dev/null gives
    # immediate EOF and falls through to the default branch below.
    if IFS= read -r response; then
        [[ -z "${response}" ]] && response="${default}"
        case "${response}" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
        esac
    fi

    # No readable input (e.g. CI with stdin closed or redirected to /dev/null).
    if [[ "${default}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# @description Removes leading and trailing whitespace from a string or standard input.
#              Utilizes pure-Bash pattern matching (no forks/subshells).
# @arg1 string input String to trim. If empty, reads from standard input.
# @stdout The trimmed string.
utils::trim() {
    local var="${1:-}"
    if [[ $# -eq 0 ]]; then
        # Read from stdin, preserving whitespace lines
        var="$(cat)"
    fi
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    printf "%s" "${var}"
}

# @description Joins a list of values together with a custom delimiter.
#              Utilizes pure-Bash array expansion (no forks/subshells).
# @arg1 string delimiter Character or string delimiter.
# @arg2 string... values Array elements to join.
# @stdout The joined string.
utils::join_by() {
    local delimiter="${1:-}"
    shift
    local first="${1:-}"
    shift
    printf "%s" "${first}" "${@/#/${delimiter}}"
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for utils::is_root
is_root() {
    utils::is_root "$@"
}

# @description Delegate for utils::current_user
current_user() {
    utils::current_user "$@"
}

# @description Delegate for utils::timestamp
timestamp() {
    utils::timestamp "$@"
}

# @description Delegate for utils::confirm
confirm() {
    utils::confirm "$@"
}

# @description Delegate for utils::trim
trim() {
    utils::trim "$@"
}

# @description Delegate for utils::join_by
join_by() {
    utils::join_by "$@"
}
