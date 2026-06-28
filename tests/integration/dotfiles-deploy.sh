#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: Dotfile Deployment
# Covers: deploy, backup, verify_links, remove_links, idempotency,
#         dry-run, and unmanaged-file safety.
# All tests use a scratch directory — nothing touches ~/.config.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs

export VERSION="0.1.0" ARCH_CFG_DRY_RUN="false" DEBUG="0"
source "${PROJECT_ROOT}/bootstrap/variables.sh" && variables::load
source "${PROJECT_ROOT}/installer/dotfiles.sh"

# ---- Platform guard ---------------------------------------------------------
# Symlink creation on Windows (Git Bash) requires Developer Mode or admin
# rights. Skip the whole suite rather than emit false failures.
if [[ "$(uname -s)" != "Linux" ]]; then
    printf "\n  [SKIP] dotfiles-deploy tests require Linux (symlinks). Platform: %s\n\n" "$(uname -s)"
    exit 0
fi

# ---- Scratch directories ----------------------------------------------------
_SCRATCH="$(mktemp -d /tmp/forge_dotfiles_test.XXXXXX)"
_SRC="${_SCRATCH}/src"     # fake dotfiles/ source
_DST="${_SCRATCH}/dst"     # fake ~/.config target
trap 'rm -rf "${_SCRATCH}"' EXIT

# Populate a minimal fake dotfiles source tree
_setup_src() {
    rm -rf "${_SRC}" "${_DST}"
    mkdir -p "${_SRC}/hypr" "${_SRC}/fish/conf.d" "${_SRC}/nvim/lua"
    echo "# hyprland config" > "${_SRC}/hypr/hyprland.conf"
    echo "# fish config"    > "${_SRC}/fish/config.fish"
    echo "# forge env"      > "${_SRC}/fish/conf.d/forge.fish"
    echo "-- nvim init"     > "${_SRC}/nvim/init.lua"
    mkdir -p "${_DST}"
}

# ---- Test runner -------------------------------------------------------------
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
# Tests
# ==============================================================================

# --- Dry-run: must not create any files --------------------------------------

test_deploy_dry_run_does_not_create_files() {
    _setup_src
    export ARCH_CFG_DRY_RUN="true"
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    export ARCH_CFG_DRY_RUN="false"
    # DST should still be empty
    [[ -z "$(ls -A "${_DST}")" ]]
}

test_backup_dry_run_does_not_create_backup() {
    _setup_src
    # Place a regular file that would be backed up
    mkdir -p "${_DST}/hypr"
    printf "user config\n" > "${_DST}/hypr/hyprland.conf"

    export ARCH_CFG_DRY_RUN="true"
    dotfiles::backup_existing "${_SRC}" "${_DST}" &>/dev/null
    export ARCH_CFG_DRY_RUN="false"
    # The original regular file should be untouched (no backup directory created)
    [[ -f "${_DST}/hypr/hyprland.conf" ]]
}

# --- Deploy: symlinks are created --------------------------------------------

test_deploy_creates_symlinks() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null

    [[ -L "${_DST}/hypr/hyprland.conf" ]] &&
    [[ -L "${_DST}/fish/config.fish"   ]] &&
    [[ -L "${_DST}/nvim/init.lua"      ]]
}

test_deploy_symlinks_point_to_source() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null

    local target
    target="$(readlink -f "${_DST}/hypr/hyprland.conf")"
    [[ "${target}" == "$(readlink -f "${_SRC}/hypr/hyprland.conf")" ]]
}

test_deploy_creates_nested_symlinks() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    [[ -L "${_DST}/fish/conf.d/forge.fish" ]]
}

# --- Idempotency -------------------------------------------------------------

test_deploy_is_idempotent() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    # Second deploy must not error
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    # Links must still be correct
    [[ -L "${_DST}/hypr/hyprland.conf" ]]
}

# --- Backup: existing regular files are backed up ---------------------------

test_deploy_backs_up_existing_regular_file() {
    _setup_src
    mkdir -p "${_DST}/hypr"
    printf "original user config\n" > "${_DST}/hypr/hyprland.conf"

    # Override backup dir to scratch so we can inspect it
    local orig_backup_dir="${BACKUP_DIR:-}"
    export BACKUP_DIR="${_SCRATCH}/backups"

    dotfiles::backup_existing "${_SRC}" "${_DST}" &>/dev/null

    # Backup directory should now contain the original file
    local backed_up
    backed_up="$(find "${_SCRATCH}/backups" -name "hyprland.conf" 2>/dev/null | head -1)"

    # Restore
    if [[ -n "${orig_backup_dir}" ]]; then
        export BACKUP_DIR="${orig_backup_dir}"
    else
        unset BACKUP_DIR
    fi

    [[ -n "${backed_up}" && -f "${backed_up}" ]]
}

# --- Verify: links checked after deploy ------------------------------------

test_verify_links_pass_after_deploy() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    dotfiles::verify_links "${_SRC}" "${_DST}" &>/dev/null
}

test_verify_links_fail_on_missing_link() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    rm -f "${_DST}/hypr/hyprland.conf"
    local rc=0
    dotfiles::verify_links "${_SRC}" "${_DST}" &>/dev/null || rc=$?
    [[ "${rc}" -ne 0 ]]
}

test_verify_links_fail_on_wrong_target() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    # Replace managed symlink with one pointing elsewhere
    rm -f "${_DST}/hypr/hyprland.conf"
    ln -s "/etc/hostname" "${_DST}/hypr/hyprland.conf"
    local rc=0
    dotfiles::verify_links "${_SRC}" "${_DST}" &>/dev/null || rc=$?
    [[ "${rc}" -ne 0 ]]
}

# --- remove_links: only managed symlinks removed ----------------------------

test_remove_links_cleans_up_managed_symlinks() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    dotfiles::remove_links "${_SRC}" "${_DST}" &>/dev/null
    # All managed symlinks should be gone
    ! [[ -L "${_DST}/hypr/hyprland.conf" ]] &&
    ! [[ -L "${_DST}/fish/config.fish"   ]]
}

test_remove_links_does_not_touch_unmanaged_files() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    # Place an unmanaged file in the same directory
    printf "user data\n" > "${_DST}/hypr/monitors.conf"
    dotfiles::remove_links "${_SRC}" "${_DST}" &>/dev/null
    # Unmanaged file must survive
    [[ -f "${_DST}/hypr/monitors.conf" ]]
}

test_remove_links_does_not_touch_unmanaged_symlinks() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    # Place an unmanaged symlink pointing elsewhere
    ln -s "/etc/hostname" "${_DST}/hypr/unmanaged.conf"
    dotfiles::remove_links "${_SRC}" "${_DST}" &>/dev/null
    # Unmanaged symlink must survive
    [[ -L "${_DST}/hypr/unmanaged.conf" ]]
    rm -f "${_DST}/hypr/unmanaged.conf"
}

# --- remove_links dry-run ---------------------------------------------------

test_remove_links_dry_run_leaves_symlinks() {
    _setup_src
    dotfiles::deploy "${_SRC}" "${_DST}" &>/dev/null
    export ARCH_CFG_DRY_RUN="true"
    dotfiles::remove_links "${_SRC}" "${_DST}" &>/dev/null
    export ARCH_CFG_DRY_RUN="false"
    # Symlinks must still exist
    [[ -L "${_DST}/hypr/hyprland.conf" ]]
}

# --- Missing source directory is graceful -----------------------------------

test_deploy_missing_source_is_graceful() {
    rm -rf "${_SRC}" "${_DST}"
    mkdir -p "${_DST}"
    local rc=0
    dotfiles::deploy "/nonexistent/dotfiles" "${_DST}" &>/dev/null || rc=$?
    [[ "${rc}" -eq 0 ]]   # warn only, not fatal
}

test_verify_missing_source_is_graceful() {
    rm -rf "${_SRC}" "${_DST}"
    mkdir -p "${_DST}"
    local rc=0
    dotfiles::verify_links "/nonexistent/dotfiles" "${_DST}" &>/dev/null || rc=$?
    [[ "${rc}" -eq 0 ]]   # warn only, not fatal
}

# ==============================================================================
# Run
# ==============================================================================
echo ""
echo "============================================================"
echo " Integration: dotfile deployment"
echo "============================================================"
echo ""
echo " Dry-run safety:"
_run_test test_deploy_dry_run_does_not_create_files
_run_test test_backup_dry_run_does_not_create_backup
_run_test test_remove_links_dry_run_leaves_symlinks
echo ""
echo " Deploy — symlink creation:"
_run_test test_deploy_creates_symlinks
_run_test test_deploy_symlinks_point_to_source
_run_test test_deploy_creates_nested_symlinks
_run_test test_deploy_is_idempotent
echo ""
echo " Backup:"
_run_test test_deploy_backs_up_existing_regular_file
echo ""
echo " Verify links:"
_run_test test_verify_links_pass_after_deploy
_run_test test_verify_links_fail_on_missing_link
_run_test test_verify_links_fail_on_wrong_target
echo ""
echo " remove_links:"
_run_test test_remove_links_cleans_up_managed_symlinks
_run_test test_remove_links_does_not_touch_unmanaged_files
_run_test test_remove_links_does_not_touch_unmanaged_symlinks
echo ""
echo " Graceful degradation:"
_run_test test_deploy_missing_source_is_graceful
_run_test test_verify_missing_source_is_graceful

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
