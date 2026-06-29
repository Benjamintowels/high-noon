extends GroyperTownNpc
class_name FastTownNpc

const FAST_AGGRO_VOICE_SCRIPT := preload("res://characters/fast/fast_aggro_voice.gd")
const FastAnimConfig := preload("res://characters/fast/fast_anim_config.gd")

const TOWNSFOLK_HAT_COLOR := Color(0.94, 0.82, 0.2)

var _idle_variant_timer := 0.0
var _idle_yawn_delay := FastAnimConfig.IDLE_YAWN_DELAY_MIN
var _move_blend := 0.0
var _walk_run_blend := 0.0


func _ready() -> void:
	random_hat_color = false
	hat_color = TOWNSFOLK_HAT_COLOR
	super._ready()


func get_town_character_group() -> StringName:
	return &"town_fast"


func get_faction_id() -> StringName:
	return FactionIds.TOWNSPEOPLE


func _bind_rig() -> void:
	_body = _model.get_node("FastRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)


func _create_aggro_voice() -> Node:
	var voice := FAST_AGGRO_VOICE_SCRIPT.new()
	voice.name = "AggroVoice"
	add_child(voice)
	voice.setup(self)
	return voice


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_fast_idle_variant(delta)


func _begin_idle() -> void:
	super._begin_idle()
	_reset_fast_idle_anim()


func _resume_peaceful_ai() -> void:
	_reset_fast_idle_anim()
	super._resume_peaceful_ai()


func _resume_locomotion_animations() -> void:
	super._resume_locomotion_animations()
	if _animation_tree == null or not _animation_tree.active:
		return
	_move_blend = 0.0
	_walk_run_blend = 0.0
	_animation_tree.set(
		"parameters/%s/blend_amount" % FastAnimConfig.MOVE_BLEND_NODE,
		0.0
	)
	_animation_tree.set(
		"parameters/%s/blend_position" % FastAnimConfig.LOCOMOTION_BLEND_NODE,
		0.0
	)
	_reset_fast_idle_anim()


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("FastTownNpc: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_fast_idle_clip(
		library,
		FastAnimConfig.IDLE_DEFAULT,
		FastAnimConfig.MESHY_IDLE_DEFAULT,
		Animation.LOOP_LINEAR
	)
	_add_fast_idle_clip(
		library,
		FastAnimConfig.IDLE_YAWN,
		FastAnimConfig.MESHY_IDLE_YAWN,
		Animation.LOOP_NONE
	)
	_add_fast_idle_clip(
		library,
		FastAnimConfig.IDLE_GUN,
		FastAnimConfig.MESHY_IDLE_GUN,
		Animation.LOOP_LINEAR
	)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)

	var default_path := _idle_anim_path(FastAnimConfig.IDLE_DEFAULT)
	var yawn_path := _idle_anim_path(FastAnimConfig.IDLE_YAWN)
	var gun_path := _idle_anim_path(FastAnimConfig.IDLE_GUN)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)

	if (
		not _animation_player.has_animation(default_path)
		or not _animation_player.has_animation(yawn_path)
		or not _animation_player.has_animation(gun_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
	):
		push_error("FastTownNpc: locomotion clips missing on AnimationPlayer.")
		return

	var idle_sm := _build_idle_state_machine(default_path, yawn_path, gun_path)

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var walk_run_space := AnimationNodeBlendSpace1D.new()
	walk_run_space.add_blend_point(walk_node, 0.0)
	walk_run_space.add_blend_point(run_node, 1.0)
	walk_run_space.min_space = 0.0
	walk_run_space.max_space = 1.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(FastAnimConfig.IDLE_STATE_NODE, idle_sm)
	blend_tree.add_node(FastAnimConfig.LOCOMOTION_BLEND_NODE, walk_run_space)
	blend_tree.add_node(FastAnimConfig.MOVE_BLEND_NODE, move_blend)
	blend_tree.connect_node(&"output", 0, FastAnimConfig.MOVE_BLEND_NODE)
	blend_tree.connect_node(FastAnimConfig.MOVE_BLEND_NODE, 0, FastAnimConfig.IDLE_STATE_NODE)
	blend_tree.connect_node(FastAnimConfig.MOVE_BLEND_NODE, 1, FastAnimConfig.LOCOMOTION_BLEND_NODE)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	call_deferred("_reset_fast_idle_anim")


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return

	var moving := speed > 0.05
	var move_target := 1.0 if moving else 0.0
	_move_blend = lerpf(_move_blend, move_target, BLEND_SPEED * delta)
	_animation_tree.set(
		"parameters/%s/blend_amount" % FastAnimConfig.MOVE_BLEND_NODE,
		_move_blend
	)

	if not moving:
		return

	var walk_run_target := 1.0 if sprinting else 0.0
	_walk_run_blend = lerpf(_walk_run_blend, walk_run_target, BLEND_SPEED * delta)
	_animation_tree.set(
		"parameters/%s/blend_position" % FastAnimConfig.LOCOMOTION_BLEND_NODE,
		_walk_run_blend
	)


func _update_fast_idle_variant(delta: float) -> void:
	if _defeated or _lasso_captured or _animation_tree == null or not _animation_tree.active:
		return
	if _move_blend > 0.05 or _combat_active:
		_idle_variant_timer = 0.0
		return

	if _should_play_threat_idle():
		_idle_variant_timer = 0.0
		_travel_idle_state(FastAnimConfig.IDLE_GUN)
		return

	if _ai_state != AiState.IDLE:
		return

	var current := _current_idle_state()
	if current == FastAnimConfig.IDLE_GUN:
		_reset_fast_idle_anim()
		return

	if current == FastAnimConfig.IDLE_YAWN:
		return

	if current != FastAnimConfig.IDLE_DEFAULT:
		return

	_idle_variant_timer += delta
	if _idle_variant_timer >= _idle_yawn_delay:
		_travel_idle_state(FastAnimConfig.IDLE_YAWN)


func _should_play_threat_idle() -> bool:
	if _ai_state == AiState.STARING:
		return true
	if _faction_standoff_active and _faction_aggro_level > 0:
		return true
	var player := _find_player()
	return player != null and _player_is_threatening(player)


func _reset_fast_idle_anim() -> void:
	_idle_variant_timer = 0.0
	_idle_yawn_delay = randf_range(
		FastAnimConfig.IDLE_YAWN_DELAY_MIN,
		FastAnimConfig.IDLE_YAWN_DELAY_MAX
	)
	_travel_idle_state(FastAnimConfig.IDLE_DEFAULT)


func _current_idle_state() -> StringName:
	var playback: AnimationNodeStateMachinePlayback = _animation_tree.get(
		"parameters/%s/playback" % FastAnimConfig.IDLE_STATE_NODE
	)
	if playback == null:
		return &""
	return playback.get_current_node()


func _travel_idle_state(state_name: StringName) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var playback: AnimationNodeStateMachinePlayback = _animation_tree.get(
		"parameters/%s/playback" % FastAnimConfig.IDLE_STATE_NODE
	)
	if playback == null:
		return
	if playback.get_current_node() == state_name:
		return
	playback.travel(state_name)


func _idle_anim_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, clip_name])


func _build_idle_state_machine(
	default_path: StringName,
	yawn_path: StringName,
	gun_path: StringName
) -> AnimationNodeStateMachine:
	var idle_sm := AnimationNodeStateMachine.new()

	var default_node := AnimationNodeAnimation.new()
	default_node.animation = default_path
	var yawn_node := AnimationNodeAnimation.new()
	yawn_node.animation = yawn_path
	var gun_node := AnimationNodeAnimation.new()
	gun_node.animation = gun_path

	idle_sm.add_node(FastAnimConfig.IDLE_DEFAULT, default_node)
	idle_sm.add_node(FastAnimConfig.IDLE_YAWN, yawn_node)
	idle_sm.add_node(FastAnimConfig.IDLE_GUN, gun_node)

	var start_to_default := AnimationNodeStateMachineTransition.new()
	idle_sm.add_transition(&"Start", FastAnimConfig.IDLE_DEFAULT, start_to_default)

	for from_state: StringName in [
		FastAnimConfig.IDLE_DEFAULT,
		FastAnimConfig.IDLE_YAWN,
		FastAnimConfig.IDLE_GUN,
	]:
		for to_state: StringName in [
			FastAnimConfig.IDLE_DEFAULT,
			FastAnimConfig.IDLE_YAWN,
			FastAnimConfig.IDLE_GUN,
		]:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = FastAnimConfig.IDLE_CROSSFADE
			idle_sm.add_transition(from_state, to_state, transition)

	var yawn_to_default := AnimationNodeStateMachineTransition.new()
	yawn_to_default.xfade_time = FastAnimConfig.IDLE_CROSSFADE
	yawn_to_default.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
	idle_sm.add_transition(FastAnimConfig.IDLE_YAWN, FastAnimConfig.IDLE_DEFAULT, yawn_to_default)

	return idle_sm


func _add_fast_idle_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode = Animation.LOOP_LINEAR
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(FastAnimConfig.MERGED_SCENE, meshy_clip)
	if raw == null:
		push_error(
			"FastTownNpc: failed to load idle clip '%s' from %s."
			% [clip_name, FastAnimConfig.MERGED_SCENE]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)
