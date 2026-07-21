# Headless self-test for the hitch profiler + instrumented paths.
# Prints pass/fail and a bandit spawn timing probe.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$godot = Get-ChildItem -Path $PSScriptRoot -Filter "Godot_v*-stable_win64.exe" |
	Sort-Object Name -Descending |
	Select-Object -First 1
if ($null -eq $godot) {
	Write-Error "Godot exe not found in $PSScriptRoot (expected Godot_v*-stable_win64.exe)"
}

$env:HIGH_NOON_HITCH_PROFILE = "1"
$out = Join-Path $PSScriptRoot "hitch_profile_selftest_stdout.txt"
$err = Join-Path $PSScriptRoot "hitch_profile_selftest_stderr.txt"
if (Test-Path $out) { Remove-Item $out }
if (Test-Path $err) { Remove-Item $err }

Write-Host "Running hitch profiler selftest..."
$args = @(
	"--headless",
	"--path", $PSScriptRoot,
	"--script", "res://gameplay/debug/run_hitch_profiler_selftest.gd"
)
$p = Start-Process -FilePath $godot.FullName -ArgumentList $args -Wait -NoNewWindow -PassThru `
	-RedirectStandardOutput $out -RedirectStandardError $err

Write-Host "--- STDOUT ---"
Get-Content $out -ErrorAction SilentlyContinue
Write-Host "--- [HITCH] / FAIL ---"
Select-String -Path $out, $err -Pattern "\[HITCH\]|FAIL|tests OK|tests FAILED" -ErrorAction SilentlyContinue |
	ForEach-Object { $_.Line }
Write-Host "EXIT=$($p.ExitCode)"
exit $p.ExitCode
