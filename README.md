# windows-11-setup

<!-- begin: last-refresh -->
_Manifest last refreshed by the monthly cron: 2026-06-19_
<!-- end: last-refresh -->

**Download:** [`Setup-Windows11.zip`](https://github.com/tchan123/windows-11-setup/releases/latest/download/Setup-Windows11.zip) — extract and double-click `Setup-Windows11.cmd`; on first run it pulls the latest manifest into the same folder. Manifest is refreshed monthly.

Post-install setup for Windows 11. Apps are sourced from winget where available (`packages.json`); otherwise directly from the manufacturer's website (`packages-manual.json`). Manual entries are refreshed periodically by `Update-Manifest.ps1`. Once the installs finish, app config files in `config/` are deployed to their target paths per `config-files.json`.

## Scripts

| Script                | Cadence                    | Purpose                                          |
| --------------------- | -------------------------- | ------------------------------------------------ |
| `Setup-Windows11.ps1` | On demand (user-invoked)   | Pulls latest manifest, installs or upgrades apps |
| `Update-Manifest.ps1` | Monthly via GitHub Actions | Refreshes versions/URLs/installer names in repo  |

## Tracked installers

<!-- begin: manifest-table -->
| Installer | Domain | Last updated | Source | Installer name | Config file |
| --- | --- | --- | --- | --- | --- |
| NVIDIA App | nvidia.com | 2026-05-07 | direct | NVIDIA_app_v11.0.7.247.exe | none |
| 7-Zip | 7-zip.org | 2026-05-20 | direct | 7z2601-x64.exe | none |
| Sizer | brianapps.net | 2026-05-20 | direct | sizer4_dev640.msi | none |
| Battle.net | battle.net | 2026-05-08 | winget | Battle.net-Setup.exe | none |
| MSI Afterburner | msi.com | 2026-05-20 | winget | [Guru3D]-MSIAfterburnerSetup466Build16757.zip | none |
| Mozilla Firefox | firefox.com | 2026-05-20 | winget | Firefox Setup 151.0.exe | none |
| Logitech G HUB | logitechg.com | 2026-06-19 | winget | LGHUB_Installer.exe | none |
<!-- end: manifest-table -->




