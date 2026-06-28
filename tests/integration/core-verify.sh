#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: core module — verify
# Tests core::verify in isolation: passes after a clean install, fails when
# runtime is missing or corrupted.
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

test_verify_passes_after_install() {
    _reset
    core::install >/dev/null 2>&1
    core::verify >/dev/null 2>&1
}

test_verify_fails_without_install() {
    _reset
    # Nothing installed — verify should fail
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

test_verify_fails_when_install_json_missing() {
    _reset
    core::install >/dev/null 2>&1
    rm -f "${STATE_INSTALL_JSON}"
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

test_verify_fails_when_modules_json_missing() {
    _reset
    core::install >/dev/null 2>&1
    rm -f "${STATE_MODULES_JSON}"
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

test_verify_fails_when_history_json_missing() {
    _reset
    core::install >/dev/null 2>&1
    rm -f "${STATE_HISTORY_JSON}"
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

test_verify_fails_when_install_json_invalid() {
    _reset
    core::install >/dev/null 2>&1
    printf 'not json' > "${STATE_INSTALL_JSON}"
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

test_verify_fails_when_runtime_dir_missing() {
    _reset
    core::install >/dev/null 2>&1
    rm -rf "${RUNTIME_DIR}"
    mkdir -p "${TEST_RUNTIME_DIR}"  # keep temp root so cleanup works
    core::verify >/dev/null 2>&1 && return 1 || return 0
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: core-verify.sh"
echo "============================================================"

_run_test test_verify_passes_after_install
_run_test test_verify_fails_without_install
_run_test test_verify_fails_when_install_json_missing
_run_test test_verify_fails_when_modules_json_missing
_run_test test_verify_fails_when_history_json_missing
_run_test test_verify_fails_when_install_json_invalid
_run_test test_verify_fails_when_runtime_dir_missing

echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
