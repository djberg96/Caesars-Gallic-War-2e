param(
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$stage = Join-Path $PSScriptRoot "stage"
$appStage = Join-Path $stage "app"
$gameStage = Join-Path $appStage "game"
$runtimeStage = Join-Path $stage "runtime"

if (Test-Path $stage) {
    Remove-Item -Recurse -Force $stage
}
New-Item -ItemType Directory -Force $gameStage, $runtimeStage | Out-Null

function Invoke-Robocopy {
    param([string[]]$Arguments)

    & robocopy @Arguments | Out-Host
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }
}

Invoke-Robocopy @(
    (Join-Path $repo "game"),
    $gameStage,
    "/E",
    "/XD", ".git", ".github", "log", "storage", "test", "tmp",
    "/XF", ".env*", "config\ai.yml", "config\master.key"
)

Invoke-Robocopy @(
    (Join-Path $repo "images"),
    (Join-Path $appStage "images"),
    "/E"
)

$rubyPrefix = & ruby -rrbconfig -e "print RbConfig::CONFIG['prefix']"
if (-not $rubyPrefix) {
    throw "Could not locate the Ruby runtime"
}
Invoke-Robocopy @($rubyPrefix, $runtimeStage, "/E")

$launcherSource = Join-Path $PSScriptRoot "Launcher.cs"
$launcherOutput = Join-Path $stage "CaesarsGallicWar.exe"
Add-Type -TypeDefinition (Get-Content $launcherSource -Raw) `
    -ReferencedAssemblies @("System.dll", "System.Windows.Forms.dll") `
    -OutputAssembly $launcherOutput `
    -OutputType WindowsApplication

$iscc = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"
if (-not (Test-Path $iscc)) {
    throw "Inno Setup 6 was not found at $iscc"
}

New-Item -ItemType Directory -Force (Join-Path $repo "dist") | Out-Null
& $iscc "/DMyAppVersion=$Version" (Join-Path $PSScriptRoot "CaesarsGallicWar.iss")
