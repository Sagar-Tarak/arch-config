#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: core module — install
# Runs core::install in an isolated temp RUNTIME_DIR and asserts that all
# expected directories, metadata files, and module registrations are present.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ---- Isolated runtime environment ----
TEST_RUNTIME_DIR="$(mktemp -d)"

_override_runtime_vars() {
    export RUNTIME_DIR="${TEST_RUNTIME_DIR}"
    export RUNTIME_BACKUPS_DIR="${RUNTIME_DIR}/backups"
    export RUNTIME_CACHE_DIR="${RUNTIME_DIR}/cache"
    export RUNTIME_LOGS_DIR="${RUNTIME_DIR}/logs"
    export RUNTIME_RUNTIME_DIR="${RUNTIME_DIR}/runtime"
    export RUNTIME_STATE_DIR="${RUNTIME_DIR}/state"
    export RUNTIME_TRANSACTIONS_DIR="${RUNTIME_DIR}/transactions"
    export STATE_INSTALL_JSON="${RUNTIME_DIR}/install.json"
    export STATE_MODULES_JSON="${RUNTIME_DIR}/modules.json"
    export STATE_HISTORY_JSON="${RUNTIME_DIR}/history.json"
    export STATE_LOCK_FILE="${RUNTIME_DIR}/runtime/lock"
    export VERSION="0.1.0"
    export ARCH_CFG_DRY_RUN="false"
    export ENV_CPU_ARCH="x86_64"
    export ENV_SHELL="bash"
    export USER="${USER:-testuser}"
}

_cleanup() {
    rm -rf "${TEST_RUNTIME_DIR}"
}
trap '_cleanup' EXIT

# ---- Bootstrap (load libraries only, skip full bootstrap::init) ----
source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs

# ---- Apply isolated runtime vars AFTER libs are loaded ----
_override_runtime_vars

# ---- Source module under test ----
export MODULE_VERSION="1.0.0"
source "${PROJECT_ROOT}/modules/core/manifest.sh"
source "${PROJECT_ROOT}/modules/core/install.sh"
source "${PROJECT_ROOT}/modules/core/verify.sh"

# ---- Test harness ----
_PASS=0
_FAIL=0

_run_test() {
    local name="${1}"
    printf "  %-55s " "${name}"

    # Reset runtime dir for each test
    rm -rf "${TEST_RUNTIME_DIR}"
    mkdir -p "${TEST_RUNTIME_DIR}"
    _override_runtime_vars

    if ( "${name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
        _PASS=$(( _PASS + 1 ))
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# ---- Tests ----

test_install_creates_runtime_dir() {
    core::install >/dev/null 2>&1
    [[ -d "${RUNTIME_DIR}" ]]
}

test_install_creates_all_subdirs() {
    core::install >/dev/null 2>&1
    local dir
    for dir in \
        "${RUNTIME_BACKUPS_DIR}" \
        "${RUNTIME_CACHE_DIR}" \
        "${RUNTIME_LOGS_DIR}" \
        "${RUNTIME_RUNTIME_DIR}" \
        "${RUNTIME_STATE_DIR}" \
        "${RUNTIME_TRANSACTIONS_DIR}"
    do
        if [[ ! -d "${dir}" ]]; then
            echo "Missing: ${dir}" >&2
            return 1
        fi
    done
}

test_install_creates_install_json() {
    core::install >/dev/null 2>&1
    [[ -f "${STATE_INSTALL_JSON}" ]]
}

test_install_creates_modules_json() {
    core::install >/dev/null 2>&1
    [[ -f "${STATE_MODULES_JSON}" ]]
}

test_install_creates_history_json() {
    core::install >/dev/null 2>&1
    [[ -f "${STATE_HISTORY_JSON}" ]]
}

test_install_json_is_valid_json() {
    core::install >/dev/null 2>&1
    state::validate_json "${STATE_INSTALL_JSON}"
}

test_modules_json_is_valid_json() {
    core::install >/dev/null 2>&1
    state::validate_json "${STATE_MODULES_JSON}"
}

test_history_json_is_valid_json() {
    core::install >/dev/null 2>&1
    state::validate_json "${STATE_HISTORY_JSON}"
}

test_install_registers_core_module() {
    core::install >/dev/null 2>&1
    state::is_module_installed "core"
}

test_install_is_idempotent() {
    core::install >/dev/null 2>&1
    core::install >/dev/null 2>&1  # second call must not fail
    state::is_module_installed "core"
}

test_install_creates_transaction_record() {
    core::install >/dev/null 2>&1
    # At least one transaction directory should exist
    local count
    count="$(find "${RUNTIME_TRANSACTIONS_DIR}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
    [[ "${count}" -ge 1 ]]
}

test_install_verify_passes_after_install() {
    core::install >/dev/null 2>&1
    core::verify >/dev/null 2>&1
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: core-install.sh"
echo "============================================================"

_run_test test_install_creates_runtime_dir
_run_test test_install_creates_all_subdirs
_run_test test_install_creates_install_json
_run_test test_install_creates_modules_json
_run_test test_install_creates_history_json
_run_test test_install_json_is_valid_json
_run_test test_modules_json_is_valid_json
_run_test test_history_json_is_valid_json
_run_test test_install_registers_core_module
_run_test test_install_is_idempotent
_run_test test_install_creates_transaction_record
_run_test test_install_verify_passes_after_install

echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
