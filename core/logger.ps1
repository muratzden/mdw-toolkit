# MDW Toolkit - Logger Core
# PowerShell 5.1 / 7 compatible

Set-StrictMode -Version 2.0

$script:MDW_LogFile = $null
$script:MDW_Verbose = $false
$script:MDW_Quiet = $false

function Initialize-MDWLogger {
    param(
        [string] $LogDirectory,
        [switch] $Verbose,
        [switch] $Quiet
    )

    $script:MDW_Verbose = [bool] $Verbose
    $script:MDW_Quiet = [bool] $Quiet

    if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
        return
    }

    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
    }

    $script:MDW_LogFile = Join-Path $LogDirectory "mdw.log"
}

function Write-MDWLog {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "DEBUG")]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    if ($script:MDW_Quiet -and $Level -ne "ERROR") {
        return
    }

    if ($Level -eq "DEBUG" -and -not $script:MDW_Verbose) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}][{1}] {2}" -f $timestamp, $Level, $Message

    switch ($Level) {
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "DEBUG"   { Write-Host $line -ForegroundColor DarkGray }
        default   { Write-Host $line }
    }

    if (-not [string]::IsNullOrWhiteSpace($script:MDW_LogFile)) {
        Add-Content -LiteralPath $script:MDW_LogFile -Value $line -Encoding UTF8
    }
}

function Write-MDWInfo {
    param([string] $Message)
    Write-MDWLog -Level "INFO" -Message $Message
}

function Write-MDWSuccess {
    param([string] $Message)
    Write-MDWLog -Level "SUCCESS" -Message $Message
}

function Write-MDWWarn {
    param([string] $Message)
    Write-MDWLog -Level "WARN" -Message $Message
}

function Write-MDWError {
    param([string] $Message)
    Write-MDWLog -Level "ERROR" -Message $Message
}

function Write-MDWDebug {
    param([string] $Message)
    Write-MDWLog -Level "DEBUG" -Message $Message
}