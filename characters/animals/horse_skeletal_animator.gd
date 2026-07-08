extends Node
class_name HorseSkeletalAnimator

const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")
const HorseAnimUtilsScript := preload("res://characters/animals/horse_anim_utils.gd")
const AnimatorScript := preload("res://characters/animals/stupid_horse_animator.gd")

const BLEND_TIME := 0.28

var _player: AnimationPlayer
var _bowing := false
var _frozen := false
var _mounted := false
var _loco_mode: int = AnimatorScript.Mode.IDLE
var _active_locomotion_clip: StringName = StringName()
var _bow_finished: Callable = Callable()


static func attach(visual: Node3D) -> Node:
	var animator := HorseSkeletalAnimator.new()
	animator.name = "HorseSkeletalAnimator"
	visual.add_child(animator)
	animator._setup(visual)
	return animator


func _setup(visual: Node3D) -> void:
	var rig_anim_utils := preload("res://characters/groyper/rig_anim_utils.gd")
	_player = rig_anim_utils.find_animation_player(visual)
	if _player == null:
		push_error("HorseSkeletalAnimator: missing AnimationPlayer on rigged horse visual.")
		return
	if not HorseAnimUtilsScript.ensure_library(_player):
		push_error("HorseSkeletalAnimator: failed to load horse animation library.")
		return
	if not _has_gameplay_clips():
		push_error("HorseSkeletalAnimator: missing horse gameplay animation clips.")
		return
	_player.autoplay = StringName()
	if not _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.connect(_on_animation_finished)
	_play_locomotion_clip(HorseAnimConfigScript.IDLE_STAND_CLIP, 0.0)


func uses_skeletal() -> bool:
	return _player != null and not _frozen


func set_mounted(mounted: bool) -> void:
	_mounted = mounted
	if mounted:
		_abort_bow()


func set_mode(next_mode: int) -> void:
	_loco_mode = next_mode


func freeze_for_death() -> void:
	_frozen = true
	_abort_bow()
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
	_bow_finished = on_finished
	_active_locomotion_clip = StringName()
	_player.play(HorseAnimConfigScript.clip_path(HorseAnimConfigScript.BOW_CLIP), 0.18)
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
	var moving := horizontal_speed > HorseAnimConfigScript.WALK_SPEED_THRESHOLD
	var running := (
		sprinting
		or in_run_mode
		or horizontal_speed > HorseAnimConfigScript.SPRINT_SPEED_THRESHOLD
	)

	if mounted:
		moving = moving or in_walk_mode or in_run_mode
		if in_run_mode:
			running = true
		elif sprinting and moving:
			running = true

	var target_clip := HorseAnimConfigScript.IDLE_STAND_CLIP
	if moving and running and _has_clip(HorseAnimConfigScript.RUN_CLIP):
		target_clip = HorseAnimConfigScript.RUN_CLIP
	elif moving:
		target_clip = HorseAnimConfigScript.WALK_CLIP

	_play_locomotion_clip(target_clip, BLEND_TIME)


func _has_gameplay_clips() -> bool:
	if _player == null or not _player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		return false
	var library: AnimationLibrary = _player.get_animation_library(HorseAnimConfigScript.LIBRARY)
	return (
		library.has_animation(String(HorseAnimConfigScript.IDLE_STAND_CLIP))
		and library.has_animation(String(HorseAnimConfigScript.WALK_CLIP))
		and library.has_animation(String(HorseAnimConfigScript.RUN_CLIP))
		and library.has_animation(String(HorseAnimConfigScript.BOW_CLIP))
	)


func _has_clip(clip_name: StringName) -> bool:
	return _player.has_animation(HorseAnimConfigScript.clip_path(clip_name))


func _play_locomotion_clip(clip_name: StringName, blend_time: float) -> void:
	var clip_path := HorseAnimConfigScript.clip_path(clip_name)
	if not _player.has_animation(clip_path):
		return
	if _active_locomotion_clip == clip_path and _player.is_playing():
		return
	_active_locomotion_clip = clip_path
	_player.play(clip_path, blend_time)


func _restore_locomotion_after_bow() -> void:
	var clip_name := HorseAnimConfigScript.IDLE_STAND_CLIP
	if _loco_mode == AnimatorScript.Mode.RUN and _has_clip(HorseAnimConfigScript.RUN_CLIP):
		clip_name = HorseAnimConfigScript.RUN_CLIP
	elif _loco_mode == AnimatorScript.Mode.WALK:
		clip_name = HorseAnimConfigScript.WALK_CLIP
	_play_locomotion_clip(clip_name, BLEND_TIME)


func _abort_bow() -> void:
	if not _bowing:
		return
	_bowing = false
	_bow_finished = Callable()
	if _player != null and _player.is_playing():
		var current := String(_player.current_animation)
		if current.ends_with(String(HorseAnimConfigScript.BOW_CLIP)):
			_player.stop()
	_restore_locomotion_after_bow()


func _on_animation_finished(animation_name: StringName) -> void:
	if not String(animation_name).ends_with(String(HorseAnimConfigScript.BOW_CLIP)):
		return
	if not _bowing:
		return

	_bowing = false
	if _bow_finished.is_valid():
		var callback := _bow_finished
		_bow_finished = Callable()
		callback.call()
	_restore_locomotion_after_bow()
