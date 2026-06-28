#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: core module — uninstall
# Verifies that core::uninstall removes the runtime state correctly while
# preserving backups, and that reinstall works after uninstall.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs
_override_runtime_vars

export MODULE_VERSION="1.0.0"
source "${PROJECT_ROOT}/modules/core/manifest.sh"
source "${PROJECT_ROOT}/modules/core/install.sh"
source "${PROJECT_ROOT}/modules/core/verify.sh"
source "${PROJECT_ROOT}/modules/core/uninstall.sh"

_PASS=0
_FAIL=0

_run_test() {
    local name="${1}"
    printf "  %-55s " "${name}"
    if ( "${name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
        _PASS=$(( _PASS + 1 ))
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

_reset() {
    rm -rf "${TEST_RUNTIME_DIR}"
    mkdir -p "${TEST_RUNTIME_DIR}"
    _override_runtime_vars
}

# ---- Tests ----

test_uninstall_removes_state_dir() {
    _reset
    core::install >/dev/null 2>&1
    core::uninstall >/dev/null 2>&1
    [[ ! -d "${RUNTIME_STATE_DIR}" ]]
}

test_uninstall_removes_cache_dir() {
    _reset
    core::install >/dev/null 2>&1
    core::uninstall >/dev/null 2>&1
    [[ ! -d "${RUNTIME_CACHE_DIR}" ]]
}

test_uninstall_removes_metadata_files() {
    _reset
    core::install >/dev/null 2>&1
    core::uninstall >/dev/null 2>&1
    [[ ! -f "${STATE_INSTALL_JSON}" ]] \
        && [[ ! -f "${STATE_MODULES_JSON}" ]] \
        && [[ ! -f "${STATE_HISTORY_JSON}" ]]
}

test_uninstall_preserves_backups_dir() {
    _reset
    core::install >/dev/null 2>&1
    # Simulate a backup file
    mkdir -p "${RUNTIME_BACKUPS_DIR}"
    printf "backup content" > "${RUNTIME_BACKUPS_DIR}/test.bak"
    core::uninstall >/dev/null 2>&1
    [[ -f "${RUNTIME_BACKUPS_DIR}/test.bak" ]]
}

test_uninstall_is_safe_without_install() {
    _reset
    # Should not fail when runtime doesn't exist
    core::uninstall >/dev/null 2>&1
}

test_reinstall_works_after_uninstall() {
    _reset
    core::install >/dev/null 2>&1
    core::uninstall >/dev/null 2>&1
    core::install >/dev/null 2>&1
    state::is_module_installed "core"
}

test_verify_passes_after_reinstall() {
    _reset
    core::install >/dev/null 2>&1
    core::uninstall >/dev/null 2>&1
    core::install >/dev/null 2>&1
    core::verify >/dev/null 2>&1
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: core-uninstall.sh"
echo "============================================================"

_run_test test_uninstall_removes_state_dir
_run_test test_uninstall_removes_cache_dir
_run_test test_uninstall_removes_metadata_files
_run_test test_uninstall_preserves_backups_dir
_run_test test_uninstall_is_safe_without_install
_run_test test_reinstall_works_after_uninstall
_run_test test_verify_passes_after_reinstall

echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
