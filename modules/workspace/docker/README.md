# Module: docker

Installs Docker CE and docker-compose, enables the daemon, and adds the current user to the `docker` group. **Disabled by default** — enable explicitly with `--module docker`.

## Packages

| Package | Manager | Purpose |
|---|---|---|
| `docker` | pacman | Container runtime |
| `docker-compose` | pacman | Multi-container orchestration |

## Verification

Checks `docker --version` succeeds.

## Supported Architectures

- `x86_64` only

## Dependencies

- `core`
