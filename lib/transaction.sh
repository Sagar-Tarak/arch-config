#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_TRANSACTION_SH_INCLUDED:-}" ]]; then return 0; fi
_TRANSACTION_SH_INCLUDED=1

# ==============================================================================
# Arch Linux Configuration Framework - Transaction Library
# File: lib/transaction.sh
# Purpose: Provides lightweight operation recording for installer runs.
#          Each transaction is a directory under RUNTIME_TRANSACTIONS_DIR
#          containing an operations log and a status file.
#          Full rollback is record-only in this phase — operations are logged
#          but not automatically reversed.
# Dependencies: lib/logger.sh, lib/state.sh
# Public API:
#   transaction::begin    - Start a new transaction; echoes the transaction ID
#   transaction::record   - Append an operation to the active transaction log
#   transaction::commit   - Mark the active transaction as committed
#   transaction::rollback - Mark the active transaction as rolled_back
# ==============================================================================

# Active transaction ID — set by transaction::begin, cleared by commit/rollback.
# Use ${_CURRENT_TRANSACTION:-} wherever strict mode (-u) is active.
_CURRENT_TRANSACTION=""

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

# Start a new transaction.
# Creates a transaction directory and status file.
# @stdout The unique transaction ID (use to resume if needed)
# @exit 0 Always
transaction::begin() {
    local tx_id
    tx_id="$(date +'%Y%m%d-%H%M%S')-$$"

    local tx_dir="${RUNTIME_TRANSACTIONS_DIR}/${tx_id}"
    mkdir -p "${tx_dir}"

    printf "%s" "${tx_id}"  > "${tx_dir}/transaction.id"
    printf "pending"        > "${tx_dir}/status"

    _CURRENT_TRANSACTION="${tx_id}"
    export _CURRENT_TRANSACTION

    log::debug "Transaction begun: ${tx_id}" "TX"
    echo "${tx_id}"
}

# Record an operation in the active transaction log.
# No-ops silently if no transaction is active.
# @arg1 string operation  Short verb describing the action (e.g. "mkdir", "create", "register")
# @arg2 string target     The target path or identifier (optional)
# @exit 0 Always
transaction::record() {
    local operation="${1}"
    local target="${2:-}"
    local tx_id="${_CURRENT_TRANSACTION:-}"

    if [[ -z "${tx_id}" ]]; then
        log::debug "No active transaction — skipping record: ${operation} ${target}" "TX"
        return 0
    fi

    local tx_dir="${RUNTIME_TRANSACTIONS_DIR}/${tx_id}"
    printf "[%s] %s %s\n" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "${operation}" "${target}" \
        >> "${tx_dir}/operations.log"
}

# Mark the active transaction as committed and clear the active transaction.
# @exit 0 Always
transaction::commit() {
    local tx_id="${_CURRENT_TRANSACTION:-}"
    if [[ -z "${tx_id}" ]]; then
        return 0
    fi

    local tx_dir="${RUNTIME_TRANSACTIONS_DIR}/${tx_id}"
    printf "committed" > "${tx_dir}/status"

    log::debug "Transaction committed: ${tx_id}" "TX"
    _CURRENT_TRANSACTION=""
    export _CURRENT_TRANSACTION
}

# Mark the active transaction as rolled_back and clear the active transaction.
# Logs a warning — automatic reversal of completed operations is not yet implemented.
# @exit 0 Always
transaction::rollback() {
    local tx_id="${_CURRENT_TRANSACTION:-}"
    if [[ -z "${tx_id}" ]]; then
        return 0
    fi

    local tx_dir="${RUNTIME_TRANSACTIONS_DIR}/${tx_id}"
    printf "rolled_back" > "${tx_dir}/status"

    log::warn "Transaction ${tx_id} marked rolled_back (automatic reversal not yet implemented)." "TX"
    _CURRENT_TRANSACTION=""
    export _CURRENT_TRANSACTION
}
