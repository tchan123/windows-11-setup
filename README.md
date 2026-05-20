# windows-11-setup

<!-- begin: last-refresh -->
_Manifest last refreshed by the monthly cron: 2026-05-20_
<!-- end: last-refresh -->

**Download:** [`windows-11-setup.zip`](https://github.com/tchan123/windows-11-setup/releases/latest/download/windows-11-setup.zip) — extract and run `Setup-Windows11.ps1`. Refreshed monthly.

Post-install setup for Windows 11. Most apps come from `winget` (`packages.json`); apps not in winget are tracked in `packages-manual.json` and refreshed periodically by `Update-Manifest.ps1`.

## Scripts

| Script                | Cadence                    | Purpose                                          |
| --------------------- | -------------------------- | ------------------------------------------------ |
| `Setup-Windows11.ps1` | On demand (user-invoked)   | Pulls latest manifest, installs or upgrades apps |
| `Update-Manifest.ps1` | Monthly via GitHub Actions | Refreshes versions/URLs/installer names in repo  |

## Tracked installers

<!-- begin: manifest-table -->
| Installer | Domain | Last updated | Source | Installer name |
| --- | --- | --- | --- | --- |
| NVIDIA App | nvidia.com | 2026-05-07 | direct | NVIDIA_app_v11.0.7.247.exe |
| 7-Zip | 7-zip.org | 2026-05-20 | direct | 7z2601-x64.exe |
| Battle.net | battle.net | 2026-05-08 | winget | Battle.net-Setup.exe |
<!-- end: manifest-table -->



