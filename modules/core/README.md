# Module: core

Installs foundational system utilities required by every other module. This module has no dependencies and must be the first module to run.

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `base-devel` | pacman | Build tools (gcc, make, etc.) |
| `curl` | pacman | HTTP client |
| `wget` | pacman | File downloader |
| `git` | pacman | Version control |
| `openssh` | pacman | SSH client/server |
| `rsync` | pacman | File sync |
| `unzip` / `zip` | pacman | Archive tools |

## Verification

Checks that `git`, `curl`, and `wget` are present in `$PATH`.

## Dependencies

None.
