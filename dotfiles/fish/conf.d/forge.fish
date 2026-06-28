# ==============================================================================
# Forge — Environment Variables
# Loaded early via conf.d/ so these are available everywhere.
# ==============================================================================

set -gx EDITOR   nvim
set -gx VISUAL   nvim
set -gx TERMINAL ghostty
set -gx BROWSER  firefox
set -gx PAGER    bat

# XDG base dirs (Fish respects these; other tools read them from env)
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME   "$HOME/.local/share"
set -gx XDG_STATE_HOME  "$HOME/.local/state"
set -gx XDG_CACHE_HOME  "$HOME/.cache"

# Wayland
set -gx WAYLAND_DISPLAY wayland-0
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND     wayland

# Go
set -gx GOPATH "$HOME/.go"
