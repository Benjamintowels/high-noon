class_name GroyperLassoStandup
extends RefCounted

const BonfirePoseConfigScript := preload("res://characters/groyper/bonfire_pose_config.gd")

const BLEND_NODE := &"LassoStandupBlend"
const STAND_ANIM_NODE := &"LassoStandupAnim"
const STAND_TIME_SEEK := &"LassoStandupTimeSeek"
const STAND_TIME_SCALE := &"LassoStandupTimeScale"

const PLAYBACK_SPEED := 1.75
const BLEND_OUT_START := 0.42
const BLEND_SPEED := 10.0
const RAGDOLL_HANDOFF_END := 0.20
const MODEL_UPRIGHT_DURATION := 0.10
const MODEL_SINK_OFFSET := -0.48
const BODY_SINK_OFFSET := 0.30
const MODEL_SINK_SPEED := 12.0
const BLEND_FINISH_THRESHOLD := 0.03


static func register_standup_library(animation_player: AnimationPlayer) -> bool:
	if animation_player == null:
		return false
	if animation_player.has_animation(BonfirePoseConfigScript.get_stand_up3_path()):
		return true

	var raw := RigAnimUtils.load_skeleton_animation(BonfirePoseConfigScript.STAND_UP3_SCENE)
	if raw == null:
		push_warning("GroyperLassoStandup: failed to load stand up clip.")
		return false

	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE

	var library := AnimationLibrary.new()
	library.add_animation(BonfirePoseConfigScript.STAND_UP3, animation)
	if animation_player.has_animation_library(BonfirePoseConfigScript.LIBRARY_NAME):
		animation_player.remove_animation_library(BonfirePoseConfigScript.LIBRARY_NAME)
	animation_player.add_animation_library(BonfirePoseConfigScript.LIBRARY_NAME, library)
	return animation_player.has_animation(BonfirePoseConfigScript.get_stand_up3_path())


static func attach_standup_branch(
	blend_tree: AnimationNodeBlendTree,
	locomotion_source: StringName,
	animation_player: AnimationPlayer
) -> bool:
	if blend_tree == null or locomotion_source == StringName():
		return false
	if not register_standup_library(animation_player):
		return false

	var stand_path := BonfirePoseConfigScript.get_stand_up3_path()
	if not animation_player.has_animation(stand_path):
		return false

	var stand_anim := AnimationNodeAnimation.new()
	stand_anim.animation = stand_path
	var stand_seek := AnimationNodeTimeSeek.new()
	var stand_scale := AnimationNodeTimeScale.new()
	var stand_blend := AnimationNodeBlend2.new()
	stand_blend.sync = false

	blend_tree.add_node(STAND_ANIM_NODE, stand_anim)
	blend_tree.add_node(STAND_TIME_SEEK, stand_seek)
	blend_tree.add_node(STAND_TIME_SCALE, stand_scale)
	blend_tree.add_node(BLEND_NODE, stand_blend)

	blend_tree.connect_node(STAND_TIME_SEEK, 0, STAND_TIME_SCALE)
	blend_tree.connect_node(STAND_TIME_SCALE, 0, STAND_ANIM_NODE)
	blend_tree.connect_node(BLEND_NODE, 0, locomotion_source)
	blend_tree.connect_node(BLEND_NODE, 1, STAND_TIME_SEEK)
	return true


static func get_stand_duration(animation_player: AnimationPlayer) -> float:
	if animation_player == null:
		return 1.0
	var anim := animation_player.get_animation(BonfirePoseConfigScript.get_stand_up3_path())
	if anim == null:
		return 1.0
	return anim.length / maxf(PLAYBACK_SPEED, 0.001)


static func init_tree_state(animation_tree: AnimationTree) -> void:
	set_blend(animation_tree, 0.0)
	set_stand_seek(animation_tree, 0.0)
	set_stand_playback_speed(animation_tree, PLAYBACK_SPEED)


static func set_stand_playback_speed(animation_tree: AnimationTree, speed: float) -> void:
	var path := "parameters/%s/scale" % STAND_TIME_SCALE
	if _has_tree_parameter(animation_tree, path):
		animation_tree.set(path, maxf(speed, 0.001))


static func _has_tree_parameter(animation_tree: AnimationTree, path: String) -> bool:
	return animation_tree != null and animation_tree.get(path) != null


static func has_standup_branch(animation_tree: AnimationTree) -> bool:
	return _has_tree_parameter(animation_tree, "parameters/%s/blend_amount" % BLEND_NODE)


static func set_blend(animation_tree: AnimationTree, amount: float) -> void:
	var path := "parameters/%s/blend_amount" % BLEND_NODE
	if _has_tree_parameter(animation_tree, path):
		animation_tree.set(path, clampf(amount, 0.0, 1.0))


static func set_stand_seek(animation_tree: AnimationTree, time: float) -> void:
	var path := "parameters/%s/seek_request" % STAND_TIME_SEEK
	if _has_tree_parameter(animation_tree, path):
		animation_tree.set(path, time)


static func get_ragdoll_handoff_influence(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p <= 0.0:
		return 1.0
	if p >= RAGDOLL_HANDOFF_END:
		return 0.0
	return 1.0 - ease_smooth(p / maxf(RAGDOLL_HANDOFF_END, 0.001))


static func get_model_upright_weight(progress: float) -> float:
	if progress < RAGDOLL_HANDOFF_END:
		return 0.0
	var span := maxf(MODEL_UPRIGHT_DURATION, 0.001)
	if progress < RAGDOLL_HANDOFF_END + span:
		return ease_smooth((progress - RAGDOLL_HANDOFF_END) / span)
	return 1.0


static func get_model_sink_weight(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p < RAGDOLL_HANDOFF_END:
		return 0.0
	if p < BLEND_OUT_START:
		return 1.0
	var t := (p - BLEND_OUT_START) / maxf(1.0 - BLEND_OUT_START, 0.001)
	return 1.0 - ease_smooth(t)


static func get_body_sink_offset(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p < RAGDOLL_HANDOFF_END:
		return 0.0
	if p < BLEND_OUT_START:
		return BODY_SINK_OFFSET
	var t := (p - BLEND_OUT_START) / maxf(1.0 - BLEND_OUT_START, 0.001)
	return lerpf(BODY_SINK_OFFSET, 0.0, ease_smooth(t))


static func get_body_stand_y(progress: float, start_y: float, target_y: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p < BLEND_OUT_START:
		return start_y
	var t := (p - BLEND_OUT_START) / maxf(1.0 - BLEND_OUT_START, 0.001)
	return lerpf(start_y, target_y, ease_smooth(t))


static func apply_model_ground_sink(
	model: Node3D,
	progress: float,
	current_sink: float,
	delta: float
) -> float:
	var target := get_model_sink_weight(progress) * MODEL_SINK_OFFSET
	var step := 1.0 - exp(-MODEL_SINK_SPEED * delta)
	var sink := lerpf(current_sink, target, step)
	if model != null:
		model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + sink
	return sink


static func compute_target_blend(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p >= BLEND_OUT_START:
		var out_t := (p - BLEND_OUT_START) / maxf(1.0 - BLEND_OUT_START, 0.001)
		return 1.0 - ease_smooth(out_t)
	return 1.0


static func is_blend_out_complete(blend_amount: float) -> bool:
	return blend_amount <= BLEND_FINISH_THRESHOLD


static func should_finish(progress: float, blend_amount: float) -> bool:
	return progress >= 1.0 and is_blend_out_complete(blend_amount)


static func update_smoothed_blend(
	current: float,
	progress: float,
	delta: float
) -> float:
	var target := compute_target_blend(progress)
	if progress >= BLEND_OUT_START:
		return target
	var step := 1.0 - exp(-BLEND_SPEED * delta)
	return lerpf(current, target, step)


static func ease_smooth(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
