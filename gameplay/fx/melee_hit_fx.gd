extends RefCounted
class_name MeleeHitFX

const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

const FLASH_DURATION := 0.14
const FLASH_ENERGY := 5.5
const FLASH_RANGE := 2.2
const ATTACKER_SHAKE := 0.55
const VICTIM_SHAKE := 0.75
const HITSTOP_DURATION := 0.09
const IMPACT_PIXEL_SIZE := 0.026
const DUST_COUNT := 3
const JOLT_DISTANCE := 0.045
const JOLT_OUT := 0.04
const JOLT_BACK := 0.1
const JOLT_META := &"melee_hit_jolt_base"


## Shared connect package for successful damaging melee hits.
## options:
##   skip_hitstop (bool) — do not request attacker linger
##   skip_dust (bool) — skip light ground puff (heavy packages supply their own)
##   skip_impact_sprite (bool) — skip directional impact pop (e.g. knife blood)
##   skip_flash_light (bool) — skip omni light flash
##   skip_jolt (bool) — skip victim Model spring
##   hitstop_duration (float) — override linger length
static func play(
	attacker: Node,
	target: Node,
	hit_position: Vector3,
	direction: Vector3,
	options: Dictionary = {}
) -> void:
	if target == null:
		return

	var fx_parent := ImpactFXScript.parent_for(target)
	if not bool(options.get("skip_impact_sprite", false)):
		DirectionalImpactFXScript.spawn_pop(
			fx_parent,
			hit_position,
			direction,
			float(options.get("impact_pixel_size", IMPACT_PIXEL_SIZE))
		)
	if not bool(options.get("skip_flash_light", false)):
		_flash_target(target, hit_position)
	if not bool(options.get("skip_jolt", false)):
		_jolt_model(target, direction)
	if not bool(options.get("skip_dust", false)) and target is Node3D:
		var ground := (target as Node3D).global_position + Vector3(0.0, 0.12, 0.0)
		SmokePuffFXScript.spawn_burst(fx_parent, ground, DUST_COUNT)

	if attacker != null and attacker.is_in_group(&"overworld_player"):
		_apply_camera_shake(attacker, ATTACKER_SHAKE)
	if target.is_in_group(&"overworld_player"):
		_apply_camera_shake(target, VICTIM_SHAKE)

	if not bool(options.get("skip_hitstop", false)):
		_request_hitstop(attacker, float(options.get("hitstop_duration", HITSTOP_DURATION)))


static func _request_hitstop(attacker: Node, duration: float) -> void:
	if attacker == null or duration <= 0.0:
		return
	if attacker.has_method("begin_melee_hitstop"):
		attacker.begin_melee_hitstop(duration)


static func _apply_camera_shake(actor: Node, strength: float) -> void:
	if actor != null and actor.has_method("apply_camera_shake"):
		actor.apply_camera_shake(strength)


static func _get_visual_root(target: Node) -> Node3D:
	if target == null:
		return null
	if target.has_method("get_lasso_drag_visual"):
		var drag := target.get_lasso_drag_visual() as Node3D
		if drag != null:
			return drag
	if target is Node3D:
		var model := (target as Node3D).get_node_or_null("Model")
		if model is Node3D:
			return model as Node3D
		return target as Node3D
	return null


static func _flash_target(target: Node, hit_position: Vector3) -> void:
	var root := _get_visual_root(target)
	if root == null:
		return

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.88, 0.62)
	light.light_energy = FLASH_ENERGY
	light.omni_range = FLASH_RANGE
	light.shadow_enabled = false
	root.add_child(light)
	light.position = root.to_local(hit_position)

	var tween := root.create_tween()
	tween.tween_property(light, "light_energy", 0.0, FLASH_DURATION)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(light.queue_free)


static func _jolt_model(target: Node, direction: Vector3) -> void:
	var root := _get_visual_root(target)
	if root == null or not is_instance_valid(root):
		return

	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	else:
		flat = flat.normalized()

	var base: Vector3
	if root.has_meta(JOLT_META):
		base = root.get_meta(JOLT_META) as Vector3
	else:
		base = root.position
		root.set_meta(JOLT_META, base)

	var peak := base + flat * JOLT_DISTANCE
	var tree := root.get_tree()
	if tree == null:
		return

	var tween := tree.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(root, "position", peak, JOLT_OUT)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "position", base, JOLT_BACK)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(root):
			return
		root.position = base
		if root.has_meta(JOLT_META):
			root.remove_meta(JOLT_META)
	)
