<#
MDW WordPress.org SVN Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWSvnInstalled {
    [CmdletBinding()]
    param()

    return $null -ne (Get-Command svn -ErrorAction SilentlyContinue)
}

function ConvertTo-MDWSvnArgument {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if ($null -eq $Value) {
        return '""'
    }

    if ($Value -match '[\s"]') {
        return '"' + ($Value -replace '"', '\"') + '"'
    }

    return $Value
}

function Invoke-MDWSvn {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $WorkingDirectory,
        [switch] $AllowFailure
    )

    $svnCommand = Get-Command svn -ErrorAction SilentlyContinue

    if ($null -eq $svnCommand) {
        throw "SVN is not installed or not available in PATH."
    }

    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $svnCommand.Source
    $process.StartInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-MDWSvnArgument -Value $_ }) -join " ")
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true

    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
    }

    [void] $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    $output = @()
    $errorOutput = @()

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        $output = @($stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        $errorOutput = @($stderr -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    $result = @{
        Passed           = ($process.ExitCode -eq 0)
        ExitCode         = $process.ExitCode
        Output           = $output
        Error            = $errorOutput
        WorkingDirectory = $WorkingDirectory
        Command          = ("svn " + ($Arguments -join " "))
    }

    if (-not $result.Passed -and -not $AllowFailure) {
        $message = ($errorOutput -join " ").Trim()

        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = "SVN command failed: $($result.Command)"
        }

        throw $message
    }

    return $result
}

function Get-MDWSvnVersion {
    [CmdletBinding()]
    param()

    if (-not (Test-MDWSvnInstalled)) {
        return $null
    }

    $result = Invoke-MDWSvn -Arguments @("--version", "--quiet") -AllowFailure

    if ($result.Passed -and $result.Output.Count -gt 0) {
        return [string] $result.Output[0]
    }

    return $null
}

function Get-MDWWpOrgConfig {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $config = Get-MDWConfig -ToolkitRoot (Get-MDWToolkitPath)
    $enabled = [bool] (Get-MDWConfigValue -Config $config -Key "wordpressOrg.enabled" -DefaultValue $false)
    $slug = Get-MDWConfigValue -Config $config -Key "wordpressOrg.slug" -DefaultValue (Get-MDWConfigValue -Config $config -Key "plugin.slug" -DefaultValue $PluginSlug)

    if (-not [string]::IsNullOrWhiteSpace($PluginSlug)) {
        $slug = $PluginSlug
    }

    if ([string]::IsNullOrWhiteSpace([string] $slug)) {
        throw "WordPress.org plugin slug is not configured."
    }

    $name = Get-MDWConfigValue -Config $config -Key "plugin.name" -DefaultValue $slug
    $entryFile = Get-MDWConfigValue -Config $config -Key "plugin.entryFile" -DefaultValue ("{0}.php" -f $slug)
    $svnUrl = Get-MDWConfigValue -Config $config -Key "wordpressOrg.svnUrl" -DefaultValue ("https://plugins.svn.wordpress.org/{0}" -f $slug)
    $assetsSource = Get-MDWConfigValue -Config $config -Key "wordpressOrg.assetsSource" -DefaultValue "wordpress-org-assets"
    $sourcePath = Get-MDWPluginPath -PluginSlug $slug
    $workingCopyPath = Get-MDWSvnPath -PluginSlug $slug

    return @{
        Enabled         = $enabled
        Slug            = [string] $slug
        Name            = [string] $name
        EntryFile       = [string] $entryFile
        SvnUrl          = [string] $svnUrl
        AssetsSource    = [string] $assetsSource
        SourcePath      = $sourcePath
        WorkingCopyPath = $workingCopyPath
        TrunkPath       = Join-Path $workingCopyPath "trunk"
        AssetsPath      = Join-Path $workingCopyPath "assets"
        TagsPath        = Join-Path $workingCopyPath "tags"
        BuildPath       = Get-MDWBuildPluginPath -PluginSlug $slug
        ReleasePath     = Get-MDWReleasePluginPath -PluginSlug $slug
        ZipPath         = Join-Path (Get-MDWReleasePluginPath -PluginSlug $slug) ("{0}.zip" -f $slug)
    }
}

function Get-MDWSvnFileHeaderValue {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Header
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $null
    }

    $escapedHeader = [regex]::Escape($Header)

    if ($Content -match "(?mi)^\s*(?:\*\s*)?$escapedHeader\s*:\s*(.+?)\s*$") {
        return $matches[1].Trim()
    }

    return $null
}

function Get-MDWSvnReadmeFieldValue {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Field
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $null
    }

    $escapedField = [regex]::Escape($Field)

    if ($Content -match "(?mi)^\s*$escapedField\s*:\s*(.+?)\s*$") {
        return $matches[1].Trim()
    }

    return $null
}

function Get-MDWSvnPluginMetadata {
    [CmdletBinding()]
    param(
        [object] $WpOrg
    )

    $mainFile = Join-Path $WpOrg.SourcePath $WpOrg.EntryFile
    $readmePath = Join-Path $WpOrg.SourcePath "readme.txt"
    $version = $null
    $textDomain = $null
    $stableTag = $null

    if (Test-Path -LiteralPath $mainFile -PathType Leaf) {
        $mainContent = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue
        $version = Get-MDWSvnFileHeaderValue -Content $mainContent -Header "Version"
        $textDomain = Get-MDWSvnFileHeaderValue -Content $mainContent -Header "Text Domain"
    }

    if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
        $readmeContent = Get-Content -LiteralPath $readmePath -Raw -ErrorAction SilentlyContinue
        $stableTag = Get-MDWSvnReadmeFieldValue -Content $readmeContent -Field "Stable tag"
    }

    return @{
        MainFile         = $mainFile
        ReadmePath       = $readmePath
        Version          = $version
        TextDomain       = $textDomain
        StableTag        = $stableTag
        ExpectedTagPath  = if ([string]::IsNullOrWhiteSpace($stableTag)) { $null } else { Join-Path $WpOrg.TagsPath $stableTag }
        VersionMatchesStableTag = (-not [string]::IsNullOrWhiteSpace($version) -and $version -eq $stableTag)
    }
}

function Test-MDWSvnWorkingCopy {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    $svnDirectory = Join-Path $Path ".svn"

    if (Test-Path -LiteralPath $svnDirectory -PathType Container) {
        return $true
    }

    if (-not (Test-MDWSvnInstalled)) {
        return $false
    }

    $info = Invoke-MDWSvn -Arguments @("info", $Path) -AllowFailure
    return $info.Passed
}

function Get-MDWSvnInfo {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if (-not (Test-MDWSvnWorkingCopy -Path $Path)) {
        return @{
            Passed   = $false
            Revision = $null
            Output   = @()
        }
    }

    $result = Invoke-MDWSvn -Arguments @("info", $Path) -AllowFailure
    $revision = $null

    foreach ($line in @($result.Output)) {
        if ($line -match '^Revision:\s*(.+)$') {
            $revision = $matches[1].Trim()
        }
    }

    return @{
        Passed   = $result.Passed
        Revision = $revision
        Output   = @($result.Output)
    }
}

function Get-MDWSvnStatus {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug
    $metadata = Get-MDWSvnPluginMetadata -WpOrg $wpOrg
    $workingCopyValid = Test-MDWSvnWorkingCopy -Path $wpOrg.WorkingCopyPath
    $svnInfo = Get-MDWSvnInfo -Path $wpOrg.WorkingCopyPath
    $localChanges = @()

    if ($workingCopyValid -and (Test-MDWSvnInstalled)) {
        $statusResult = Invoke-MDWSvn -Arguments @("status", $wpOrg.WorkingCopyPath) -AllowFailure

        if ($statusResult.Passed) {
            $localChanges = @($statusResult.Output)
        }
    }

    return @{
        Passed             = ((Test-MDWSvnInstalled) -and $wpOrg.Enabled -and -not [string]::IsNullOrWhiteSpace($wpOrg.SvnUrl))
        SvnInstalled       = Test-MDWSvnInstalled
        SvnVersion         = Get-MDWSvnVersion
        WordPressOrg       = $wpOrg
        Metadata           = $metadata
        WorkingCopyExists  = (Test-Path -LiteralPath $wpOrg.WorkingCopyPath -PathType Container)
        WorkingCopyValid   = $workingCopyValid
        Revision           = $svnInfo.Revision
        LocalChanges       = @($localChanges)
        TrunkExists        = (Test-Path -LiteralPath $wpOrg.TrunkPath -PathType Container)
        AssetsExists       = (Test-Path -LiteralPath $wpOrg.AssetsPath -PathType Container)
        ExpectedTagExists  = (-not [string]::IsNullOrWhiteSpace($metadata.ExpectedTagPath) -and (Test-Path -LiteralPath $metadata.ExpectedTagPath -PathType Container))
    }
}

function Initialize-MDWSvnWorkingCopy {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug

    if (-not (Test-MDWSvnInstalled)) {
        throw "SVN is not installed or not available in PATH."
    }

    $parentPath = Split-Path -Parent $wpOrg.WorkingCopyPath

    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    if (Test-MDWSvnWorkingCopy -Path $wpOrg.WorkingCopyPath) {
        $updateResult = Invoke-MDWSvn -Arguments @("update", $wpOrg.WorkingCopyPath) -AllowFailure
        $info = Get-MDWSvnInfo -Path $wpOrg.WorkingCopyPath

        return @{
            Passed          = $updateResult.Passed
            Action          = "update"
            WordPressOrg    = $wpOrg
            Revision        = $info.Revision
            Output          = @($updateResult.Output)
            Errors          = @($updateResult.Error)
        }
    }

    if (Test-Path -LiteralPath $wpOrg.WorkingCopyPath -PathType Container) {
        throw "SVN working copy path exists but is not a valid SVN working copy: $($wpOrg.WorkingCopyPath)"
    }

    $checkoutResult = Invoke-MDWSvn -Arguments @("checkout", $wpOrg.SvnUrl, $wpOrg.WorkingCopyPath) -AllowFailure
    $checkoutInfo = Get-MDWSvnInfo -Path $wpOrg.WorkingCopyPath

    return @{
        Passed       = $checkoutResult.Passed
        Action       = "checkout"
        WordPressOrg = $wpOrg
        Revision     = $checkoutInfo.Revision
        Output       = @($checkoutResult.Output)
        Errors       = @($checkoutResult.Error)
    }
}

function Copy-MDWSvnDirectoryContent {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $TargetPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
        throw "Source directory not found: $SourcePath"
    }

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Container)) {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    }

    Get-ChildItem -LiteralPath $TargetPath -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne ".svn"
    } | ForEach-Object {
        if ($_.PSIsContainer) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
        else {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

    Get-ChildItem -LiteralPath $SourcePath -Force -ErrorAction Stop | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $TargetPath -Recurse -Force
    }
}

function Invoke-MDWSvnScheduleMissingDeletes {
    [CmdletBinding()]
    param(
        [string] $WorkingCopyPath,
        [string] $TargetPath
    )

    $deleteResults = New-Object System.Collections.Generic.List[object]
    $statusResult = Invoke-MDWSvn -Arguments @("status", $TargetPath) -AllowFailure

    if (-not $statusResult.Passed) {
        return @($deleteResults.ToArray())
    }

    foreach ($line in @($statusResult.Output)) {
        if ($line -notmatch '^\!\s+(.+)$') {
            continue
        }

        $missingPath = $matches[1].Trim()

        if ([string]::IsNullOrWhiteSpace($missingPath)) {
            continue
        }

        $deleteResult = Invoke-MDWSvn -Arguments @("delete", $missingPath) -WorkingDirectory $WorkingCopyPath -AllowFailure
        $deleteResults.Add($deleteResult)
    }

    return @($deleteResults.ToArray())
}

function Get-MDWSvnRelativeFileMap {
    [CmdletBinding()]
    param(
        [string] $RootPath,
        [switch] $ExcludeSvnMetadata
    )

    $map = @{}

    if ([string]::IsNullOrWhiteSpace($RootPath) -or -not (Test-Path -LiteralPath $RootPath -PathType Container)) {
        return $map
    }

    $normalizedRoot = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([char[]] @("\", "/"))

    Get-ChildItem -LiteralPath $normalizedRoot -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $relativePath = $_.FullName.Substring($normalizedRoot.Length).TrimStart("\", "/").Replace("\", "/")

        if ($ExcludeSvnMetadata -and ($relativePath -like ".svn/*" -or $relativePath -eq ".svn")) {
            return
        }

        $map[$relativePath] = @{
            Path = $_.FullName
            Length = $_.Length
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    }

    return $map
}

function Get-MDWSvnSyncPreview {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $TargetPath
    )

    $sourceMap = Get-MDWSvnRelativeFileMap -RootPath $SourcePath
    $targetMap = Get-MDWSvnRelativeFileMap -RootPath $TargetPath -ExcludeSvnMetadata
    $added = New-Object System.Collections.Generic.List[string]
    $updated = New-Object System.Collections.Generic.List[string]
    $deleted = New-Object System.Collections.Generic.List[string]

    foreach ($relativePath in @($sourceMap.Keys | Sort-Object)) {
        if (-not $targetMap.ContainsKey($relativePath)) {
            $added.Add($relativePath)
            continue
        }

        if ($sourceMap[$relativePath].Hash -ne $targetMap[$relativePath].Hash) {
            $updated.Add($relativePath)
        }
    }

    foreach ($relativePath in @($targetMap.Keys | Sort-Object)) {
        if (-not $sourceMap.ContainsKey($relativePath)) {
            $deleted.Add($relativePath)
        }
    }

    return @{
        Added = @($added.ToArray())
        Updated = @($updated.ToArray())
        Deleted = @($deleted.ToArray())
    }
}

function Sync-MDWSvnTrunk {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $DryRun
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug

    if ($DryRun) {
        $preview = Get-MDWSvnSyncPreview -SourcePath $wpOrg.BuildPath -TargetPath $wpOrg.TrunkPath

        return @{
            Passed       = (Test-Path -LiteralPath $wpOrg.BuildPath -PathType Container)
            DryRun       = $true
            Source       = $wpOrg.BuildPath
            Target       = $wpOrg.TrunkPath
            Added        = @($preview.Added)
            Updated      = @($preview.Updated)
            Deleted      = @($preview.Deleted)
            Output       = @("Dry run: trunk sync not written.")
        }
    }

    Copy-MDWSvnDirectoryContent -SourcePath $wpOrg.BuildPath -TargetPath $wpOrg.TrunkPath
    $deleteResults = @(Invoke-MDWSvnScheduleMissingDeletes -WorkingCopyPath $wpOrg.WorkingCopyPath -TargetPath $wpOrg.TrunkPath)
    $addResult = Invoke-MDWSvn -Arguments @("add", "--force", $wpOrg.TrunkPath) -AllowFailure
    $deleteFailures = @($deleteResults | Where-Object { -not $_.Passed })

    return @{
        Passed = ($addResult.Passed -and $deleteFailures.Count -eq 0)
        DryRun = $false
        Source = $wpOrg.BuildPath
        Target = $wpOrg.TrunkPath
        Output = @($addResult.Output)
        Errors = @($addResult.Error + ($deleteFailures | ForEach-Object { $_.Error }))
    }
}

function Sync-MDWSvnAssets {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $DryRun
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug
    $assetsSourcePath = Join-Path $wpOrg.SourcePath $wpOrg.AssetsSource

    if (-not (Test-Path -LiteralPath $assetsSourcePath -PathType Container)) {
        return @{
            Passed = $true
            Skipped = $true
            DryRun = [bool] $DryRun
            Source = $assetsSourcePath
            Target = $wpOrg.AssetsPath
            Output = @("WordPress.org assets source directory not found. Assets sync skipped.")
        }
    }

    if ($DryRun) {
        return @{
            Passed = $true
            Skipped = $false
            DryRun = $true
            Source = $assetsSourcePath
            Target = $wpOrg.AssetsPath
            Output = @("Dry run: assets sync not written.")
        }
    }

    Copy-MDWSvnDirectoryContent -SourcePath $assetsSourcePath -TargetPath $wpOrg.AssetsPath
    $addResult = Invoke-MDWSvn -Arguments @("add", "--force", $wpOrg.AssetsPath) -AllowFailure

    return @{
        Passed = $addResult.Passed
        Skipped = $false
        DryRun = $false
        Source = $assetsSourcePath
        Target = $wpOrg.AssetsPath
        Output = @($addResult.Output)
        Errors = @($addResult.Error)
    }
}

function New-MDWSvnTag {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $DryRun
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug
    $metadata = Get-MDWSvnPluginMetadata -WpOrg $wpOrg

    if ([string]::IsNullOrWhiteSpace($metadata.Version) -or [string]::IsNullOrWhiteSpace($metadata.StableTag) -or $metadata.Version -ne $metadata.StableTag) {
        return @{
            Passed = $false
            Version = $metadata.Version
            StableTag = $metadata.StableTag
            Message = "Plugin Version and Stable tag must match before creating an SVN tag."
        }
    }

    $tagPath = Join-Path $wpOrg.TagsPath $metadata.Version

    if (Test-Path -LiteralPath $tagPath -PathType Container) {
        return @{
            Passed = $false
            Version = $metadata.Version
            TagPath = $tagPath
            Message = "SVN tag already exists: $($metadata.Version)"
        }
    }

    if ($DryRun) {
        return @{
            Passed = $true
            DryRun = $true
            Version = $metadata.Version
            TagPath = $tagPath
            Message = "Dry run: tag would be created from trunk."
        }
    }

    if (-not (Test-Path -LiteralPath $wpOrg.TagsPath -PathType Container)) {
        New-Item -ItemType Directory -Path $wpOrg.TagsPath -Force | Out-Null
    }

    $copyResult = Invoke-MDWSvn -Arguments @("copy", $wpOrg.TrunkPath, $tagPath) -AllowFailure

    return @{
        Passed = $copyResult.Passed
        DryRun = $false
        Version = $metadata.Version
        TagPath = $tagPath
        Output = @($copyResult.Output)
        Errors = @($copyResult.Error)
    }
}

function Commit-MDWSvnChanges {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $Message
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $metadata = Get-MDWSvnPluginMetadata -WpOrg $wpOrg
        $Message = "Release $($metadata.Version)"
    }

    return Invoke-MDWSvn -Arguments @("commit", $wpOrg.WorkingCopyPath, "-m", $Message) -AllowFailure
}

function Invoke-MDWSvnPublish {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $DryRun,
        [string] $Message
    )

    $wpOrg = Get-MDWWpOrgConfig -PluginSlug $PluginSlug
    $metadata = Get-MDWSvnPluginMetadata -WpOrg $wpOrg
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $gitChangedFiles = @()
    $gitClean = Test-MDWWorkingTreeClean -RepositoryPath (Get-MDWToolkitPath)

    if (-not $gitClean) {
        $gitChangedFiles = @(Get-MDWGitChangedFiles -RepositoryPath (Get-MDWToolkitPath))

        if ($DryRun) {
            $warnings.Add("Git working tree has changes. Dry-run continues for validation.")

            foreach ($changedFile in $gitChangedFiles) {
                $warnings.Add(("Git {0}: {1}" -f $changedFile.Status, $changedFile.Path))
            }
        }
        else {
            $errors.Add("Git working tree has changes. Commit or otherwise resolve local changes before publishing.")
        }
    }

    if (-not $wpOrg.Enabled) {
        $errors.Add("WordPress.org publishing is not enabled in mdw.json.")
    }

    if (-not (Test-MDWSvnInstalled)) {
        $errors.Add("SVN is not installed or not available in PATH.")
    }

    if (-not (Test-Path -LiteralPath $wpOrg.SourcePath -PathType Container)) {
        $errors.Add("Plugin source directory not found: $($wpOrg.SourcePath)")
    }

    if ([string]::IsNullOrWhiteSpace($metadata.Version)) {
        $errors.Add("Plugin Version header could not be resolved.")
    }

    if ([string]::IsNullOrWhiteSpace($metadata.StableTag)) {
        $errors.Add("Stable tag could not be resolved from readme.txt.")
    }
    elseif ($metadata.Version -ne $metadata.StableTag) {
        $errors.Add("Plugin Version and Stable tag do not match.")
    }

    if ($metadata.TextDomain -ne $wpOrg.Slug) {
        $warnings.Add("Text Domain should match plugin slug.")
    }

    $buildResult = $null
    $validateResult = $null
    $zipPath = $wpOrg.ZipPath

    if ($errors.Count -eq 0) {
        $buildResult = Invoke-MDWBuildService -PluginSlug $wpOrg.Slug
        $validateResult = Invoke-MDWValidateService -ToolkitRoot (Get-MDWToolkitPath) -PluginSlug $wpOrg.Slug

        if (-not $validateResult.Passed) {
            foreach ($errorItem in $validateResult.Errors) {
                $errors.Add($errorItem)
            }
        }

        New-MDWZipPackage -SourceDirectory $wpOrg.BuildPath -DestinationZip $zipPath -RootFolderName $wpOrg.Slug
    }

    $workingCopyValid = Test-MDWSvnWorkingCopy -Path $wpOrg.WorkingCopyPath
    $trunkResult = $null
    $assetsResult = $null
    $tagResult = $null
    $commitResult = $null

    if (-not $workingCopyValid) {
        $warnings.Add("SVN working copy is missing or invalid: $($wpOrg.WorkingCopyPath)")
    }

    if ($errors.Count -eq 0) {
        $trunkResult = Sync-MDWSvnTrunk -PluginSlug $wpOrg.Slug -DryRun:$DryRun
        $assetsResult = Sync-MDWSvnAssets -PluginSlug $wpOrg.Slug -DryRun:$DryRun
        $tagResult = New-MDWSvnTag -PluginSlug $wpOrg.Slug -DryRun:$DryRun

        if (-not $tagResult.Passed) {
            $errors.Add($tagResult.Message)
        }

        if (-not $DryRun -and $errors.Count -eq 0) {
            $commitResult = Commit-MDWSvnChanges -PluginSlug $wpOrg.Slug -Message $Message

            if (-not $commitResult.Passed) {
                $errors.Add("SVN commit failed.")
            }
        }
    }

    return @{
        Passed           = ($errors.Count -eq 0)
        DryRun           = [bool] $DryRun
        WordPressOrg     = $wpOrg
        Metadata         = $metadata
        Build            = $buildResult
        Validation       = $validateResult
        ZipPath          = $zipPath
        WorkingCopyValid = $workingCopyValid
        GitClean         = $gitClean
        GitChangedFiles  = @($gitChangedFiles)
        Trunk            = $trunkResult
        Assets           = $assetsResult
        Tag              = $tagResult
        Commit           = $commitResult
        Errors           = @($errors.ToArray())
        Warnings         = @($warnings.ToArray())
    }
}
