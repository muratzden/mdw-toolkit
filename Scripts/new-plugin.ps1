param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [string]$Slug
)

$ConfigPath = "C:\Workspace\mdw-toolkit\Config\mdw.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json

$ProjectPath = Join-Path $Config.Plugins $Slug

if (Test-Path $ProjectPath) {
    Write-Host "Project already exists: $ProjectPath" -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Force -Path `
"$ProjectPath\docs", `
"$ProjectPath\includes", `
"$ProjectPath\assets", `
"$ProjectPath\languages", `
"$ProjectPath\templates", `
"$ProjectPath\tests" | Out-Null

$TemplatePath = $Config.PluginTemplate

if (Test-Path $TemplatePath) {
    Copy-Item "$TemplatePath\*" $ProjectPath -Recurse -Force
}

$Files = Get-ChildItem $ProjectPath -Recurse -File

foreach ($File in $Files) {
    $Content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -ne $Content) {
        $Content = $Content.Replace("PROJECT_NAME", $Name)
        $Content = $Content.Replace("PROJECT_SLUG", $Slug)
        $Content | Set-Content $File.FullName -Encoding UTF8
    }
}

$StubPath = Join-Path $ProjectPath "plugin.php.stub"
$PluginFile = Join-Path $ProjectPath "$Slug.php"

if (Test-Path $StubPath) {
    Rename-Item $StubPath $PluginFile -Force
}

Set-Location $ProjectPath

if (Get-Command git -ErrorAction SilentlyContinue) {
    git init | Out-Null
    git branch -M main
    git add .
    git commit -m "chore: initial plugin scaffold" | Out-Null
}

Write-Host "Plugin created: $ProjectPath" -ForegroundColor Green
