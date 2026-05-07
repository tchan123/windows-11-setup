[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$manifest = Join-Path $root 'packages-manual.json'
$readme   = Join-Path $root 'README.md'
$packages = Get-Content $manifest | ConvertFrom-Json

function Update-NvidiaApp($pkg) {
    $page    = (Invoke-WebRequest $pkg.page -UseBasicParsing).Content
    $version = [regex]::Match($page, 'NVIDIA_app_v([\d.]+)\.exe').Groups[1].Value
    if (-not $version) { throw "Could not parse NVIDIA app version from $($pkg.page)" }
    $pkg.version = $version
    $pkg.url     = "https://us.download.nvidia.com/nvapp/client/$version/NVIDIA_app_v$version.exe"
}

$updaters = @{
    'nvidia-app' = ${function:Update-NvidiaApp}
}

$today = (Get-Date).ToString('yyyy-MM-dd')

foreach ($pkg in $packages) {
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

$packages | ConvertTo-Json -Depth 10 | Set-Content $manifest -Encoding utf8

# Rebuild README table between markers
$rows = $packages | ForEach-Object {
    $domain = ([uri]$_.page).Host -replace '^www\.',''
    "| {0} | {1} | {2} |" -f $_.name, $domain, $_.lastUpdated
}
$header = "| Installer | Domain | Last updated |`n| --- | --- | --- |"
$table  = ($header, ($rows -join "`n")) -join "`n"

$content = Get-Content $readme -Raw
$pattern = '(?s)<!-- begin: manifest-table -->.*?<!-- end: manifest-table -->'
$replacement = "<!-- begin: manifest-table -->`n$table`n<!-- end: manifest-table -->"
$updated = [regex]::Replace($content, $pattern, $replacement)
Set-Content $readme $updated -Encoding utf8
