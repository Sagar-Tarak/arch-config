#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: AUR Bootstrap and Helper Selection
# Covers: helper selection, availability detection, dry-run bootstrap,
#         --aur-helper flag parsing, unsupported/empty helper rejection,
#         and the nounset regression (declare -A scoping bug).
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
    printf "  %-65s " "${name}"
    if ( "${name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
        _PASS=$(( _PASS + 1 ))
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# ==============================================================================
# Helper selection
# ==============================================================================

test_default_helper_is_paru() {
    # ARCH_CFG_AUR_HELPER unset/empty → should default to paru
    local saved="${ARCH_CFG_AUR_HELPER:-}"
    unset ARCH_CFG_AUR_HELPER
    local result
    result="$(aur::get_helper 2>/dev/null)"
    export ARCH_CFG_AUR_HELPER="${saved:-paru}"
    [[ "${result}" == "paru" ]]
}

test_helper_selection_paru_explicit() {
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "$(aur::get_helper 2>/dev/null)" == "paru" ]]
}

test_helper_selection_yay() {
    export ARCH_CFG_AUR_HELPER="yay"
    local result
    result="$(aur::get_helper 2>/dev/null)"
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "${result}" == "yay" ]]
}

# Regression: previously 'paru: unbound variable' under set -u when
# _AUR_HELPER_URLS was declared with declare -A inside a function scope.
# aur::get_helper must work after loader::load_libs returns.
test_get_helper_survives_nounset_after_loader_returns() {
    export ARCH_CFG_AUR_HELPER="paru"
    # loader::load_libs was already called above — ensure get_helper still works
    local result
    result="$(aur::get_helper 2>/dev/null)"
    [[ "${result}" == "paru" ]]
}

# ==============================================================================
# Validation — invalid / empty helper must fail loudly, never fall back silently
# ==============================================================================

test_unsupported_helper_returns_nonzero() {
    export ARCH_CFG_AUR_HELPER="unsupported-tool"
    local rc=0
    aur::get_helper 2>/dev/null || rc=$?
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "${rc}" -ne 0 ]]
}

test_unsupported_helper_does_not_silently_emit_paru() {
    export ARCH_CFG_AUR_HELPER="invalid-helper"
    local result
    result="$(aur::get_helper 2>/dev/null || true)"
    export ARCH_CFG_AUR_HELPER="paru"
    [[ "${result}" != "paru" ]]
}

test_empty_helper_returns_nonzero() {
    # An explicitly empty ARCH_CFG_AUR_HELPER triggers the empty-name guard
    # (the :-paru default only fires when unset or empty, so empty → paru default)
    # Actually the default covers this; we test the validate path directly.
    local rc=0
    ( _aur::validate_helper "" 2>/dev/null ) || rc=$?
    [[ "${rc}" -ne 0 ]]
}

# ==============================================================================
# Clone URL lookup (_aur::clone_url)
# ==============================================================================

test_clone_url_paru() {
    local url
    url="$(_aur::clone_url paru 2>/dev/null)"
    [[ "${url}" == "https://aur.archlinux.org/paru.git" ]]
}

test_clone_url_yay() {
    local url
    url="$(_aur::clone_url yay 2>/dev/null)"
    [[ "${url}" == "https://aur.archlinux.org/yay.git" ]]
}

test_clone_url_invalid_returns_nonzero() {
    local rc=0
    _aur::clone_url "unknown-helper" 2>/dev/null || rc=$?
    [[ "${rc}" -ne 0 ]]
}

# ==============================================================================
# Availability detection
# ==============================================================================

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

test_is_available_yay_when_yay_on_path() {
    export ARCH_CFG_AUR_HELPER="yay"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${_MOCK_BIN}/yay"
    chmod +x "${_MOCK_BIN}/yay"
    aur::is_available
    rm -f "${_MOCK_BIN}/yay"
    export ARCH_CFG_AUR_HELPER="paru"
}

# ==============================================================================
# Dry-run bootstrap
# ==============================================================================

test_bootstrap_dry_run_paru_logs_dry_run() {
    export ARCH_CFG_AUR_HELPER="paru"
    rm -f "${_MOCK_BIN}/paru"
    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::bootstrap 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    echo "${out}" | grep -qi "DRY-RUN"
}

test_bootstrap_dry_run_paru_mentions_url() {
    export ARCH_CFG_AUR_HELPER="paru"
    rm -f "${_MOCK_BIN}/paru"
    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::bootstrap 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    echo "${out}" | grep -q "paru.git"
}

test_bootstrap_dry_run_yay_logs_dry_run() {
    export ARCH_CFG_AUR_HELPER="yay"
    rm -f "${_MOCK_BIN}/yay"
    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::bootstrap 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    export ARCH_CFG_AUR_HELPER="paru"
    echo "${out}" | grep -qi "DRY-RUN"
}

test_bootstrap_dry_run_does_not_invoke_git() {
    export ARCH_CFG_AUR_HELPER="paru"
    rm -f "${_MOCK_BIN}/paru"
    # Poison git in mock path — if bootstrap calls it, test fails
    printf '#!/usr/bin/env bash\nexit 99\n' > "${_MOCK_BIN}/git"
    chmod +x "${_MOCK_BIN}/git"
    local rc=0
    ( export ARCH_CFG_DRY_RUN=true; aur::bootstrap &>/dev/null ) || rc=$?
    rm -f "${_MOCK_BIN}/git"
    [[ "${rc}" -eq 0 ]]
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

# ==============================================================================
# --aur-helper flag parsing (installer/args.sh)
# ==============================================================================

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

# ==============================================================================
# aur::install dry-run
# ==============================================================================

test_aur_install_dry_run_logs_package() {
    export ARCH_CFG_AUR_HELPER="paru"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${_MOCK_BIN}/paru"
    chmod +x "${_MOCK_BIN}/paru"
    # Mock pacman to report package not installed
    printf '#!/usr/bin/env bash\nexit 1\n' > "${_MOCK_BIN}/pacman"
    chmod +x "${_MOCK_BIN}/pacman"

    local out
    out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 aur::install some-aur-pkg 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    rm -f "${_MOCK_BIN}/paru" "${_MOCK_BIN}/pacman"

    echo "${out}" | grep -qi "some-aur-pkg"
}

test_aur_install_dry_run_does_not_invoke_helper() {
    export ARCH_CFG_AUR_HELPER="paru"
    printf '#!/usr/bin/env bash\nexit 99\n' > "${_MOCK_BIN}/paru"
    chmod +x "${_MOCK_BIN}/paru"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${_MOCK_BIN}/pacman"
    chmod +x "${_MOCK_BIN}/pacman"

    local rc=0
    ( export ARCH_CFG_DRY_RUN=true; aur::install some-aur-pkg &>/dev/null ) || rc=$?
    rm -f "${_MOCK_BIN}/paru" "${_MOCK_BIN}/pacman"
    [[ "${rc}" -eq 0 ]]
}

test_aur_install_empty_list_is_noop() {
    export ARCH_CFG_AUR_HELPER="paru"
    aur::install 2>/dev/null
}

# ==============================================================================
# Run
# ==============================================================================
echo ""
echo "============================================================"
echo " Integration: AUR bootstrap"
echo "============================================================"
echo ""
echo " Helper selection:"
_run_test test_default_helper_is_paru
_run_test test_helper_selection_paru_explicit
_run_test test_helper_selection_yay
_run_test test_get_helper_survives_nounset_after_loader_returns
echo ""
echo " Validation (invalid/empty must fail loudly):"
_run_test test_unsupported_helper_returns_nonzero
_run_test test_unsupported_helper_does_not_silently_emit_paru
_run_test test_empty_helper_returns_nonzero
echo ""
echo " Clone URL lookup:"
_run_test test_clone_url_paru
_run_test test_clone_url_yay
_run_test test_clone_url_invalid_returns_nonzero
echo ""
echo " Availability detection:"
_run_test test_is_available_false_when_not_installed
_run_test test_is_available_true_when_installed
_run_test test_is_available_yay_when_yay_on_path
echo ""
echo " Dry-run bootstrap:"
_run_test test_bootstrap_dry_run_paru_logs_dry_run
_run_test test_bootstrap_dry_run_paru_mentions_url
_run_test test_bootstrap_dry_run_yay_logs_dry_run
_run_test test_bootstrap_dry_run_does_not_invoke_git
_run_test test_bootstrap_skips_when_already_installed
echo ""
echo " --aur-helper flag:"
_run_test test_args_parse_aur_helper_paru
_run_test test_args_parse_aur_helper_yay
_run_test test_args_parse_aur_helper_rejects_invalid
echo ""
echo " aur::install dry-run:"
_run_test test_aur_install_dry_run_logs_package
_run_test test_aur_install_dry_run_does_not_invoke_helper
_run_test test_aur_install_empty_list_is_noop

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
