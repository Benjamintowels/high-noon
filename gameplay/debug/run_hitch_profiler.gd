extends RefCounted

## Opt-in hitch timing for roguelike zone boot / spawn / cover / explode.
##
## Enable any of:
##   - Run zone inspector: hitch_profile = true (zone_1 has this on for profiling)
##   - Cmdline: --hitch-profile
##   - Env: HIGH_NOON_HITCH_PROFILE=1
##   - Marker file: res://gameplay/debug/hitch_profile.on
##   - force_enable() from tests / scripts
##
## Launchers (project root):
##   .\run_hitch_profile_zone1.ps1      — play Dry Gulch with logs
##   .\run_hitch_profile_selftest.ps1   — headless unit check
##
## Usage:
##   var t := RunHitchProfiler.begin()
##   ... work ...
##   RunHitchProfiler.end(&"director.enemy_spawn", t, "groyper_bandit_npc")

const ENV_KEY := "HIGH_NOON_HITCH_PROFILE"
const CMD_FLAG := "--hitch-profile"
const MARKER_PATH := "res://gameplay/debug/hitch_profile.on"
const DEFAULT_THRESHOLD_MS := 4.0
const LOG_PREFIX := "[HITCH]"

## Labels (keep stable — tests and log greps depend on them).
const LABEL_ZONE_FX_WARM := &"zone.fx_warm"
const LABEL_ZONE_MATERIALS := &"zone.materials"
const LABEL_ZONE_PLAYER_SPAWN := &"zone.player_spawn"
const LABEL_ZONE_COVER_JOB := &"zone.cover_job"
const LABEL_ZONE_COVER_FRAME := &"zone.cover_frame"
const LABEL_DIRECTOR_PRELOAD := &"director.preload_scenes"
const LABEL_DIRECTOR_ANIM_WARM := &"director.anim_warm"
const LABEL_DIRECTOR_ENEMY_SPAWN := &"director.enemy_spawn"
const LABEL_NPC_LOCOMOTION := &"npc.setup_locomotion"
const LABEL_COVER_TRIMESH := &"cover.trimesh"
const LABEL_DYNAMITE_EXPLODE := &"dynamite.explode"

static var threshold_ms: float = DEFAULT_THRESHOLD_MS
## When true, every sample is retained (for tests). When false, only samples
## at/above threshold_ms are kept (keeps runtime memory tiny).
static var record_all: bool = false
static var print_over_threshold: bool = true

static var _forced: bool = false
static var _cached_enabled: int = -1
static var _announced: bool = false
static var _records: Array[Dictionary] = []
static var _totals_ms: Dictionary = {}
static var _counts: Dictionary = {}
static var _max_ms: Dictionary = {}


static func force_enable(enabled: bool = true) -> void:
	_forced = enabled
	_cached_enabled = -1


static func is_enabled() -> bool:
	if _forced:
		return true
	if _cached_enabled < 0:
		_cached_enabled = 1 if _detect_enabled() else 0
	return _cached_enabled == 1


static func announce_enabled() -> void:
	if not is_enabled() or _announced:
		return
	_announced = true
	print(
		"%s profiling ON (threshold=%.1fms). Look for [HITCH] lines on boot/spawn/cover/explode."
		% [LOG_PREFIX, threshold_ms]
	)


static func reset() -> void:
	_records.clear()
	_totals_ms.clear()
	_counts.clear()
	_max_ms.clear()


static func begin() -> int:
	if not is_enabled():
		return -1
	return Time.get_ticks_usec()


static func end(label: StringName, start_usec: int, detail: String = "") -> float:
	if start_usec < 0 or not is_enabled():
		return 0.0
	return _finish(label, start_usec, detail)


static func measure(label: StringName, work: Callable, detail: String = "") -> Variant:
	if not is_enabled():
		return work.call()
	var start_usec := Time.get_ticks_usec()
	var result: Variant = work.call()
	_finish(label, start_usec, detail)
	return result


static func get_records() -> Array[Dictionary]:
	return _records


static func get_total_ms(label: StringName) -> float:
	return float(_totals_ms.get(label, 0.0))


static func get_count(label: StringName) -> int:
	return int(_counts.get(label, 0))


static func get_max_ms(label: StringName) -> float:
	return float(_max_ms.get(label, 0.0))


static func records_for(label: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for record in _records:
		if record.get("label", &"") == label:
			out.append(record)
	return out


static func summary_text() -> String:
	if _counts.is_empty():
		return "%s (no samples)" % LOG_PREFIX
	var labels: Array = _counts.keys()
	labels.sort()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s summary (threshold=%.1fms)" % [LOG_PREFIX, threshold_ms])
	for label in labels:
		var key := label as StringName
		var count := get_count(key)
		var total := get_total_ms(key)
		var peak := get_max_ms(key)
		var avg := total / float(count) if count > 0 else 0.0
		lines.append(
			"  %s  n=%d  total=%.1fms  avg=%.1fms  max=%.1fms"
			% [String(key), count, total, avg, peak]
		)
	return "\n".join(lines)


static func print_summary() -> void:
	if not is_enabled():
		return
	print(summary_text())


static func _detect_enabled() -> bool:
	if OS.get_environment(ENV_KEY) == "1":
		return true
	if FileAccess.file_exists(MARKER_PATH):
		return true
	for arg in OS.get_cmdline_user_args():
		if arg == CMD_FLAG or arg == "hitch-profile":
			return true
	for arg in OS.get_cmdline_args():
		if arg == CMD_FLAG:
			return true
	return false


static func _finish(label: StringName, start_usec: int, detail: String) -> float:
	var ms := float(Time.get_ticks_usec() - start_usec) * 0.001
	var prev_total := float(_totals_ms.get(label, 0.0))
	_totals_ms[label] = prev_total + ms
	_counts[label] = int(_counts.get(label, 0)) + 1
	var prev_max := float(_max_ms.get(label, 0.0))
	if ms > prev_max:
		_max_ms[label] = ms

	var over := ms >= threshold_ms
	if record_all or over:
		_records.append({
			"label": label,
			"ms": ms,
			"detail": detail,
			"frame": Engine.get_process_frames(),
			"physics_frame": Engine.get_physics_frames(),
		})

	if print_over_threshold and over:
		if detail.is_empty():
			print("%s %s %.1fms (frame=%d)" % [LOG_PREFIX, String(label), ms, Engine.get_process_frames()])
		else:
			print(
				"%s %s %.1fms (%s) (frame=%d)"
				% [LOG_PREFIX, String(label), ms, detail, Engine.get_process_frames()]
			)
	return ms
