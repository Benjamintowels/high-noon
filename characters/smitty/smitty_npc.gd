extends SmittyActor
class_name SmittyNpc

const HammerStrikeFlash := preload("res://gameplay/fx/hammer_strike_flash.gd")

const GRAVITY := 22.0
const FACING_SPEED := 10.0

const RETURN_GREETING_LINES: Array[String] = [
	"What can I do for you today?",
	"I make things",
	"Let's see what we have",
]

@export var speaker_name := "Smitty"

@onready var _interact_area: Area3D = $InteractArea
@onready var _strike_flash: HammerStrikeFlash = $ForgeStrike/StrikeFlash

var _player_in_range: Node3D
var _talking := false
var _hammer_work_blend := 1.0
var _hammer_cycle_length := 1.0
var _hammer_strike_timer := 0.0
var _voice_player: AudioStreamPlayer3D
var _strike_tween: Tween


func _on_actor_ready() -> void:
	add_to_group("smitty_npc")
	velocity = Vector3.ZERO
	_setup_work_animation()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_start_hammer_strike_loop()


func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if _talking and _player_in_range != null:
		_face_position(_player_in_range.global_position, delta)
	move_and_slide()


func _process(delta: float) -> void:
	if _voice_player != null and is_instance_valid(_voice_player) and _voice_player.playing:
		_voice_player.global_position = get_voice_world_position()

	if _talking:
		return

	_hammer_work_blend = lerpf(_hammer_work_blend, 1.0, 8.0 * delta)
	_set_work_blend(_hammer_work_blend)


func interact(player: Node3D) -> void:
	if _talking or player == null:
		return

	_talking = true
	_player_in_range = player
	_stop_hammer_strike_loop()
	_blend_to_idle()

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	if not BlacksmithProgress.met_smitty:
		_show_first_meeting_dialog(player)
	else:
		_show_return_dialog(player)


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.55, 0.0)


func get_interact_hint() -> String:
	return "Talk"


func _show_first_meeting_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Hello, I've never seen you before"]),
		func() -> void:
			BlacksmithProgress.mark_met()
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _show_return_dialog(player: Node3D) -> void:
	var line := RETURN_GREETING_LINES[randi() % RETURN_GREETING_LINES.size()]
	DialogManager.show_dialog_sequence(
		PackedStringArray([line]),
		func() -> void:
			_open_upgrade_menu(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _open_upgrade_menu(player: Node3D) -> void:
	DialogManager.hide_dialog()
	BlacksmithUpgradeManager.show_menu(
		func() -> void:
			_end_dialog(player)
	)


func _end_dialog(player: Node3D) -> void:
	_talking = false
	_stop_voice()
	_blend_to_hammer()
	_start_hammer_strike_loop()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _blend_to_idle() -> void:
	_hammer_work_blend = 0.0
	_set_work_blend(0.0)


func _blend_to_hammer() -> void:
	_hammer_work_blend = 1.0
	_set_work_blend(1.0)


func _setup_work_animation() -> void:
	if _animation_player == null:
		push_error("SmittyNpc: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_work_clip(library, SmittyAnimConfig.CLIP_IDLE, SmittyAnimConfig.MESHY_IDLE, true)
	_add_work_clip(library, SmittyAnimConfig.CLIP_HAMMER, SmittyAnimConfig.MESHY_HAMMER, true)

	if _animation_player.has_animation_library(SmittyAnimConfig.WORK_LIBRARY):
		_animation_player.remove_animation_library(SmittyAnimConfig.WORK_LIBRARY)
	_animation_player.add_animation_library(SmittyAnimConfig.WORK_LIBRARY, library)

	var idle_path := _anim_path(SmittyAnimConfig.CLIP_IDLE)
	var hammer_path := _anim_path(SmittyAnimConfig.CLIP_HAMMER)
	if not _animation_player.has_animation(idle_path) or not _animation_player.has_animation(hammer_path):
		push_error("SmittyNpc: work clips missing on AnimationPlayer.")
		return

	var hammer_anim := _animation_player.get_animation(hammer_path)
	_hammer_cycle_length = maxf(hammer_anim.length, 0.35)

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var hammer_node := AnimationNodeAnimation.new()
	hammer_node.animation = hammer_path

	var blend := AnimationNodeBlend2.new()
	blend.sync = true

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(SmittyAnimConfig.WORK_BLEND_NODE, blend)
	blend_tree.add_node(&"IdleAnim", idle_node)
	blend_tree.add_node(&"HammerAnim", hammer_node)
	blend_tree.connect_node(SmittyAnimConfig.WORK_BLEND_NODE, 0, &"IdleAnim")
	blend_tree.connect_node(SmittyAnimConfig.WORK_BLEND_NODE, 1, &"HammerAnim")
	blend_tree.connect_node(&"output", 0, SmittyAnimConfig.WORK_BLEND_NODE)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_player.stop()
	_set_work_blend(1.0)


func _add_work_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop: bool
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(SmittyAnimConfig.MERGED_SCENE, meshy_clip)
	if raw == null:
		push_error("SmittyNpc: failed to load clip '%s'." % meshy_clip)
		return
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	library.add_animation(clip_name, animation)


func _anim_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [SmittyAnimConfig.WORK_LIBRARY, clip_name])


func _set_work_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % SmittyAnimConfig.WORK_BLEND_NODE,
		clampf(value, 0.0, 1.0)
	)


func _start_hammer_strike_loop() -> void:
	_stop_hammer_strike_loop()
	_schedule_next_strike()


func _stop_hammer_strike_loop() -> void:
	if _strike_tween != null and _strike_tween.is_valid():
		_strike_tween.kill()
	_strike_tween = null


func _schedule_next_strike() -> void:
	if _talking:
		return
	var strike_delay := _hammer_cycle_length * SmittyAnimConfig.HAMMER_STRIKE_NORMALIZED
	_strike_tween = create_tween()
	_strike_tween.tween_interval(strike_delay)
	_strike_tween.tween_callback(_on_hammer_strike)
	_strike_tween.tween_interval(maxf(_hammer_cycle_length - strike_delay, 0.05))
	_strike_tween.finished.connect(_on_hammer_cycle_finished, CONNECT_ONE_SHOT)


func _on_hammer_cycle_finished() -> void:
	if not _talking:
		_schedule_next_strike()


func _on_hammer_strike() -> void:
	if _talking:
		return
	if _strike_flash != null:
		_strike_flash.flash()
	GameAudio.play_hammer_chink(self, global_position + Vector3(0.0, 0.9, 0.35))


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _play_talk_voice() -> void:
	_stop_voice()
	var stream := SmittyAudio.pick_talk_voice()
	if stream == null:
		return
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "SmittyVoice"
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
	_voice_player = null


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
