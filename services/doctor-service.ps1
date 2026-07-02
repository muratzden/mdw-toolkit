<#
MDW Doctor Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWDoctorService {
    [CmdletBinding()]
    param()

    $toolkitRoot = Get-MDWRootPath
    $validatorResult = Invoke-MDWEnvironmentValidator -ToolkitRoot $toolkitRoot
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $checks = New-Object System.Collections.Generic.List[object]

    foreach ($errorItem in $validatorResult.Errors) {
        $errors.Add($errorItem)
    }

    foreach ($warning in $validatorResult.Warnings) {
        $warnings.Add($warning)
    }

    foreach ($check in $validatorResult.Checks) {
        $checks.Add($check)
    }

    if (Get-Command Invoke-MDWPluginCheck -ErrorAction SilentlyContinue) {
        $checks.Add(@{ Name = "MDW Internal Plugin Check Service"; Passed = $true; Message = "MDW Internal Plugin Check Service available"; Severity = "Info" })
    }
    else {
        $message = "MDW Internal Plugin Check Service is not available."
        $errors.Add($message)
        $checks.Add(@{ Name = "MDW Internal Plugin Check Service"; Passed = $false; Message = $message; Severity = "Error" })
    }

    $localWPReport = Get-MDWLocalWPReport

    foreach ($localCheck in $localWPReport.Checks) {
        $severity = if ($localCheck.Passed) { "Info" } else { "Warning" }

        if (-not $localCheck.Passed) {
            $warnings.Add($localCheck.Message)
        }

        $checks.Add(@{
            Name     = $localCheck.Name
            Passed   = $localCheck.Passed
            Message  = $localCheck.Message
            Severity = $severity
        })
    }

    $gitStatus = Get-MDWGitStatus -RepositoryPath $toolkitRoot

    if (-not $gitStatus.Available) {
        $message = "Git is not installed or not available in PATH."
        $errors.Add($message)
        $checks.Add(@{ Name = "Git Installed"; Passed = $false; Message = $message; Severity = "Error" })
    }
    else {
        $checks.Add(@{ Name = "Git Installed"; Passed = $true; Message = "Git command is available."; Severity = "Info" })

        if ($gitStatus.Repository) {
            $checks.Add(@{ Name = "Repository"; Passed = $true; Message = "Git repository detected: $($gitStatus.RepositoryName)"; Severity = "Info" })
        }
        else {
            $message = "Not a Git repository."
            $warnings.Add($message)
            $checks.Add(@{ Name = "Repository"; Passed = $false; Message = $message; Severity = "Warning" })
        }

        if ($gitStatus.Remote) {
            $checks.Add(@{ Name = "Remote"; Passed = $true; Message = $gitStatus.Remote; Severity = "Info" })
        }
        else {
            $message = "Git remote is not configured."
            $warnings.Add($message)
            $checks.Add(@{ Name = "Remote"; Passed = $false; Message = $message; Severity = "Warning" })
        }

        if ($gitStatus.Branch) {
            $checks.Add(@{ Name = "Branch"; Passed = $true; Message = $gitStatus.Branch; Severity = "Info" })
        }
        else {
            $message = "Git branch could not be resolved."
            $warnings.Add($message)
            $checks.Add(@{ Name = "Branch"; Passed = $false; Message = $message; Severity = "Warning" })
        }

        if ($gitStatus.Repository -and $gitStatus.Clean) {
            $checks.Add(@{ Name = "Working Tree"; Passed = $true; Message = "Working tree is clean."; Severity = "Info" })
        }
        elseif ($gitStatus.Repository) {
            $message = "Working tree has changes."
            $warnings.Add($message)
            $checks.Add(@{ Name = "Working Tree"; Passed = $false; Message = $message; Severity = "Warning" })
        }
    }

    return @{
        Passed       = ($errors.Count -eq 0)
        ErrorCount   = $errors.Count
        WarningCount = $warnings.Count
        Errors       = @($errors.ToArray())
        Warnings     = @($warnings.ToArray())
        Checks       = @($checks.ToArray())
        ToolkitRoot  = $toolkitRoot
        Git          = $gitStatus
        LocalWP      = $localWPReport
    }
}
