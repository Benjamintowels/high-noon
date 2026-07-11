@tool
extends Node

const TwoHandedConfigScript := preload("res://characters/groyper/two_handed_config.gd")

## Attach to groyper_body.tscn. Set a per-clip yaw tweak in degrees, then toggle
## apply_yaw_tweak to rotate that clip's Hips keys in two_handed.tres and save.
## Tweaks are incremental (each apply adds on top of the current facing) and the
## degree fields reset to 0 after applying — undo a tweak by applying its negative.

## Skeleton-space up axis on the groyper rig (Hips has no parent bone, so its
## rotation keys live directly in skeleton space where +Z is up).
const UP := Vector3(0.0, 0.0, 1.0)

@export_range(-90.0, 90.0, 0.1) var idle_yaw_deg: float = 0.0
@export_range(-90.0, 90.0, 0.1) var walk_yaw_deg: float = 0.0
@export_range(-90.0, 90.0, 0.1) var sprint_yaw_deg: float = 0.0

@export var apply_yaw_tweak: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		apply_yaw_tweak = false
		if _apply(idle_yaw_deg, walk_yaw_deg, sprint_yaw_deg):
			idle_yaw_deg = 0.0
			walk_yaw_deg = 0.0
			sprint_yaw_deg = 0.0
			notify_property_list_changed()


func _apply(idle_deg: float, walk_deg: float, sprint_deg: float) -> bool:
	var library := load(TwoHandedConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error("TwoHandedYawAdjust: cannot load %s." % TwoHandedConfigScript.OUT_PATH)
		return false

	var changed := false
	var tweaks := [
		[TwoHandedConfigScript.CLIP_IDLE, idle_deg],
		[TwoHandedConfigScript.CLIP_WALK, walk_deg],
		[TwoHandedConfigScript.CLIP_SPRINT, sprint_deg],
	]
	for entry in tweaks:
		var degrees: float = entry[1]
		if is_zero_approx(degrees):
			continue
		if _rotate_hips(library.get_animation(entry[0]), degrees):
			print("TwoHandedYawAdjust: %s yawed %+.1f deg." % [entry[0], degrees])
			changed = true

	if not changed:
		return false
	var err := ResourceSaver.save(library, TwoHandedConfigScript.OUT_PATH)
	if err != OK:
		push_error("TwoHandedYawAdjust: save failed (%s)." % err)
		return false
	return true


func _rotate_hips(animation: Animation, degrees: float) -> bool:
	if animation == null:
		push_error("TwoHandedYawAdjust: clip missing from two_handed.tres.")
		return false
	var correction := Quaternion(UP, deg_to_rad(degrees))
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		if not String(animation.track_get_path(track_idx)).ends_with(":Hips"):
			continue
		for key_idx in animation.track_get_key_count(track_idx):
			var q: Quaternion = animation.track_get_key_value(track_idx, key_idx)
			animation.track_set_key_value(track_idx, key_idx, (correction * q).normalized())
		return true
	push_error("TwoHandedYawAdjust: no Hips rotation track found.")
	return false
