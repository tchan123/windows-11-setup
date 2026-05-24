[CmdletBinding()]
param(
    [switch]$Unattended
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# Bootstrap: if the manifest isn't alongside the script, fetch it from the latest release into $root.
if (-not (Test-Path (Join-Path $root 'packages.json'))) {
    $zipUrl  = 'https://github.com/tchan123/windows-11-setup/releases/latest/download/manifest.zip'
    $zipPath = Join-Path $env:TEMP 'manifest.zip'
    Write-Host "Downloading manifest from $zipUrl" -ForegroundColor Cyan
    Invoke-WebRequest $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $root -Force
    Remove-Item $zipPath -Force
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $args = if ($Unattended) { '-Unattended' } else { '' }
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath,$args
    exit
}

function Install-WingetPackages {
    $file = Join-Path $root 'packages.json'
    if (-not (Test-Path $file)) { return }
    $packages = @((Get-Content $file | ConvertFrom-Json).Sources[0].Packages)
    foreach ($p in $packages) {
        $id = $p.PackageIdentifier
        Write-Host "winget install $id" -ForegroundColor Cyan
        winget install $id --silent --accept-package-agreements --accept-source-agreements
    }
}

function Install-ManualPackages {
    $file = Join-Path $root 'packages-manual.json'
    if (-not (Test-Path $file)) { return }
    $packages = Get-Content $file | ConvertFrom-Json
    foreach ($pkg in $packages) {
        Write-Host "Installing $($pkg.name) v$($pkg.version)" -ForegroundColor Cyan
        $ext = [System.IO.Path]::GetExtension(([uri]$pkg.url).AbsolutePath)
        if (-not $ext) { $ext = '.exe' }
        $installer = Join-Path $env:TEMP "$($pkg.id)$ext"
        Invoke-WebRequest $pkg.url -OutFile $installer -UseBasicParsing
        if ($ext -eq '.msi') {
            Start-Process msiexec.exe -ArgumentList "/i `"$installer`" $($pkg.installArgs)" -Wait
        } else {
            Start-Process $installer -ArgumentList $pkg.installArgs -Wait
        }
        Remove-Item $installer -Force
    }
}

function Show-PostInstallSteps {
    $file = Join-Path $root 'packages-manual.json'
    if (-not (Test-Path $file)) { return }
    $packages = Get-Content $file | ConvertFrom-Json
    Write-Host "`n=== Manual steps remaining ===" -ForegroundColor Yellow
    foreach ($pkg in $packages) {
        if ($pkg.postInstall) {
            Write-Host "  - $($pkg.name): $($pkg.postInstall)"
        }
    }
}

function Deploy-ConfigFiles {
    $file = Join-Path $root 'config-files.json'
    if (-not (Test-Path $file)) { return }
    $configs = @(Get-Content $file | ConvertFrom-Json)
    foreach ($cfg in $configs) {
        if (-not $cfg.source) {
            Write-Host "No config file provided yet for $($cfg.app) - skipping" -ForegroundColor DarkGray
            continue
        }
        $src = Join-Path $root $cfg.source
        if (-not (Test-Path $src)) {
            Write-Warning "Config source missing: $($cfg.source) - skipping $($cfg.app)"
            continue
        }
        $dest    = [Environment]::ExpandEnvironmentVariables($cfg.dest)
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Write-Host "Deploying $($cfg.app) config -> $dest" -ForegroundColor Cyan
        Copy-Item $src $dest -Force
    }
}

Install-WingetPackages
Install-ManualPackages
Deploy-ConfigFiles
Show-PostInstallSteps
