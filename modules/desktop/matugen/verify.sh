#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_MODULE_MATUGEN_VERIFY_INCLUDED:-}" ]]; then return 0; fi
_MODULE_MATUGEN_VERIFY_INCLUDED=1

# @description Verifies matugen is installed, config and templates are deployed,
#              and all generated color files exist.
# @exit 0 PASS, 1 FAIL, 3 SKIPPED
matugen::verify() {
    local failed=0

    if ! command -v matugen &>/dev/null; then
        log::error "matugen: binary not found in PATH" "MATUGEN"
        return 1
    fi
    log::success "matugen binary: found" "MATUGEN"

    local config="${HOME}/.config/matugen/config.toml"
    if [[ ! -L "${config}" && ! -f "${config}" ]]; then
        log::error "matugen config not deployed: ${config}" "MATUGEN"
        failed=$(( failed + 1 ))
    else
        log::success "matugen config: deployed" "MATUGEN"
    fi

    local templates_dir="${HOME}/.config/matugen/templates"
    if [[ ! -d "${templates_dir}" ]]; then
        log::error "matugen templates directory missing: ${templates_dir}" "MATUGEN"
        failed=$(( failed + 1 ))
    else
        log::success "matugen templates: deployed" "MATUGEN"
    fi

    local -a _generated=(
        "${HOME}/.config/hypr/colors.conf"
        "${HOME}/.config/waybar/colors.css"
        "${HOME}/.config/rofi/colors.rasi"
        "${HOME}/.config/swaync/colors.css"
        "${HOME}/.config/hyprlock/colors.conf"
        "${HOME}/.config/ghostty/colors"
        "${HOME}/.config/fish/conf.d/colors.fish"
    )

    local file
    for file in "${_generated[@]}"; do
        if [[ ! -f "${file}" ]]; then
            log::error "Generated color file missing: ${file}" "MATUGEN"
            failed=$(( failed + 1 ))
        fi
    done

    if [[ "${failed}" -eq 0 ]]; then
        log::success "All matugen outputs: present" "MATUGEN"
    fi

    [[ "${failed}" -eq 0 ]]
}
