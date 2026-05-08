[CmdletBinding()]
param(
    [switch]$Unattended
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# Best-effort manifest refresh before doing anything else.
git -C $root pull --ff-only origin main
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not refresh manifest from origin (git exit $LASTEXITCODE) - continuing with local copy"
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $args = if ($Unattended) { '-Unattended' } else { '' }
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath,$args
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
        $exe = Join-Path $env:TEMP "$($pkg.id).exe"
        Invoke-WebRequest $pkg.url -OutFile $exe -UseBasicParsing
        Start-Process $exe -ArgumentList $pkg.installArgs -Wait
        Remove-Item $exe -Force
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

Install-WingetPackages
Install-ManualPackages
Show-PostInstallSteps
