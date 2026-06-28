#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8

if [[ -n "${_FORGE_BASE_SYSTEM_INCLUDED:-}" ]]; then return 0; fi
_FORGE_BASE_SYSTEM_INCLUDED=1

# ==============================================================================
# Forge — Base System Definition
# File: forge/base-system.sh
# Purpose: Single source of truth for the Forge base system.
#
#          Forge installs exactly one desktop environment (Hyprland) and one
#          base development environment. There is no installation wizard, no
#          profile selection, and no desktop choice.
#
#          Every key in this file answers: "what does Forge always install?"
#
# Usage:
#   source forge/base-system.sh
#   for module in "${FORGE_BASE_MODULES[@]}"; do
#       module::install "${module}"
#   done
# ==============================================================================

# ------------------------------------------------------------------------------
# Ordered module list — the Forge base system.
#
# Modules are installed in array order. A module must appear after all modules
# it depends on. The module loader enforces declared dependencies but ordering
# here also serves as documentation of the install sequence.
# ------------------------------------------------------------------------------
readonly -a FORGE_BASE_MODULES=(
    # 1. Core: initialize the runtime directory structure
    "core"

    # 2. Desktop environment: Hyprland + full compositor stack
    "desktop/fonts"        # fonts first — hyprland depends on them
    "desktop/hyprland"     # Wayland compositor
    "desktop/waybar"       # status bar
    "desktop/hyprlock"     # screen locker
    "desktop/hypridle"     # idle management
    "desktop/hyprpaper"    # wallpaper daemon
    "desktop/rofi"         # application launcher
    "desktop/swaync"       # notification center
    "desktop/thunar"       # graphical file manager

    # 3. Terminal
    "terminal/ghostty"     # Ghostty terminal emulator

    # 4. Shell
    "shell/fish"           # Fish shell + Starship prompt

    # 5. Editors
    "editor/nvim"          # Neovim with Lazy.nvim

    # 6. Browser
    "browser/firefox"      # Firefox

    # 7. Development baseline
    "workspace/git"        # Git + GitHub CLI

    # 8. Theming: wallpaper-driven color generation
    "desktop/matugen"      # matugen — generates colors from wallpaper

    # 9. Dotfiles: always last — links configs after tools are installed
    "dotfiles"
)

# ------------------------------------------------------------------------------
# Workspace extensions — NOT part of the base system.
# Installed on demand via: forge install <name>  (future CLI)
# Defined here for documentation purposes only.
# ------------------------------------------------------------------------------
#
# forge install node     → workspace/node
# forge install docker   → workspace/docker
# forge install rust     → (future workspace/rust)
# forge install go       → (future workspace/go)
