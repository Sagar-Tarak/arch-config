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
if [[ -n "${_COMMAND_SH_INCLUDED:-}" ]]; then
    return 0
fi
_COMMAND_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Command Execution Library
# File: lib/command.sh
# Purpose: Provides mechanisms to run external commands safely, quietly, or
#          with failure checks. Keeps signatures future-ready for dry-run,
#          verbose mode, and retries without implementing them yet.
# Dependencies: lib/logger.sh
# Public API:
#   command::run             - Runs a command with optional debug logging
#   command::run_quiet       - Runs a command hiding stdout/stderr unless it fails
#   command::run_checked     - Runs a command, logging and exiting on failure
#   command::command_exists  - Checks if a command exists in $PATH
#   command::require_command - Asserts a command exists, exiting with code 10 if not
#   run                      - Delegate for command::run
#   run_quiet                - Delegate for command::run_quiet
#   run_checked              - Delegate for command::run_checked
#   command_exists           - Delegate for command::command_exists
#   require_command          - Delegate for command::require_command
#   sys::require_command     - Compatibility delegate for command::require_command
# Usage Example:
#   source lib/command.sh
#   command::require_command "git"
#   command::run git clone https://example.com/repo.git
#   command::run_quiet pacman -Syu --noconfirm
# ==============================================================================

# Import logger.sh dependency — resolved relative to this file, not the caller
_COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_COMMAND_DIR}/logger.sh" ]]; then
    # shellcheck source=lib/logger.sh
    source "${_COMMAND_DIR}/logger.sh"
else
    echo "Error: logger.sh not found relative to command.sh at: ${_COMMAND_DIR}/logger.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Runs a command. Future-ready for dry-run and verbose modes.
# @arg1 string... cmd The command and arguments to execute.
# @globals ARCH_CFG_DRY_RUN
# @exit Code returned by the executed command, or 0 in dry-run mode.
command::run() {
    log::debug "Executing command: $*" "CMD"

    # Dry-run support placeholder
    if [[ "${ARCH_CFG_DRY_RUN:-}" == "true" ]]; then
        log::info "[DRY-RUN] Would run: $*" "CMD"
        return 0
    fi

    "$@"
}

# @description Runs a command hiding its output unless the command fails.
#              If it fails, the captured output is dumped to stderr.
# @arg1 string... cmd The command and arguments to execute.
# @globals ARCH_CFG_DRY_RUN
# @exit 0 on success, or command exit code on failure.
command::run_quiet() {
    log::debug "Executing command quiet: $*" "CMD"

    # Dry-run support placeholder
    if [[ "${ARCH_CFG_DRY_RUN:-}" == "true" ]]; then
        log::info "[DRY-RUN] Would run quiet: $*" "CMD"
        return 0
    fi

    local tmp_file
    tmp_file="$(mktemp /tmp/cmd_output.XXXXXX)"
    local exit_code=0

    "$@" > "${tmp_file}" 2>&1 || exit_code=$?

    if [[ "${exit_code}" -ne 0 ]]; then
        log::error "Command failed with exit code ${exit_code}: $*" "CMD"
        cat "${tmp_file}" >&2
    fi

    rm -f "${tmp_file}"
    return "${exit_code}"
}

# @description Runs a command and exits the script with the command's exit status
#              if it fails.
# @arg1 string... cmd The command and arguments to execute.
# @globals ARCH_CFG_DRY_RUN
# @exit 0 on success, or terminates the shell process on failure.
command::run_checked() {
    log::debug "Executing command checked: $*" "CMD"

    # Dry-run support placeholder
    if [[ "${ARCH_CFG_DRY_RUN:-}" == "true" ]]; then
        log::info "[DRY-RUN] Would run checked: $*" "CMD"
        return 0
    fi

    local exit_code=0
    "$@" || exit_code=$?

    if [[ "${exit_code}" -ne 0 ]]; then
        log::error "Checked command failed with exit code ${exit_code}: $*" "CMD"
        exit "${exit_code}"
    fi

    return 0
}

# @description Checks if a command exists in the environment PATH.
# @arg1 string cmd The executable name to verify.
# @exit 0 if command exists, 1 otherwise.
command::command_exists() {
    local cmd="${1:-}"
    [[ -n "${cmd}" ]] && command -v "${cmd}" &>/dev/null
}

# @description Asserts that a command exists. Exits with code 10 if not found.
# @arg1 string cmd The executable name to verify.
# @exit 0 if command exists, exits 10 otherwise.
command::require_command() {
    local cmd="${1:-}"
    if ! command::command_exists "${cmd}"; then
        log::fatal "Required command '${cmd}' is missing." "SYS"
        exit 10
    fi
    return 0
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for command::run
run() {
    command::run "$@"
}

# @description Delegate for command::run_quiet
run_quiet() {
    command::run_quiet "$@"
}

# @description Delegate for command::run_checked
run_checked() {
    command::run_checked "$@"
}

# @description Delegate for command::command_exists
command_exists() {
    command::command_exists "$@"
}

# @description Delegate for command::require_command
require_command() {
    command::require_command "$@"
}

# @description Compatibility delegate matching sys::require_command usage pattern in AI_CONTEXT.md
sys::require_command() {
    command::require_command "$@"
}
