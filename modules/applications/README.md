# Category: applications

Optional graphical applications installed outside the Forge base system.

Applications are installed on demand via the `forge install` CLI (future):

```bash
forge install discord
forge install telegram
forge install obsidian
forge install vlc
```

## Adding an Application Module

Create a subdirectory with the standard module layout:

```
modules/applications/<name>/
  manifest.sh
  install.sh
  verify.sh
  uninstall.sh
  README.md
```

Set `MODULE_ENABLED_BY_DEFAULT=false` — application modules are never
installed as part of the Forge base system.
