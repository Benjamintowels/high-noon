# Play Dry Gulch (zone_1) with [HITCH] frame-time logs in the console.
# Watch Output for lines like:
#   [HITCH] profiling ON ...
#   [HITCH] zone.fx_warm 12.3ms ...
#   [HITCH] director.enemy_spawn 140ms (groyper_bandit_npc) ...
#
# Stop profiling later: untick hitch_profile on the zone_1 root in the inspector,
# or delete gameplay/debug/hitch_profile.on

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$godot = Get-ChildItem -Path $PSScriptRoot -Filter "Godot_v*-stable_win64.exe" |
	Sort-Object Name -Descending |
	Select-Object -First 1
if ($null -eq $godot) {
	Write-Error "Godot exe not found in $PSScriptRoot (expected Godot_v*-stable_win64.exe)"
}

$marker = Join-Path $PSScriptRoot "gameplay\debug\hitch_profile.on"
if (-not (Test-Path $marker)) {
	New-Item -ItemType File -Path $marker -Force | Out-Null
	Write-Host "Created $marker (profiling marker)"
}

$env:HIGH_NOON_HITCH_PROFILE = "1"
$out = Join-Path $PSScriptRoot "hitch_profile_zone1_stdout.txt"
$err = Join-Path $PSScriptRoot "hitch_profile_zone1_stderr.txt"
if (Test-Path $out) { Remove-Item $out }
if (Test-Path $err) { Remove-Item $err }

Write-Host "Launching zone_1 with hitch profiling..."
Write-Host "  exe: $($godot.FullName)"
Write-Host "  logs: $out"
Write-Host "  Look for [HITCH] lines. Walk into encounters to spawn bandits."
Write-Host ""

$args = @(
	"--path", $PSScriptRoot,
	"--hitch-profile",
	"res://stages/runs/zone_1.tscn"
)
$p = Start-Process -FilePath $godot.FullName -ArgumentList $args -Wait -NoNewWindow -PassThru `
	-RedirectStandardOutput $out -RedirectStandardError $err

Write-Host ""
Write-Host "Game exited ($($p.ExitCode)). [HITCH] lines from this run:"
Write-Host "----------------------------------------------------------------"
Select-String -Path $out, $err -Pattern "\[HITCH\]" -ErrorAction SilentlyContinue |
	ForEach-Object { $_.Line }
Write-Host "----------------------------------------------------------------"
Write-Host "Full logs: $out / $err"
