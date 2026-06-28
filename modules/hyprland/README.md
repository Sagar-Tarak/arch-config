# Module: hyprland

Installs the Hyprland Wayland compositor with a complete supporting stack (notifications, wallpapers, screenshots, clipboard).

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `hyprland` | pacman | Wayland compositor |
| `wofi` | pacman | Application launcher |
| `dunst` | pacman | Notification daemon |
| `swww` | pacman | Wallpaper daemon |
| `grim` | pacman | Screenshot utility |
| `slurp` | pacman | Region selection |
| `wl-clipboard` | pacman | Wayland clipboard |
| `hyprpicker` | AUR | Color picker |
| `hypridle` | AUR | Idle daemon |
| `hyprlock` | AUR | Screen locker |

## Dotfiles

| Source | Target |
|---|---|
| `dotfiles/hypr/` | `~/.config/hypr/` |

## Verification

Checks `hyprctl` is present in `$PATH`.

## Supported Architectures

- `x86_64` only

## Dependencies

- `core`
- `fonts`
- `terminal`
