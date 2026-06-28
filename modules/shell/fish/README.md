# Module: shell

Installs Zsh and Fish shell environments with plugins and prompt configuration.

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `zsh` | pacman | Z shell |
| `fish` | pacman | Friendly interactive shell |
| `bash-completion` | pacman | Tab completion for bash |

## Dotfiles

| Source | Target |
|---|---|
| `dotfiles/shell/.zshrc` | `~/.zshrc` |
| `dotfiles/shell/config.fish` | `~/.config/fish/config.fish` |

## Verification

Checks that `zsh` or `fish` is present in `$PATH`.

## Dependencies

- `core`
