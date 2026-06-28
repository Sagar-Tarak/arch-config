#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi

# Double-sourcing guard to prevent multiple imports of the library
if [[ -n "${_FILESYSTEM_SH_INCLUDED:-}" ]]; then
    return 0
fi
_FILESYSTEM_SH_INCLUDED=1

# ==============================================================================
# Forge - Filesystem Utilities Library
# File: lib/filesystem.sh
# Purpose: Idempotent filesystem manipulation helpers with safety checks and backups.
# Dependencies: lib/logger.sh
# Public API:
#   fs::ensure_directory - Idempotently creates directories and parents
#   fs::ensure_file      - Idempotently creates files and directories
#   fs::copy_file        - Idempotently copies file if contents differ
#   fs::copy_directory   - Idempotently copies folder recursively
#   fs::create_symlink   - Idempotently links, creating backups of overwritten targets
#   fs::backup_file      - Backs up target file/directory to framework state path
#   fs::restore_backup   - Restores target file/directory from a backup path
#   fs::remove_if_exists - Safely removes file/directory if it exists
#   ensure_directory     - Delegate for fs::ensure_directory
#   ensure_file          - Delegate for fs::ensure_file
#   copy_file            - Delegate for fs::copy_file
#   copy_directory       - Delegate for fs::copy_directory
#   create_symlink       - Delegate for fs::create_symlink
#   backup_file          - Delegate for fs::backup_file
#   restore_backup       - Delegate for fs::restore_backup
#   remove_if_exists     - Delegate for fs::remove_if_exists
# ==============================================================================

# Import logger.sh dependency — resolved relative to this file, not the caller
_FS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_FS_DIR}/logger.sh" ]]; then
    # shellcheck source=lib/logger.sh
    source "${_FS_DIR}/logger.sh"
else
    echo "Error: logger.sh not found relative to filesystem.sh at: ${_FS_DIR}/logger.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# Global cached backup directory path to ensure single-run consistency
_FS_BACKUP_RUN_DIR=""

# ==============================================================================
# Internal Helper Functions
# ==============================================================================

# @description Determines the backup base directory for the current session execution.
#              Groups all backups within the same run into one timestamped folder.
# @noargs
# @stdout String path to the backup folder
_fs_get_backup_dir() {
    local xdg_state="${XDG_STATE_HOME:-}"
    if [[ -z "${xdg_state}" ]]; then
        xdg_state="${HOME}/.local/state"
    fi
    if [[ -z "${_FS_BACKUP_RUN_DIR:-}" ]]; then
        local timestamp
        timestamp="$(date +'%Y%m%d-%H%M%S')"
        _FS_BACKUP_RUN_DIR="${xdg_state}/arch-config/backups/${timestamp}"
    fi
    echo "${_FS_BACKUP_RUN_DIR}"
}

# @description Validates if a path is safe for modification/deletion (not root or system paths).
# @arg1 string target_path The path to validate.
# @exit 0 if safe, 1 if unsafe.
_fs_is_path_safe() {
    local target_path="${1:-}"
    if [[ -z "${target_path}" ]]; then
        return 1
    fi

    # Expand absolute path resolving symlinks
    local abs_path
    abs_path="$(readlink -m "${target_path}")"

    if [[ -z "${abs_path}" ]]; then
        return 1
    fi

    # Block root, home, and root home directories
    if [[ "${abs_path}" == "/" || "${abs_path}" == "/home" || "${abs_path}" == "/root" ]]; then
        return 1
    fi

    # Block direct files under / (e.g. /some_file.txt)
    local parent_dir
    parent_dir="$(dirname "${abs_path}")"
    if [[ "${parent_dir}" == "/" ]]; then
        if [[ "${abs_path}" != "/tmp" && "${abs_path}" != "/run" ]]; then
            return 1
        fi
    fi

    # Block system directories and their subdirectories
    local sys_dirs=(
        "/etc" "/usr" "/boot" "/var" "/opt" "/srv" "/bin" "/sbin" "/lib" "/lib64" "/sys" "/proc" "/dev"
    )
    local sys_dir
    for sys_dir in "${sys_dirs[@]}"; do
        if [[ "${abs_path}" == "${sys_dir}" || "${abs_path}" == "${sys_dir}"/* ]]; then
            return 1
        fi
    done

    return 0
}

# ==============================================================================
# Namespaced API Functions
# ==============================================================================

# @description Creates target directory and all parents if it does not exist.
# @arg1 string dir Path to directory.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::ensure_directory() {
    local dir="${1:-}"
    if [[ -z "${dir}" ]]; then
        log::error "Directory path cannot be empty" "FS"
        return 1
    fi

    if [[ ! -d "${dir}" ]]; then
        log::info "Creating directory: ${dir}" "FS"
        if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
            mkdir -p "${dir}"
        fi
    fi
    return 0
}

# @description Creates target file and its parents if it does not exist.
# @arg1 string file Path to file.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::ensure_file() {
    local file="${1:-}"
    if [[ -z "${file}" ]]; then
        log::error "File path cannot be empty" "FS"
        return 1
    fi

    local dir
    dir="$(dirname "${file}")"
    fs::ensure_directory "${dir}"

    if [[ ! -e "${file}" ]]; then
        log::info "Creating empty file: ${file}" "FS"
        if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
            touch "${file}"
        fi
    fi
    return 0
}

# @description Copies a file from source to destination only if the destination
#              does not exist or contains different content.
# @arg1 string src Source file path.
# @arg2 string dst Destination file/directory path.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::copy_file() {
    local src="${1:-}"
    local dst="${2:-}"

    if [[ -z "${src}" || -z "${dst}" ]]; then
        log::error "Source and destination paths are required" "FS"
        return 1
    fi
    if [[ ! -f "${src}" ]]; then
        log::error "Source file does not exist: ${src}" "FS"
        return 1
    fi

    local target="${dst}"
    if [[ -d "${dst}" ]]; then
        target="${dst%/}/$(basename "${src}")"
    fi

    if [[ -f "${target}" ]] && cmp -s "${src}" "${target}"; then
        log::debug "File is already up-to-date and identical: ${target}" "FS"
        return 0
    fi

    if ! _fs_is_path_safe "${target}"; then
        log::error "Target path is unsafe for backup/modification: ${target}" "FS"
        return 1
    fi

    if [[ -e "${target}" ]]; then
        fs::backup_file "${target}"
    fi

    fs::ensure_directory "$(dirname "${target}")"

    log::info "Copying file: ${src} -> ${target}" "FS"
    if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
        cp "${src}" "${target}"
    fi
    return 0
}

# @description Copies a directory recursively, updating files.
# @arg1 string src Source directory.
# @arg2 string dst Destination directory.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::copy_directory() {
    local src="${1:-}"
    local dst="${2:-}"

    if [[ -z "${src}" || -z "${dst}" ]]; then
        log::error "Source and destination paths are required" "FS"
        return 1
    fi
    if [[ ! -d "${src}" ]]; then
        log::error "Source directory does not exist: ${src}" "FS"
        return 1
    fi

    fs::ensure_directory "${dst}"

    log::info "Copying directory recursively: ${src} -> ${dst}" "FS"
    if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
        # cp -r with trailing /. copies contents instead of directory itself
        cp -r "${src}/." "${dst}/"
    fi
    return 0
}

# @description Backs up a file or directory recursively to the session's backup base folder.
# @arg1 string path File or directory path to back up.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::backup_file() {
    local file="${1:-}"
    if [[ -z "${file}" ]]; then
        log::error "Path to backup is required" "FS"
        return 1
    fi
    if [[ ! -e "${file}" && ! -L "${file}" ]]; then
        return 0
    fi

    local backup_base
    backup_base="$(_fs_get_backup_dir)"

    local abs_file
    abs_file="$(readlink -f "${file}")"

    # Destination inside backup directory replicates absolute structure
    local backup_dest="${backup_base}${abs_file}"

    log::info "Backing up target state: ${file} -> ${backup_dest}" "FS"
    if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
        mkdir -p "$(dirname "${backup_dest}")"
        cp -a "${file}" "${backup_dest}"
    fi
    return 0
}

# @description Restores a file or directory from backup.
# @arg1 string file Target destination path to restore.
# @arg2 string backup_path Absolute path of the backup file/directory.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::restore_backup() {
    local file="${1:-}"
    local backup_path="${2:-}"

    if [[ -z "${file}" || -z "${backup_path}" ]]; then
        log::error "Restore target and backup path are required" "FS"
        return 1
    fi
    if [[ ! -e "${backup_path}" ]]; then
        log::error "Backup path does not exist: ${backup_path}" "FS"
        return 1
    fi
    if ! _fs_is_path_safe "${file}"; then
        log::error "Restore target path is unsafe: ${file}" "FS"
        return 1
    fi

    log::info "Restoring backup: ${backup_path} -> ${file}" "FS"
    if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
        if [[ -e "${file}" || -L "${file}" ]]; then
            rm -rf "${file}"
        fi
        mkdir -p "$(dirname "${file}")"
        cp -a "${backup_path}" "${file}"
    fi
    return 0
}

# @description Creates a symbolic link pointing to the source file.
#              Automatically backs up and overrides target if it differs.
# @arg1 string src Absolute source file path.
# @arg2 string dst Absolute destination link path.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::create_symlink() {
    local src="${1:-}"
    local dst="${2:-}"

    if [[ -z "${src}" || -z "${dst}" ]]; then
        log::error "Source and destination paths are required" "FS"
        return 1
    fi

    # Read absolute path of source to be deterministic
    local abs_src
    abs_src="$(readlink -f "${src}")"

    # Check if link exists and points to the correct source already
    if [[ -L "${dst}" ]]; then
        local current_target
        current_target="$(readlink -f "${dst}")"
        if [[ "${current_target}" == "${abs_src}" ]]; then
            log::debug "Link is already correct: ${dst} -> ${abs_src}" "FS"
            return 0
        fi
    fi

    if ! _fs_is_path_safe "${dst}"; then
        log::error "Destination path is unsafe for symlinking: ${dst}" "FS"
        return 1
    fi

    # Backup and delete the existing destination if it exists
    if [[ -e "${dst}" || -L "${dst}" ]]; then
        fs::backup_file "${dst}"
        log::info "Removing existing path for link replacement: ${dst}" "FS"
        if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
            rm -rf "${dst}"
        fi
    fi

    # Ensure parent folder of destination exists
    fs::ensure_directory "$(dirname "${dst}")"

    log::info "Linked: ${dst} -> ${abs_src}" "FS"
    if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
        ln -sf "${abs_src}" "${dst}"
    fi
    return 0
}

# @description Safely removes a path from filesystem if it exists.
# @arg1 string path Target file/directory/symlink.
# @exit 0 on success, 1 on invalid arguments or failure.
fs::remove_if_exists() {
    local path="${1:-}"
    if [[ -z "${path}" ]]; then
        log::error "Path to remove is required" "FS"
        return 1
    fi

    if [[ -e "${path}" || -L "${path}" ]]; then
        if ! _fs_is_path_safe "${path}"; then
            log::error "Path is unsafe for deletion: ${path}" "FS"
            return 1
        fi

        log::info "Removing path: ${path}" "FS"
        if [[ "${ARCH_CFG_DRY_RUN:-}" != "true" ]]; then
            rm -rf "${path}"
        fi
    fi
    return 0
}

# ==============================================================================
# Non-Namespaced Public API Delegates
# ==============================================================================

# @description Delegate for fs::ensure_directory
ensure_directory() {
    fs::ensure_directory "$@"
}

# @description Delegate for fs::ensure_file
ensure_file() {
    fs::ensure_file "$@"
}

# @description Delegate for fs::copy_file
copy_file() {
    fs::copy_file "$@"
}

# @description Delegate for fs::copy_directory
copy_directory() {
    fs::copy_directory "$@"
}

# @description Delegate for fs::create_symlink
create_symlink() {
    fs::create_symlink "$@"
}

# @description Delegate for fs::backup_file
backup_file() {
    fs::backup_file "$@"
}

# @description Delegate for fs::restore_backup
restore_backup() {
    fs::restore_backup "$@"
}

# @description Delegate for fs::remove_if_exists
remove_if_exists() {
    fs::remove_if_exists "$@"
}
