# Bootstrap System

The Bootstrap System is the first layer of the Arch Linux Configuration Framework.
It prepares the execution environment before any module, package, or configuration
step runs. Nothing in the installer should execute until `bootstrap::init` returns
successfully.

---

## Directory Structure

```
bootstrap/
├── bootstrap.sh     # Orchestration entry point
├── loader.sh        # Sources all lib/ libraries in dependency order
├── variables.sh     # Defines and exports all global path variables
├── environment.sh   # Host environment detection helpers
├── checks.sh        # Pre-flight validation functions
└── README.md        # This file
```

---

## Responsibilities

### `bootstrap.sh` — Entry Point

Orchestrates the full bootstrap sequence in a single call to `bootstrap::init`:

1. Sources `loader.sh` and calls `loader::load_libs` to bring in all core libraries.
2. Sources `variables.sh`, `environment.sh`, and `checks.sh`.
3. Calls `variables::load` to export all global path variables.
4. Calls `environment::detect` to export all `ENV_*` detection variables.
5. Creates the log directory.
6. Prints the framework version banner.

**Usage:**

```bash
source bootstrap/bootstrap.sh
bootstrap::init
log::info "Ready for module installation" "INSTALL"
```

---

### `loader.sh` — Library Loader

Safely sources all six `lib/` libraries in strict dependency order. Uses each
library's own double-sourcing guard, so calling `loader::load_libs` multiple
times is always safe.

**Load order:**

```
lib/colors.sh → lib/logger.sh → lib/command.sh
             → lib/filesystem.sh → lib/package.sh → lib/utils.sh
```

**Public API:**

| Function | Description |
|---|---|
| `loader::load_libs` | Sources all six core libraries |
| `loader::lib_path` | Returns the absolute path to `lib/` |

**Usage:**

```bash
source bootstrap/loader.sh
loader::load_libs
log::info "Libraries loaded" "BOOTSTRAP"
```

---

### `variables.sh` — Global Variables

Exports every global path variable used by the framework. Every path is computed
dynamically from `PROJECT_ROOT` — no absolute paths are hardcoded, making the
framework fully relocatable.

**Exported variables:**

| Variable | Description |
|---|---|
| `PROJECT_ROOT` | Absolute root of the framework checkout |
| `CONFIG_DIR` | User-editable configuration |
| `MODULES_DIR` | Installable module subdirectories |
| `PACKAGES_DIR` | Package list definitions |
| `THEMES_DIR` | Theme assets |
| `DOTFILES_DIR` | Managed dotfile sources |
| `CACHE_DIR` | Runtime cache (`$XDG_CACHE_HOME/arch-config`) |
| `BACKUP_DIR` | File backups (`$XDG_STATE_HOME/arch-config/backups`) |
| `LOG_DIR` | Log output (`$XDG_STATE_HOME/arch-config/logs`) |
| `VERSION` | Framework version (reads `VERSION` file or defaults to `0.1.0`) |
| `DEFAULT_PACKAGE_MANAGER` | `pacman` |
| `ARCH_CFG_DRY_RUN` | `false` unless set externally |
| `DEBUG` | `0` unless set externally |

**Public API:**

| Function | Description |
|---|---|
| `variables::load` | Computes and exports all variables above |

**Usage:**

```bash
source bootstrap/variables.sh
variables::load
echo "Installing to: ${PROJECT_ROOT}"
```

---

### `environment.sh` — Environment Detection

Pure detection helpers — no installation, no mutation. Every function is a query
that returns a result code or prints a string. The aggregate `environment::detect`
function runs all helpers and exports results as `ENV_*` variables.

**Public API:**

| Function | Returns / Exits |
|---|---|
| `environment::is_arch_linux` | `0` if Arch Linux, `1` otherwise |
| `environment::detect_shell` | Prints login shell name (`bash`, `zsh`, …) |
| `environment::is_root` | `0` if `EUID == 0` |
| `environment::is_sudo` | `0` if `SUDO_USER` is set |
| `environment::detect_terminal` | Prints terminal emulator name |
| `environment::detect_package_manager` | Prints `pacman` or `unknown` |
| `environment::detect_aur_helper` | Prints `paru`, `yay`, or exits 1 |
| `environment::has_internet` | `0` if internet is reachable |
| `environment::detect_cpu_arch` | Prints CPU architecture (`x86_64`, …) |
| `environment::detect_display_server` | Prints `wayland`, `x11`, or `none` |
| `environment::detect` | Runs all above; exports `ENV_*` variables |

**Exported `ENV_*` variables (after `environment::detect`):**

`ENV_IS_ARCH_LINUX`, `ENV_SHELL`, `ENV_IS_ROOT`, `ENV_IS_SUDO`,
`ENV_TERMINAL`, `ENV_PACKAGE_MANAGER`, `ENV_AUR_HELPER`,
`ENV_HAS_INTERNET`, `ENV_CPU_ARCH`, `ENV_DISPLAY_SERVER`

**Usage:**

```bash
source bootstrap/environment.sh
if environment::is_arch_linux; then
    echo "Running on Arch Linux"
fi
environment::detect
echo "Display server: ${ENV_DISPLAY_SERVER}"
```

---

### `checks.sh` — Pre-flight Validation

Reusable gate functions that validate the host environment before the installer
proceeds. Every function returns `0` (pass) or `1` (fail) and **never calls
`exit`** — the caller decides how to handle failures.

**Public API:**

| Function | Validates |
|---|---|
| `checks::check_arch` | OS is Arch Linux |
| `checks::check_internet` | Internet is reachable |
| `checks::check_disk_space [min_gib] [mount]` | Free disk space ≥ `min_gib` GiB (default: 10) |
| `checks::check_ram [min_mib]` | Available RAM ≥ `min_mib` MiB (default: 512) |
| `checks::check_root` | NOT running as root |
| `checks::check_supported_shell` | Login shell is bash, zsh, or fish |
| `checks::check_required_commands cmd…` | All listed commands exist in `$PATH` |
| `checks::check_project_structure` | `lib/` and `bootstrap/` exist under `PROJECT_ROOT` |
| `checks::run_all` | Runs all checks; logs each result; returns 1 if any fail |

**Usage:**

```bash
source bootstrap/checks.sh

# Abort on failure
checks::check_arch || { log::fatal "Arch Linux required" "INSTALL"; exit 1; }

# Run all and report
checks::run_all || log::warn "Some pre-flight checks failed" "INSTALL"
```

---

## Tests

Each component has a dedicated test file under `tests/`:

```
tests/
├── test-bootstrap.sh    # Tests bootstrap::init orchestration
├── test-checks.sh       # Tests all check_* functions with mocked conditions
├── test-environment.sh  # Tests each ENV detection helper
├── test-loader.sh       # Tests library loading and idempotency
└── test-variables.sh    # Tests all exported path variables
```

Run individual suites from the project root:

```bash
bash tests/test-loader.sh
bash tests/test-variables.sh
bash tests/test-environment.sh
bash tests/test-checks.sh
bash tests/test-bootstrap.sh
```

---

## Design Decisions

**Why separate `loader.sh` from `bootstrap.sh`?**
`loader.sh` can be sourced standalone by any component that only needs the core
libraries without the full bootstrap sequence. This avoids circular dependencies
as the project grows.

**Why does `environment.sh` expose only query functions?**
Keeping detection and action separate means the same helpers can be used by both
the installer and the uninstaller, and by tests that need to mock specific
conditions without side effects.

**Why do `checks.sh` functions never call `exit`?**
Library files must not terminate the caller's shell. Callers (installer scripts,
CI gates, interactive prompts) have different policies for how to handle failures.
Returning a status code gives callers full control.

**Why is `SCRIPT_DIR` set per-library rather than inherited?**
Each library resolves its own dependencies relative to its own `BASH_SOURCE[0]`,
making every file independently sourceable from any working directory without
relying on the caller's `SCRIPT_DIR`.
