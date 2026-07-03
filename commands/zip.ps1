<#
MDW ZIP Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWZipDisplaySize {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "0 KB"
    }

    $length = (Get-Item -LiteralPath $Path).Length

    if ($length -lt 1MB) {
        return ("{0:N0} KB" -f [math]::Max(1, [math]::Ceiling($length / 1KB)))
    }

    return ("{0:N2} MB" -f ($length / 1MB))
}

function New-MDWZipPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceDirectory,

        [Parameter(Mandatory = $true)]
        [string] $DestinationZip,

        [Parameter(Mandatory = $true)]
        [string] $RootFolderName
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    if (Test-Path -LiteralPath $DestinationZip -PathType Leaf) {
        Remove-Item -LiteralPath $DestinationZip -Force
    }

    $destinationDirectory = Split-Path -Parent $DestinationZip

    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }

    $zipStream = [System.IO.File]::Open(
        $DestinationZip,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )

    try {
        $archive = New-Object System.IO.Compression.ZipArchive(
            $zipStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )

        try {
            $sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path.TrimEnd('\', '/')
            $files = Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force

            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
                $entryName = ($RootFolderName + "/" + $relativePath.Replace('\', '/')).TrimStart('/')

                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $archive,
                    $file.FullName,
                    $entryName,
                    [System.IO.Compression.CompressionLevel]::Optimal
                ) | Out-Null
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $zipStream.Dispose()
    }
}

function Invoke-MDWZip {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    if (-not $pluginSlug) {
        $currentPath = Get-Location
        $pluginSlug = Split-Path $currentPath -Leaf
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "ZIP Package"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    $buildPath = Get-MDWBuildPluginPath -PluginSlug $pluginSlug
    $releasePluginRoot = Get-MDWReleasePluginPath -PluginSlug $pluginSlug
    $zipPath = Join-Path $releasePluginRoot "$pluginSlug.zip"

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Validate build directory"

    if (-not (Test-Path -LiteralPath $buildPath -PathType Container)) {
        Write-MDWResult -Status "FAIL" -Message "Build directory not found. Run first: mdw build $pluginSlug"
        return
    }

    $buildItems = @(Get-ChildItem -LiteralPath $buildPath -Force)

    if ($buildItems.Count -eq 0) {
        Write-MDWResult -Status "FAIL" -Message "Build directory is empty: $buildPath"
        return
    }

    Write-MDWStatus -Status "INFO" -Message "Create ZIP package"

    try {
        New-MDWZipPackage `
            -SourceDirectory $buildPath `
            -DestinationZip $zipPath `
            -RootFolderName $pluginSlug

        Write-MDWStatus -Status "OK" -Message "ZIP package created"

        Write-MDWSection -Title "Output"
        Write-MDWInfoCard -Label "ZIP" -Value $zipPath
        Write-MDWInfoCard -Label "Size" -Value (Get-MDWZipDisplaySize -Path $zipPath)

        Write-MDWResult -Status "OK" -Message "ZIP package created."
    }
    catch {
        Write-MDWResult -Status "FAIL" -Message $_.Exception.Message
    }
}