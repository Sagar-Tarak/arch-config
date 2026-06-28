# ==============================================================================
# Forge — Fish Shell Configuration
# ==============================================================================

# Suppress default greeting (Forge has its own via forge.fish)
set -g fish_greeting ""

# --- PATH ---------------------------------------------------------------------
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.go/bin"

# --- Aliases ------------------------------------------------------------------
if command -q eza
    alias ls   "eza -la --icons --group-directories-first"
    alias ll   "eza -la --icons --group-directories-first"
    alias lt   "eza -la --icons --tree --level=2"
    alias tree "eza --icons --tree"
end

if command -q bat
    alias cat "bat --style=plain"
end

if command -q nvim
    alias vi  nvim
    alias vim nvim
end

alias grep "grep --color=auto"
alias cp   "cp -iv"
alias mv   "mv -iv"
alias rm   "rm -iv"
alias mkdir "mkdir -pv"

# Git shortcuts
alias g    git
alias ga   "git add"
alias gc   "git commit"
alias gco  "git checkout"
alias gd   "git diff"
alias gl   "git log --oneline --graph --decorate"
alias gp   "git push"
alias gs   "git status -sb"

# --- Integrations -------------------------------------------------------------
if command -q zoxide
    zoxide init fish | source
    # Override cd to use zoxide
    alias cd z
end

if command -q starship
    starship init fish | source
end

if command -q fzf
    fzf --fish | source
end
