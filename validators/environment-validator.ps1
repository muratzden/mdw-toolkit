<#
MDW Environment Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWEnvironmentCommand {
    [CmdletBinding()]
    param(
        [string] $CommandName
    )

    return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function New-MDWEnvironmentCheckResult {
    [CmdletBinding()]
    param(
        [string] $Name,
        [bool] $Passed,
        [string] $Message,
        [string] $Severity
    )

    return @{
        Name     = $Name
        Passed   = $Passed
        Message  = $Message
        Severity = $Severity
    }
}

function Test-MDWWordPressPluginCheckCli {
    [CmdletBinding()]
    param()

    if (-not (Test-MDWEnvironmentCommand -CommandName "wp")) {
        return $false
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    try {
        & wp plugin check --help *> $null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Invoke-MDWEnvironmentValidator {
    [CmdletBinding()]
    param(
        [string] $ToolkitRoot
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $checks = New-Object System.Collections.Generic.List[object]

    $commandChecks = @(
        @{ Name = "Git"; Command = "git"; Message = "git command is available."; Missing = "Git is not installed or not available in PATH." }
        @{ Name = "PHP"; Command = "php"; Message = "php command is available."; Missing = "PHP was not found in PATH." }
        @{ Name = "Composer"; Command = "composer"; Message = "composer command is available."; Missing = "Composer was not found in PATH." }
        @{ Name = "SVN"; Command = "svn"; Message = "svn command is available."; Missing = "SVN was not found in PATH." }
    )

    foreach ($commandCheck in $commandChecks) {
        $commandExists = Test-MDWEnvironmentCommand -CommandName $commandCheck.Command

        if ($commandExists) {
            $checks.Add((New-MDWEnvironmentCheckResult -Name $commandCheck.Name -Passed $true -Message $commandCheck.Message -Severity "Info"))
        }
        else {
            $warnings.Add($commandCheck.Missing)
            $checks.Add((New-MDWEnvironmentCheckResult -Name $commandCheck.Name -Passed $false -Message $commandCheck.Missing -Severity "Warning"))
        }
    }

    $pluginCheckAvailable = Test-MDWWordPressPluginCheckCli

    if ($pluginCheckAvailable) {
        $checks.Add((New-MDWEnvironmentCheckResult -Name "WordPress Plugin Check CLI" -Passed $true -Message "wp plugin check command is available." -Severity "Info"))
    }
    else {
        $pluginCheckMessage = "WordPress Plugin Check CLI was not found or wp plugin check is not available."
        $warnings.Add($pluginCheckMessage)
        $checks.Add((New-MDWEnvironmentCheckResult -Name "WordPress Plugin Check CLI" -Passed $false -Message $pluginCheckMessage -Severity "Warning"))
    }

    $pluginsPath = Get-MDWPluginsPath
    $backupPath = Get-MDWBackupPath

    $pathChecks = @(
        @{ Name = "Plugins directory"; Path = $pluginsPath; Missing = "Plugins directory not found: $pluginsPath" }
        @{ Name = "Backup directory"; Path = $backupPath; Missing = "Backup directory not found: $backupPath" }
    )

    foreach ($pathCheck in $pathChecks) {
        if (Test-Path -LiteralPath $pathCheck.Path -PathType Container) {
            $checks.Add((New-MDWEnvironmentCheckResult -Name $pathCheck.Name -Passed $true -Message "$($pathCheck.Path) exists." -Severity "Info"))
        }
        else {
            $warnings.Add($pathCheck.Missing)
            $checks.Add((New-MDWEnvironmentCheckResult -Name $pathCheck.Name -Passed $false -Message $pathCheck.Missing -Severity "Warning"))
        }
    }

    try {
        if ([string]::IsNullOrWhiteSpace($ToolkitRoot)) {
            throw "Toolkit root could not be resolved."
        }

        $config = Get-MDWConfig -ToolkitRoot $ToolkitRoot
        $checks.Add((New-MDWEnvironmentCheckResult -Name "mdw.json" -Passed $true -Message "MDW config is readable: $($config._path)" -Severity "Info"))
    }
    catch {
        $configMessage = "MDW config could not be read. $($_.Exception.Message)"
        $errors.Add($configMessage)
        $checks.Add((New-MDWEnvironmentCheckResult -Name "mdw.json" -Passed $false -Message $configMessage -Severity "Error"))
    }

    return @{
        Passed   = ($errors.Count -eq 0)
        Errors   = @($errors.ToArray())
        Warnings = @($warnings.ToArray())
        Checks   = @($checks.ToArray())
    }
}
