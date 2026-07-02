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

        "Git" { return "Tools" }
        "PHP" { return "Tools" }
        "Composer" { return "Tools" }
        "SVN" { return "Tools" }
        "WordPress Plugin Check CLI" { return "Tools" }

        "mdw.json" { return "Workspace" }
        "Backup directory" { return "Workspace" }
        "MDW Internal Plugin Check Service" { return "Workspace" }

        "Plugins directory" {
    if ($message -match "C:\\Workspace\\Plugins|exists") {
        return "Workspace"
    }

    return "Skip"
}

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
    $category = Get-MDWDoctorCategory -Check $Check

    switch -Wildcard ($name) {
        "Git" { return "Git" }
        "PHP" { return "PHP" }
        "Composer" { return "Composer" }
        "SVN" { return "SVN" }
        "WordPress Plugin Check CLI" { return "WP Plugin Check CLI" }

        "mdw.json" { return "mdw.json" }
        "Backup directory" { return "Backup directory" }
        "MDW Internal Plugin Check Service" { return "Internal plugin check" }

        "Plugins directory" {
            if ($category -eq "LocalWP") {
                return "LocalWP plugins directory"
            }

            return "Plugins directory"
        }

        "LocalWP root" { return "LocalWP root" }
        "Default site" { return "Default LocalWP site" }

        "Repository" { return "Repository" }
        "Remote" { return "Remote" }
        "Branch" { return "Branch" }
        "Working Tree" { return "Working tree" }

        default {
            return $name
        }
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

    $toolsChecks = @()
    $workspaceChecks = @()
    $localChecks = @()
    $gitChecks = @()

    foreach ($check in $result.Checks) {
        $category = Get-MDWDoctorCategory -Check $check

        switch ($category) {
            "Tools" {
                $toolsChecks += $check
            }
            "Workspace" {
                $workspaceChecks += $check
            }
            "LocalWP" {
                $localChecks += $check
            }
            "Git" {
                $gitChecks += $check
            }
        }
    }

    Write-MDWHeader `
        -Title "MDW Toolkit" `
        -Subtitle "Development Environment"

    Write-MDWDoctorGroup -Title "Tools" -Checks $toolsChecks
	$workspaceChecks = $workspaceChecks | Sort-Object @{
    Expression = {
        switch ($_.Name) {
            "mdw.json" { 1 }
            "Plugins directory" { 2 }
            "Backup directory" { 3 }
            "MDW Internal Plugin Check Service" { 4 }
            default { 99 }
        }
    }
}
    Write-MDWDoctorGroup -Title "Workspace" -Checks $workspaceChecks
    Write-MDWDoctorGroup -Title "LocalWP" -Checks $localChecks
	$gitChecks = $gitChecks | Sort-Object @{
    Expression = {
        switch ($_.Name) {
            "Repository" { 1 }
            "Remote" { 2 }
            "Branch" { 3 }
            "Working Tree" { 4 }
            default { 99 }
        }
    }
}
    Write-MDWDoctorGroup -Title "Git" -Checks $gitChecks

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