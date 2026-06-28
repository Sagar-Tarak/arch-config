#!/usr/bin/env bash
set -Eeuo pipefail

# Reloads all Forge desktop components after matugen regenerates colors.
# Safe to run headless (no Hyprland session required).

if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
    hyprctl reload 2>/dev/null || true
fi

if pgrep -x waybar &>/dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
fi

if command -v swaync-client &>/dev/null; then
    swaync-client --reload-config 2>/dev/null || true
fi
