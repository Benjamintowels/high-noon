extends GroyperActor
class_name FarmerNpc

const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const YELLOW_HAT_MATERIAL := preload("res://characters/groyper/cowboy_hat_material_yellow.tres")
const WEAPON_PICKUP_SCENE := preload("res://gameplay/world/weapon_pickup.tscn")

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const LOCOMOTION_BLEND := &"LocomotionBlend"
const REWARD_GRAM := 25

@export var speaker_name := "Farmer"

@onready var _interact_area: Area3D = $InteractArea

var _duel_hat
var _player_in_range: Node3D
var _talking := false
var _reward_claimed := false
var _voice_player: AudioStreamPlayer3D


func _on_actor_ready() -> void:
	add_to_group("farmer_npc")
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


func _process(_delta: float) -> void:
	if _voice_player == null or not is_instance_valid(_voice_player) or not _voice_player.playing:
		return
	_voice_player.global_position = get_voice_world_position()


func interact(player: Node3D) -> void:
	if _talking or player == null:
		return

	_talking = true
	velocity = Vector3.ZERO
	_player_in_range = player

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	if _reward_claimed:
		_show_post_quest_dialog(player)
	elif CowWrangleQuest.is_ready_for_reward() and not _reward_claimed:
		_show_reward_dialog(player)
	elif CowWrangleQuest.accepted:
		_show_hint_dialog(player)
	else:
		_show_intro_dialog(player)


func get_interact_hint() -> String:
	return "Talk"


func reset_for_quest() -> void:
	_reward_claimed = false
	_talking = false
	_stop_voice()


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.45, 0.0)


func _show_intro_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["My cows got loose! I'm screwed!"]),
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Help the Farmer", "That sucks"]),
				func(choice_index: int) -> void:
					if choice_index == 0:
						_on_player_accepted_help(player)
					else:
						DialogManager.hide_dialog()
						_end_dialog(player)
			),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func _on_player_accepted_help(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Here you might need this"]),
		func() -> void:
			_grant_quest_lasso()
			CowWrangleQuest.begin_quest()
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func _show_hint_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["I saw them over by that funny looking rock"]),
		func() -> void:
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func _show_reward_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray([
			"Gee thanks mister! you saved my hide",
			"Take this for your troubles",
		]),
		func() -> void:
			_reward_claimed = true
			CowWrangleQuest.mark_reward_claimed()
			_end_dialog(player),
		speaker_name,
		func(line_index: int) -> void:
			_play_gropyptalk()
			if line_index == 1:
				_give_reward()
	)


func _show_post_quest_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray([
			"Remember when you wrangles those steer for me?",
			"That was crazy",
		]),
		func() -> void:
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func _give_reward() -> void:
	if _reward_claimed:
		return
	_reward_claimed = true
	PlayerInventory.add_gram(REWARD_GRAM)
	RewardPopupManager.show_gram_reward(REWARD_GRAM)


func _grant_quest_lasso() -> void:
	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.LASSO):
		return

	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = GroyperWeapons.Id.LASSO
	get_parent().add_child(pickup)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	pickup.global_position = global_position + forward * 1.35
	pickup.global_position.y = global_position.y
	pickup.global_rotation.y = global_rotation.y


func _play_gropyptalk() -> void:
	_stop_voice()
	var stream := GameAudio.pick_gropyptalk_voice()
	if stream == null:
		return

	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "FarmerVoice"
	_voice_player.stream = stream
	_voice_player.max_distance = 48.0
	_voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice_player.unit_size = 2.0
	_voice_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
	_voice_player.volume_db = randf_range(
		-GameAudio.VOLUME_JITTER_DB * 0.5,
		GameAudio.VOLUME_JITTER_DB * 0.5
	)
	add_child(_voice_player)
	_voice_player.global_position = get_voice_world_position()
	_voice_player.finished.connect(_on_voice_finished)
	_voice_player.play()


func _stop_voice() -> void:
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.queue_free()
	_voice_player = null


func _on_voice_finished() -> void:
	_stop_voice()


func _end_dialog(player: Node3D) -> void:
	_talking = false
	_stop_voice()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _setup_hat() -> void:
	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton, YELLOW_HAT_MATERIAL)
	_duel_hat.prepare_for_round(false)


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("FarmerNpc: missing AnimationPlayer on groyper body.")
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
		push_error("FarmerNpc: locomotion clips missing on AnimationPlayer.")
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
			"FarmerNpc: failed to load locomotion clip '%s' from %s."
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
