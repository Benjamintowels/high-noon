extends CharacterBody3D
class_name ChiefGetchaActor

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _npc_locomotion_audio: Node
var _melee_stun_timer := 0.0
var _knockback_hold_timer := 0.0


func _ready() -> void:
	GroyperBodyUtils.configure_ground_physics(self)
	GroyperBodyUtils.apply_model_baseline(_model)
	_bind_rig()
	_on_actor_ready()


func _on_actor_ready() -> void:
	pass


func _bind_rig() -> void:
	_body = _model.get_node("ChiefGetchaRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)


func snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	# The spawn marker rotates the CharacterBody3D root, so convert the
	# world-space facing yaw into a Model-local yaw. Without this subtraction
	# the root rotation is double-counted and the boss moonwalks (faces the
	# opposite way from travel).
	var world_yaw := MeshyLocomotionUtils.facing_yaw_for_direction(direction)
	return world_yaw - global_rotation.y


func setup_npc_locomotion_audio() -> void:
	if _npc_locomotion_audio != null:
		return
	const LocomotionAudioScript := preload("res://gameplay/audio/locomotion_audio.gd")
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
