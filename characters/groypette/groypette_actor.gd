extends CharacterBody3D
class_name GroypetteActor

const LocomotionAudioScript := preload("res://gameplay/audio/locomotion_audio.gd")

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _npc_locomotion_audio: Node


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
	_body = _model.get_node("GroypetteRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)


func snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)


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
