#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_FORGE_SERVICES_INCLUDED:-}" ]]; then return 0; fi
_FORGE_SERVICES_INCLUDED=1

# ==============================================================================
# Forge — Base System Service Definitions
# File: forge/services.sh
#
# Philosophy (v2):
#   Forge assumes an archinstall Hyprland installation, which already enables:
#     - NetworkManager (system service)
#     - bluetooth (system service)
#     - pipewire, pipewire-pulse, wireplumber (user services)
#
#   Forge does NOT re-enable those services. They are assumed to be running
#   before Forge is executed.
#
#   This file is intentionally empty. If a future Forge module introduces a
#   service that archinstall does not handle (e.g. docker, syncthing), add it
#   here with the backing package documented below.
# ==============================================================================

# System services managed by Forge (currently none — archinstall handles them)
readonly -a FORGE_SYSTEM_SERVICES=()

# User services managed by Forge (currently none — archinstall handles them)
readonly -a FORGE_USER_SERVICES=()

# ------------------------------------------------------------------------------
# Services assumed present from archinstall Hyprland profile:
#
#   NetworkManager     ← networkmanager  (pacman, system)
#   bluetooth          ← bluez           (pacman, system)
#   pipewire           ← pipewire        (pacman, user)
#   pipewire-pulse     ← pipewire-pulse  (pacman, user)
#   wireplumber        ← wireplumber     (pacman, user)
# ------------------------------------------------------------------------------
