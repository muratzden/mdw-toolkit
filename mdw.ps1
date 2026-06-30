param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [string]$Name,
    [string]$Slug
)

$Root = "C:\Workspace\mdw-toolkit"
$Scripts = Join-Path $Root "Scripts"

switch ($Command) {
    "new-plugin" {
        & "$Scripts\new-plugin.ps1" -Name $Name -Slug $Slug
    }

    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Available commands: new-plugin"
        exit 1
    }
}
