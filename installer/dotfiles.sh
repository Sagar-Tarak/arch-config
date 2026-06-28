#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Double-sourcing guard
if [[ -n "${_DOTFILES_SH_INCLUDED:-}" ]]; then
    return 0
fi
_DOTFILES_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Dotfile Deployment Interface
# File: installer/dotfiles.sh
# Purpose: Provides the public API for deploying, backing up, restoring, and
#          verifying dotfile symlinks. All destructive operations are guarded
#          by ARCH_CFG_DRY_RUN and delegate to lib/filesystem.sh for safe,
#          idempotent file operations with automatic backups.
# Dependencies: lib/logger.sh, lib/filesystem.sh, bootstrap/variables.sh
# Public API:
#   dotfiles::deploy          - Symlinks all files from source_dir into target_dir
#   dotfiles::backup_existing - Backs up regular files that would be overwritten
#   dotfiles::restore_backup  - Restores a backup directory into target_dir
#   dotfiles::verify_links    - Checks all expected symlinks exist and point correctly
# Usage Example:
#   source installer/dotfiles.sh
#   dotfiles::backup_existing
#   dotfiles::deploy
#   dotfiles::verify_links
# ==============================================================================

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Symlinks every file under source_dir into the equivalent path
#              under target_dir. Uses fs::create_symlink which backs up any
#              existing non-symlink targets automatically.
# @arg1 string source_dir Root of dotfile sources (default: DOTFILES_DIR)
# @arg2 string target_dir Destination root (default: HOME)
# @exit 0 on success, 1 on missing source directory
dotfiles::deploy() {
    local source_dir="${1:-${DOTFILES_DIR}}"
    local target_dir="${2:-${HOME}}"

    if [[ ! -d "${source_dir}" ]]; then
        log::warn "Dotfiles source directory not found: ${source_dir}" "DOTFILES"
        log::warn "Nothing to deploy." "DOTFILES"
        return 0
    fi

    log::info "Deploying dotfiles: ${source_dir} → ${target_dir}" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN}" == "true" ]]; then
        log::info "[DRY-RUN] Would symlink files from ${source_dir} to ${target_dir}" "DOTFILES"
        _dotfiles::walk_files "${source_dir}" | while IFS= read -r rel_path; do
            log::info "[DRY-RUN]   ${target_dir}/${rel_path} -> ${source_dir}/${rel_path}" "DOTFILES"
        done
        return 0
    fi

    local rel_path
    while IFS= read -r rel_path; do
        local src="${source_dir}/${rel_path}"
        local dst="${target_dir}/${rel_path}"
        fs::create_symlink "${src}" "${dst}"
    done < <(_dotfiles::walk_files "${source_dir}")

    log::success "Dotfile deployment complete." "DOTFILES"
    return 0
}

# @description Backs up any regular files under target_dir that share a path
#              with the dotfiles in source_dir. Must be called before deploy
#              when you want a manual backup checkpoint separate from the
#              automatic backup that fs::create_symlink performs.
# @arg1 string source_dir Root of dotfile sources (default: DOTFILES_DIR)
# @arg2 string target_dir Destination root (default: HOME)
# @exit 0 Always
dotfiles::backup_existing() {
    local source_dir="${1:-${DOTFILES_DIR}}"
    local target_dir="${2:-${HOME}}"

    if [[ ! -d "${source_dir}" ]]; then
        log::warn "Dotfiles source directory not found: ${source_dir}" "DOTFILES"
        return 0
    fi

    log::info "Backing up existing dotfiles in: ${target_dir}" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN}" == "true" ]]; then
        log::info "[DRY-RUN] Would back up conflicting files in ${target_dir}" "DOTFILES"
        return 0
    fi

    local rel_path
    while IFS= read -r rel_path; do
        local target_file="${target_dir}/${rel_path}"
        # Only back up regular files (not symlinks; those are managed by us)
        if [[ -f "${target_file}" && ! -L "${target_file}" ]]; then
            log::info "Backing up: ${target_file}" "DOTFILES"
            fs::backup_file "${target_file}"
        fi
    done < <(_dotfiles::walk_files "${source_dir}")

    return 0
}

# @description Restores every file from a timestamped backup directory back
#              into target_dir. Wraps fs::restore_backup per file.
# @arg1 string backup_path Absolute path to the backup snapshot directory
# @arg2 string target_dir  Restore destination root (default: HOME)
# @exit 0 on success, 1 on missing or invalid backup path
dotfiles::restore_backup() {
    local backup_path="${1:-}"
    local target_dir="${2:-${HOME}}"

    if [[ -z "${backup_path}" ]]; then
        log::error "dotfiles::restore_backup requires a backup snapshot path." "DOTFILES"
        return 1
    fi

    if [[ ! -d "${backup_path}" ]]; then
        log::error "Backup directory not found: ${backup_path}" "DOTFILES"
        return 1
    fi

    log::info "Restoring dotfile backup: ${backup_path} → ${target_dir}" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN}" == "true" ]]; then
        log::info "[DRY-RUN] Would restore files from ${backup_path} to ${target_dir}" "DOTFILES"
        return 0
    fi

    local rel_path
    while IFS= read -r rel_path; do
        local backup_file="${backup_path}/${rel_path}"
        local target_file="${target_dir}/${rel_path}"
        if [[ -e "${backup_file}" ]]; then
            fs::restore_backup "${target_file}" "${backup_file}"
        fi
    done < <(_dotfiles::walk_files "${backup_path}")

    log::success "Backup restoration complete." "DOTFILES"
    return 0
}

# @description Verifies that every file under source_dir has a corresponding
#              symlink in target_dir that points to the correct source path.
#              Reports each broken or missing link.
# @arg1 string source_dir Root of dotfile sources (default: DOTFILES_DIR)
# @arg2 string target_dir Destination root (default: HOME)
# @exit 0 if all links are correct, 1 if any are missing or broken
dotfiles::verify_links() {
    local source_dir="${1:-${DOTFILES_DIR}}"
    local target_dir="${2:-${HOME}}"

    if [[ ! -d "${source_dir}" ]]; then
        log::warn "Dotfiles source directory not found: ${source_dir}" "DOTFILES"
        return 0
    fi

    local broken=0

    local rel_path
    while IFS= read -r rel_path; do
        local src="${source_dir}/${rel_path}"
        local dst="${target_dir}/${rel_path}"

        if [[ -L "${dst}" ]]; then
            local actual_target
            actual_target="$(readlink -f "${dst}")"
            if [[ "${actual_target}" == "$(readlink -f "${src}")" ]]; then
                log::debug "  ✔ ${dst}" "DOTFILES"
            else
                log::warn "  Link mismatch: ${dst} → ${actual_target} (expected ${src})" "DOTFILES"
                broken=$(( broken + 1 ))
            fi
        elif [[ -e "${dst}" ]]; then
            log::warn "  Regular file (should be symlink): ${dst}" "DOTFILES"
            broken=$(( broken + 1 ))
        else
            log::warn "  Missing link: ${dst}" "DOTFILES"
            broken=$(( broken + 1 ))
        fi
    done < <(_dotfiles::walk_files "${source_dir}")

    if [[ "${broken}" -gt 0 ]]; then
        log::error "${broken} dotfile link(s) are missing or broken." "DOTFILES"
        return 1
    fi

    log::success "All dotfile links verified." "DOTFILES"
    return 0
}

# @description Removes managed symlinks from target_dir that point back into
#              source_dir. Files in target_dir that are NOT symlinks (user
#              files, or files not managed by Forge) are left untouched.
# @arg1 string source_dir Root of dotfile sources (default: DOTFILES_DIR)
# @arg2 string target_dir Destination root (default: HOME/.config)
# @exit 0 Always
dotfiles::remove_links() {
    local source_dir="${1:-${DOTFILES_DIR}}"
    local target_dir="${2:-${HOME}/.config}"

    if [[ ! -d "${source_dir}" ]]; then
        log::warn "Dotfiles source directory not found: ${source_dir}" "DOTFILES"
        return 0
    fi

    log::info "Removing dotfile symlinks from: ${target_dir}" "DOTFILES"

    if [[ "${ARCH_CFG_DRY_RUN}" == "true" ]]; then
        log::info "[DRY-RUN] Would remove symlinks from ${target_dir} that point into ${source_dir}" "DOTFILES"
        return 0
    fi

    local rel_path
    while IFS= read -r rel_path; do
        local src="${source_dir}/${rel_path}"
        local dst="${target_dir}/${rel_path}"

        if [[ -L "${dst}" ]]; then
            local actual_target
            actual_target="$(readlink -f "${dst}" 2>/dev/null || true)"
            local expected_target
            expected_target="$(readlink -f "${src}" 2>/dev/null || true)"
            if [[ "${actual_target}" == "${expected_target}" ]]; then
                log::info "Removing symlink: ${dst}" "DOTFILES"
                rm -f "${dst}"
            else
                log::debug "Skipping unmanaged symlink: ${dst}" "DOTFILES"
            fi
        fi
    done < <(_dotfiles::walk_files "${source_dir}")

    log::success "Dotfile symlinks removed." "DOTFILES"
    return 0
}

# ==============================================================================
# Internal helpers
# ==============================================================================

# @description Walks a directory tree and prints relative paths for every
#              regular file found, one path per line. Avoids a fork per entry
#              by using a bash glob + recursive function approach.
# @arg1 string root_dir Directory to walk
# @stdout Relative file paths (no leading slash, no root prefix)
_dotfiles::walk_files() {
    local root_dir="${1}"
    _dotfiles::_recurse "${root_dir}" ""
}

# @description Recursive helper for _dotfiles::walk_files.
# @arg1 string base  Absolute root directory
# @arg2 string rel   Current relative path prefix (empty at root level)
_dotfiles::_recurse() {
    local base="${1}"
    local rel="${2}"
    local entry

    for entry in "${base}${rel:+/}${rel}"/*/  "${base}${rel:+/}${rel}"/*; do
        # Avoid double-matching directories by checking each entry type
        if [[ -d "${entry}" && ! -L "${entry}" ]]; then
            local sub="${entry#${base}/}"
            sub="${sub%/}"
            _dotfiles::_recurse "${base}" "${sub}"
        elif [[ -f "${entry}" && ! -d "${entry}" ]]; then
            # Print path relative to base
            printf "%s\n" "${entry#${base}/}"
        fi
    done 2>/dev/null || true
}
