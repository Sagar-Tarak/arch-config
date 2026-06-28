#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_ARGS_SH_INCLUDED:-}" ]]; then
    return 0
fi
_ARGS_SH_INCLUDED=1

# ==============================================================================
# Forge - CLI Argument Parser
# File: installer/args.sh
# Purpose: Parses install.sh CLI flags into exported global variables.
#          Prints usage on unknown arguments and exits with code 2.
# Dependencies: lib/logger.sh (loaded via bootstrap)
# Public API:
#   args::parse         - Parses "$@" and exports all ARCH_CFG_FLAG_* variables
#   args::print_usage   - Prints synopsis to stdout
#   args::print_help    - Prints full help to stdout
# Usage Example:
#   source installer/args.sh
#   args::parse "$@"
#   [[ "${ARCH_CFG_FLAG_DRY_RUN}" == "true" ]] && echo "dry-run mode"
# ==============================================================================

# ------------------------------------------------------------------------------
# Flag defaults — exported so all installer components can read them.
# ARCH_CFG_DRY_RUN is owned by variables.sh; we honour its existing value.
# ------------------------------------------------------------------------------
export ARCH_CFG_FLAG_HELP="${ARCH_CFG_FLAG_HELP:-false}"
export ARCH_CFG_FLAG_VERSION="${ARCH_CFG_FLAG_VERSION:-false}"
export ARCH_CFG_FLAG_YES="${ARCH_CFG_FLAG_YES:-false}"
export ARCH_CFG_FLAG_VERBOSE="${ARCH_CFG_FLAG_VERBOSE:-false}"
export ARCH_CFG_FLAG_LIST_MODULES="${ARCH_CFG_FLAG_LIST_MODULES:-false}"
export ARCH_CFG_FLAG_MODULE="${ARCH_CFG_FLAG_MODULE:-}"
export ARCH_CFG_FLAG_VERIFY="${ARCH_CFG_FLAG_VERIFY:-false}"
export ARCH_CFG_AUR_HELPER="${ARCH_CFG_AUR_HELPER:-paru}"

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Parses the CLI argument list and sets ARCH_CFG_FLAG_* globals.
#              Exits with code 2 on unknown flags or missing required values.
# @arg1 string... "$@" All arguments passed to install.sh
# @exit 0 on success, 2 on bad arguments
args::parse() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -h|--help)
                ARCH_CFG_FLAG_HELP="true"
                ;;
            --version)
                ARCH_CFG_FLAG_VERSION="true"
                ;;
            -d|--dry-run)
                ARCH_CFG_DRY_RUN="true"
                ;;
            -y|--yes)
                ARCH_CFG_FLAG_YES="true"
                ;;
            --verbose)
                ARCH_CFG_FLAG_VERBOSE="true"
                # Activate debug logging in the logger
                DEBUG="1"
                export DEBUG
                ;;
            --list-modules)
                ARCH_CFG_FLAG_LIST_MODULES="true"
                ;;
            --module)
                shift
                if [[ $# -eq 0 || -z "${1:-}" ]]; then
                    log::error "--module requires a module name as its argument." "ARGS"
                    args::print_usage >&2
                    exit 2
                fi
                ARCH_CFG_FLAG_MODULE="${1}"
                ;;
            --verify)
                ARCH_CFG_FLAG_VERIFY="true"
                ;;
            --aur-helper)
                shift
                if [[ $# -eq 0 || -z "${1:-}" ]]; then
                    log::error "--aur-helper requires a helper name (paru or yay)" "ARGS"
                    args::print_usage >&2
                    exit 2
                fi
                case "${1}" in
                    paru|yay) ARCH_CFG_AUR_HELPER="${1}" ;;
                    *)
                        log::error "Unsupported AUR helper '${1}' — must be paru or yay" "ARGS"
                        exit 2
                        ;;
                esac
                ;;
            -*)
                log::error "Unknown option: '${1}'" "ARGS"
                args::print_usage >&2
                exit 2
                ;;
            *)
                log::error "Unexpected argument: '${1}'" "ARGS"
                args::print_usage >&2
                exit 2
                ;;
        esac
        shift
    done

    export ARCH_CFG_FLAG_HELP ARCH_CFG_FLAG_VERSION ARCH_CFG_DRY_RUN
    export ARCH_CFG_FLAG_YES ARCH_CFG_FLAG_VERBOSE
    export ARCH_CFG_FLAG_LIST_MODULES ARCH_CFG_FLAG_MODULE ARCH_CFG_FLAG_VERIFY
    export ARCH_CFG_AUR_HELPER
    return 0
}

# @description Prints a one-line synopsis and the list of supported flags.
# @noargs
# @stdout Usage text
# @exit 0 Always
args::print_usage() {
    cat <<'EOF'
Usage: install.sh [OPTIONS]

Options:
  -h, --help            Show this help message and exit
      --version         Print the framework version and exit
  -d, --dry-run         Simulate installation without making system changes
  -y, --yes             Skip all confirmation prompts (non-interactive)
      --verbose         Enable verbose/debug output
      --list-modules    List all available modules with descriptions, then exit
      --module <name>   Install (or verify) only the named module
      --verify          Run post-install verification checks only, then exit
      --aur-helper <n>  AUR helper to use: paru (default) or yay

Examples:
  ./install.sh --help
  ./install.sh --version
  ./install.sh --dry-run
  ./install.sh --dry-run --yes
  ./install.sh --list-modules
  ./install.sh --module git
  ./install.sh --module hyprland --dry-run
  ./install.sh --verify
EOF
}

# @description Prints the full help banner including the framework version.
# @noargs
# @stdout Version line followed by usage text
# @exit 0 Always
args::print_help() {
    if declare -f colors::supports_color &>/dev/null && colors::supports_color; then
        printf "%sForge%s  v%s\n" \
            "${BOLD_WHITE:-}" "${RESET:-}" "${VERSION:-0.0.0}"
    else
        printf "Forge  v%s\n" "${VERSION:-0.0.0}"
    fi
    echo ""
    args::print_usage
}
