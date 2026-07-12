$tests = New-Object System.Collections.Generic.List[object]

$services = @(
    @{ Name = "Build"; EntryPoint = "Invoke-MDWBuildService" }
    @{ Name = "Check"; EntryPoint = "Invoke-MDWCheckService" }
    @{ Name = "Release"; EntryPoint = "Invoke-MDWRelease" }
    @{ Name = "Doctor"; EntryPoint = "Invoke-MDWDoctorService" }
    @{ Name = "Git"; EntryPoint = "Get-MDWGitStatus" }
    @{ Name = "Lint"; EntryPoint = "Invoke-MDWLintService" }
    @{ Name = "Compliance"; EntryPoint = "Invoke-MDWComplianceService" }
    @{ Name = "Validate"; EntryPoint = "Invoke-MDWValidateService" }
    @{ Name = "Output"; EntryPoint = "Write-MDWTitle" }
    @{ Name = "LocalWP Service"; EntryPoint = "Get-MDWLocalWPReport" }
    @{ Name = "LocalWP Config"; EntryPoint = "Get-MDWLocalWPConfig" }
    @{ Name = "LocalWP Path Resolution"; EntryPoint = "Get-MDWLocalWPPluginsPath" }
    @{ Name = "LocalWP Availability Check"; EntryPoint = "Test-MDWLocalWPAvailable" }
    @{ Name = "Plugin Check"; EntryPoint = "Invoke-MDWPluginCheckService" }
    @{ Name = "Plugin Structure"; EntryPoint = "Test-MDWPluginStructure" }
    @{ Name = "Plugin Headers"; EntryPoint = "Test-MDWPluginHeaders" }
    @{ Name = "Readme Validation"; EntryPoint = "Test-MDWPluginReadme" }
    @{ Name = "Forbidden Files"; EntryPoint = "Test-MDWPluginForbiddenFiles" }
    @{ Name = "Init"; EntryPoint = "Invoke-MDWInitService" }
    @{ Name = "Workspace"; EntryPoint = "Invoke-MDWWorkspaceService" }
    @{ Name = "SVN Path"; EntryPoint = "Get-MDWSvnPath" }
)

foreach ($service in $services) {
    $tests.Add(@{
        Name = $service.Name
        Passed = $null -ne (Get-Command $service.EntryPoint -ErrorAction SilentlyContinue)
        Duration = 0
        Message = ""
    })
}

$config = Get-MDWPathConfig

$tests.Add(@{
    Name = "SVN Root Config"
    Passed = ((Get-MDWConfigValue -Config $config -Key "workspace.svnPath") -eq "C:\Workspace\SVN")
    Duration = 0
    Message = ""
})

$tests.Add(@{
    Name = "SVN Root Path"
    Passed = ((Get-MDWSvnPath) -eq "C:\Workspace\SVN")
    Duration = 0
    Message = ""
})

$tests.Add(@{
    Name = "SVN Plugin Path"
    Passed = ((Get-MDWSvnPath -PluginSlug "cck-review-flow-for-woocommerce") -eq "C:\Workspace\SVN\cck-review-flow-for-woocommerce")
    Duration = 0
    Message = ""
})

$tests.Add(@{
    Name = "SVN Plugin Path Positional"
    Passed = ((Get-MDWSvnPath "cck-review-flow-for-woocommerce") -eq "C:\Workspace\SVN\cck-review-flow-for-woocommerce")
    Duration = 0
    Message = ""
})

$originalGetMDWPathConfig = (Get-Command Get-MDWPathConfig).ScriptBlock

try {
    Set-Item -Path Function:\Get-MDWPathConfig -Value {
        return [pscustomobject] @{
            workspace = [pscustomobject] @{
                svnPath = "C:\Workspace Test\SVN Copies\"
                pluginsPath = "C:\Workspace\Plugins"
                buildPath = "C:\Workspace\Build"
                releasePath = "C:\Workspace\Releases"
                backupPath = "D:\Workspace Backup"
            }
        }
    }

    $tests.Add(@{
        Name = "SVN Path Join Normalization"
        Passed = ((Get-MDWSvnPath -PluginSlug "cck-review-flow-for-woocommerce") -eq "C:\Workspace Test\SVN Copies\cck-review-flow-for-woocommerce")
        Duration = 0
        Message = ""
    })

    $tests.Add(@{
        Name = "SVN Root Path With Spaces"
        Passed = ((Get-MDWSvnPath) -eq "C:\Workspace Test\SVN Copies")
        Duration = 0
        Message = ""
    })
}
finally {
    Set-Item -Path Function:\Get-MDWPathConfig -Value $originalGetMDWPathConfig
}

$relativeRootOriginalGetMDWPathConfig = (Get-Command Get-MDWPathConfig).ScriptBlock
$relativeRootRejected = $false

try {
    Set-Item -Path Function:\Get-MDWPathConfig -Value {
        return [pscustomobject] @{
            workspace = [pscustomobject] @{
                svnPath = "SVN"
            }
        }
    }

    try {
        Get-MDWSvnPath | Out-Null
    }
    catch {
        $relativeRootRejected = $true
    }

    $tests.Add(@{
        Name = "SVN Root Path Must Be Absolute"
        Passed = $relativeRootRejected
        Duration = 0
        Message = ""
    })
}
finally {
    Set-Item -Path Function:\Get-MDWPathConfig -Value $relativeRootOriginalGetMDWPathConfig
}

$invalidSlugs = @("..\plugin", "../plugin", "C:\Temp\plugin", "plugin\child", "plugin/child")
$invalidSlugPassed = $true

foreach ($invalidSlug in $invalidSlugs) {
    try {
        Get-MDWSvnPath -PluginSlug $invalidSlug | Out-Null
        $invalidSlugPassed = $false
    }
    catch {
    }
}

$tests.Add(@{
    Name = "SVN Invalid Slugs"
    Passed = $invalidSlugPassed
    Duration = 0
    Message = ""
})

$sideEffectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mdw-svn-path-test-{0}" -f ([guid]::NewGuid().ToString("N")))
$sideEffectOriginalGetMDWPathConfig = (Get-Command Get-MDWPathConfig).ScriptBlock

try {
    $script:MDWSideEffectSvnRoot = $sideEffectRoot
    Set-Item -Path Function:\Get-MDWPathConfig -Value {
        return [pscustomobject] @{
            workspace = [pscustomobject] @{
                svnPath = $script:MDWSideEffectSvnRoot
            }
        }
    }
    $resolvedSideEffectPath = Get-MDWSvnPath -PluginSlug "cck-review-flow-for-woocommerce"
    $tests.Add(@{
        Name = "SVN Resolver Has No Filesystem Side Effects"
        Passed = (-not (Test-Path -LiteralPath $sideEffectRoot) -and -not (Test-Path -LiteralPath $resolvedSideEffectPath))
        Duration = 0
        Message = ""
    })
}
finally {
    Set-Item -Path Function:\Get-MDWPathConfig -Value $sideEffectOriginalGetMDWPathConfig
    $script:MDWSideEffectSvnRoot = $null
}

$tests.Add(@{
    Name = "Path Regression"
    Passed = (
        (Get-MDWPluginPath -PluginSlug "my-plugin") -eq "C:\Workspace\Plugins\my-plugin" -and
        (Get-MDWBuildPluginPath -PluginSlug "my-plugin") -eq "C:\Workspace\Build\my-plugin" -and
        (Get-MDWReleasePluginPath -PluginSlug "my-plugin") -eq "C:\Workspace\Releases\my-plugin" -and
        (Get-MDWBackupPluginPath -PluginSlug "my-plugin") -eq "D:\Workspace Backup\my-plugin"
    )
    Duration = 0
    Message = ""
})

return @($tests.ToArray())
