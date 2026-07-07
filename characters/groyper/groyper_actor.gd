extends CharacterBody3D
class_name GroyperActor

## Shared CharacterBody3D foundation for every walking groyper (NPCs + overworld player).
## Model placement, collision, and rig wiring live here — subclasses only add behavior.

const LocomotionAudioScript := preload("res://gameplay/audio/locomotion_audio.gd")

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _npc_locomotion_audio: Node
var _melee_stun_timer := 0.0
var _knockback_hold_timer := 0.0


func _ready() -> void:
	_ensure_scene_nodes()
	GroyperBodyUtils.configure_ground_physics(self)
	GroyperBodyUtils.apply_model_baseline(_model)
	_bind_rig()
	MeshyCharacterMaterials.apply_outdoor_skin(_body)
	_on_actor_ready()


func _ensure_scene_nodes() -> void:
	if _model == null:
		_model = get_node_or_null("Model") as Node3D
	if _animation_tree == null:
		_animation_tree = get_node_or_null("AnimationTree") as AnimationTree


func _on_actor_ready() -> void:
	pass


func _bind_rig() -> void:
	_body = _model.get_node("GroyperRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)


func snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	var world_yaw := GroyperBodyUtils.facing_yaw_for_direction(direction)
	return world_yaw - global_rotation.y


func move_with_ground_snap(snap_floor: bool = true) -> bool:
	return GroyperBodyUtils.move_and_slide_grounded(self, snap_floor)


func setup_npc_locomotion_audio() -> void:
	if _npc_locomotion_audio != null:
		return

	_npc_locomotion_audio = LocomotionAudioScript.new()
	_npc_locomotion_audio.name = "NpcLocomotionAudio"
	add_child(_npc_locomotion_audio)
	_npc_locomotion_audio.setup(self, LocomotionAudioScript.Kind.NPC)


func update_npc_locomotion_audio(
	delta: float,
	horizontal_speed: float,
	moving: bool,
	sprinting: bool
) -> void:
	if _npc_locomotion_audio == null:
		return

	_npc_locomotion_audio.update(
		delta,
		moving,
		sprinting,
		horizontal_speed,
		is_on_floor()
	)


func apply_melee_stun(duration: float) -> void:
	_melee_stun_timer = maxf(_melee_stun_timer, duration)


func is_melee_stunned() -> bool:
	return _melee_stun_timer > 0.0


func tick_melee_stun(delta: float) -> void:
	_melee_stun_timer = maxf(_melee_stun_timer - delta, 0.0)
	_knockback_hold_timer = maxf(_knockback_hold_timer - delta, 0.0)


func hold_knockback_velocity(duration: float) -> void:
	_knockback_hold_timer = maxf(_knockback_hold_timer, duration)


func should_preserve_knockback_velocity() -> bool:
	return _knockback_hold_timer > 0.0

