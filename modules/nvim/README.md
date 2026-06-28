# Module: nvim

Installs Neovim and deploys a Lazy.nvim-based configuration with LSP support.

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `neovim` | pacman | Modal text editor |

## Dotfiles

| Source | Target |
|---|---|
| `dotfiles/nvim/` | `~/.config/nvim/` |

## Verification

Checks `nvim --version` succeeds.

## Dependencies

- `core`
- `git` (required by Lazy.nvim to clone plugins)
