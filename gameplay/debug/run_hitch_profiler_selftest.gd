extends SceneTree

## Headless self-test for run_hitch_profiler + bandit anim cache.
## Run: .\run_hitch_profile_selftest.ps1

const HitchProfiler := preload("res://gameplay/debug/run_hitch_profiler.gd")

var _failed := 0
var _passed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	HitchProfiler.force_enable(true)
	HitchProfiler.record_all = true
	HitchProfiler.print_over_threshold = false
	HitchProfiler.announce_enabled()

	_test_begin_end()
	await _test_bandit_spawn_cache()

	print(HitchProfiler.summary_text())
	if _failed > 0:
		push_error("run_hitch_profiler selftest FAILED: %d failed, %d passed" % [_failed, _passed])
		quit(1)
		return
	print("run_hitch_profiler selftest OK: %d passed" % _passed)
	quit(0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func _test_begin_end() -> void:
	HitchProfiler.reset()
	var t := HitchProfiler.begin()
	OS.delay_usec(5000)
	var ms := HitchProfiler.end(HitchProfiler.LABEL_NPC_LOCOMOTION, t, "probe")
	_ok(ms >= 4.0, "timed sleep >= 4ms (got %.2f)" % ms)


func _spawn_bandit(host: Node3D) -> Node:
	var scene: PackedScene = load("res://characters/groyper/groyper_bandit_npc.tscn") as PackedScene
	if scene == null:
		return null
	var enemy: Node = scene.instantiate()
	if enemy != null:
		enemy.set_meta(&"canyon_raider", true)
		host.add_child(enemy)
	return enemy


func _test_bandit_spawn_cache() -> void:
	var cache_script: GDScript = load("res://characters/groyper/groyper_npc_anim_cache.gd") as GDScript
	_ok(cache_script != null, "npc anim cache loads")
	if cache_script == null:
		return

	# Mirror run_director.begin_run: warm under "fade" before first spawn.
	HitchProfiler.reset()
	var warm_t := HitchProfiler.begin()
	cache_script.call("warm")
	var warm_ms := HitchProfiler.end(&"director.anim_warm", warm_t)
	_ok(warm_ms > 0.0, "anim warm timed (%.1fms)" % warm_ms)

	var host := Node3D.new()
	host.name = "EnemyHost"
	root.add_child(host)

	HitchProfiler.reset()
	var first := _spawn_bandit(host)
	_ok(first != null, "first bandit spawns")
	for i in 6:
		await process_frame
	var first_loco := HitchProfiler.get_max_ms(HitchProfiler.LABEL_NPC_LOCOMOTION)
	_ok(first_loco > 0.0, "first locomotion timed (%.1fms)" % first_loco)

	HitchProfiler.reset()
	var second := _spawn_bandit(host)
	_ok(second != null, "second bandit spawns")
	for i in 6:
		await process_frame
	var second_loco := HitchProfiler.get_max_ms(HitchProfiler.LABEL_NPC_LOCOMOTION)
	_ok(second_loco > 0.0, "second locomotion timed (%.1fms)" % second_loco)

	print(
		"bandit anim cache probe: warm=%.1fms first=%.1fms second=%.1fms"
		% [warm_ms, first_loco, second_loco]
	)
	_ok(first_loco < 40.0, "post-warm first spawn < 40ms (got %.1f)" % first_loco)
	_ok(second_loco < 40.0, "second spawn < 40ms (got %.1f)" % second_loco)

	if first != null:
		first.queue_free()
	if second != null:
		second.queue_free()
	host.queue_free()
	await process_frame
