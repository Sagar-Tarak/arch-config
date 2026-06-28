# Forge

An opinionated Hyprland dotfiles project for developers.

Clone it. Run it. Reboot. You're home.

```bash
git clone git@github.com:Sagar-Tarak/forge.git
cd forge
./install.sh
```

---

## What you get

| Category | Tool |
|---|---|
| Compositor | Hyprland |
| Bar | Waybar |
| Terminal | Ghostty |
| Shell | Fish + Starship |
| Editor | Neovim (LazyVim) |
| Browser | Firefox |
| Launcher | Rofi |
| Notifications | SwayNC |
| Lock screen | Hyprlock |
| File manager | Thunar |
| Theme | Catppuccin Mocha |
| Font | JetBrainsMono Nerd |

---

## What the installer does

1. Installs all packages from the official Arch repositories
2. Bootstraps `paru` and installs AUR packages
3. Enables system and user services
4. Deploys dotfiles from `dotfiles/` into `~/.config/` via symlinks
5. Verifies every step

Nothing else. No wizard. No profile selection. One desktop.

---

## Flags

```
--dry-run          Log everything, touch nothing
--yes              Skip the confirmation prompt
--aur-helper yay   Use yay instead of paru
--module <name>    Install only one module (e.g. --module desktop/hyprland)
--verify           Re-run verification without installing
--list-modules     List all available modules
```

---

## Uninstall

```bash
./uninstall.sh
```

Removes symlinks and restores any pre-existing configs from backup.

---

## Structure

```
forge/
  install.sh          entry point
  uninstall.sh        reversal entry point
  dotfiles/           configs deployed to ~/.config/
  modules/            install / verify / uninstall per tool
  packages/           pacman.txt + aur.txt
  assets/             wallpapers, icons, cursors
  forge/              base system definition
  lib/                shared libraries
  installer/          pipeline orchestration
  bootstrap/          environment initialisation
  docs/               architecture reference
```
