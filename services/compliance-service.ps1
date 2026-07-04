<#
MDW Compliance Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWComplianceValidatorFiles {
    [CmdletBinding()]
    param()

    $validatorRoot = Join-Path (Join-Path (Get-MDWRootPath) "validators") "compliance"

    if (-not (Test-Path -LiteralPath $validatorRoot -PathType Container)) {
        return @()
    }

    $files = Get-ChildItem -LiteralPath $validatorRoot -Filter "*.ps1" -File -ErrorAction SilentlyContinue | Sort-Object Name
    return @($files | Select-Object -ExpandProperty FullName)
}

function New-MDWComplianceResult {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [object[]] $Findings
    )

    $safeFindings = @($Findings)
    $failed = @($safeFindings | Where-Object { $_.Severity -eq "Error" -or $_.Status -eq "FAIL" }).Count
    $warnings = @($safeFindings | Where-Object { $_.Severity -eq "Warning" -or $_.Status -eq "WARN" }).Count

    return @{
        Passed         = ($failed -eq 0)
        Failed         = $failed
        Warnings       = $warnings
        Findings       = $safeFindings
        PluginSlug     = $PluginSlug
        PluginPath     = $PluginPath
        ExpectedPrefix = $ExpectedPrefix
    }
}

function Resolve-MDWComplianceScope {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $resolvedSlug = $PluginSlug
    $resolvedPath = $PluginPath

    if (-not [string]::IsNullOrWhiteSpace($resolvedPath)) {
        if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
            $resolvedPath = (Resolve-Path -LiteralPath $resolvedPath).ProviderPath
        }

        if ([string]::IsNullOrWhiteSpace($resolvedSlug)) {
            $resolvedSlug = Split-Path -Path $resolvedPath -Leaf
        }
    }
    else {
        $resolvedPath = Resolve-MDWPluginPath -PluginSlug $resolvedSlug
    }

    return @{
        PluginSlug = $resolvedSlug
        PluginPath = $resolvedPath
    }
}

function New-MDWComplianceFixResult {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [bool] $WhatIf,
        [string] $BackupPath,
        [object[]] $Changes,
        [object[]] $Skipped,
        [object] $Validation
    )

    $safeChanges = @($Changes)
    $safeSkipped = @($Skipped)
    $replacementCount = 0

    foreach ($change in $safeChanges) {
        $replacementCount += [int] $change.ReplacementCount
    }

    return @{
        Passed           = ($null -ne $Validation -and $Validation.Failed -eq 0)
        WhatIf           = $WhatIf
        BackupPath       = $BackupPath
        ChangedFiles      = @($safeChanges)
        ChangedFileCount  = $safeChanges.Count
        ReplacementCount  = $replacementCount
        Skipped           = @($safeSkipped)
        SkippedCount      = $safeSkipped.Count
        Validation        = $Validation
        PluginSlug        = $PluginSlug
        PluginPath        = $PluginPath
        ExpectedPrefix    = $ExpectedPrefix
    }
}

function New-MDWComplianceBackup {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = $null

    try {
        $pluginsRoot = Get-MDWPluginsPath

        if ($PluginPath.StartsWith($pluginsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $backupRoot = Get-MDWBackupPluginPath -PluginSlug $PluginSlug
        }
    }
    catch {
        $backupRoot = $null
    }

    if ([string]::IsNullOrWhiteSpace($backupRoot)) {
        $backupRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) "mdw-compliance-backups") $PluginSlug
    }

    $backupPath = Join-Path $backupRoot ("prefix-fix-{0}" -f $timestamp)

    if (-not (Test-Path -LiteralPath $backupPath -PathType Container)) {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    }

    Get-ChildItem -LiteralPath $PluginPath -Force -ErrorAction Stop | Where-Object {
        $_.Name -notin @(".git", "node_modules", "vendor", "build", "dist", ".DS_Store")
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $backupPath -Recurse -Force -ErrorAction Stop
    }

    return $backupPath
}

function Invoke-MDWComplianceService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix
    )

    foreach ($validatorFile in (Get-MDWComplianceValidatorFiles)) {
        . $validatorFile
    }

    $scope = Resolve-MDWComplianceScope -PluginSlug $PluginSlug -PluginPath $PluginPath
    $findings = New-Object System.Collections.Generic.List[object]

    if (-not (Get-Command Invoke-MDWComplianceValidator -ErrorAction SilentlyContinue)) {
        $findings.Add(@{
            Rule             = "Compliance.Validator"
            Severity         = "Error"
            Status           = "FAIL"
            Message          = "Compliance validator is not available."
            File             = $null
            Line             = $null
            CurrentValue     = $null
            RecommendedValue = $null
        })

        return New-MDWComplianceResult -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath -ExpectedPrefix $ExpectedPrefix -Findings @($findings.ToArray())
    }

    $validatorResult = Invoke-MDWComplianceValidator -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath

    foreach ($finding in @($validatorResult.Findings)) {
        $findings.Add($finding)
    }

    if (Get-Command Invoke-MDWCompliancePrefixValidator -ErrorAction SilentlyContinue) {
        $prefixResult = Invoke-MDWCompliancePrefixValidator `
            -PluginSlug $scope.PluginSlug `
            -PluginPath $scope.PluginPath `
            -ExpectedPrefix $ExpectedPrefix

        foreach ($finding in @($prefixResult.Findings)) {
            $findings.Add($finding)
        }
    }

    return New-MDWComplianceResult -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath -ExpectedPrefix $ExpectedPrefix -Findings @($findings.ToArray())
}

function Invoke-MDWComplianceFixService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedPrefix)) {
        throw "Prefix is required for compliance fix."
    }

    foreach ($validatorFile in (Get-MDWComplianceValidatorFiles)) {
        . $validatorFile
    }

    if (-not (Get-Command Invoke-MDWCompliancePrefixFixer -ErrorAction SilentlyContinue)) {
        throw "Compliance prefix fixer is not available."
    }

    $scope = Resolve-MDWComplianceScope -PluginSlug $PluginSlug -PluginPath $PluginPath
    $backupPath = $null

    if (-not $WhatIf) {
        $backupPath = New-MDWComplianceBackup -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath
    }

    $fixResult = Invoke-MDWCompliancePrefixFixer `
        -PluginSlug $scope.PluginSlug `
        -PluginPath $scope.PluginPath `
        -ExpectedPrefix $ExpectedPrefix `
        -WhatIf:$WhatIf

    $validation = Invoke-MDWComplianceService `
        -PluginSlug $scope.PluginSlug `
        -PluginPath $scope.PluginPath `
        -ExpectedPrefix $ExpectedPrefix

    return New-MDWComplianceFixResult `
        -PluginSlug $scope.PluginSlug `
        -PluginPath $scope.PluginPath `
        -ExpectedPrefix $ExpectedPrefix `
        -WhatIf ([bool] $WhatIf) `
        -BackupPath $backupPath `
        -Changes @($fixResult.ChangedFiles) `
        -Skipped @($fixResult.Skipped) `
        -Validation $validation
}
