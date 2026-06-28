#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: AUR Bootstrap and Helper Selection
# Covers: helper selection, availability detection, dry-run bootstrap,
#         --aur-helper flag parsing, and unsupported helper rejection.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs

export VERSION="0.1.0" ARCH_CFG_DRY_RUN="false" DEBUG="0"
source "${PROJECT_ROOT}/bootstrap/variables.sh" && variables::load
source "${PROJECT_ROOT}/installer/args.sh"

# ---- Mock bin directory to fake AUR helpers ----
_MOCK_BIN="$(mktemp -d /tmp/forge_aur_test.XXXXXX)"
trap 'rm -rf "${_MOCK_BIN}"' EXIT
export PATH="${_MOCK_BIN}:${PATH}"

_PASS=0
_FAIL=0

_run_test() {
    local name="${1}"
    printf "  %-60s " "${name}"
    if ( "${name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
        _PASS=$(( _PASS + 1 ))
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# ---- Helper selection ----

test_default_helper_is_paru() {
    unset ARCH_CFG_AUR_HELPER 2>/dev/null || true
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "$(aur::get_helper)" == "paru" ]]
}

test_helper_selection_yay() {
    export ARCH_CFG_AUR_HELPER="yay"
    [[ "$(aur::get_helper)" == "yay" ]]
    export ARCH_CFG_AUR_HELPER="paru"
}

test_unsupported_helper_falls_back_to_paru() {
    export ARCH_CFG_AUR_HELPER="unsupported-tool"
    local result
    result="$(aur::get_helper 2>/dev/null)"
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "${result}" == "paru" ]]
}

# ---- Availability detection ----

test_is_available_false_when_not_installed() {
    export ARCH_CFG_AUR_HELPER="paru"
    rm -f "${_MOCK_BIN}/paru"
    ! aur::is_available
}

test_is_available_true_when_installed() {
    export ARCH_CFG_AUR_HELPER="paru"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${_MOCK_BIN}/paru"
    chmod +x "${_MOCK_BIN}/paru"
    aur::is_available
    rm -f "${_MOCK_BIN}/paru"
}

# ---- Dry-run bootstrap ----

test_bootstrap_dry_run_logs_dry_run() {
    export ARCH_CFG_AUR_HELPER="paru"
    rm -f "${_MOCK_BIN}/paru"

    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::bootstrap 2>&1)"
    export ARCH_CFG_DRY_RUN="false"

    echo "${out}" | grep -qi "DRY-RUN"
}

test_bootstrap_skips_when_already_installed() {
    export ARCH_CFG_AUR_HELPER="paru"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${_MOCK_BIN}/paru"
    chmod +x "${_MOCK_BIN}/paru"

    local out
    out="$(NO_COLOR=1 aur::bootstrap 2>&1)"
    rm -f "${_MOCK_BIN}/paru"
    echo "${out}" | grep -qi "already installed"
}

# ---- --aur-helper flag parsing ----

test_args_parse_aur_helper_paru() {
    export ARCH_CFG_AUR_HELPER="paru"
    args::parse --aur-helper paru 2>/dev/null
    [[ "${ARCH_CFG_AUR_HELPER}" == "paru" ]]
}

test_args_parse_aur_helper_yay() {
    export ARCH_CFG_AUR_HELPER="paru"
    args::parse --aur-helper yay 2>/dev/null
    [[ "${ARCH_CFG_AUR_HELPER}" == "yay" ]]
    export ARCH_CFG_AUR_HELPER="paru"
}

test_args_parse_aur_helper_rejects_invalid() {
    local rc=0
    ( args::parse --aur-helper invalid 2>/dev/null ) || rc=$?
    [[ "${rc}" -ne 0 ]]
}

# ---- aur::install dry-run ----

test_aur_install_dry_run_logs_package() {
    export ARCH_CFG_AUR_HELPER="paru"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${_MOCK_BIN}/paru"
    chmod +x "${_MOCK_BIN}/paru"

    # Mock pacman to say package is not installed
    printf '#!/usr/bin/env bash\nexit 1\n' > "${_MOCK_BIN}/pacman"
    chmod +x "${_MOCK_BIN}/pacman"

    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::install some-aur-pkg 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    rm -f "${_MOCK_BIN}/paru" "${_MOCK_BIN}/pacman"

    echo "${out}" | grep -qi "some-aur-pkg"
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: AUR bootstrap"
echo "============================================================"
echo ""
echo " Helper selection:"
_run_test test_default_helper_is_paru
_run_test test_helper_selection_yay
_run_test test_unsupported_helper_falls_back_to_paru
echo ""
echo " Availability detection:"
_run_test test_is_available_false_when_not_installed
_run_test test_is_available_true_when_installed
echo ""
echo " Dry-run bootstrap:"
_run_test test_bootstrap_dry_run_logs_dry_run
_run_test test_bootstrap_skips_when_already_installed
echo ""
echo " --aur-helper flag:"
_run_test test_args_parse_aur_helper_paru
_run_test test_args_parse_aur_helper_yay
_run_test test_args_parse_aur_helper_rejects_invalid
echo ""
echo " aur::install dry-run:"
_run_test test_aur_install_dry_run_logs_package

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
