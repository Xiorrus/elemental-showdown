# Run the Godot suites without modifying your real campaign or settings.
param(
    [string]$GodotPath = 'godot',
    [string[]]$Tests = @(),
    [int]$TimeoutSeconds = 90
)
$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $PSScriptRoot
$engineCommand = Get-Command $GodotPath -ErrorAction Stop
$enginePath = $engineCommand.Source
# Launch the engine directly so the timeout also terminates the game process.
if ($enginePath.EndsWith('_console.exe')) {
    $nativeEngine = $enginePath.Replace('_console.exe', '.exe')
    if (Test-Path -LiteralPath $nativeEngine) { $enginePath = $nativeEngine }
}
$runDir = Join-Path $projectDir ('.godot\audit_tests\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
if ($Tests.Count -eq 0) {
    $Tests = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object Name)
}
$originalAppData = $env:APPDATA
$failed = 0
try {
    foreach ($test in $Tests) {
        $testName = [IO.Path]::GetFileName($test)
        if ($testName -notmatch '^test_[a-z0-9_]+\.gd$' -or !(Test-Path -LiteralPath (Join-Path $PSScriptRoot $testName))) {
            throw "Unknown test script: $test"
        }
        $suiteDir = Join-Path $runDir ([IO.Path]::GetFileNameWithoutExtension($testName))
        New-Item -ItemType Directory -Force -Path $suiteDir | Out-Null
        $env:APPDATA = Join-Path $suiteDir 'appdata'
        New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
        $stdout = Join-Path $suiteDir 'stdout.log'
        $stderr = Join-Path $suiteDir 'stderr.log'
        $engineLog = Join-Path $suiteDir 'engine.log'
        $arguments = @('--headless', '--path', ('"' + $projectDir + '"'), '--log-file', ('"' + $engineLog + '"'), '--script', ('res://scripts/' + $testName))
        $process = Start-Process -FilePath $enginePath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        $timedOut = $false
        while (!$process.WaitForExit(250)) {
            # A failed GDScript assert can leave SceneTree running forever.
            $errors = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            if ($errors -match 'SCRIPT ERROR:' -or (Get-Date) -ge $deadline) {
                $timedOut = (Get-Date) -ge $deadline
                $process.Kill()
                $process.WaitForExit()
                break
            }
        }
        $output = (Get-Content -LiteralPath $stdout -Raw) + "`n" + (Get-Content -LiteralPath $stderr -Raw)
        # The isolated Windows profile can lack the certificate store. This is
        # unrelated to game tests; all other engine/script errors fail the run.
        $badOutput = $output -match '(?m)\[FAIL\]|SCRIPT ERROR:|^ERROR: (?!Failed to read the root certificate store\.)'
        if ($timedOut -or $process.ExitCode -ne 0 -or $badOutput) {
            $failed++
            Write-Host "FAIL $testName (exit $($process.ExitCode), timeout $timedOut)"
            $output -split "`r?`n" | Where-Object { $_ -match '\[FAIL\]|SCRIPT ERROR:|^ERROR:|^   at:' } | Select-Object -First 12 | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host "PASS $testName"
        }
    }
} finally {
    $env:APPDATA = $originalAppData
}
Write-Host "$($Tests.Count - $failed)/$($Tests.Count) suites passed. Logs: $runDir"
if ($failed -gt 0) { exit 1 }
exit 0
