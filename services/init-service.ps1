<#
MDW Init Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWInitExcludedDirectoryName {
    [CmdletBinding()]
    param(
        [string] $Name
    )

    return $Name -in @(".git", "node_modules", "vendor", "build", "dist")
}

function Copy-MDWInitDirectoryContent {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $TargetPath
    )

    Get-ChildItem -LiteralPath $SourcePath -Force | ForEach-Object {
        $destinationPath = Join-Path $TargetPath $_.Name

        if ($_.PSIsContainer) {
            if (-not (Test-MDWInitExcludedDirectoryName -Name $_.Name)) {
                if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                }

                Copy-MDWInitDirectoryContent -SourcePath $_.FullName -TargetPath $destinationPath
            }
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
        }
    }
}

function Resolve-MDWInitMainPluginFile {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $preferredPluginFile = Join-Path $PluginPath "$PluginSlug.php"

    if (Test-Path -LiteralPath $preferredPluginFile -PathType Leaf) {
        return $preferredPluginFile
    }

    $candidateFiles = Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -File -ErrorAction SilentlyContinue

    foreach ($candidateFile in $candidateFiles) {
        $content = Get-Content -LiteralPath $candidateFile.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "Plugin Name:") {
            Rename-Item -LiteralPath $candidateFile.FullName -NewName "$PluginSlug.php" -Force
            return $preferredPluginFile
        }
    }

    return $preferredPluginFile
}

function Invoke-MDWInitService {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $PluginSlug
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        $errors.Add("Source path is required.")
    }

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $errors.Add("Plugin slug could not be resolved.")
    }

    if ($PluginSlug -and $PluginSlug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $errors.Add("Invalid plugin slug: $PluginSlug. Use lowercase letters, numbers, and single hyphens only.")
    }

    $resolvedSourcePath = $null
    $targetPath = $null
    $mainPluginFile = $null
    $createdTarget = $false

    if ($errors.Count -eq 0) {
        try {
            $resolvedSourcePath = (Resolve-Path -LiteralPath $SourcePath -ErrorAction Stop).ProviderPath
        }
        catch {
            $errors.Add("Source directory not found: $SourcePath")
        }
    }

    if ($errors.Count -eq 0 -and -not (Test-Path -LiteralPath $resolvedSourcePath -PathType Container)) {
        $errors.Add("Source path is not a directory: $resolvedSourcePath")
    }

    if ($errors.Count -eq 0) {
        $targetPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug

        if (Test-Path -LiteralPath $targetPath) {
            $errors.Add("Plugin directory already exists: $targetPath")
        }
    }

    if ($errors.Count -eq 0) {
        try {
            $targetParent = Split-Path -Parent $targetPath

            if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }

            New-Item -ItemType Directory -Path $targetPath -ErrorAction Stop | Out-Null
            $createdTarget = $true

            Copy-MDWInitDirectoryContent -SourcePath $resolvedSourcePath -TargetPath $targetPath

            $mainPluginFile = Resolve-MDWInitMainPluginFile -PluginSlug $PluginSlug -PluginPath $targetPath

            $headerResult = Invoke-MDWPluginHeaderValidator -PluginSlug $PluginSlug -PluginPath $targetPath
            $readmeResult = Invoke-MDWReadmeValidator -PluginSlug $PluginSlug -PluginPath $targetPath

            foreach ($errorItem in $headerResult.Errors) {
                $errors.Add($errorItem)
            }

            foreach ($warning in $headerResult.Warnings) {
                $warnings.Add($warning)
            }

            foreach ($errorItem in $readmeResult.Errors) {
                $errors.Add($errorItem)
            }

            foreach ($warning in $readmeResult.Warnings) {
                $warnings.Add($warning)
            }

            if ($errors.Count -gt 0 -and $createdTarget -and (Test-Path -LiteralPath $targetPath)) {
                Remove-Item -LiteralPath $targetPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            if ($createdTarget -and (Test-Path -LiteralPath $targetPath)) {
                Remove-Item -LiteralPath $targetPath -Recurse -Force -ErrorAction SilentlyContinue
            }

            $errors.Add($_.Exception.Message)
        }
    }

    return @{
        Passed         = ($errors.Count -eq 0)
        ErrorCount     = $errors.Count
        WarningCount   = $warnings.Count
        Errors         = @($errors.ToArray())
        Warnings       = @($warnings.ToArray())
        SourcePath     = $resolvedSourcePath
        TargetPath     = $targetPath
        PluginSlug     = $PluginSlug
        MainPluginFile = $mainPluginFile
    }
}
