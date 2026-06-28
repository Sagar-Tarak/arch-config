#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_FORGE_BASE_SYSTEM_INCLUDED:-}" ]]; then return 0; fi
_FORGE_BASE_SYSTEM_INCLUDED=1

# ==============================================================================
# Forge — Base System Definition
# File: forge/base-system.sh
#
# Philosophy (v2):
#   Forge is a POST-INSTALL workstation bootstrapper.
#   It assumes the user already has Arch Linux + Hyprland installed via archinstall.
#   Forge adds the personal workstation layer on top of that clean base:
#   applications, dotfiles, CLI tools, and theming.
#
#   Forge does NOT install:
#     - The operating system
#     - Graphics drivers
#     - The Hyprland compositor itself
#     - NetworkManager, PipeWire, or the audio stack
#     - The base system (base-devel, git, curl)
#
#   Those belong to archinstall.
#
# Usage:
#   source forge/base-system.sh
#   for module in "${FORGE_BASE_MODULES[@]}"; do
#       module::install "${module}"
#   done
# ==============================================================================

# ------------------------------------------------------------------------------
# Ordered module list — the Forge workstation layer.
#
# Prerequisites (managed by archinstall, NOT Forge):
#   - Arch Linux
#   - Hyprland + xdg-desktop-portal-hyprland
#   - NetworkManager (enabled)
#   - PipeWire + WirePlumber (enabled)
#   - base-devel (for AUR helper)
#   - git
#
# Modules are installed in array order. A module must appear after all modules
# it depends on.
# ------------------------------------------------------------------------------
readonly -a FORGE_BASE_MODULES=(
    # 1. Core: initialize the framework runtime directory structure
    "core"

    # 2. Fonts: must come first — all other desktop apps depend on them
    "desktop/fonts"

    # 3. Hyprland extras: tools that archinstall does not install by default
    "desktop/waybar"       # status bar
    "desktop/hyprlock"     # screen locker
    "desktop/hypridle"     # idle management
    "desktop/hyprpaper"    # wallpaper daemon
    "desktop/rofi"         # application launcher
    "desktop/swaync"       # notification center
    "desktop/thunar"       # graphical file manager

    # 4. Terminal
    "terminal/ghostty"     # Ghostty terminal emulator (AUR)

    # 5. Shell
    "shell/fish"           # Fish shell + Starship prompt + Atuin history

    # 6. Editors
    "editor/nvim"          # Neovim (LazyVim bootstrap on first launch)

    # 7. Browser
    "browser/firefox"      # Firefox

    # 8. Development tools
    "workspace/git"        # GitHub CLI + Lazygit (git itself is from archinstall)

    # 9. Theming: wallpaper-driven color generation
    "desktop/matugen"      # matugen — generates colors from wallpaper

    # 10. Dotfiles: always last — links configs after all tools are installed
    "dotfiles"
)

# ------------------------------------------------------------------------------
# Workspace extensions — NOT part of the base workstation.
# Installed on demand: forge install <name>  (future CLI)
# Defined here for documentation purposes only.
# ------------------------------------------------------------------------------
#
# forge install docker   → workspace/docker
# forge install node     → workspace/node
