<#
MDW Lint Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWPhpVersion {
    [CmdletBinding()]
    param()

    if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $version = & php -r "echo PHP_VERSION;" 2>$null
        return [string]$version
    }
    catch {
        return $null
    }
}

function Invoke-MDWPhpLintFile {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    $output = @(& php -l $Path 2>&1)
    $message = ($output | ForEach-Object { [string]$_ }) -join " "

    if ($LASTEXITCODE -eq 0) {
        return @{
            Path    = $Path
            Status  = "OK"
            Message = ("OK: {0}" -f $Path)
            Output  = $message
        }
    }

    return @{
        Path    = $Path
        Status  = "FAIL"
        Message = ("FAIL: {0}" -f $Path)
        Output  = $message
    }
}

function Invoke-MDWLintService {
    [CmdletBinding()]
    param(
        [string] $PluginPath,
        [string] $PluginSlug
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $files = New-Object System.Collections.Generic.List[object]
    $phpVersion = Get-MDWPhpVersion

    if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
        $message = "PHP is not installed or not available in PATH."
        $errors.Add($message)
        $files.Add(@{ Path = $null; Status = "FAIL"; Message = $message; Output = "" })

        return @{
            Passed     = $false
            ErrorCount = $errors.Count
            Errors     = @($errors.ToArray())
            Files      = @($files.ToArray())
            FileCount  = 0
            PluginPath = $PluginPath
            PhpVersion = "Not available"
        }
    }

    if ([string]::IsNullOrWhiteSpace($PluginPath)) {
        if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
            $errors.Add("Plugin path or plugin slug is required.")
        }
        else {
            $PluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting
        }
    }

    if ($errors.Count -eq 0 -and -not (Test-Path -LiteralPath $PluginPath -PathType Container)) {
        $errors.Add("Plugin path not found: $PluginPath")
    }

    if ($errors.Count -gt 0) {
        foreach ($errorItem in $errors) {
            $files.Add(@{ Path = $null; Status = "FAIL"; Message = $errorItem; Output = "" })
        }

        return @{
            Passed     = $false
            ErrorCount = $errors.Count
            Errors     = @($errors.ToArray())
            Files      = @($files.ToArray())
            FileCount  = 0
            PluginPath = $PluginPath
            PhpVersion = $phpVersion
        }
    }

    $phpFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -Recurse -File -ErrorAction SilentlyContinue)

    foreach ($phpFile in $phpFiles) {
        $lintResult = Invoke-MDWPhpLintFile -Path $phpFile.FullName
        $files.Add($lintResult)

        if ($lintResult.Status -eq "FAIL") {
            $errors.Add($lintResult.Output)
        }
    }

    return @{
        Passed     = ($errors.Count -eq 0)
        ErrorCount = $errors.Count
        Errors     = @($errors.ToArray())
        Files      = @($files.ToArray())
        FileCount  = $phpFiles.Count
        PluginPath = $PluginPath
        PhpVersion = $phpVersion
    }
}
