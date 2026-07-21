extends RefCounted

## Process-lifetime AnimationLibrary cache for town NPCs / bandits.
## Spawn used to rebuild locomotion + chair_sit from FBX and deep-copy every
## authored .tres each time (~180ms). Libraries are playback-only — share one
## prepared Ref across all AnimationPlayers; keep AnimationTree per instance.

const RigAnimConfig := preload("res://characters/groyper/rig_anim_config.gd")
const RigAnimUtils := preload("res://characters/groyper/rig_anim_utils.gd")
const ChairSitConfig := preload("res://characters/groyper/chair_sit_config.gd")
const BonfirePoseConfig := preload("res://characters/groyper/bonfire_pose_config.gd")
const RollDodgeConfig := preload("res://characters/groyper/roll_dodge_config.gd")
const PunchPoseConfig := preload("res://characters/groyper/punch_pose_config.gd")
const CoverPoseConfig := preload("res://characters/groyper/cover_pose_config.gd")
const UnarmedBlockPoseConfig := preload("res://characters/groyper/unarmed_block_pose_config.gd")
const PunchStaggerConfig := preload("res://characters/groyper/punch_stagger_config.gd")

static var _locomotion: AnimationLibrary
static var _chair_sit: AnimationLibrary
static var _bonfire_standup: AnimationLibrary
static var _disk_libs: Dictionary = {}


## Build shared libraries once (call under zone fade / begin_run) so the first
## bandit spawn doesn't pay the FBX extract hitch mid-combat.
static func warm() -> void:
	get_locomotion_library()
	get_chair_sit_library()
	get_bonfire_standup_library()
	get_disk_library(RollDodgeConfig.OUT_PATH)
	get_disk_library(PunchPoseConfig.OUT_PATH)
	get_disk_library(CoverPoseConfig.OUT_PATH)
	get_disk_library(UnarmedBlockPoseConfig.OUT_PATH)
	get_disk_library(PunchStaggerConfig.OUT_PATH)


static func get_locomotion_library() -> AnimationLibrary:
	if _locomotion != null:
		return _locomotion
	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE, true)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE, true)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE, true)
	_add_locomotion_clip(
		library,
		RigAnimConfig.LOCOMOTION_STUMBLE,
		RigAnimConfig.STUMBLE_SCENE,
		false
	)
	_locomotion = library
	return _locomotion


static func get_chair_sit_library() -> AnimationLibrary:
	if _chair_sit != null:
		return _chair_sit
	var library := AnimationLibrary.new()
	var all_ok := _add_chair_clip(
		library,
		ChairSitConfig.STAND_TO_SIT,
		ChairSitConfig.SOURCE_STAND_TO_SIT,
		Animation.LOOP_NONE
	)
	for i in ChairSitConfig.SOURCE_SIT_TO_STANDS.size():
		var clip_name := StringName("%s%d" % [ChairSitConfig.SIT_TO_STAND_PREFIX, i])
		all_ok = (
			_add_chair_clip(
				library,
				clip_name,
				ChairSitConfig.SOURCE_SIT_TO_STANDS[i],
				Animation.LOOP_NONE
			)
			and all_ok
		)
	for i in ChairSitConfig.SOURCE_SIT_IDLES.size():
		var clip_name := StringName("%s%d" % [ChairSitConfig.SIT_IDLE_PREFIX, i])
		all_ok = (
			_add_chair_clip(
				library,
				clip_name,
				ChairSitConfig.SOURCE_SIT_IDLES[i],
				Animation.LOOP_LINEAR
			)
			and all_ok
		)
	if not all_ok:
		push_warning("GroyperNpcAnimCache: chair_sit library missing some clips.")
	_chair_sit = library
	return _chair_sit


static func get_bonfire_standup_library() -> AnimationLibrary:
	if _bonfire_standup != null:
		return _bonfire_standup
	var raw := RigAnimUtils.load_skeleton_animation(BonfirePoseConfig.STAND_UP3_SCENE)
	if raw == null:
		push_warning("GroyperNpcAnimCache: failed to load bonfire stand_up3 clip.")
		return null
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	var library := AnimationLibrary.new()
	library.add_animation(BonfirePoseConfig.STAND_UP3, animation)
	_bonfire_standup = library
	return _bonfire_standup


static func get_disk_library(path: String) -> AnimationLibrary:
	if path.is_empty():
		return null
	if _disk_libs.has(path):
		return _disk_libs[path] as AnimationLibrary
	var library := load(path) as AnimationLibrary
	if library != null:
		_disk_libs[path] = library
	return library


## Install a shared library Ref (no duplicate). Skips when already present.
static func install_shared(
	animation_player: AnimationPlayer,
	library_name: StringName,
	library: AnimationLibrary,
	replace_existing: bool = false
) -> bool:
	if animation_player == null or library == null:
		return false
	if animation_player.has_animation_library(library_name):
		if not replace_existing:
			return true
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(library_name, library)
	return true


## Body scene already ships authored libs as ExtResources. Leave them alone;
## only load from disk if a clip path is missing (no FBX extract, no duplicate).
static func ensure_authored_library(
	animation_player: AnimationPlayer,
	library_name: StringName,
	disk_path: String,
	required_clip_paths: Array[StringName] = []
) -> bool:
	if animation_player == null:
		return false
	if _has_required_clips(animation_player, required_clip_paths):
		return true
	var library := get_disk_library(disk_path)
	if library == null:
		return false
	return install_shared(animation_player, library_name, library, true)


static func ensure_town_authored_libraries(animation_player: AnimationPlayer) -> void:
	if animation_player == null:
		return
	ensure_authored_library(
		animation_player,
		RollDodgeConfig.LIBRARY_NAME,
		RollDodgeConfig.OUT_PATH,
		[
			StringName("%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]),
		]
	)
	ensure_authored_library(
		animation_player,
		PunchPoseConfig.LIBRARY_NAME,
		PunchPoseConfig.OUT_PATH,
		[PunchPoseConfig.get_animation_path()]
	)
	ensure_authored_library(
		animation_player,
		CoverPoseConfig.LIBRARY_NAME,
		CoverPoseConfig.OUT_PATH,
		[CoverPoseConfig.get_crouch_cover_path()]
	)
	ensure_authored_library(
		animation_player,
		UnarmedBlockPoseConfig.LIBRARY_NAME,
		UnarmedBlockPoseConfig.OUT_PATH,
		[UnarmedBlockPoseConfig.get_animation_path()]
	)
	ensure_authored_library(
		animation_player,
		PunchStaggerConfig.LIBRARY_NAME,
		PunchStaggerConfig.OUT_PATH,
		[PunchStaggerConfig.get_animation_path(PunchStaggerConfig.HIT_REACTION_1)]
	)


static func install_locomotion(animation_player: AnimationPlayer) -> bool:
	return install_shared(
		animation_player,
		RigAnimConfig.LOCOMOTION_LIBRARY,
		get_locomotion_library(),
		true
	)


static func install_chair_sit(animation_player: AnimationPlayer) -> bool:
	if animation_player == null:
		return false
	if animation_player.has_animation(ChairSitConfig.get_stand_to_sit_path()):
		return true
	if not install_shared(
		animation_player,
		ChairSitConfig.LIBRARY_NAME,
		get_chair_sit_library(),
		true
	):
		return false
	return animation_player.has_animation(ChairSitConfig.get_stand_to_sit_path())


static func install_bonfire_standup(animation_player: AnimationPlayer) -> bool:
	if animation_player == null:
		return false
	if animation_player.has_animation(BonfirePoseConfig.get_stand_up3_path()):
		return true
	var library := get_bonfire_standup_library()
	if library == null:
		return false
	return install_shared(animation_player, BonfirePoseConfig.LIBRARY_NAME, library, true)


static func _has_required_clips(
	animation_player: AnimationPlayer,
	required_clip_paths: Array[StringName]
) -> bool:
	if required_clip_paths.is_empty():
		return false
	for clip_path in required_clip_paths:
		if not animation_player.has_animation(clip_path):
			return false
	return true


static func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	loop: bool
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperNpcAnimCache: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	library.add_animation(clip_name, animation)


static func _add_chair_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	source_clip: String,
	loop_mode: Animation.LoopMode
) -> bool:
	var raw := RigAnimUtils.load_skeleton_animation(ChairSitConfig.MERGED_SCENE, source_clip)
	if raw == null:
		push_error(
			"GroyperNpcAnimCache: failed to load chair clip '%s' from merged FBX." % source_clip
		)
		return false
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)
	return true
