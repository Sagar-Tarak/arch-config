#!/usr/bin/env bash

# Use strict bash options
set -Eeuo pipefail

# Ensure script is run from a clean environment
export LC_ALL=C.UTF-8

# Resolve the absolute script path safely
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ==============================================================================
# Forge - filesystem.sh Unit Test Suite
# File: tests/test-filesystem.sh
# Purpose: Verifies filesystem manipulation functions (ensure, copy, symlink,
#          backup, restore, remove) in an isolated, temporary environment.
# Dependencies: lib/filesystem.sh
# ==============================================================================

# Source the filesystem library
source "${SCRIPT_DIR}/../lib/filesystem.sh"

# Setup temporary test directory workspace
TEST_WORK_DIR="$(mktemp -d /tmp/arch_cfg_test_fs.XXXXXX)"
readonly TEST_WORK_DIR

# Establish isolated state backup target folder for tests
export XDG_STATE_HOME="${TEST_WORK_DIR}/state"

# Ensure cleanup on script termination
cleanup() {
    rm -rf "${TEST_WORK_DIR}"
}
trap cleanup EXIT

# @description Runs a test case, printing colored output indicating status.
# @arg1 string test_name The name of the test function.
run_test() {
    local test_name="${1}"
    printf "Running %s... " "${test_name}"
    
    # Run test in subshell to isolate filesystem states
    if ( "${test_name}" ); then
        printf "\e[32m✔ PASSED\e[0m\n"
    else
        printf "\e[31m✘ FAILED\e[0m\n"
        exit 1
    fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

# Verifies that importing filesystem.sh multiple times does not error or reset state.
test_double_sourcing() {
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/../lib/filesystem.sh"
    return 0
}

# Verifies idempotent folder creation
test_ensure_directory() {
    local target_dir="${TEST_WORK_DIR}/nested/dir/test"
    
    # First creation
    fs::ensure_directory "${target_dir}"
    if [[ ! -d "${target_dir}" ]]; then
        echo "Error: Directory was not created" >&2
        return 1
    fi

    # Second creation (idempotency check)
    fs::ensure_directory "${target_dir}"
    return 0
}

# Verifies idempotent empty file creation
test_ensure_file() {
    local target_file="${TEST_WORK_DIR}/nested/file/test.txt"

    # First creation
    fs::ensure_file "${target_file}"
    if [[ ! -f "${target_file}" ]]; then
        echo "Error: File was not created" >&2
        return 1
    fi

    # Second creation (idempotency check)
    fs::ensure_file "${target_file}"
    return 0
}

# Verifies idempotent file copying (skips copy if identical, overwrites/backups if different)
test_copy_file() {
    local src_file="${TEST_WORK_DIR}/src.txt"
    local dst_file="${TEST_WORK_DIR}/dst.txt"

    echo "content A" > "${src_file}"

    # First copy
    fs::copy_file "${src_file}" "${dst_file}"
    if [[ ! -f "${dst_file}" ]] || [[ "$(cat "${dst_file}")" != "content A" ]]; then
        echo "Error: Copy failed or contents mismatch" >&2
        return 1
    fi

    # Copy identical (should skip/not fail)
    fs::copy_file "${src_file}" "${dst_file}"

    # Copy with different content (overwrites and creates backup)
    echo "content B" > "${src_file}"
    fs::copy_file "${src_file}" "${dst_file}"
    if [[ "$(cat "${dst_file}")" != "content B" ]]; then
        echo "Error: Copy did not update contents" >&2
        return 1
    fi

    # Verify backup exists in state directory
    local backup_count
    backup_count=$(find "${XDG_STATE_HOME}" -type f -name "dst.txt" | wc -l)
    if [[ "${backup_count}" -lt 1 ]]; then
        echo "Error: Backup of overwritten file not found in state folder" >&2
        return 1
    fi
    return 0
}

# Verifies directory copy recursively
test_copy_directory() {
    local src_dir="${TEST_WORK_DIR}/src_dir"
    local dst_dir="${TEST_WORK_DIR}/dst_dir"

    mkdir -p "${src_dir}/a"
    echo "file1" > "${src_dir}/a/file1.txt"
    echo "file2" > "${src_dir}/file2.txt"

    fs::copy_directory "${src_dir}" "${dst_dir}"

    if [[ ! -f "${dst_dir}/a/file1.txt" ]] || [[ ! -f "${dst_dir}/file2.txt" ]]; then
        echo "Error: Directory copy did not replicate all files" >&2
        return 1
    fi
    return 0
}

# Verifies backup and restore mechanism
test_backup_restore() {
    local target_file="${TEST_WORK_DIR}/backup_target.txt"
    local restore_file="${TEST_WORK_DIR}/restored_target.txt"
    echo "original content" > "${target_file}"

    # Run backup
    fs::backup_file "${target_file}"

    # Identify the backup path
    local backup_path
    backup_path=$(find "${XDG_STATE_HOME}" -type f -name "backup_target.txt" | head -n 1)

    if [[ -z "${backup_path}" ]]; then
        echo "Error: Backup file could not be resolved" >&2
        return 1
    fi

    # Run restore
    fs::restore_backup "${restore_file}" "${backup_path}"
    if [[ ! -f "${restore_file}" ]] || [[ "$(cat "${restore_file}")" != "original content" ]]; then
        echo "Error: Restore failed or contents mismatch" >&2
        return 1
    fi
    return 0
}

# Verifies safe symlinking and file replacement with backups
test_create_symlink() {
    local source_file="${TEST_WORK_DIR}/real_source.conf"
    local symlink_path="${TEST_WORK_DIR}/link_dest.conf"

    echo "source conf" > "${source_file}"

    # Create link
    fs::create_symlink "${source_file}" "${symlink_path}"
    if [[ ! -L "${symlink_path}" ]] || [[ "$(readlink -f "${symlink_path}")" != "$(readlink -f "${source_file}")" ]]; then
        echo "Error: Symlink was not created correctly" >&2
        return 1
    fi

    # Idempotency check: linking again shouldn't mutate/fail
    fs::create_symlink "${source_file}" "${symlink_path}"

    # Overwrite link replacement (replace existing file with symlink and verify backup)
    local replacement_link="${TEST_WORK_DIR}/replace_file_with_link.conf"
    echo "pre-existing configuration file" > "${replacement_link}"

    fs::create_symlink "${source_file}" "${replacement_link}"
    if [[ ! -L "${replacement_link}" ]]; then
        echo "Error: Existing file was not replaced with a symlink" >&2
        return 1
    fi

    # Verify backup exists
    local backup_path
    backup_path=$(find "${XDG_STATE_HOME}" -type f -name "replace_file_with_link.conf" | head -n 1)
    if [[ -z "${backup_path}" ]]; then
        echo "Error: Pre-existing file was not backed up prior to symlink replacement" >&2
        return 1
    fi
    return 0
}

# Verifies idempotent deletion
test_remove_if_exists() {
    local temp_file="${TEST_WORK_DIR}/to_be_deleted.txt"
    touch "${temp_file}"

    # First deletion
    fs::remove_if_exists "${temp_file}"
    if [[ -f "${temp_file}" ]]; then
        echo "Error: File was not deleted" >&2
        return 1
    fi

    # Second deletion (idempotency check)
    fs::remove_if_exists "${temp_file}"
    return 0
}

# Verifies path safety check preventing system folder mutations
test_path_safety() {
    local exit_code=0

    # Try to delete root (should fail and prevent action)
    fs::remove_if_exists "/" || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected fs::remove_if_exists to reject '/' path" >&2
        return 1
    fi

    # Try to copy file to root (should fail and prevent action)
    local temp_file="${TEST_WORK_DIR}/some_temp.txt"
    touch "${temp_file}"
    
    exit_code=0
    fs::copy_file "${temp_file}" "/" || exit_code=$?
    if [[ "${exit_code}" -eq 0 ]]; then
        echo "Error: Expected fs::copy_file to reject root target path" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# Execution Entrypoint
# ==============================================================================
echo "============================================================"
echo "Starting test suite: test-filesystem.sh"
echo "============================================================"

run_test test_double_sourcing
run_test test_ensure_directory
run_test test_ensure_file
run_test test_copy_file
run_test test_copy_directory
run_test test_backup_restore
run_test test_create_symlink
run_test test_remove_if_exists
run_test test_path_safety

echo "All test-filesystem.sh tests passed!"
echo "============================================================"
