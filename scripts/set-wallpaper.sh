#!/usr/bin/env bash
set -Eeuo pipefail

WALLPAPER="${1:?Usage: set-wallpaper.sh /path/to/image}"

if [[ ! -f "${WALLPAPER}" ]]; then
    printf "Error: file not found: %s\n" "${WALLPAPER}" >&2
    exit 1
fi

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
mkdir -p "${WALLPAPER_DIR}"

ln -sf "$(realpath "${WALLPAPER}")" "${WALLPAPER_DIR}/current.jpg"

matugen image "${WALLPAPER_DIR}/current.jpg"

if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
    hyprctl hyprpaper wallpaper ", ${WALLPAPER_DIR}/current.jpg" 2>/dev/null || true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/reload.sh"
