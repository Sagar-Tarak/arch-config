#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_SERVICE_SH_INCLUDED:-}" ]]; then return 0; fi
_SERVICE_SH_INCLUDED=1

# ==============================================================================
# Forge — Service Management Library
# File: lib/service.sh
# Purpose: Wraps systemctl for enabling, disabling, starting, stopping, and
#          querying systemd services. Supports both system and user services.
#          All state-changing operations respect ARCH_CFG_DRY_RUN.
# Dependencies: lib/logger.sh
# Public API:
#   service::enable    - Enable a service (and optionally start it now)
#   service::disable   - Disable a service
#   service::start     - Start a service immediately
#   service::stop      - Stop a service immediately
#   service::restart   - Restart a running service
#   service::is_enabled- Returns 0 if the service is enabled
#   service::is_active - Returns 0 if the service is currently running
# Notes:
#   User services (--user flag / scope "user") run under the calling user's
#   systemd instance. System services require sudo.
# ==============================================================================

_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_SERVICE_DIR}/logger.sh" ]]; then
    source "${_SERVICE_DIR}/logger.sh"
else
    echo "Error: logger.sh not found at: ${_SERVICE_DIR}/logger.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# Internal helpers
# ==============================================================================

# @description Builds the systemctl command prefix based on scope.
# @arg1 string scope  "system" (default) or "user"
# @stdout  "sudo systemctl" or "systemctl --user"
_service::ctl() {
    local scope="${1:-system}"
    if [[ "${scope}" == "user" ]]; then
        echo "systemctl --user"
    else
        echo "sudo systemctl"
    fi
}

# @description Checks that systemctl is available on this system.
# @exit 0 if available, 1 otherwise
_service::require_systemctl() {
    if ! command -v systemctl &>/dev/null; then
        log::warn "systemctl not available — service management skipped" "SERVICE"
        return 1
    fi
    return 0
}

# ==============================================================================
# Public API
# ==============================================================================

# @description Enables a service so it starts on boot. Optionally starts it now.
# @arg1 string service  Service unit name (e.g. NetworkManager, pipewire)
# @arg2 string scope    Optional: "system" (default) or "user"
# @arg3 string now      Optional: "now" to also start the service immediately
# @exit 0 on success or dry-run, 1 on failure or missing systemctl
service::enable() {
    local service="${1:-}"
    local scope="${2:-system}"
    local now="${3:-}"

    if [[ -z "${service}" ]]; then
        log::error "service::enable: service name required" "SERVICE"
        return 1
    fi

    _service::require_systemctl || return 0  # non-fatal on systems without systemd

    local ctl
    ctl="$(_service::ctl "${scope}")"

    if service::is_enabled "${service}" "${scope}"; then
        log::info "Already enabled: ${service} (${scope})" "SERVICE"
        # Still start it if requested and not running
        if [[ "${now}" == "now" ]] && ! service::is_active "${service}" "${scope}"; then
            service::start "${service}" "${scope}"
        fi
        return 0
    fi

    log::info "Enabling service: ${service} (${scope})" "SERVICE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would enable: ${service} (${scope})" "SERVICE"
        return 0
    fi

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    if [[ "${now}" == "now" ]]; then
        _cmd+=(enable --now "${service}")
    else
        _cmd+=(enable "${service}")
    fi

    if "${_cmd[@]}"; then
        log::success "Enabled: ${service} (${scope})" "SERVICE"
        return 0
    else
        log::error "Failed to enable: ${service} (${scope})" "SERVICE"
        return 1
    fi
}

# @description Disables a service so it no longer starts on boot.
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 on success or dry-run
service::disable() {
    local service="${1:-}"
    local scope="${2:-system}"

    if [[ -z "${service}" ]]; then
        log::error "service::disable: service name required" "SERVICE"
        return 1
    fi

    _service::require_systemctl || return 0

    local ctl
    ctl="$(_service::ctl "${scope}")"

    if ! service::is_enabled "${service}" "${scope}"; then
        log::info "Already disabled: ${service} (${scope})" "SERVICE"
        return 0
    fi

    log::info "Disabling service: ${service} (${scope})" "SERVICE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would disable: ${service} (${scope})" "SERVICE"
        return 0
    fi

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    _cmd+=(disable "${service}")
    if "${_cmd[@]}"; then
        log::success "Disabled: ${service} (${scope})" "SERVICE"
        return 0
    else
        log::error "Failed to disable: ${service} (${scope})" "SERVICE"
        return 1
    fi
}

# @description Starts a service immediately (does not affect boot state).
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 on success or dry-run
service::start() {
    local service="${1:-}"
    local scope="${2:-system}"

    if [[ -z "${service}" ]]; then
        log::error "service::start: service name required" "SERVICE"
        return 1
    fi

    _service::require_systemctl || return 0

    local ctl
    ctl="$(_service::ctl "${scope}")"

    log::info "Starting service: ${service} (${scope})" "SERVICE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would start: ${service} (${scope})" "SERVICE"
        return 0
    fi

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    _cmd+=(start "${service}")
    if "${_cmd[@]}"; then
        log::success "Started: ${service} (${scope})" "SERVICE"
        return 0
    else
        log::error "Failed to start: ${service} (${scope})" "SERVICE"
        return 1
    fi
}

# @description Stops a running service (does not affect boot state).
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 on success or dry-run
service::stop() {
    local service="${1:-}"
    local scope="${2:-system}"

    if [[ -z "${service}" ]]; then
        log::error "service::stop: service name required" "SERVICE"
        return 1
    fi

    _service::require_systemctl || return 0

    local ctl
    ctl="$(_service::ctl "${scope}")"

    log::info "Stopping service: ${service} (${scope})" "SERVICE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would stop: ${service} (${scope})" "SERVICE"
        return 0
    fi

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    _cmd+=(stop "${service}")
    if "${_cmd[@]}"; then
        log::success "Stopped: ${service} (${scope})" "SERVICE"
        return 0
    else
        log::error "Failed to stop: ${service} (${scope})" "SERVICE"
        return 1
    fi
}

# @description Restarts a service.
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 on success or dry-run
service::restart() {
    local service="${1:-}"
    local scope="${2:-system}"

    if [[ -z "${service}" ]]; then
        log::error "service::restart: service name required" "SERVICE"
        return 1
    fi

    _service::require_systemctl || return 0

    local ctl
    ctl="$(_service::ctl "${scope}")"

    log::info "Restarting service: ${service} (${scope})" "SERVICE"

    if [[ "${ARCH_CFG_DRY_RUN:-false}" == "true" ]]; then
        log::info "[DRY-RUN] Would restart: ${service} (${scope})" "SERVICE"
        return 0
    fi

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    _cmd+=(restart "${service}")
    if "${_cmd[@]}"; then
        log::success "Restarted: ${service} (${scope})" "SERVICE"
        return 0
    else
        log::error "Failed to restart: ${service} (${scope})" "SERVICE"
        return 1
    fi
}

# @description Returns 0 if the service is enabled (starts on boot).
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 if enabled, 1 otherwise
service::is_enabled() {
    local service="${1:-}"
    local scope="${2:-system}"

    _service::require_systemctl || return 1

    local ctl
    ctl="$(_service::ctl "${scope}")"

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    "${_cmd[@]}" is-enabled --quiet "${service}" 2>/dev/null
}

# @description Returns 0 if the service is currently running.
# @arg1 string service  Service unit name
# @arg2 string scope    Optional: "system" (default) or "user"
# @exit 0 if active, 1 otherwise
service::is_active() {
    local service="${1:-}"
    local scope="${2:-system}"

    _service::require_systemctl || return 1

    local ctl
    ctl="$(_service::ctl "${scope}")"

    local -a _cmd
    read -ra _cmd <<< "${ctl}"
    "${_cmd[@]}" is-active --quiet "${service}" 2>/dev/null
}
