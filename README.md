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
| Colors | Matugen (wallpaper-driven) |
| Font | JetBrainsMono Nerd |

---

## Wallpaper-driven theming

Forge uses [matugen](https://github.com/InioX/matugen) to generate a Material Design 3 color
scheme from your wallpaper. Every app — Hyprland borders, Waybar, Rofi, Ghostty, SwayNC,
Hyprlock, Fish — reads from the same generated palette.

**Change your wallpaper:**

```bash
bash scripts/set-wallpaper.sh ~/Pictures/my-photo.jpg
```

This updates the wallpaper, regenerates all colors, and reloads the desktop in one step.

**Regenerate colors without changing wallpaper:**

```bash
matugen image ~/Pictures/Wallpapers/current.jpg
bash scripts/reload.sh
```

**Apps that update when you change wallpaper:**

| App | What changes |
|---|---|
| Hyprland | Border colors |
| Waybar | Bar and widget colors |
| Rofi | Window, selection, and text colors |
| Ghostty | Terminal palette (16 ANSI colors + fg/bg) |
| SwayNC | Notification and control center colors |
| Hyprlock | Lock screen accent, input field, text |
| Fish | Syntax highlighting colors |

---

## What the installer does

1. Installs all packages from the official Arch repositories
2. Bootstraps `paru` and installs AUR packages (including `matugen-bin`)
3. Enables system and user services
4. Deploys dotfiles from `dotfiles/` into `~/.config/` via symlinks
5. Runs matugen to generate the initial color scheme from the bundled default wallpaper
6. Verifies every step

Nothing else. No wizard. No profile selection. No theme switcher. One desktop.

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

Removes symlinks and restores any pre-existing configs from backup. Packages are not removed
automatically — run `pacman -Rs <package>` for any you want gone.

---

## Updating

```bash
git pull
./install.sh --module dotfiles   # redeploy configs
matugen image ~/Pictures/Wallpapers/current.jpg  # regenerate colors
bash scripts/reload.sh           # reload desktop
```

---

## Structure

```
forge/
  install.sh          entry point
  uninstall.sh        reversal entry point
  dotfiles/           configs deployed to ~/.config/
    matugen/          matugen config + color templates
  modules/            install / verify / uninstall per tool
  packages/           pacman.txt + aur.txt
  assets/             wallpapers, icons, cursors
  scripts/            set-wallpaper.sh, reload.sh
  forge/              base system definition
  lib/                shared libraries
  installer/          pipeline orchestration
  bootstrap/          environment initialisation
  docs/               architecture reference
```
