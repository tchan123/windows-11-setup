# windows-11-setup

Post-install setup for Windows 11. Most apps come from `winget` (`packages.json`); apps not in winget are tracked in `packages-manual.json` and refreshed periodically by `Update-Manifest.ps1`.

## Tracked installers

<!-- begin: manifest-table -->
| Installer  | Domain     | Last updated | Source | Installer name                  |
| ---------- | ---------- | ------------ | ------ | ------------------------------- |
| NVIDIA App | nvidia.com | 2026-05-07   | direct | NVIDIA_app_v11.0.7.247.exe      |
| Battle.net | battle.net | 2026-05-07   | winget | Blizzard.BattleNet              |
<!-- end: manifest-table -->
