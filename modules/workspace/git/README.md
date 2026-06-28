# Module: git

Installs git and deploys the framework's global gitconfig template.

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `git` | pacman | Version control system |

## Dotfiles

| Source | Target |
|---|---|
| `dotfiles/git/.gitconfig` | `~/.gitconfig` |

## Verification

Checks `git --version` succeeds.

## Dependencies

- `core`
