# Forge

Forge is a post-install desktop configuration framework for Arch Linux with Hyprland.

It is not an Arch installer. It does not provision a system. It configures a desktop.

---

## What Forge is

You install Arch Linux. You install Hyprland. Then you run Forge.

Forge takes a fresh Hyprland session and turns it into a polished, cohesive desktop: a configured status bar, lock screen, launcher, notification center, terminal, shell, and a wallpaper-driven Material Design color scheme that ties all of it together.

That is all it does.

---

## Prerequisites

| Requirement | How to get it |
|---|---|
| Arch Linux | Install with [archinstall](https://wiki.archlinux.org/title/Archinstall) |
| Hyprland | Select the Hyprland desktop profile during archinstall |
| base-devel | Included in the archinstall Hyprland profile |
| git | Included in the archinstall Hyprland profile |
| Internet | Required for package installation |

Boot into Hyprland, open a terminal, then run Forge.

---

## Installation

```bash
git clone git@github.com:Sagar-Tarak/forge.git
cd forge
./install.sh
```

Forge will verify all assumptions before touching anything. If something is missing, it exits with a clear explanation.

---

## What Forge installs

### Desktop shell

| Component | Purpose |
|---|---|
| Waybar | Status bar |
| Rofi | Application launcher |
| SwayNC | Notification center |
| Hyprlock | Screen locker |
| Hypridle | Idle management |
| Hyprpaper | Wallpaper daemon |
| Thunar | Graphical file manager |
| Polkit GNOME | Authentication dialogs |

### Terminal

| Component | Purpose |
|---|---|
| Ghostty | GPU-accelerated terminal emulator |
| Fish | Shell |
| Starship | Cross-shell prompt |

### Fonts

| Font | Purpose |
|---|---|
| JetBrainsMono Nerd Font | Terminal and editor |
| Font Awesome | Waybar icons |
| Noto Fonts | Unicode + emoji |

### Theming

| Tool | Purpose |
|---|---|
| Matugen | Generates a Material Design 3 color palette from your wallpaper |

### CLI productivity

Ripgrep, fd, fzf, bat, eza, zoxide, jq, yq, fastfetch, btop.
These are terminal tools used by Forge's shell config and Rofi scripts.

---

## What Forge does NOT install

These are your responsibility. Forge assumes they exist.

| Component | Where it comes from |
|---|---|
| Arch Linux | archinstall |
| Hyprland | archinstall (Hyprland profile) |
| NetworkManager | archinstall |
| PipeWire / WirePlumber | archinstall |
| Graphics drivers | archinstall |
| base-devel / git / curl | archinstall |
| Neovim | Optional module |
| Firefox | Optional module |
| GitHub CLI / Lazygit | Optional module |
| Docker | Optional module |

---

## Optional modules

Developer tools are not part of the desktop and are not installed by default.
Install them individually:

```bash
./install.sh --module editor/nvim
./install.sh --module workspace/git
./install.sh --module browser/firefox
./install.sh --module workspace/docker
```

See [packages/optional.txt](packages/optional.txt) for the full list of optional packages.

---

## Wallpaper-driven theming

Forge uses [matugen](https://github.com/InioX/matugen) to generate a Material Design 3 color scheme from your wallpaper. Every desktop component reads from the same generated palette — Hyprland borders, Waybar, Rofi, Ghostty, SwayNC, Hyprlock, and Fish all update at once.

**Change your wallpaper:**

```bash
bash scripts/set-wallpaper.sh ~/Pictures/my-photo.jpg
```

---

## Pre-flight checks

Forge verifies the following before doing anything:

| Check | Type |
|---|---|
| OS is Arch Linux | Required |
| Wayland session active | Required |
| Hyprland is installed | Required |
| base-devel / makepkg available | Required |
| Internet connectivity | Required |
| Disk space (≥ 10 GiB) | Required |
| Not running as root | Required |
| NetworkManager running | Warning |
| PipeWire running | Warning |
| Running in a VM | Info |

If any required check fails, Forge stops immediately with instructions.

---

## After installation

**Set Fish as your default shell:**
```bash
chsh -s $(which fish)
```

Log out and back in to apply the shell change.

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
./install.sh --dry-run                # preview what will happen
./install.sh --module terminal/ghostty # reinstall Ghostty config only
./install.sh --verify                 # check installed state
```

---

## Updating

```bash
git pull
./install.sh --module dotfiles
matugen image ~/Pictures/Wallpapers/current.jpg
bash scripts/reload.sh
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
    hypr/             Hyprland configuration + color fallbacks
    waybar/           status bar config + stylesheet
    rofi/             launcher layout + theme
    ghostty/          terminal config
    fish/             shell config
    matugen/          color generation templates
    swaync/           notification center config
    hyprlock/         lock screen config
    hyprpaper/        wallpaper config
  modules/            per-component install / verify / uninstall
  packages/
    pacman.txt        desktop packages (installed by default)
    aur.txt           AUR desktop packages (installed by default)
    optional.txt      developer tools (installed only if module selected)
  assets/             wallpapers, icons, cursors
  scripts/            set-wallpaper.sh, reload.sh
  forge/              base system definition
  lib/                shared bash libraries
  installer/          pipeline orchestration
  bootstrap/          preflight checks + environment detection
  tests/              integration tests
```
