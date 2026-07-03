$tests = New-Object System.Collections.Generic.List[object]

$services = @(
    @{ Name = "Build"; EntryPoint = "Invoke-MDWBuildService" }
    @{ Name = "Check"; EntryPoint = "Invoke-MDWCheckService" }
    @{ Name = "Release"; EntryPoint = "Invoke-MDWRelease" }
    @{ Name = "Doctor"; EntryPoint = "Invoke-MDWDoctorService" }
    @{ Name = "Git"; EntryPoint = "Get-MDWGitStatus" }
    @{ Name = "Lint"; EntryPoint = "Invoke-MDWLintService" }
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
)

foreach ($service in $services) {
    $tests.Add(@{
        Name = $service.Name
        Passed = $null -ne (Get-Command $service.EntryPoint -ErrorAction SilentlyContinue)
        Duration = 0
        Message = ""
    })
}

return @($tests.ToArray())
