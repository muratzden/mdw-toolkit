$tests = New-Object System.Collections.Generic.List[object]
$fixturesRoot = Join-Path (Join-Path (Get-MDWRootPath) "tests") "fixtures"

$validPlugin = Join-Path $fixturesRoot "valid-plugin"
$missingHeader = Join-Path $fixturesRoot "missing-header"
$missingReadme = Join-Path $fixturesRoot "missing-readme"
$missingLicense = Join-Path $fixturesRoot "missing-license"
$missingTextDomain = Join-Path $fixturesRoot "missing-text-domain"

$headerResult = Invoke-MDWPluginHeaderValidator -PluginSlug "valid-plugin" -PluginPath $validPlugin
$missingHeaderResult = Invoke-MDWPluginHeaderValidator -PluginSlug "missing-header" -PluginPath $missingHeader

$tests.Add(@{
    Name = "Plugin Header"
    Passed = $headerResult.Passed -and (-not $missingHeaderResult.Passed)
    Duration = 0
    Message = ""
})

$readmeResult = Invoke-MDWReadmeValidator -PluginSlug "missing-readme" -PluginPath $missingReadme

$tests.Add(@{
    Name = "Readme"
    Passed = $readmeResult.Passed -and ($readmeResult.Warnings.Count -gt 0)
    Duration = 0
    Message = ""
})

$licenseResult = Invoke-MDWLicenseValidator -PluginSlug "missing-license" -PluginPath $missingLicense

$tests.Add(@{
    Name = "License"
    Passed = $licenseResult.Passed -and ($licenseResult.Warnings.Count -gt 0)
    Duration = 0
    Message = ""
})

$textDomainResult = Invoke-MDWTextDomainValidator -PluginSlug "missing-text-domain" -PluginPath $missingTextDomain

$tests.Add(@{
    Name = "Text Domain"
    Passed = $textDomainResult.Passed -and ($textDomainResult.Warnings.Count -gt 0)
    Duration = 0
    Message = ""
})

$environmentResult = Invoke-MDWEnvironmentValidator -ToolkitRoot (Get-MDWRootPath)

$tests.Add(@{
    Name = "Environment"
    Passed = $environmentResult.Passed
    Duration = 0
    Message = ""
})

$pluginCheckCliResult = Invoke-MDWPluginCheckCliValidator

$tests.Add(@{
    Name = "Plugin Check CLI"
    Passed = $pluginCheckCliResult.Passed
    Duration = 0
    Message = ""
})

$workspaceResult = Invoke-MDWWorkspaceValidator `
    -WorkspacePath "C:\Workspace" `
    -ToolkitRoot (Get-MDWRootPath) `
    -PluginSlug "valid-plugin" `
    -PluginPath $validPlugin `
    -ReleasePath $null `
    -BackupPath $null

$tests.Add(@{
    Name = "Workspace"
    Passed = ($null -ne $workspaceResult.Workspace) -and ($null -ne $workspaceResult.Environment) -and ($workspaceResult.Plugin.Slug -eq "valid-plugin")
    Duration = 0
    Message = ""
})

$complianceResult = Invoke-MDWComplianceService -PluginSlug "valid-plugin" -PluginPath $validPlugin
$missingComplianceResult = Invoke-MDWComplianceService -PluginSlug "missing-header" -PluginPath $missingHeader

$tests.Add(@{
    Name = "Compliance"
    Passed = ($complianceResult.Findings.Count -gt 0) -and (-not $missingComplianceResult.Passed) -and ($missingComplianceResult.Failed -gt 0)
    Duration = 0
    Message = ""
})

return @($tests.ToArray())
