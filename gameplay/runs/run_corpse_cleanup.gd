extends Node

## Roguelike-only corpse despawn: wait for the ragdoll to settle, hold briefly,
## then fade + sink into the ground before freeing the actor. Attached as a
## child of the defeated enemy by RunDirector.

const META_KEY := &"run_corpse_cleanup"
const SETTLE_TIMEOUT_SEC := 5.0
const HOLD_AFTER_SETTLE_SEC := 2.75
const FADE_SINK_DURATION_SEC := 2.0
const SINK_DEPTH := 1.85
const FORCE_FADE_DURATION_SEC := 0.85
const POLL_STEP_SEC := 0.1

var _corpse: Node3D
var _force_now := false
var _fading := false


static func attach(corpse: Node3D) -> void:
	if corpse == null or not is_instance_valid(corpse):
		return
	if corpse.has_meta(META_KEY):
		return
	corpse.set_meta(META_KEY, true)
	# Avoid self-preload cycles; resolve the script from this instance's path.
	var script: Script = load("res://gameplay/runs/run_corpse_cleanup.gd") as Script
	if script == null:
		corpse.queue_free()
		return
	var node: Node = (script as GDScript).new()
	node.name = "RunCorpseCleanup"
	corpse.add_child(node)


static func force_despawn(corpse: Node3D) -> void:
	if corpse == null or not is_instance_valid(corpse):
		return
	attach(corpse)
	var cleanup := corpse.get_node_or_null("RunCorpseCleanup")
	if cleanup != null and cleanup.has_method("force_now"):
		cleanup.call("force_now")
	elif is_instance_valid(corpse):
		corpse.queue_free()


func force_now() -> void:
	_force_now = true


func _ready() -> void:
	_corpse = get_parent() as Node3D
	if _corpse == null:
		queue_free()
		return
	_run_cleanup()


func _run_cleanup() -> void:
	await _wait_until_ready_to_fade()
	if not is_instance_valid(_corpse):
		queue_free()
		return
	await _fade_and_sink()
	if is_instance_valid(_corpse):
		_corpse.queue_free()


func _wait_until_ready_to_fade() -> void:
	var elapsed := 0.0
	while is_instance_valid(_corpse) and not _force_now:
		if _is_ragdoll_settled_or_absent():
			break
		await get_tree().create_timer(POLL_STEP_SEC).timeout
		elapsed += POLL_STEP_SEC
		if elapsed >= SETTLE_TIMEOUT_SEC:
			break

	if not is_instance_valid(_corpse) or _force_now:
		return

	var hold_left := HOLD_AFTER_SETTLE_SEC
	while hold_left > 0.0 and is_instance_valid(_corpse) and not _force_now:
		var step := minf(POLL_STEP_SEC, hold_left)
		await get_tree().create_timer(step).timeout
		hold_left -= step


func _is_ragdoll_settled_or_absent() -> bool:
	if _corpse == null or not is_instance_valid(_corpse):
		return true
	var ragdoll := _find_ragdoll(_corpse)
	if ragdoll == null:
		# No ragdoll at all (standing / failed activate) — don't linger.
		return true
	if ragdoll.has_method("is_settled") and bool(ragdoll.is_settled()):
		return true
	# Inactive and never settled: treat as ready (fallback collapse, etc.).
	if ragdoll.has_method("is_active") and not bool(ragdoll.is_active()):
		return true
	return false


func _fade_and_sink() -> void:
	if _fading or _corpse == null or not is_instance_valid(_corpse):
		return
	_fading = true

	var ragdoll := _find_ragdoll(_corpse)
	if ragdoll != null and ragdoll.has_method("freeze_for_despawn"):
		ragdoll.freeze_for_despawn()

	var duration := FORCE_FADE_DURATION_SEC if _force_now else FADE_SINK_DURATION_SEC
	var end_y := _corpse.global_position.y - SINK_DEPTH
	var meshes := _collect_fade_targets(_corpse)

	var tween := _corpse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_corpse, "global_position:y", end_y, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for geo in meshes:
		if geo != null and is_instance_valid(geo):
			tween.tween_property(geo, "transparency", 1.0, duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished


func _collect_fade_targets(root: Node3D) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		var geo := node as GeometryInstance3D
		if geo != null:
			out.append(geo)
	return out


func _find_ragdoll(corpse: Node3D) -> Node:
	if corpse == null:
		return null
	if corpse.has_method("get_lasso_ragdoll"):
		var via_getter = corpse.call("get_lasso_ragdoll")
		if via_getter != null:
			return via_getter
	var child := corpse.get_node_or_null("Ragdoll")
	if child != null:
		return child
	if corpse.get("_ragdoll") != null:
		return corpse.get("_ragdoll")
	return null
