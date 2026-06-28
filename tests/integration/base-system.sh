#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

# ==============================================================================
# Integration Test: base-system definition and module discovery
# Verifies that forge/base-system.sh loads correctly, that module_loader::list
# discovers all expected modules in the hierarchical structure, and that
# module dispatch resolves function names from leaf paths.
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/bootstrap/loader.sh"
loader::load_libs

export VERSION="0.1.0" ARCH_CFG_DRY_RUN="false" DEBUG="0"
source "${PROJECT_ROOT}/bootstrap/variables.sh" && variables::load
source "${PROJECT_ROOT}/installer/module_loader.sh"
source "${PROJECT_ROOT}/forge/base-system.sh"

# Capture module list once (avoids repeated find calls and SIGPIPE issues
# from grep -q exiting early inside a pipefail pipeline)
_ALL_MODULES="$(module_loader::list 2>/dev/null)"

# Returns 0 if the module list contains exactly this module path
_has_module() {
    local needle="${1}"
    local name
    while IFS= read -r name; do
        [[ "${name}" == "${needle}" ]] && return 0
    done <<< "${_ALL_MODULES}"
    return 1
}

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

# ---- Tests: base-system.sh ----

test_base_system_loads() {
    [[ -n "${FORGE_BASE_MODULES[*]+x}" ]]
}

test_base_system_has_core_first() {
    [[ "${FORGE_BASE_MODULES[0]}" == "core" ]]
}

test_base_system_has_dotfiles_last() {
    local last="${FORGE_BASE_MODULES[-1]}"
    [[ "${last}" == "dotfiles" ]]
}

test_base_system_includes_desktop_hyprland() {
    local m
    for m in "${FORGE_BASE_MODULES[@]}"; do
        [[ "${m}" == "desktop/hyprland" ]] && return 0
    done
    return 1
}

test_base_system_includes_terminal_ghostty() {
    local m
    for m in "${FORGE_BASE_MODULES[@]}"; do
        [[ "${m}" == "terminal/ghostty" ]] && return 0
    done
    return 1
}

test_base_system_includes_shell_fish() {
    local m
    for m in "${FORGE_BASE_MODULES[@]}"; do
        [[ "${m}" == "shell/fish" ]] && return 0
    done
    return 1
}

test_base_system_does_not_include_workspace_docker() {
    local m
    for m in "${FORGE_BASE_MODULES[@]}"; do
        [[ "${m}" == "workspace/docker" ]] && return 1
    done
    return 0
}

test_base_system_does_not_include_workspace_node() {
    local m
    for m in "${FORGE_BASE_MODULES[@]}"; do
        [[ "${m}" == "workspace/node" ]] && return 1
    done
    return 0
}

test_base_system_module_count_is_reasonable() {
    local count="${#FORGE_BASE_MODULES[@]}"
    [[ "${count}" -ge 10 ]]
}

# ---- Tests: module discovery ----

test_loader_discovers_flat_core()         { _has_module "core"; }
test_loader_discovers_desktop_hyprland()  { _has_module "desktop/hyprland"; }
test_loader_discovers_terminal_ghostty()  { _has_module "terminal/ghostty"; }
test_loader_discovers_shell_fish()        { _has_module "shell/fish"; }
test_loader_discovers_editor_nvim()       { _has_module "editor/nvim"; }
test_loader_discovers_browser_zen()       { _has_module "browser/zen"; }
test_loader_discovers_workspace_docker()  { _has_module "workspace/docker"; }
test_loader_discovers_dotfiles()          { _has_module "dotfiles"; }

test_loader_does_not_discover_category_dirs() {
    ! _has_module "desktop" \
    && ! _has_module "terminal" \
    && ! _has_module "shell" \
    && ! _has_module "editor" \
    && ! _has_module "browser" \
    && ! _has_module "workspace"
}

# ---- Tests: module_loader::exists ----

test_exists_core() {
    module_loader::exists "core" 2>/dev/null
}

test_exists_desktop_hyprland() {
    module_loader::exists "desktop/hyprland" 2>/dev/null
}

test_exists_rejects_plain_hyprland() {
    # "hyprland" alone is not a valid module path — it's at "desktop/hyprland"
    ! module_loader::exists "hyprland" 2>/dev/null
}

test_exists_rejects_category_dir() {
    ! module_loader::exists "desktop" 2>/dev/null
}

# ---- Tests: function name resolution ----

test_module_leaf_extraction_nested() {
    local name="desktop/hyprland"
    local leaf="${name##*/}"
    [[ "${leaf}" == "hyprland" ]]
}

test_module_leaf_extraction_flat() {
    local name="core"
    local leaf="${name##*/}"
    [[ "${leaf}" == "core" ]]
}

# ---- Run ----
echo ""
echo "============================================================"
echo " Integration: base-system.sh"
echo "============================================================"
echo ""
echo " Base system definition:"
_run_test test_base_system_loads
_run_test test_base_system_has_core_first
_run_test test_base_system_has_dotfiles_last
_run_test test_base_system_includes_desktop_hyprland
_run_test test_base_system_includes_terminal_ghostty
_run_test test_base_system_includes_shell_fish
_run_test test_base_system_does_not_include_workspace_docker
_run_test test_base_system_does_not_include_workspace_node
_run_test test_base_system_module_count_is_reasonable
echo ""
echo " Module discovery:"
_run_test test_loader_discovers_flat_core
_run_test test_loader_discovers_desktop_hyprland
_run_test test_loader_discovers_terminal_ghostty
_run_test test_loader_discovers_shell_fish
_run_test test_loader_discovers_editor_nvim
_run_test test_loader_discovers_browser_zen
_run_test test_loader_discovers_workspace_docker
_run_test test_loader_discovers_dotfiles
_run_test test_loader_does_not_discover_category_dirs
echo ""
echo " module_loader::exists:"
_run_test test_exists_core
_run_test test_exists_desktop_hyprland
_run_test test_exists_rejects_plain_hyprland
_run_test test_exists_rejects_category_dir
echo ""
echo " Function name resolution:"
_run_test test_module_leaf_extraction_nested
_run_test test_module_leaf_extraction_flat

echo ""
echo "------------------------------------------------------------"
printf " Results: \e[32m%d passed\e[0m, \e[31m%d failed\e[0m\n" "${_PASS}" "${_FAIL}"
echo "============================================================"
echo ""

[[ "${_FAIL}" -eq 0 ]]
