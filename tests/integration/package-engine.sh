#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: Package Engine
# Covers: manifest parsing, install_list idempotency, dry-run mode,
#         missing_from_manifest, verify_manifest, count_manifest,
#         and service library no-op on non-systemd hosts.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs

export VERSION="0.1.0" ARCH_CFG_DRY_RUN="false" DEBUG="0"
source "${PROJECT_ROOT}/bootstrap/variables.sh" && variables::load

# ---- Mock pacman for is_installed checks ----
# We use a temp directory prepended to PATH so pacman calls hit our stub.
_MOCK_BIN="$(mktemp -d /tmp/forge_pkg_test.XXXXXX)"
trap 'rm -rf "${_MOCK_BIN}"' EXIT

# Mock pacman: only "git" and "neovim" are "installed"
cat > "${_MOCK_BIN}/pacman" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Qq" ]]; then
    case "${2:-}" in
        git|neovim) exit 0 ;;
        *) exit 1 ;;
    esac
fi
exit 0
MOCK
chmod +x "${_MOCK_BIN}/pacman"

export PATH="${_MOCK_BIN}:${PATH}"

# Temp manifest file
_MANIFEST="$(mktemp /tmp/forge_manifest.XXXXXX)"
trap 'rm -rf "${_MOCK_BIN}" "${_MANIFEST}"' EXIT

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

# ---- Manifest parsing ----

test_parse_manifest_strips_comments() {
    printf "# comment\ngit\n# another comment\nneovim\n" > "${_MANIFEST}"
    local out
    out="$(_package::parse_manifest "${_MANIFEST}")"
    local count
    count="$(echo "${out}" | wc -l | tr -d '[:space:]')"
    [[ "${count}" -eq 2 ]]
}

test_parse_manifest_strips_blank_lines() {
    printf "\ngit\n\n\nneovim\n\n" > "${_MANIFEST}"
    local out
    out="$(_package::parse_manifest "${_MANIFEST}")"
    local count
    count="$(echo "${out}" | grep -c '[^[:space:]]' || true)"
    [[ "${count}" -eq 2 ]]
}

test_parse_manifest_strips_inline_comments() {
    printf "git  # version control\nneovim # editor\n" > "${_MANIFEST}"
    local line1 line2
    line1="$(_package::parse_manifest "${_MANIFEST}" | sed -n '1p')"
    line2="$(_package::parse_manifest "${_MANIFEST}" | sed -n '2p')"
    [[ "${line1}" == "git" && "${line2}" == "neovim" ]]
}

test_count_manifest_correct() {
    printf "git\n# skip me\nneovim\nfish\n" > "${_MANIFEST}"
    local count
    count="$(package::count_manifest "${_MANIFEST}")"
    [[ "${count}" -eq 3 ]]
}

test_count_manifest_empty_file() {
    printf "# only comments\n\n" > "${_MANIFEST}"
    local count
    count="$(package::count_manifest "${_MANIFEST}")"
    [[ "${count}" -eq 0 ]]
}

# ---- is_installed (via mock pacman) ----

test_is_installed_returns_true_for_git() {
    package::is_installed "git" "pacman"
}

test_is_installed_returns_false_for_unknown() {
    ! package::is_installed "nonexistent-pkg-xyz" "pacman"
}

# ---- missing_from_manifest ----

test_missing_from_manifest_detects_missing() {
    printf "git\nfish\nneovim\n" > "${_MANIFEST}"
    local missing
    missing="$(package::missing_from_manifest "${_MANIFEST}" "pacman" 2>/dev/null)"
    # fish is not in the mock → should appear in missing list
    echo "${missing}" | grep -qx "fish"
}

test_missing_from_manifest_exits_0_when_all_installed() {
    printf "git\nneovim\n" > "${_MANIFEST}"
    package::missing_from_manifest "${_MANIFEST}" "pacman" 2>/dev/null
}

test_missing_from_manifest_exits_1_when_some_missing() {
    printf "git\nfish\n" > "${_MANIFEST}"
    ! package::missing_from_manifest "${_MANIFEST}" "pacman" 2>/dev/null
}

# ---- verify_manifest ----

test_verify_manifest_passes_when_all_installed() {
    printf "git\nneovim\n" > "${_MANIFEST}"
    package::verify_manifest "${_MANIFEST}" "pacman" 2>/dev/null
}

test_verify_manifest_fails_when_package_missing() {
    printf "git\nnotinstalled-xyz\n" > "${_MANIFEST}"
    ! package::verify_manifest "${_MANIFEST}" "pacman" 2>/dev/null
}

# ---- dry-run ----

test_dry_run_install_does_not_call_pacman() {
    # Create a pacman stub that writes a sentinel file if install is called
    local _sentinel
    _sentinel="$(mktemp /tmp/forge_sentinel.XXXXXX)"
    rm "${_sentinel}"  # remove it; it should NOT appear after dry-run

    cat > "${_MOCK_BIN}/pacman" <<STUB
#!/usr/bin/env bash
if [[ "\${1:-}" == "-Qq" ]]; then exit 1; fi
# Real install path — should not be reached in dry-run
touch "${_sentinel}"
exit 0
STUB
    chmod +x "${_MOCK_BIN}/pacman"

    export ARCH_CFG_DRY_RUN="true"
    package::install "somepackage" "pacman" 2>/dev/null || true
    export ARCH_CFG_DRY_RUN="false"

    # Restore normal mock
    cat > "${_MOCK_BIN}/pacman" <<'MOCK2'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Qq" ]]; then
    case "${2:-}" in
        git|neovim) exit 0 ;;
        *) exit 1 ;;
    esac
fi
exit 0
MOCK2
    chmod +x "${_MOCK_BIN}/pacman"

    [[ ! -f "${_sentinel}" ]]
}

test_dry_run_install_list_skips_real_calls() {
    local _out
    _out="$(export ARCH_CFG_DRY_RUN=true; NO_COLOR=1 package::install_list "pacman" "fish" "bat" 2>&1)"
    export ARCH_CFG_DRY_RUN="false"
    echo "${_out}" | grep -qi "DRY-RUN"
}

# ---- install_list idempotency ----

test_install_list_skips_already_installed() {
    local _out
    _out="$(NO_COLOR=1 package::install_list "pacman" "git" "neovim" 2>&1)"
    # Both are "installed" via mock — should log skip messages, not attempt install
    echo "${_out}" | grep -qi "already installed"
}

# ---- service library (graceful no-op without systemd) ----

test_service_enable_noop_without_systemctl() {
    # systemctl is not available on Windows/this host — should warn and return 0
    export ARCH_CFG_DRY_RUN="false"
    service::enable "NetworkManager" "system" 2>/dev/null
}

test_service_is_enabled_returns_false_without_systemctl() {
    ! service::is_enabled "NetworkManager" "system" 2>/dev/null
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: package engine"
echo "============================================================"
echo ""
echo " Manifest parsing:"
_run_test test_parse_manifest_strips_comments
_run_test test_parse_manifest_strips_blank_lines
_run_test test_parse_manifest_strips_inline_comments
_run_test test_count_manifest_correct
_run_test test_count_manifest_empty_file
echo ""
echo " Package queries:"
_run_test test_is_installed_returns_true_for_git
_run_test test_is_installed_returns_false_for_unknown
echo ""
echo " Missing packages:"
_run_test test_missing_from_manifest_detects_missing
_run_test test_missing_from_manifest_exits_0_when_all_installed
_run_test test_missing_from_manifest_exits_1_when_some_missing
echo ""
echo " Verify manifest:"
_run_test test_verify_manifest_passes_when_all_installed
_run_test test_verify_manifest_fails_when_package_missing
echo ""
echo " Dry-run mode:"
_run_test test_dry_run_install_does_not_call_pacman
_run_test test_dry_run_install_list_skips_real_calls
echo ""
echo " Install idempotency:"
_run_test test_install_list_skips_already_installed
echo ""
echo " Service library:"
_run_test test_service_enable_noop_without_systemctl
_run_test test_service_is_enabled_returns_false_without_systemctl

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
