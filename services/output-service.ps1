<#
MDW Output Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Write-MDWTitle {
    param([string] $Text)

    Write-Host ""
    Write-Host ("=" * 38) -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host ("=" * 38) -ForegroundColor Cyan
    Write-Host ""
}

function Write-MDWSection {
    param([string] $Text)

    Write-Host ""
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("-" * $Text.Length) -ForegroundColor Cyan
}

function Write-MDWInfo {
    param([string] $Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-MDWSuccess {
    param([string] $Message)

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-MDWWarning {
    param([string] $Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-MDWError {
    param([string] $Message)

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-MDWSummary {
    param(
        [int] $Failed,
        [int] $Warnings
    )

    Write-MDWSection "Validate Summary"

    Write-Host "Failed   : $Failed"
    Write-Host "Warnings : $Warnings"
    Write-Host ""

    if ($Failed -gt 0) {
        Write-Host "Result   : FAILED" -ForegroundColor Red
        return
    }

    if ($Warnings -gt 0) {
        Write-Host "Result   : PASSED WITH WARNINGS" -ForegroundColor Yellow
        return
    }

    Write-Host "Result   : PASSED" -ForegroundColor Green
}