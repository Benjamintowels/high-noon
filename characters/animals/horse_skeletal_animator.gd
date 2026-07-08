extends Node
class_name HorseSkeletalAnimator

const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")
const HorseAnimUtilsScript := preload("res://characters/animals/horse_anim_utils.gd")
const AnimatorScript := preload("res://characters/animals/stupid_horse_animator.gd")

var _player: AnimationPlayer
var _bowing := false
var _frozen := false
var _mounted := false
var _loco_mode: int = AnimatorScript.Mode.IDLE
var _locomoting := false
var _idle_holding := false
var _active_clip: StringName = StringName()
var _active_speed_scale := 1.0
var _bow_finished: Callable = Callable()


static func attach(visual: Node3D) -> Node:
	var animator := HorseSkeletalAnimator.new()
	animator.name = "HorseSkeletalAnimator"
	visual.add_child(animator)
	animator._setup(visual)
	return animator


func _setup(visual: Node3D) -> void:
	var RigAnimUtils := preload("res://characters/groyper/rig_anim_utils.gd")
	_player = RigAnimUtils.find_animation_player(visual)
	if _player == null:
		push_error("HorseSkeletalAnimator: missing AnimationPlayer on rigged horse visual.")
		return
	if not _has_gameplay_clips():
		if not HorseAnimUtilsScript.ensure_library(_player):
			push_error("HorseSkeletalAnimator: failed to load horse animation library.")
			return
	if not _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.connect(_on_animation_finished)
	_play_idle()


func uses_skeletal() -> bool:
	return _player != null


func set_mounted(mounted: bool) -> void:
	_mounted = mounted
	if mounted:
		_cancel_bow()


func set_mode(next_mode: int) -> void:
	_loco_mode = next_mode


func freeze_for_death() -> void:
	_frozen = true
	_locomoting = false
	_idle_holding = false
	_cancel_bow()
	if _player != null:
		_player.active = false
		if _player.is_playing():
			_player.stop()


func can_bow() -> bool:
	return _player != null and not _frozen and not _bowing and not _mounted


func play_bow(on_finished: Callable = Callable()) -> bool:
	if not can_bow():
		return false
	_bowing = true
	_idle_holding = false
	_locomoting = false
	_bow_finished = on_finished
	_play_clip(HorseAnimConfigScript.BOW_CLIP, 1.0)
	return true


func update_animation(
	_delta: float,
	horizontal_speed: float,
	sprinting: bool = false,
	mounted: bool = false
) -> void:
	if _player == null or _frozen or _bowing:
		return

	_mounted = mounted

	var in_run_mode := _loco_mode == AnimatorScript.Mode.RUN
	var in_walk_mode := _loco_mode == AnimatorScript.Mode.WALK
	var sprinting_locomotion := (
		sprinting
		or in_run_mode
		or horizontal_speed > HorseAnimConfigScript.SPRINT_SPEED_THRESHOLD
	)
	var walking := (
		in_walk_mode
		or horizontal_speed > HorseAnimConfigScript.WALK_SPEED_THRESHOLD
	)

	if mounted:
		if in_run_mode:
			sprinting_locomotion = true
			walking = true
		elif in_walk_mode and horizontal_speed > 0.01:
			walking = true

	if sprinting_locomotion and _has_clip(HorseAnimConfigScript.RUN_CLIP):
		_play_run()
	elif walking:
		_play_walk()
	else:
		_play_idle()


func _has_gameplay_clips() -> bool:
	if _player == null or not _player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		return false
	var library: AnimationLibrary = _player.get_animation_library(HorseAnimConfigScript.LIBRARY)
	return (
		library.has_animation(String(HorseAnimConfigScript.WALK_CLIP))
		and library.has_animation(String(HorseAnimConfigScript.RUN_CLIP))
		and library.has_animation(String(HorseAnimConfigScript.BOW_CLIP))
	)


func _has_clip(clip_name: StringName) -> bool:
	return _player.has_animation(HorseAnimConfigScript.clip_path(clip_name))


func _play_walk() -> void:
	_idle_holding = false
	_locomoting = true
	_play_clip(HorseAnimConfigScript.WALK_CLIP, 1.0)


func _play_run() -> void:
	_idle_holding = false
	_locomoting = true
	_play_clip(HorseAnimConfigScript.RUN_CLIP, 1.0)


func _play_idle() -> void:
	_locomoting = false
	if _idle_holding and _is_playing_clip(HorseAnimConfigScript.BOW_CLIP):
		return
	_play_clip(HorseAnimConfigScript.BOW_CLIP, 1.0)


func _play_clip(clip_name: StringName, speed_scale: float) -> void:
	var clip_path := HorseAnimConfigScript.clip_path(clip_name)
	if not _player.has_animation(clip_path):
		return
	if (
		_active_clip == clip_path
		and _player.is_playing()
		and is_equal_approx(_active_speed_scale, speed_scale)
	):
		return
	_idle_holding = false
	_active_clip = clip_path
	_active_speed_scale = speed_scale
	_player.speed_scale = speed_scale
	_player.play(clip_path)


func _hold_idle_pose() -> void:
	var clip_path := HorseAnimConfigScript.clip_path(HorseAnimConfigScript.BOW_CLIP)
	if not _player.has_animation(clip_path):
		return
	var animation: Animation = _player.get_animation(clip_path)
	_player.play(clip_path)
	_player.seek(maxf(animation.length - 0.001, 0.0))
	_player.pause()
	_idle_holding = true
	_active_clip = clip_path
	_active_speed_scale = 1.0


func _cancel_bow() -> void:
	_bowing = false
	_bow_finished = Callable()
	if _is_playing_clip(HorseAnimConfigScript.BOW_CLIP):
		_player.stop()
		_active_clip = StringName()
		_idle_holding = false
		_play_idle()


func _is_playing_clip(clip_name: StringName) -> bool:
	if _player == null:
		return false
	if _idle_holding and clip_name == HorseAnimConfigScript.BOW_CLIP:
		return _active_clip == HorseAnimConfigScript.clip_path(clip_name)
	if not _player.is_playing():
		return false
	return String(_player.current_animation).ends_with(String(clip_name))


func _on_animation_finished(animation_name: StringName) -> void:
	var anim_str := String(animation_name)
	if not anim_str.ends_with(String(HorseAnimConfigScript.BOW_CLIP)):
		if anim_str.ends_with(String(HorseAnimConfigScript.WALK_CLIP)) and _locomoting:
			_play_clip(HorseAnimConfigScript.WALK_CLIP, _active_speed_scale)
		elif anim_str.ends_with(String(HorseAnimConfigScript.RUN_CLIP)) and _locomoting:
			_play_clip(HorseAnimConfigScript.RUN_CLIP, _active_speed_scale)
		return

	if _bowing:
		_bowing = false
		_active_clip = StringName()
		if _bow_finished.is_valid():
			var callback := _bow_finished
			_bow_finished = Callable()
			callback.call()
		if not _locomoting:
			_hold_idle_pose()
		return

	if not _locomoting:
		_hold_idle_pose()
