<#
MDW Doctor Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWDoctorStatus {
    param([Parameter(Mandatory = $true)][object] $Check)

    if ($Check.Passed) {
        return "OK"
    }

    if ($Check.Severity -eq "Error") {
        return "FAIL"
    }

    return "WARN"
}

function Get-MDWDoctorCategory {
    param([Parameter(Mandatory = $true)][object] $Check)

    $name = [string]$Check.Name
    $message = [string]$Check.Message

    switch -Wildcard ($name) {
        "Git Installed" { return "Skip" }

        "Git" { return "Core" }
        "PHP" { return "Environment" }
        "WP-CLI" { return "Environment" }
        "Composer" { return "Environment" }
        "SVN" { return "Environment" }
        "WordPress Plugin Check CLI" { return "Plugin Check" }

        "mdw.json" { return "Workspace" }
        "Workspace root" { return "Workspace" }
        "Plugins directory" {
            if ($message -notmatch "C:\\Workspace\\Plugins") {
                return "LocalWP"
            }

            return "Workspace"
        }
        "Build directory" { return "Workspace" }
        "Releases directory" { return "Workspace" }
        "Backup directory" { return "Workspace" }
        "Laragon directory" { return "Workspace" }
        "MDW Internal Plugin Check Service" { return "Plugin Check" }

        "LocalWP root" { return "LocalWP" }
        "Default site" { return "LocalWP" }

        "Repository" { return "Git" }
        "Remote" { return "Git" }
        "Branch" { return "Git" }
        "Working Tree" { return "Git" }

        default { return "Skip" }
    }
}

function Get-MDWDoctorMessage {
    param([Parameter(Mandatory = $true)][object] $Check)

    $name = [string]$Check.Name
    $message = [string]$Check.Message

    switch -Wildcard ($name) {
        "Git" { return "Git" }
        "PHP" { return ("PHP {0}" -f $message) }
        "WP-CLI" { return $message }
        "Composer" { return "Composer" }
        "SVN" { return "SVN" }
        "WordPress Plugin Check CLI" { return "WP Plugin Check CLI" }

        "mdw.json" { return "mdw.json" }
        "Workspace root" { return "Workspace root" }
        "Plugins directory" {
            if ($message -notmatch "C:\\Workspace\\Plugins") {
                return "LocalWP plugins directory"
            }

            return "Plugins directory"
        }
        "Build directory" { return "Build directory" }
        "Releases directory" { return "Releases directory" }
        "Backup directory" { return "Backup directory" }
        "Laragon directory" { return "Laragon directory" }
        "MDW Internal Plugin Check Service" { return "Internal plugin check" }

        "LocalWP root" { return "LocalWP root" }
        "Default site" { return "Default LocalWP site" }

        "Repository" { return "Repository" }
        "Remote" { return "Remote" }
        "Branch" { return "Branch" }
        "Working Tree" { return "Working tree" }

        default { return $name }
    }
}

function Write-MDWDoctorGroup {
    param(
        [Parameter(Mandatory = $true)][string] $Title,
        [Parameter(Mandatory = $true)][array] $Checks
    )

    if (-not $Checks -or $Checks.Count -eq 0) {
        return
    }

    Write-MDWSection -Title $Title

    foreach ($check in $Checks) {
        Write-MDWStatus `
            -Status (Get-MDWDoctorStatus -Check $check) `
            -Message (Get-MDWDoctorMessage -Check $check)
    }
}

function Invoke-MDWDoctor {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $result = Invoke-MDWDoctorService

    $coreChecks = @()
    $environmentChecks = @()
    $workspaceChecks = @()
    $localChecks = @()
    $gitChecks = @()
    $pluginCheckChecks = @()

    foreach ($check in $result.Checks) {
        $category = Get-MDWDoctorCategory -Check $check

        switch ($category) {
            "Core" { $coreChecks += $check }
            "Environment" { $environmentChecks += $check }
            "Workspace" { $workspaceChecks += $check }
            "LocalWP" { $localChecks += $check }
            "Git" { $gitChecks += $check }
            "Plugin Check" { $pluginCheckChecks += $check }
        }
    }

    Write-MDWHeader `
        -Title "MDW Toolkit" `
        -Subtitle "Development Environment"

    Write-MDWDoctorGroup -Title "Core" -Checks $coreChecks
    Write-MDWDoctorGroup -Title "Environment" -Checks $environmentChecks
    Write-MDWDoctorGroup -Title "Workspace" -Checks $workspaceChecks
    Write-MDWDoctorGroup -Title "Git" -Checks $gitChecks
    Write-MDWDoctorGroup -Title "LocalWP" -Checks $localChecks
    Write-MDWDoctorGroup -Title "Plugin Check" -Checks $pluginCheckChecks

    if ($result.ErrorCount -gt 0) {
        Write-MDWResult `
            -Status "FAIL" `
            -Message ("Environment has {0} errors and {1} warnings." -f $result.ErrorCount, $result.WarningCount)

        return
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWResult `
            -Status "WARN" `
            -Message ("Environment ready with {0} warnings." -f $result.WarningCount)

        return
    }

    Write-MDWResult `
        -Status "OK" `
        -Message "Environment ready."
}



