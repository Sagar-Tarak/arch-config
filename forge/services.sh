#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_FORGE_SERVICES_INCLUDED:-}" ]]; then return 0; fi
_FORGE_SERVICES_INCLUDED=1

# ==============================================================================
# Forge — Base System Service Definitions
# File: forge/services.sh
# Purpose: Single source of truth for which systemd services the Forge base
#          system enables. Service names are systemd unit names (without .service
#          suffix where systemctl accepts them either way).
#
#          System services require elevated privileges.
#          User services run under the installing user's systemd instance.
#
# Usage:
#   source forge/services.sh
#   for entry in "${FORGE_SYSTEM_SERVICES[@]}"; do
#       service::enable "${entry}" "system" "now"
#   done
# ==============================================================================

# ------------------------------------------------------------------------------
# System services — enabled for all users, require sudo
# ------------------------------------------------------------------------------
readonly -a FORGE_SYSTEM_SERVICES=(
    "NetworkManager"   # network connectivity
    "bluetooth"        # Bluetooth (bluez)
    "avahi-daemon"     # local network discovery (optional but common)
)

# ------------------------------------------------------------------------------
# User services — enabled per-user via systemctl --user
# PipeWire, WirePlumber, and xdg-desktop-portal run as user services on Arch.
# ------------------------------------------------------------------------------
readonly -a FORGE_USER_SERVICES=(
    "pipewire"         # audio/video routing
    "pipewire-pulse"   # PulseAudio compatibility layer
    "wireplumber"      # PipeWire session manager
)

# ------------------------------------------------------------------------------
# Packages that back these services (installed via the packages/ manifests
# but documented here so the relationship is explicit)
# ------------------------------------------------------------------------------
#
# NetworkManager → networkmanager   (pacman)
# bluetooth      → bluez bluez-utils (pacman)
# avahi-daemon   → avahi            (pacman)
# pipewire       → pipewire         (pacman)
# pipewire-pulse → pipewire-pulse   (pacman)
# wireplumber    → wireplumber      (pacman)
# polkit         → polkit           (pacman) — no service entry, auto-started by dbus
# gvfs           → gvfs             (pacman) — auto-started per session
