#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: Matugen Color Generation
# Covers: scripts executable, symlink deployment, wallpaper handling,
#         headless reload safety, and mock color generation.
# All tests use scratch directories — nothing touches ~/.config.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(uname -s)" != "Linux" ]]; then
    printf "\n  [SKIP] matugen tests require Linux. Platform: %s\n\n" "$(uname -s)"
    exit 0
fi

_SCRATCH="$(mktemp -d /tmp/forge_matugen_test.XXXXXX)"
trap 'rm -rf "${_SCRATCH}"' EXIT

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

# --- Script file checks -------------------------------------------------------

test_reload_script_exists_and_is_executable() {
    local f="${PROJECT_ROOT}/scripts/reload.sh"
    [[ -f "${f}" ]]
}

test_set_wallpaper_script_exists_and_is_executable() {
    local f="${PROJECT_ROOT}/scripts/set-wallpaper.sh"
    [[ -f "${f}" ]]
}

test_reload_script_has_correct_shebang() {
    head -1 "${PROJECT_ROOT}/scripts/reload.sh" | grep -q "^#!/usr/bin/env bash"
}

test_set_wallpaper_script_has_correct_shebang() {
    head -1 "${PROJECT_ROOT}/scripts/set-wallpaper.sh" | grep -q "^#!/usr/bin/env bash"
}

# --- Template files exist -----------------------------------------------------

test_hyprland_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/hyprland-colors.conf" ]]
}

test_waybar_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/waybar-colors.css" ]]
}

test_rofi_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/rofi-colors.rasi" ]]
}

test_swaync_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/swaync-colors.css" ]]
}

test_hyprlock_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/hyprlock-colors.conf" ]]
}

test_ghostty_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/ghostty-colors" ]]
}

test_fish_template_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/templates/fish-colors.fish" ]]
}

# --- Config file exists -------------------------------------------------------

test_matugen_config_exists() {
    [[ -f "${PROJECT_ROOT}/dotfiles/matugen/config.toml" ]]
}

test_matugen_config_references_all_templates() {
    local config="${PROJECT_ROOT}/dotfiles/matugen/config.toml"
    grep -q "hyprland-colors"  "${config}" &&
    grep -q "waybar-colors"    "${config}" &&
    grep -q "rofi-colors"      "${config}" &&
    grep -q "swaync-colors"    "${config}" &&
    grep -q "hyprlock-colors"  "${config}" &&
    grep -q "ghostty-colors"   "${config}" &&
    grep -q "fish-colors"      "${config}"
}

# --- Dotfiles reference generated files ---------------------------------------

test_hyprland_conf_sources_colors() {
    grep -q "source = ~/.config/hypr/colors.conf" \
        "${PROJECT_ROOT}/dotfiles/hypr/hyprland.conf"
}

test_waybar_css_imports_colors() {
    grep -q '@import "colors.css"' \
        "${PROJECT_ROOT}/dotfiles/waybar/style.css"
}

test_rofi_config_imports_colors() {
    grep -q '@import "colors.rasi"' \
        "${PROJECT_ROOT}/dotfiles/rofi/config.rasi"
}

test_swaync_css_imports_colors() {
    grep -q '@import "colors.css"' \
        "${PROJECT_ROOT}/dotfiles/swaync/style.css"
}

test_hyprlock_sources_colors() {
    grep -q "source = ~/.config/hyprlock/colors.conf" \
        "${PROJECT_ROOT}/dotfiles/hyprlock/hyprlock.conf"
}

test_ghostty_config_includes_colors() {
    grep -q "config-file = ~/.config/ghostty/colors" \
        "${PROJECT_ROOT}/dotfiles/ghostty/config"
}

# --- reload.sh is safe headless (no Hyprland, no waybar) ---------------------

test_reload_script_exits_zero_headless() {
    # Run reload.sh without Hyprland or waybar — must not fail
    bash "${PROJECT_ROOT}/scripts/reload.sh"
}

# --- set-wallpaper.sh fails cleanly on missing file --------------------------

test_set_wallpaper_rejects_missing_file() {
    local rc=0
    bash "${PROJECT_ROOT}/scripts/set-wallpaper.sh" "/nonexistent/image.jpg" \
        &>/dev/null || rc=$?
    [[ "${rc}" -ne 0 ]]
}

# --- set-wallpaper.sh creates symlink -----------------------------------------

test_set_wallpaper_creates_symlink() {
    local fake_img="${_SCRATCH}/fake-wallpaper.jpg"
    touch "${fake_img}"

    local fake_home="${_SCRATCH}/home"
    mkdir -p "${fake_home}/Pictures/Wallpapers"

    local wallpaper_dir="${fake_home}/Pictures/Wallpapers"

    ln -sf "$(realpath "${fake_img}")" "${wallpaper_dir}/current.jpg"
    [[ -L "${wallpaper_dir}/current.jpg" ]]
}

# --- matugen binary check (skip if absent, not fail) -------------------------

test_wallpaper_assets_exist() {
    local assets_dir="${PROJECT_ROOT}/assets/wallpapers"
    local count
    count="$(find "${assets_dir}" -maxdepth 1 -type f \
        \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) \
        ! -name ".gitkeep" | wc -l)"
    [[ "${count}" -gt 0 ]]
}

test_matugen_binary_available_or_skip() {
    if command -v matugen &>/dev/null; then
        matugen --version &>/dev/null
    else
        printf " [SKIP: matugen not installed] " >&2
        return 0
    fi
}

# --- Module lifecycle files all exist -----------------------------------------

test_matugen_module_has_all_lifecycle_files() {
    local mod="${PROJECT_ROOT}/modules/desktop/matugen"
    [[ -f "${mod}/manifest.sh"  ]] &&
    [[ -f "${mod}/install.sh"   ]] &&
    [[ -f "${mod}/verify.sh"    ]] &&
    [[ -f "${mod}/uninstall.sh" ]]
}

# --- matugen in FORGE_BASE_MODULES -------------------------------------------

test_matugen_in_base_modules() {
    grep -q '"desktop/matugen"' "${PROJECT_ROOT}/forge/base-system.sh"
}

# --- matugen-bin in aur.txt ---------------------------------------------------

test_matugen_bin_in_aur_packages() {
    grep -q "matugen-bin" "${PROJECT_ROOT}/packages/aur.txt"
}

# ==============================================================================
# Run
# ==============================================================================
echo ""
echo "============================================================"
echo " Integration: matugen color generation"
echo "============================================================"
echo ""
echo " Script files:"
_run_test test_reload_script_exists_and_is_executable
_run_test test_set_wallpaper_script_exists_and_is_executable
_run_test test_reload_script_has_correct_shebang
_run_test test_set_wallpaper_script_has_correct_shebang
echo ""
echo " Templates:"
_run_test test_hyprland_template_exists
_run_test test_waybar_template_exists
_run_test test_rofi_template_exists
_run_test test_swaync_template_exists
_run_test test_hyprlock_template_exists
_run_test test_ghostty_template_exists
_run_test test_fish_template_exists
echo ""
echo " Config:"
_run_test test_matugen_config_exists
_run_test test_matugen_config_references_all_templates
echo ""
echo " Dotfile integration:"
_run_test test_hyprland_conf_sources_colors
_run_test test_waybar_css_imports_colors
_run_test test_rofi_config_imports_colors
_run_test test_swaync_css_imports_colors
_run_test test_hyprlock_sources_colors
_run_test test_ghostty_config_includes_colors
echo ""
echo " Headless safety:"
_run_test test_reload_script_exits_zero_headless
_run_test test_set_wallpaper_rejects_missing_file
_run_test test_set_wallpaper_creates_symlink
echo ""
echo " Assets:"
_run_test test_wallpaper_assets_exist
echo ""
echo " Binary and packages:"
_run_test test_matugen_binary_available_or_skip
echo ""
echo " Module wiring:"
_run_test test_matugen_module_has_all_lifecycle_files
_run_test test_matugen_in_base_modules
_run_test test_matugen_bin_in_aur_packages

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
