extends RefCounted
class_name MeleeHitFX

const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const FLASH_DURATION := 0.14
const FLASH_ENERGY := 5.5
const FLASH_RANGE := 2.2
const ATTACKER_SHAKE := 0.32
const VICTIM_SHAKE := 0.58


static func play(
	attacker: Node,
	target: Node,
	hit_position: Vector3,
	direction: Vector3
) -> void:
	if target == null:
		return

	var fx_parent := ImpactFXScript.parent_for(target)
	DirectionalImpactFXScript.spawn(fx_parent, hit_position, direction)
	_flash_target(target, hit_position)

	if attacker != null and attacker.is_in_group(&"overworld_player"):
		_apply_camera_shake(attacker, ATTACKER_SHAKE)
	if target.is_in_group(&"overworld_player"):
		_apply_camera_shake(target, VICTIM_SHAKE)


static func _apply_camera_shake(actor: Node, strength: float) -> void:
	if actor != null and actor.has_method("apply_camera_shake"):
		actor.apply_camera_shake(strength)


static func _flash_target(target: Node, hit_position: Vector3) -> void:
	var root: Node3D = null
	if target.has_method("get_lasso_drag_visual"):
		root = target.get_lasso_drag_visual() as Node3D
	elif target is Node3D:
		var model := (target as Node3D).get_node_or_null("Model")
		root = model as Node3D if model != null else target as Node3D
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
