extends "res://gameplay/combat/knife_projectile.gd"

## Thrown torch. Flies and sticks like other thrown weapons, stays lit for a
## short burn, then extinguishes. Interact pickup works whether lit or out.

const TorchGripScene := preload("res://characters/groyper/torch_grip.tscn")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const LIT_DURATION := 10.0
const THROWN_DAMAGE := 1
const THROWN_VISUAL_SCALE := 1.0
const SPIN_SPEED_RAD := TAU * 1.6

var _visual_pivot: Node3D
var _torch_visual: Node3D
var _lit := true
var _lit_left := LIT_DURATION


static func spawn_thrown(
	parent: Node,
	origin: Vector3,
	direction: Vector3,
	speed: float,
	exclude: Array = [],
	shooter: Node3D = null
) -> Node3D:
	var projectile: Node3D = load("res://gameplay/combat/torch_projectile.gd").new()
	projectile.name = "TorchProjectile"
	parent.add_child(projectile)
	projectile._build_visual()
	projectile.setup(origin, direction, speed, exclude, shooter)
	return projectile


func _build_visual() -> void:
	_visual_pivot = Node3D.new()
	_visual_pivot.name = "SpinPivot"
	add_child(_visual_pivot)
	_torch_visual = TorchGripScene.instantiate()
	_torch_visual.name = "TorchGrip"
	_visual_pivot.add_child(_torch_visual)


func _process(delta: float) -> void:
	if not _stuck and _visual_pivot != null:
		_visual_pivot.rotate_x(SPIN_SPEED_RAD * GameTime.process_delta(delta))
	if _stuck and _lit:
		_lit_left -= GameTime.process_delta(delta)
		if _lit_left <= 0.0:
			_extinguish()


func _get_damage() -> int:
	return THROWN_DAMAGE


func _get_visual_scale() -> float:
	return THROWN_VISUAL_SCALE


func _get_pickup_label() -> String:
	return "Torch"


func _apply_pickup(player: Node3D) -> void:
	PlayerInventory.add_weapon(GroyperWeaponsScript.Id.TORCH)
	if (
		player.has_method("equip_weapon")
		and "_equipped_weapon" in player
		and player._equipped_weapon == GroyperWeaponsScript.Id.UNARMED
	):
		player.equip_weapon(GroyperWeaponsScript.Id.TORCH, false)


func _extinguish() -> void:
	_lit = false
	if _torch_visual == null:
		return
	var fire := _torch_visual.get_node_or_null("Fire")
	if fire != null and fire.has_method("extinguish"):
		fire.extinguish()
		return
	if fire == null:
		return
	var light := fire.get_node_or_null("Light") as OmniLight3D
	if light != null:
		light.visible = false
	var particles := fire.get_node_or_null("FireVFX") as CPUParticles3D
	if particles != null:
		particles.emitting = false
	var audio := fire.get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	if audio != null:
		audio.stop()
