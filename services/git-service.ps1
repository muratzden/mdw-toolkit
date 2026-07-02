<#
MDW Git Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWGit {
    [CmdletBinding()]
    param()

    return $null -ne (Get-Command git -ErrorAction SilentlyContinue)
}

function ConvertTo-MDWGitArgument {
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

function Invoke-MDWGit {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $RepositoryPath,
        [switch] $AllowFailure
    )

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue

    if ($null -eq $gitCommand) {
        throw "Git is not installed or not available in PATH."
    }

    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    if ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
        $RepositoryPath = Get-MDWToolkitPath
    }

    $resolvedRepositoryPath = $RepositoryPath

    if (Test-Path -LiteralPath $RepositoryPath -PathType Container) {
        $resolvedRepositoryPath = (Resolve-Path -LiteralPath $RepositoryPath).ProviderPath
    }

    $gitArguments = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($resolvedRepositoryPath)) {
        $gitArguments.Add("-c")
        $gitArguments.Add("safe.directory=$resolvedRepositoryPath")
        $gitArguments.Add("-C")
        $gitArguments.Add($resolvedRepositoryPath)
    }

    foreach ($argument in $Arguments) {
        $gitArguments.Add($argument)
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $gitCommand.Source
    $process.StartInfo.Arguments = (($gitArguments | ForEach-Object { ConvertTo-MDWGitArgument -Value $_ }) -join " ")
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true

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
        Passed         = ($process.ExitCode -eq 0)
        ExitCode       = $process.ExitCode
        Output         = $output
        Error          = $errorOutput
        RepositoryPath = $resolvedRepositoryPath
        Command        = ("git " + ($Arguments -join " "))
    }

    if (-not $result.Passed -and -not $AllowFailure) {
        $message = ($errorOutput -join " ").Trim()

        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = "Git command failed: $($result.Command)"
        }

        throw $message
    }

    return $result
}

function Test-MDWGitRepository {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    if (-not (Test-MDWGit)) {
        return $false
    }

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("rev-parse", "--is-inside-work-tree") -AllowFailure

    return ($result.Passed -and $result.Output.Count -gt 0 -and $result.Output[0] -eq "true")
}

function Get-MDWCurrentBranch {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("branch", "--show-current") -AllowFailure

    if ($result.Passed -and $result.Output.Count -gt 0) {
        return [string] $result.Output[0]
    }

    return $null
}

function Get-MDWGitRemote {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $origin = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("remote", "get-url", "origin") -AllowFailure

    if ($origin.Passed -and $origin.Output.Count -gt 0) {
        return [string] $origin.Output[0]
    }

    $remotes = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("remote") -AllowFailure

    if ($remotes.Passed -and $remotes.Output.Count -gt 0) {
        return [string] $remotes.Output[0]
    }

    return $null
}

function Get-MDWLastCommit {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("log", "-1", "--pretty=format:%h %s") -AllowFailure

    if ($result.Passed -and $result.Output.Count -gt 0) {
        return [string] $result.Output[0]
    }

    return $null
}

function Get-MDWCommitCount {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("rev-list", "--count", "HEAD") -AllowFailure

    if ($result.Passed -and $result.Output.Count -gt 0) {
        $count = 0

        if ([int]::TryParse([string] $result.Output[0], [ref] $count)) {
            return $count
        }
    }

    return 0
}

function Get-MDWTags {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("tag", "--list") -AllowFailure

    if ($result.Passed) {
        return @($result.Output)
    }

    return @()
}

function Test-MDWWorkingTreeClean {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("status", "--porcelain") -AllowFailure

    return ($result.Passed -and $result.Output.Count -eq 0)
}

function ConvertFrom-MDWGitShortStatusLine {
    [CmdletBinding()]
    param(
        [string] $Line
    )

    if ([string]::IsNullOrWhiteSpace($Line) -or $Line.Length -lt 3) {
        return $null
    }

    $indexStatus = $Line.Substring(0, 1)
    $workingTreeStatus = $Line.Substring(1, 1)
    $path = $Line.Substring(3).Trim()

    if ($path -match ' -> ') {
        $path = ($path -split ' -> ')[-1].Trim()
    }

    $statusCode = ($indexStatus + $workingTreeStatus).Trim()
    $category = "Modified"

    if ($indexStatus -eq "?" -and $workingTreeStatus -eq "?") {
        $statusCode = "??"
        $category = "Untracked"
    }
    elseif ($indexStatus -eq "A" -or $workingTreeStatus -eq "A") {
        $category = "Added"
    }
    elseif ($indexStatus -eq "D" -or $workingTreeStatus -eq "D") {
        $category = "Deleted"
    }
    elseif ($indexStatus -eq "R" -or $workingTreeStatus -eq "R") {
        $category = "Modified"
    }

    return @{
        Status   = $statusCode
        Category = $category
        Path     = $path
        Raw      = $Line
    }
}

function Get-MDWGitChangedFiles {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("status", "--short") -AllowFailure
    $files = New-Object System.Collections.Generic.List[object]

    if (-not $result.Passed) {
        return @()
    }

    foreach ($line in $result.Output) {
        $file = ConvertFrom-MDWGitShortStatusLine -Line $line

        if ($null -ne $file) {
            $files.Add($file)
        }
    }

    return @($files.ToArray())
}

function Get-MDWGitDiffSummary {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    $changedFiles = @(Get-MDWGitChangedFiles -RepositoryPath $RepositoryPath)

    return @{
        Files     = $changedFiles
        Modified  = @($changedFiles | Where-Object { $_.Category -eq "Modified" }).Count
        Added     = @($changedFiles | Where-Object { $_.Category -eq "Added" }).Count
        Deleted   = @($changedFiles | Where-Object { $_.Category -eq "Deleted" }).Count
        Untracked = @($changedFiles | Where-Object { $_.Category -eq "Untracked" }).Count
        Total     = $changedFiles.Count
    }
}

function Get-MDWGitHistory {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [int] $Limit = 10
    )

    if ($Limit -lt 1) {
        $Limit = 10
    }

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("log", "-$Limit", "--pretty=format:%h %s") -AllowFailure

    if ($result.Passed) {
        return @($result.Output)
    }

    return @()
}

function Test-MDWConventionalCommitMessage {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return $Message -match '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9][a-z0-9-]*\))?: .+'
}

function Test-MDWSemVer {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        return $false
    }

    return $Version -match '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?$'
}

function Test-MDWGitTagExists {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [string] $TagName
    )

    if ([string]::IsNullOrWhiteSpace($TagName)) {
        return $false
    }

    $result = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("tag", "--list", $TagName) -AllowFailure

    return ($result.Passed -and $result.Output.Count -gt 0)
}

function New-MDWGitCommit {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [string] $Message
    )

    $errors = New-Object System.Collections.Generic.List[string]

    if (-not (Test-MDWGit)) {
        $errors.Add("Git is not installed or not available in PATH.")
    }
    elseif (-not (Test-MDWGitRepository -RepositoryPath $RepositoryPath)) {
        $errors.Add("Not a Git repository.")
    }
    elseif (-not (Test-MDWConventionalCommitMessage -Message $Message)) {
        $errors.Add("Invalid commit message. Use Conventional Commit format, for example: feat(git): add workflow automation")
    }
    else {
        $changedFiles = @(Get-MDWGitChangedFiles -RepositoryPath $RepositoryPath)

        if ($changedFiles.Count -eq 0) {
            $errors.Add("No changes to commit.")
        }
    }

    if ($errors.Count -gt 0) {
        return @{
            Passed      = $false
            Message     = $Message
            ChangedFileCount = 0
            Output      = @()
            Errors      = @($errors.ToArray())
        }
    }

    $changedFileCount = @(Get-MDWGitChangedFiles -RepositoryPath $RepositoryPath).Count
    $addResult = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("add", "-A") -AllowFailure

    if (-not $addResult.Passed) {
        return @{
            Passed      = $false
            Message     = $Message
            ChangedFileCount = $changedFileCount
            Output      = @($addResult.Output)
            Errors      = @($addResult.Error)
        }
    }

    $commitResult = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("commit", "-m", $Message) -AllowFailure

    return @{
        Passed      = $commitResult.Passed
        Message     = $Message
        ChangedFileCount = $changedFileCount
        Output      = @($commitResult.Output)
        Errors      = @($commitResult.Error)
    }
}

function New-MDWGitTag {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [string] $Version
    )

    $errors = New-Object System.Collections.Generic.List[string]

    if (-not (Test-MDWGit)) {
        $errors.Add("Git is not installed or not available in PATH.")
    }
    elseif (-not (Test-MDWGitRepository -RepositoryPath $RepositoryPath)) {
        $errors.Add("Not a Git repository.")
    }
    elseif (-not (Test-MDWSemVer -Version $Version)) {
        $errors.Add("Invalid tag version. Use SemVer format, for example: v0.1.5-alpha")
    }
    elseif (Test-MDWGitTagExists -RepositoryPath $RepositoryPath -TagName $Version) {
        $errors.Add("Git tag already exists: $Version")
    }
    elseif (-not (Test-MDWWorkingTreeClean -RepositoryPath $RepositoryPath)) {
        $errors.Add("Working tree has changes. Commit or discard changes before creating a tag.")
    }

    if ($errors.Count -gt 0) {
        return @{
            Passed = $false
            Tag    = $Version
            Output = @()
            Errors = @($errors.ToArray())
        }
    }

    $tagMessage = "MDW Toolkit $Version"
    $tagResult = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("tag", "-a", $Version, "-m", $tagMessage) -AllowFailure

    return @{
        Passed = $tagResult.Passed
        Tag    = $Version
        Output = @($tagResult.Output)
        Errors = @($tagResult.Error)
    }
}

function Get-MDWGitStatus {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
        $RepositoryPath = Get-MDWToolkitPath
    }

    $status = @{
        Available      = $false
        Repository     = $false
        RepositoryPath = $RepositoryPath
        RepositoryName = if ([string]::IsNullOrWhiteSpace($RepositoryPath)) { $null } else { Split-Path $RepositoryPath -Leaf }
        Branch         = $null
        Remote         = $null
        Clean          = $false
        Status         = "Git is not installed or not available in PATH."
        LastCommit     = $null
        CommitCount    = 0
        ChangedFileCount = 0
        UntrackedFileCount = 0
        LatestTag      = $null
        Tags           = @()
        Errors         = @()
        Warnings       = @()
    }

    if (-not (Test-MDWGit)) {
        $status.Errors = @("Git is not installed or not available in PATH.")
        return $status
    }

    $status.Available = $true

    if (-not (Test-Path -LiteralPath $RepositoryPath -PathType Container)) {
        $message = "Not a Git repository."
        $status.Status = $message
        $status.Warnings = @($message)
        return $status
    }

    if (-not (Test-MDWGitRepository -RepositoryPath $RepositoryPath)) {
        $message = "Not a Git repository."
        $status.Status = $message
        $status.Warnings = @($message)
        return $status
    }

    $status.Repository = $true
    $status.Branch = Get-MDWCurrentBranch -RepositoryPath $RepositoryPath
    $status.Remote = Get-MDWGitRemote -RepositoryPath $RepositoryPath
    $status.Clean = Test-MDWWorkingTreeClean -RepositoryPath $RepositoryPath
    $status.LastCommit = Get-MDWLastCommit -RepositoryPath $RepositoryPath
    $status.CommitCount = Get-MDWCommitCount -RepositoryPath $RepositoryPath
    $status.Tags = @(Get-MDWTags -RepositoryPath $RepositoryPath)
    $diffSummary = Get-MDWGitDiffSummary -RepositoryPath $RepositoryPath
    $status.ChangedFileCount = $diffSummary.Total
    $status.UntrackedFileCount = $diffSummary.Untracked

    if ($status.Tags.Count -gt 0) {
        $latestTagResult = Invoke-MDWGit -RepositoryPath $RepositoryPath -Arguments @("describe", "--tags", "--abbrev=0") -AllowFailure

        if ($latestTagResult.Passed -and $latestTagResult.Output.Count -gt 0) {
            $status.LatestTag = [string] $latestTagResult.Output[0]
        }
    }

    if ($status.Clean) {
        $status.Status = "Working Tree Clean"
    }
    else {
        $status.Status = "Working Tree Has Changes"
        $status.Warnings = @("Working tree has changes.")
    }

    return $status
}
