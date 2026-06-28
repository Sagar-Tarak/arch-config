# Forge

Post-install workstation bootstrapper for Arch Linux + Hyprland.

Forge does not install Arch Linux. It configures it.

---

## Prerequisites

Before running Forge you need:

1. **Arch Linux** installed via [archinstall](https://wiki.archlinux.org/title/Archinstall)
2. **Hyprland desktop profile** selected during archinstall
3. Rebooted into Hyprland

That's it. Forge takes over from there.

---

## Quickstart

```bash
git clone git@github.com:Sagar-Tarak/forge.git
cd forge
./install.sh
```

Follow the post-install next steps printed at the end.

---

## What Forge adds

Forge layers a complete personal development workstation on top of a clean Arch + Hyprland base.

### Desktop

| Tool | Purpose |
|---|---|
| Waybar | Status bar |
| Rofi | Application launcher |
| SwayNC | Notification center |
| Hyprlock | Screen locker |
| Hypridle | Idle management |
| Hyprpaper | Wallpaper daemon |
| Thunar | Graphical file manager |
| Polkit GNOME | Authentication dialogs |

### Development environment

| Tool | Purpose |
|---|---|
| Neovim (LazyVim) | Editor |
| Fish + Starship | Shell + prompt |
| Atuin | Encrypted shell history |
| GitHub CLI | GitHub from the terminal |
| Lazygit | Terminal Git UI |
| Ghostty | GPU-accelerated terminal |

### CLI toolkit

| Tool | Purpose |
|---|---|
| Ripgrep | Fast search |
| fd | Modern `find` |
| fzf | Fuzzy finder |
| bat | Syntax-highlighted `cat` |
| eza | Modern `ls` |
| zoxide | Smart `cd` |
| yazi | Terminal file manager |
| btop | Resource monitor |
| fastfetch | System info |
| jq / yq | JSON / YAML tools |

### Theming

| Tool | Purpose |
|---|---|
| Matugen | Wallpaper-driven Material You colors |
| JetBrainsMono Nerd Font | Primary monospace font |
| Font Awesome | Icon font |
| Noto Fonts | Unicode + emoji coverage |

### Browser

Firefox.

---

## What Forge does NOT install

These come from archinstall and are assumed to be present:

- Arch Linux base system
- Hyprland compositor
- NetworkManager
- PipeWire / WirePlumber
- Graphics drivers
- base-devel / git / curl
- Display manager (SDDM)

If any of these are missing, the pre-flight check will tell you.

---

## Wallpaper-driven theming

Forge uses [matugen](https://github.com/InioX/matugen) to generate a Material Design 3 color
scheme from your wallpaper. Every application reads from the same generated palette.

**Change your wallpaper:**

```bash
bash scripts/set-wallpaper.sh ~/Pictures/my-photo.jpg
```

This updates the wallpaper, regenerates all colors, and reloads the desktop in one step.

**Apps that update when you change wallpaper:**

| App | What changes |
|---|---|
| Hyprland | Window border colors |
| Waybar | Bar and widget colors |
| Rofi | Selection and background colors |
| Ghostty | Terminal palette (16 ANSI colors) |
| SwayNC | Notification colors |
| Hyprlock | Lock screen accent and text |
| Fish | Syntax highlighting |

---

## After installation

**Set Fish as your default shell:**
```bash
chsh -s $(which fish)
```

**Log out and back into Hyprland:**
```
Super+M → log out → log back in
```

---

## Updating

Pull the latest configs and redeploy:

```bash
git pull
./install.sh --module dotfiles
matugen image ~/Pictures/Wallpapers/current.jpg
bash scripts/reload.sh
```

---

## Flags

```
--dry-run          Log everything, touch nothing
--yes              Skip the confirmation prompt
--aur-helper yay   Use yay instead of paru
--module <name>    Install only one module
--verify           Run verification without installing
--list-modules     List all available modules
```

**Examples:**

```bash
./install.sh --dry-run           # preview what will happen
./install.sh --module shell/fish # reinstall fish config only
./install.sh --verify            # check installed state
```

---

## Uninstall

```bash
./uninstall.sh
```

Removes dotfile symlinks and restores pre-existing configs from backup.
Packages are not removed — run `pacman -Rs <package>` for any you want gone.

---

## Repository structure

```
forge/
  install.sh          entry point
  uninstall.sh        removal entry point
  dotfiles/           configs deployed to ~/.config/ via symlinks
    hypr/             Hyprland + colors
    waybar/           Waybar config + stylesheet
    rofi/             Rofi layout + theme
    ghostty/          Ghostty terminal config
    fish/             Fish shell config
    nvim/             Neovim (LazyVim)
    matugen/          matugen config + color templates
    swaync/           notification center config
    hyprlock/         lock screen config
  modules/            per-tool install / verify / uninstall
  packages/           pacman.txt + aur.txt (workstation packages only)
  assets/             wallpapers, icons, cursors
  scripts/            set-wallpaper.sh, reload.sh
  forge/              base system definition + services
  lib/                shared bash libraries
  installer/          pipeline orchestration
  bootstrap/          environment detection + pre-flight checks
  tests/              integration tests
```

---

## Pre-flight checks

Forge verifies the following before installing anything:

| Check | Type |
|---|---|
| OS is Arch Linux | Required |
| Hyprland is installed | Required |
| base-devel / makepkg available | Required |
| Internet connectivity | Required |
| Disk space (≥ 10 GiB) | Required |
| Not running as root | Required |
| NetworkManager running | Warning |
| PipeWire running | Warning |
| Running in a VM | Info |

If the Hyprland check fails, Forge exits immediately with instructions to use archinstall first.
