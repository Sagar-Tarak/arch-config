# Category: services

System services that run as daemons (NetworkManager, Bluetooth, printing, etc.).

Services are installed as part of the Forge base system where appropriate,
or on demand for optional services.

## Planned Modules

| Module | Description |
|---|---|
| `services/network` | NetworkManager with nm-applet |
| `services/bluetooth` | Bluetooth stack (bluez + blueman) |
| `services/printing` | CUPS print server |
| `services/audio` | PipeWire audio stack |

## Adding a Service Module

Create a subdirectory with the standard module layout:

```
modules/services/<name>/
  manifest.sh
  install.sh
  verify.sh
  uninstall.sh
  README.md
```
