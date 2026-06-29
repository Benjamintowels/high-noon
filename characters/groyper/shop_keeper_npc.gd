extends GroyperActor
class_name ShopKeeperNpc

const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const WHITE_HAT_MATERIAL := preload("res://characters/groyper/cowboy_hat_material_white.tres")

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const LOCOMOTION_BLEND := &"LocomotionBlend"

@export var speaker_name := "Shopkeeper"
@export var dialog_lines: PackedStringArray = PackedStringArray([
	"Howdy! Let me know what you need",
])

@onready var _interact_area: Area3D = $InteractArea

var _duel_hat
var _player_in_range: Node3D
var _talking := false


func _on_actor_ready() -> void:
	add_to_group("shop_keeper")
	_setup_hat()
	_setup_locomotion()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	call_deferred("_finalize_spawn")


func _finalize_spawn() -> void:
	snap_to_floor()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = 0.0
	velocity.z = 0.0

	if _talking and _player_in_range != null:
		_face_position(_player_in_range.global_position, delta)

	move_and_slide()


func interact(player: Node3D) -> void:
	if _talking or player == null:
		return

	_talking = true
	velocity = Vector3.ZERO
	_player_in_range = player

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		dialog_lines,
		func() -> void:
			_end_dialog(player),
		speaker_name
	)


func get_interact_hint() -> String:
	return "Talk"


func _end_dialog(player: Node3D) -> void:
	_talking = false
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _setup_hat() -> void:
	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton, WHITE_HAT_MATERIAL)
	_duel_hat.prepare_for_round(false)


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("ShopKeeperNpc: missing AnimationPlayer on groyper body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	if not _animation_player.has_animation(idle_path) or not _animation_player.has_animation(walk_path):
		push_error("ShopKeeperNpc: locomotion clips missing on AnimationPlayer.")
		return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.connect_node(&"output", 0, LOCOMOTION_BLEND)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)


func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"ShopKeeperNpc: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := GroyperBodyUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
