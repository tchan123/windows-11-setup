[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$manualManifest = Join-Path $root 'packages-manual.json'
$wingetManifest = Join-Path $root 'packages.json'
$wingetMetaFile = Join-Path $root 'winget-meta.json'
$configFile     = Join-Path $root 'config-files.json'
$readme         = Join-Path $root 'README.md'

$manualPackages = Get-Content $manualManifest | ConvertFrom-Json
$wingetPackages = @((Get-Content $wingetManifest | ConvertFrom-Json).Sources[0].Packages)
$wingetMeta     = Get-Content $wingetMetaFile | ConvertFrom-Json

function Update-NvidiaApp($pkg) {
    $page    = (Invoke-WebRequest $pkg.page -UseBasicParsing).Content
    $version = [regex]::Match($page, 'NVIDIA_app_v([\d.]+)\.exe').Groups[1].Value
    if (-not $version) { throw "Could not parse NVIDIA app version from $($pkg.page)" }
    $pkg.version = $version
    $pkg.url     = "https://us.download.nvidia.com/nvapp/client/$version/NVIDIA_app_v$version.exe"
    $pkg | Add-Member -NotePropertyName installerName -NotePropertyValue (Split-Path $pkg.url -Leaf) -Force
}

$updaters = @{
    'nvidia-app' = ${function:Update-NvidiaApp}
}

$today = (Get-Date).ToString('yyyy-MM-dd')

foreach ($pkg in $manualPackages) {
    if (-not $updaters.ContainsKey($pkg.id)) { continue }
    $before = $pkg.version
    & $updaters[$pkg.id] $pkg | Out-Null
    if ($pkg.version -ne $before) {
        $pkg.lastUpdated = $today
        Write-Host "$($pkg.id): $before -> $($pkg.version)" -ForegroundColor Green
    } else {
        Write-Host "$($pkg.id): up to date ($($pkg.version))" -ForegroundColor DarkGray
    }
}

ConvertTo-Json -InputObject @($manualPackages) -Depth 10 | Set-Content $manualManifest -Encoding utf8

# Map app name -> config-file cell: full destination path when set, 'pending' when required but not yet provided
$configMap = @{}
if (Test-Path $configFile) {
    foreach ($c in @(Get-Content $configFile | ConvertFrom-Json)) {
        $configMap[$c.app] = if ($c.dest) { $c.dest } else { 'pending' }
    }
}

# Rebuild README table between markers — combined manual + winget rows
$rows = @()
foreach ($pkg in $manualPackages) {
    $domain = ([uri]$pkg.page).Host -replace '^www\.',''
    $config = if ($configMap.ContainsKey($pkg.name)) { $configMap[$pkg.name] } else { 'none' }
    $rows += "| {0} | {1} | {2} | direct | {3} | {4} |" -f $pkg.name, $domain, $pkg.lastUpdated, $pkg.installerName, $config
}
foreach ($p in $wingetPackages) {
    $id   = $p.PackageIdentifier
    $meta = $wingetMeta.$id
    if (-not $meta) {
        Write-Warning "No winget-meta.json entry for $id - skipping README row"
        continue
    }
    $config = if ($configMap.ContainsKey($meta.name)) { $configMap[$meta.name] } else { 'none' }
    $rows += "| {0} | {1} | {2} | winget | {3} | {4} |" -f $meta.name, $meta.domain, $meta.lastUpdated, $meta.installerName, $config
}

$header = "| Installer | Domain | Last updated | Source | Installer name | Config file |`n| --- | --- | --- | --- | --- | --- |"
$table  = ($header, ($rows -join "`n")) -join "`n"

$content = Get-Content $readme -Raw
$pattern = '(?s)<!-- begin: manifest-table -->.*?<!-- end: manifest-table -->'
$replacement = "<!-- begin: manifest-table -->`n$table`n<!-- end: manifest-table -->"
$updated = [regex]::Replace($content, $pattern, $replacement)

# Stamp the last time this refresh ran (updated on every run, including the monthly cron)
$refreshPattern = '(?s)<!-- begin: last-refresh -->.*?<!-- end: last-refresh -->'
$refreshReplacement = "<!-- begin: last-refresh -->`n_Manifest last refreshed by the monthly cron: $($today)_`n<!-- end: last-refresh -->"
$updated = [regex]::Replace($updated, $refreshPattern, $refreshReplacement)

Set-Content $readme $updated -Encoding utf8
