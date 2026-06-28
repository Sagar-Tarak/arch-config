#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_STATE_SH_INCLUDED:-}" ]]; then return 0; fi
_STATE_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - State Management Library
# File: lib/state.sh
# Purpose: Manages persistent framework state via JSON metadata files under
#          RUNTIME_DIR. Uses jq when available; falls back to python3, then
#          pure bash for environments where jq is not yet installed.
# Dependencies: lib/logger.sh
# Public API:
#   state::exists           - True if runtime is initialized
#   state::read             - Read a top-level key from a JSON file
#   state::write            - Update a top-level string key in a JSON file
#   state::validate_json    - True if a file contains valid JSON
#   state::init_install_json  - Create install.json (skip if exists)
#   state::init_modules_json  - Create modules.json (skip if exists)
#   state::init_history_json  - Create history.json (skip if exists)
#   state::append_history   - Append an entry to history.json
#   state::register_module  - Register a module as installed in modules.json
#   state::is_module_installed - True if a module is registered
#   state::lock_acquire     - Acquire the exclusive installer lock
#   state::lock_release     - Release the installer lock (only if we own it)
#   state::lock_is_held     - True if the lock file exists
# ==============================================================================

# ------------------------------------------------------------------------------
# Internal: JSON tool selection
# ------------------------------------------------------------------------------

# Echoes the best available JSON tool: "jq", "python3", or "bash".
# Caches the result in _STATE_JSON_TOOL_CACHE to avoid repeated detection.
# python3 is validated by actually running a trivial program — on some systems
# (e.g. Windows) the python3 binary is a stub that exits non-zero when called
# with arguments, even though `command -v python3` succeeds.
_state::json_tool() {
    if [[ -n "${_STATE_JSON_TOOL_CACHE:-}" ]]; then
        echo "${_STATE_JSON_TOOL_CACHE}"
        return 0
    fi

    local tool
    if command -v jq &>/dev/null; then
        tool="jq"
    elif command -v python3 &>/dev/null && python3 -c "import sys" >/dev/null 2>&1; then
        tool="python3"
    else
        tool="bash"
    fi

    _STATE_JSON_TOOL_CACHE="${tool}"
    export _STATE_JSON_TOOL_CACHE
    echo "${tool}"
}

# ------------------------------------------------------------------------------
# Public: Existence and validation
# ------------------------------------------------------------------------------

# True if the runtime directory has been initialized (install.json present)
state::exists() {
    [[ -d "${RUNTIME_DIR:-}" && -f "${STATE_INSTALL_JSON:-}" ]]
}

# Checks if a file contains valid JSON
# @arg1 string file  Path to check
# @exit 0 if valid, 1 otherwise
state::validate_json() {
    local file="${1}"
    [[ -f "${file}" ]] || return 1

    case "$(_state::json_tool)" in
        jq)      jq empty "${file}" 2>/dev/null ;;
        python3) python3 -c "import json,sys; json.load(open(sys.argv[1]))" "${file}" 2>/dev/null ;;
        bash)
            local first_char
            first_char="$(head -c1 "${file}" 2>/dev/null || echo "")"
            [[ "${first_char}" == "{" || "${first_char}" == "[" ]]
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Public: Key-value read/write against JSON objects
# ------------------------------------------------------------------------------

# Read a top-level string key from a JSON object file
# @arg1 string file  Path to JSON file
# @arg2 string key   Top-level key name
# @stdout The value, or empty string if missing
state::read() {
    local file="${1}"
    local key="${2}"

    if [[ ! -f "${file}" ]]; then
        log::error "state::read: file not found: ${file}" "STATE"
        return 1
    fi

    case "$(_state::json_tool)" in
        jq)
            jq -r --arg k "${key}" '.[$k] // empty' "${file}" 2>/dev/null
            ;;
        python3)
            python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
val = data.get(sys.argv[2], '')
print(val if val is not None else '')
" "${file}" "${key}" 2>/dev/null
            ;;
        bash)
            grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "${file}" 2>/dev/null \
                | sed "s/\"${key}\"[[:space:]]*:[[:space:]]*\"//;s/\"$//" \
                | head -1 \
                || true
            ;;
    esac
}

# Update a top-level string key in a JSON object file
# @arg1 string file   Path to JSON file
# @arg2 string key    Top-level key name
# @arg3 string value  New string value
state::write() {
    local file="${1}"
    local key="${2}"
    local value="${3}"

    if [[ ! -f "${file}" ]]; then
        log::error "state::write: file not found: ${file}" "STATE"
        return 1
    fi

    local tmp
    tmp="$(mktemp)"

    case "$(_state::json_tool)" in
        jq)
            jq --arg k "${key}" --arg v "${value}" '.[$k] = $v' "${file}" > "${tmp}" \
                && mv "${tmp}" "${file}"
            ;;
        python3)
            python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data[sys.argv[2]] = sys.argv[3]
print(json.dumps(data, indent=2))
" "${file}" "${key}" "${value}" > "${tmp}" && mv "${tmp}" "${file}"
            ;;
        bash)
            # Remove old key line if present, insert updated value before closing }
            grep -v "\"${key}\"[[:space:]]*:" "${file}" \
                | sed "s/}[[:space:]]*$/,\"${key}\": \"${value}\"}/" \
                > "${tmp}" && mv "${tmp}" "${file}"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Public: Metadata file initialization
# ------------------------------------------------------------------------------

# Create install.json with current system metadata (skip if already exists)
state::init_install_json() {
    local file="${STATE_INSTALL_JSON}"

    if [[ -f "${file}" ]]; then
        log::debug "install.json already exists, skipping creation" "STATE"
        return 0
    fi

    log::info "Creating install.json" "STATE"

    local hostname distribution
    hostname="$(hostname 2>/dev/null || echo "unknown")"
    distribution="unknown"
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        distribution="$(. /etc/os-release 2>/dev/null && echo "${ID:-unknown}")"
    fi

    cat > "${file}" <<EOF
{
  "version": "${VERSION:-0.1.0}",
  "installed_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "arch": "${ENV_CPU_ARCH:-unknown}",
  "hostname": "${hostname}",
  "username": "${USER:-unknown}",
  "shell": "${ENV_SHELL:-unknown}",
  "distribution": "${distribution}",
  "installer_version": "${VERSION:-0.1.0}"
}
EOF
}

# Create modules.json as an empty JSON object (skip if already exists)
state::init_modules_json() {
    local file="${STATE_MODULES_JSON}"

    if [[ -f "${file}" ]]; then
        log::debug "modules.json already exists, skipping creation" "STATE"
        return 0
    fi

    log::info "Creating modules.json" "STATE"
    printf '{}\n' > "${file}"
}

# Create history.json as an empty JSON array (skip if already exists)
state::init_history_json() {
    local file="${STATE_HISTORY_JSON}"

    if [[ -f "${file}" ]]; then
        log::debug "history.json already exists, skipping creation" "STATE"
        return 0
    fi

    log::info "Creating history.json" "STATE"
    printf '[]\n' > "${file}"
}

# ------------------------------------------------------------------------------
# Public: History management
# ------------------------------------------------------------------------------

# Append an entry to history.json
# @arg1 string command  The command that was run (e.g. "install.sh --module core")
# @arg2 string status   "success" or "failure"
state::append_history() {
    local command="${1:-unknown}"
    local status="${2:-unknown}"
    local timestamp
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    local file="${STATE_HISTORY_JSON}"

    if [[ ! -f "${file}" ]]; then
        log::error "state::append_history: history file not found: ${file}" "STATE"
        return 1
    fi

    local tmp
    tmp="$(mktemp)"

    case "$(_state::json_tool)" in
        jq)
            jq \
                --arg time "${timestamp}" \
                --arg cmd "${command}" \
                --arg status "${status}" \
                '. += [{"time": $time, "command": $cmd, "status": $status}]' \
                "${file}" > "${tmp}" && mv "${tmp}" "${file}"
            ;;
        python3)
            python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data.append({'time': sys.argv[2], 'command': sys.argv[3], 'status': sys.argv[4]})
print(json.dumps(data, indent=2))
" "${file}" "${timestamp}" "${command}" "${status}" > "${tmp}" && mv "${tmp}" "${file}"
            ;;
        bash)
            local entry
            entry="  {\"time\": \"${timestamp}\", \"command\": \"${command}\", \"status\": \"${status}\"}"
            local content
            content="$(cat "${file}")"
            if [[ "${content}" =~ ^\[\] ]]; then
                printf '[\n%s\n]\n' "${entry}" > "${file}"
            else
                # Strip trailing ], append new entry, close array
                head -n -1 "${file}" > "${tmp}"
                printf ',\n%s\n]\n' "${entry}" >> "${tmp}"
                mv "${tmp}" "${file}"
            fi
            rm -f "${tmp}"
            ;;
    esac

    log::debug "History updated: ${command} [${status}]" "STATE"
}

# ------------------------------------------------------------------------------
# Public: Module registration
# ------------------------------------------------------------------------------

# Register a module as installed in modules.json
# @arg1 string name     Module name
# @arg2 string version  Module version (defaults to "1.0.0")
state::register_module() {
    local name="${1}"
    local version="${2:-1.0.0}"
    local timestamp
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    local file="${STATE_MODULES_JSON}"

    if [[ ! -f "${file}" ]]; then
        log::error "state::register_module: modules file not found: ${file}" "STATE"
        return 1
    fi

    log::info "Registering module: ${name} v${version}" "STATE"

    local tmp
    tmp="$(mktemp)"

    case "$(_state::json_tool)" in
        jq)
            jq \
                --arg name "${name}" \
                --arg version "${version}" \
                --arg ts "${timestamp}" \
                '.[$name] = {"installed": true, "version": $version, "installed_at": $ts}' \
                "${file}" > "${tmp}" && mv "${tmp}" "${file}"
            ;;
        python3)
            python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data[sys.argv[2]] = {'installed': True, 'version': sys.argv[3], 'installed_at': sys.argv[4]}
print(json.dumps(data, indent=2))
" "${file}" "${name}" "${version}" "${timestamp}" > "${tmp}" && mv "${tmp}" "${file}"
            ;;
        bash)
            rm -f "${tmp}"
            _state::bash_register_module "${name}" "${version}" "${timestamp}"
            ;;
    esac
}

# Bash fallback for state::register_module: uses a side-channel flat file store
# under RUNTIME_STATE_DIR/modules/ and rebuilds modules.json from it.
_state::bash_register_module() {
    local name="${1}" version="${2}" timestamp="${3}"
    local state_modules_dir="${RUNTIME_STATE_DIR}/modules"

    mkdir -p "${state_modules_dir}"

    # Persist this module's state as a simple key=value file
    printf 'name=%s\nversion=%s\ninstalled=true\ninstalled_at=%s\n' \
        "${name}" "${version}" "${timestamp}" > "${state_modules_dir}/${name}"

    # Rebuild modules.json from all stored module state files
    local file="${STATE_MODULES_JSON}"
    printf '{\n' > "${file}"
    local first=true
    local mod_file
    for mod_file in "${state_modules_dir}/"*; do
        [[ -f "${mod_file}" ]] || continue
        local m_name m_version m_ts
        m_name="$(grep '^name=' "${mod_file}" | cut -d= -f2)"
        m_version="$(grep '^version=' "${mod_file}" | cut -d= -f2)"
        m_ts="$(grep '^installed_at=' "${mod_file}" | cut -d= -f2)"

        if [[ "${first}" == "true" ]]; then
            first=false
        else
            printf ',\n' >> "${file}"
        fi
        printf '  "%s": {"installed": true, "version": "%s", "installed_at": "%s"}' \
            "${m_name}" "${m_version}" "${m_ts}" >> "${file}"
    done
    printf '\n}\n' >> "${file}"
}

# True if a module is registered as installed
# @arg1 string name  Module name
# @exit 0 if installed, 1 otherwise
state::is_module_installed() {
    local name="${1}"
    local file="${STATE_MODULES_JSON}"

    if [[ ! -f "${file}" ]]; then
        return 1
    fi

    case "$(_state::json_tool)" in
        jq)
            local result
            result="$(jq -r --arg name "${name}" '.[$name].installed // false' "${file}" 2>/dev/null)"
            [[ "${result}" == "true" ]]
            ;;
        python3)
            python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
entry = data.get(sys.argv[2], {})
sys.exit(0 if entry.get('installed') else 1)
" "${file}" "${name}" 2>/dev/null
            ;;
        bash)
            # Fallback: check side-channel state dir, then JSON
            [[ -f "${RUNTIME_STATE_DIR}/modules/${name}" ]] \
                || grep -q "\"${name}\"" "${file}" 2>/dev/null
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Public: Locking
# ------------------------------------------------------------------------------

# Acquire the exclusive installer lock.
# Detects and clears stale locks (process no longer running).
# @exit 0 on success, 1 if locked by another live process
state::lock_acquire() {
    local lock_file="${STATE_LOCK_FILE}"
    local lock_dir
    lock_dir="$(dirname "${lock_file}")"

    mkdir -p "${lock_dir}"

    if [[ -f "${lock_file}" ]]; then
        local lock_pid
        lock_pid="$(cat "${lock_file}" 2>/dev/null || echo "")"
        if [[ -n "${lock_pid}" ]] && kill -0 "${lock_pid}" 2>/dev/null; then
            log::error "Another installer instance is running (PID ${lock_pid})." "LOCK"
            log::error "Remove the lock if no installer is running: ${lock_file}" "LOCK"
            return 1
        fi
        log::warn "Removing stale lock (PID ${lock_pid:-unknown} no longer running)." "LOCK"
        rm -f "${lock_file}"
    fi

    printf "%d" "$$" > "${lock_file}"
    log::debug "Lock acquired (PID $$): ${lock_file}" "LOCK"
    return 0
}

# Release the installer lock — only if owned by the current process.
state::lock_release() {
    local lock_file="${STATE_LOCK_FILE}"

    [[ -f "${lock_file}" ]] || return 0

    local lock_pid
    lock_pid="$(cat "${lock_file}" 2>/dev/null || echo "")"

    if [[ "${lock_pid}" == "$$" ]]; then
        rm -f "${lock_file}"
        log::debug "Lock released (PID $$)" "LOCK"
    else
        log::warn "Lock owned by PID ${lock_pid}, not ours ($$); skipping release." "LOCK"
    fi
}

# True if the lock file exists (regardless of owner)
# @exit 0 if locked, 1 if not
state::lock_is_held() {
    [[ -f "${STATE_LOCK_FILE}" ]]
}
