# Launch visual capture scripts with a private Godot user profile.
param(
    [string]$GodotPath = 'godot',
    [ValidateSet('master', 'campaign_screens', 'hub_tabs', 'screens', 'skill_forms', 'calendar', 'ui_overhaul')]
    [string]$Capture = 'master',
    [string]$Screen = ''
)
$ErrorActionPreference = 'Stop'
if ($Screen -and $Capture -ne 'master') { throw '-Screen is only supported with -Capture master.' }
$projectDir = Split-Path -Parent $PSScriptRoot
$enginePath = (Get-Command $GodotPath -ErrorAction Stop).Source
# PowerShell does not wait for a GUI .exe; Godot's console companion does.
if ($enginePath.EndsWith('.exe') -and !$enginePath.EndsWith('_console.exe')) {
    $consolePath = $enginePath.Substring(0, $enginePath.Length - 4) + '_console.exe'
    if (Test-Path -LiteralPath $consolePath) { $enginePath = $consolePath }
}
$profileDir = Join-Path $projectDir ('.godot\capture_profiles\' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

$originalAppData = $env:APPDATA
$originalCaptureFlag = $env:ELEMENTAL_CAPTURE_ISOLATED
try {
    $env:APPDATA = $profileDir
    $env:ELEMENTAL_CAPTURE_ISOLATED = '1'
    $arguments = @('--path', $projectDir, '--resolution', '1920x1080', '--script', "res://scripts/capture_$Capture.gd")
    if ($Screen) { $arguments += @('--', "--screen=$Screen") }
    & $enginePath @arguments
    if ($LASTEXITCODE -ne 0) { throw "Capture exited with code $LASTEXITCODE" }
} finally {
    $env:APPDATA = $originalAppData
    $env:ELEMENTAL_CAPTURE_ISOLATED = $originalCaptureFlag
}
Write-Host "Screenshots: $(Join-Path $projectDir 'screenshots\new_ui')"
