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
if [[ -n "${_LOGGER_SH_INCLUDED:-}" ]]; then
    return 0
fi
_LOGGER_SH_INCLUDED=1

# ==============================================================================
# Forge - Terminal Logging Library
# File: lib/logger.sh
# Purpose: Provides clean, structured, and colored logging functions for terminals.
#          Integrates with lib/colors.sh to automatically support colorless environments.
# Dependencies: lib/colors.sh
# Public API:
#   log::info       - Logs an informational message with [INFO] prefix
#   log::success    - Logs a success message with [SUCCESS] prefix
#   log::warn       - Logs a warning message with [WARNING] prefix
#   log::error      - Logs an error message with [ERROR] prefix
#   log::debug      - Logs a debug message with [DEBUG] prefix (only if DEBUG=1)
#   log::fatal      - Logs a fatal message with [FATAL] prefix
#   log::step       - Logs a visually distinct section header with horizontal lines
#   log_info        - Delegate for log::info
#   log_success     - Delegate for log::success
#   log_warn        - Delegate for log::warn
#   log_error       - Delegate for log::error
#   log_debug       - Delegate for log::debug
#   log_step        - Delegate for log::step
# Usage Example:
#   source lib/logger.sh
#   log::info "Bootstrapping packages..." "CORE"
#   log::step "Installing Desktop Environment"
#   log::warn "Optional package not found, skipping" "DWM"
# ==============================================================================

# Import colors.sh dependency — resolved relative to this file, not the caller
_LOGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_LOGGER_DIR}/colors.sh" ]]; then
    # shellcheck source=lib/colors.sh
    source "${_LOGGER_DIR}/colors.sh"
else
    echo "Error: colors.sh not found relative to logger.sh at: ${_LOGGER_DIR}/colors.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Internal Helper Functions
# ==============================================================================

# @description Internal helper to format and print log messages to stderr.
#              Splits multiline messages and prefixes each line with timestamp, level, and namespace.
# @arg1 string level The log level name (e.g. "INFO", "SUCCESS")
# @arg2 string color_prefix The ANSI color code variable
# @arg3 string message The message text (can be multiline)
# @arg4 string namespace The category/component namespace (default: "CORE")
# @noexit
log::_print() {
    local level="${1}"
    local color_prefix="${2}"
    local msg="${3:-}"
    local ns="${4:-CORE}"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

    # Pad level for nice visual alignment
    local padded_level
    case "${level}" in
        INFO)    padded_level="[INFO]   " ;;
        SUCCESS) padded_level="[SUCCESS]" ;;
        WARNING) padded_level="[WARNING]" ;;
        ERROR)   padded_level="[ERROR]  " ;;
        DEBUG)   padded_level="[DEBUG]  " ;;
        FATAL)   padded_level="[FATAL]  " ;;
        *)       padded_level="[${level}]" ;;
    esac

    # Wrap the level in color codes only if color is currently supported
    if colors::supports_color && [[ -n "${color_prefix}" ]]; then
        padded_level="${color_prefix}${padded_level}${RESET}"
    fi

    # Loop through lines to support multiline messages while preserving whitespace
    while IFS= read -r line || [[ -n "${line}" ]]; do
        printf "[%s] %s [%s]: %s\n" "${timestamp}" "${padded_level}" "${ns}" "${line}" >&2
    done <<< "${msg}"
}

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Logs an informational message to stderr.
# @arg1 string message The informational message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_BLUE RESET
# @exit 0 Always
log::info() {
    local msg="${1:-}"
    local ns="${2:-CORE}"
    log::_print "INFO" "${BOLD_BLUE}" "${msg}" "${ns}"
}

# @description Logs a success message to stderr.
# @arg1 string message The success message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_GREEN RESET
# @exit 0 Always
log::success() {
    local msg="${1:-}"
    local ns="${2:-CORE}"
    log::_print "SUCCESS" "${BOLD_GREEN}" "${msg}" "${ns}"
}

# @description Logs a warning message to stderr.
# @arg1 string message The warning message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_YELLOW RESET
# @exit 0 Always
log::warn() {
    local msg="${1:-}"
    local ns="${2:-CORE}"
    log::_print "WARNING" "${BOLD_YELLOW}" "${msg}" "${ns}"
}

# @description Logs an error message to stderr.
# @arg1 string message The error message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_RED RESET
# @exit 0 Always
log::error() {
    local msg="${1:-}"
    local ns="${2:-CORE}"
    log::_print "ERROR" "${BOLD_RED}" "${msg}" "${ns}"
}

# @description Logs a debug message to stderr. Only outputs when DEBUG=1.
# @arg1 string message The debug message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_MAGENTA RESET DEBUG
# @exit 0 Always
log::debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        local msg="${1:-}"
        local ns="${2:-CORE}"
        log::_print "DEBUG" "${BOLD_MAGENTA}" "${msg}" "${ns}"
    fi
}

# @description Logs a fatal/panic message to stderr.
# @arg1 string message The fatal message to log.
# @arg2 string namespace The namespace/component logging the message.
# @globals BOLD_RED RESET
# @exit 0 Always (caller is responsible for exit)
log::fatal() {
    local msg="${1:-}"
    local ns="${2:-CORE}"
    log::_print "FATAL" "${BOLD_RED}" "${msg}" "${ns}"
}

# @description Logs a visually distinct section header with horizontal lines to stderr.
# @arg1 string title The title of the step/section.
# @globals BOLD_CYAN BOLD RESET
# @exit 0 Always
log::step() {
    local message="${1:-}"
    local divider="────────────────────────────────────────────────────────────"

    if colors::supports_color; then
        echo "${BOLD_CYAN}${divider}${RESET}" >&2
        while IFS= read -r line || [[ -n "${line}" ]]; do
            echo "${BOLD}${line}${RESET}" >&2
        done <<< "${message}"
        echo "${BOLD_CYAN}${divider}${RESET}" >&2
    else
        echo "${divider}" >&2
        while IFS= read -r line || [[ -n "${line}" ]]; do
            echo "${line}" >&2
        done <<< "${message}"
        echo "${divider}" >&2
    fi
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for log::info
log_info() {
    log::info "$@"
}

# @description Delegate for log::success
log_success() {
    log::success "$@"
}

# @description Delegate for log::warn
log_warn() {
    log::warn "$@"
}

# @description Delegate for log::error
log_error() {
    log::error "$@"
}

# @description Delegate for log::debug
log_debug() {
    log::debug "$@"
}

# @description Delegate for log::step
log_step() {
    log::step "$@"
}
