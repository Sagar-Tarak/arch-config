# Module: dotfiles

Deploys Forge dotfiles by creating symlinks from the repository's `dotfiles/`
directory into `$HOME`. Backs up any existing regular files before linking.

## Dotfile Deployment

All files under `dotfiles/` are symlinked relative to `$HOME`.

| Source | Target |
|---|---|
| `dotfiles/fish/config.fish` | `~/.config/fish/config.fish` |
| `dotfiles/starship.toml` | `~/.config/starship.toml` |
| `dotfiles/ghostty/config` | `~/.config/ghostty/config` |
| `dotfiles/nvim/` | `~/.config/nvim/` |
| `dotfiles/hyprland/` | `~/.config/hypr/` |
| `dotfiles/waybar/` | `~/.config/waybar/` |

## Dependencies

- `core`
