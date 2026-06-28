#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_FORGE_BASE_SYSTEM_INCLUDED:-}" ]]; then return 0; fi
_FORGE_BASE_SYSTEM_INCLUDED=1

# ==============================================================================
# Forge — Base System Definition
# File: forge/base-system.sh
#
# Philosophy (v3):
#   Forge is a desktop configuration framework.
#   It assumes the user already has Arch Linux + Hyprland installed via archinstall.
#   Forge installs and configures the Hyprland desktop environment layer only —
#   the visual stack, theming, terminal, and shell that make the desktop usable.
#
#   Forge does NOT install:
#     - The operating system
#     - Graphics drivers
#     - The Hyprland compositor itself
#     - NetworkManager, PipeWire, or the audio stack
#     - The base system (base-devel, git, curl)
#     - Development tools (editors, version control UIs, language runtimes)
#     - Browsers
#
#   Those are the user's responsibility (archinstall + manual selection).
#   Developer tools are available as optional modules — see packages/optional.txt.
#
# Usage:
#   source forge/base-system.sh
#   for module in "${FORGE_BASE_MODULES[@]}"; do
#       module::install "${module}"
#   done
# ==============================================================================

# ------------------------------------------------------------------------------
# Base module list — the Forge desktop layer.
#
# Only modules that are direct components of the Forge desktop belong here.
# Modules are installed in array order. Each module must appear after all
# modules it depends on.
#
# Prerequisites (managed by archinstall, NOT Forge):
#   - Arch Linux + base-devel + git
#   - Hyprland + xdg-desktop-portal-hyprland
#   - NetworkManager (enabled)
#   - PipeWire + WirePlumber (enabled)
# ------------------------------------------------------------------------------
readonly -a FORGE_BASE_MODULES=(
    # 1. Core: initialize the framework runtime directory structure
    "core"

    # 2. Fonts: must come before all other desktop apps
    "desktop/fonts"

    # 3. Desktop shell — status bar, lock screen, idle, wallpaper, launcher, notifications
    "desktop/waybar"       # status bar
    "desktop/hyprlock"     # screen locker
    "desktop/hypridle"     # idle management
    "desktop/hyprpaper"    # wallpaper daemon
    "desktop/rofi"         # application launcher
    "desktop/swaync"       # notification center
    "desktop/thunar"       # graphical file manager

    # 4. Terminal — the primary interface to the desktop
    "terminal/ghostty"     # GPU-accelerated terminal (AUR)

    # 5. Shell — enhances the terminal experience within the desktop
    "shell/fish"           # Fish shell + Starship prompt

    # 6. Theming — wallpaper-driven color generation for all desktop components
    "desktop/matugen"      # generates Material Design 3 palette from wallpaper

    # 7. Dotfiles — always last; links configs after all tools are installed
    "dotfiles"
)

# ------------------------------------------------------------------------------
# Optional modules — NOT part of the Forge desktop.
# Install individually: ./install.sh --module <name>
#
# See packages/optional.txt for the full list of optional packages.
# ------------------------------------------------------------------------------
#
# Development:
#   editor/nvim        — Neovim with LazyVim
#   workspace/git      — GitHub CLI + Lazygit
#   workspace/docker   — Docker + Compose
#   workspace/node     — Node.js + npm
#
# Browser:
#   browser/firefox    — Firefox
#   browser/zen        — Zen Browser (AUR)
