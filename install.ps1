<#
MDW Toolkit Installer
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

$toolkitRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $toolkitRoot "mdw.ps1"))) {
    Write-Host "[MDW INSTALL ERROR] mdw.ps1 not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $toolkitRoot "mdw.cmd"))) {
    Write-Host "[MDW INSTALL ERROR] mdw.cmd not found." -ForegroundColor Red
    exit 1
}

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

$paths = $currentPath -split ";"

if ($paths -contains $toolkitRoot) {
    Write-Host "[MDW INSTALL] PATH already contains: $toolkitRoot" -ForegroundColor Yellow
}
else {
    $newPath = if ([string]::IsNullOrWhiteSpace($currentPath)) {
        $toolkitRoot
    }
    else {
        "$currentPath;$toolkitRoot"
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

    Write-Host "[MDW INSTALL] Added to user PATH:" -ForegroundColor Green
    Write-Host $toolkitRoot
}

Write-Host ""
Write-Host "[MDW INSTALL] Installation completed." -ForegroundColor Green
Write-Host "Close and reopen PowerShell, then run:"
Write-Host ""
Write-Host "mdw version" -ForegroundColor Cyan