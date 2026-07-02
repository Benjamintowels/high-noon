extends BaldwinActor
class_name BaldwinOverworldPlayer

## Playable Baldwin crusader — locomotion-only foundation for future player control.

const BaldwinAnimConfigScript := preload("res://characters/baldwin/baldwin_anim_config.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")

const GRAVITY := 22.0
const WALK_SPEED := 3.2
const RUN_SPEED := 6.0
const FACING_SPEED := 12.0
const LOCOMOTION_BLEND := BaldwinAnimConfigScript.LOCOMOTION_BLEND


func _on_actor_ready() -> void:
	add_to_group("overworld_player")
	add_to_group("player")
	_setup_locomotion()
	call_deferred("snap_to_floor")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if move_dir.length_squared() > 0.0001:
		move_dir = move_dir.normalized()
		var speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		_model.rotation.y = lerp_angle(
			_model.rotation.y,
			atan2(move_dir.x, move_dir.z),
			FACING_SPEED * delta
		)
		var blend := 0.5 if speed <= WALK_SPEED + 0.01 else 1.0
		_animation_tree.set("parameters/%s/blend_position" % LOCOMOTION_BLEND, blend)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_animation_tree.set("parameters/%s/blend_position" % LOCOMOTION_BLEND, 0.0)

	move_and_slide()


func get_faction_id() -> StringName:
	return FactionIdsScript.PLAYER


func _setup_locomotion() -> void:
	if _animation_player == null:
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_clip(library, BaldwinAnimConfigScript.CLIP_IDLE, BaldwinAnimConfigScript.MESHY_IDLE, Animation.LOOP_LINEAR)
	_add_clip(library, BaldwinAnimConfigScript.CLIP_WALK, BaldwinAnimConfigScript.MESHY_WALK, Animation.LOOP_LINEAR)
	_add_clip(library, BaldwinAnimConfigScript.CLIP_RUN, BaldwinAnimConfigScript.MESHY_RUN, Animation.LOOP_LINEAR)

	if _animation_player.has_animation_library(BaldwinAnimConfigScript.LIBRARY):
		_animation_player.remove_animation_library(BaldwinAnimConfigScript.LIBRARY)
	_animation_player.add_animation_library(BaldwinAnimConfigScript.LIBRARY, library)

	var idle_path := _clip_path(BaldwinAnimConfigScript.CLIP_IDLE)
	var walk_path := _clip_path(BaldwinAnimConfigScript.CLIP_WALK)
	var run_path := _clip_path(BaldwinAnimConfigScript.CLIP_RUN)

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 0.5)
	blend_space.add_blend_point(run_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.connect_node(&"output", 0, LOCOMOTION_BLEND)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_tree.set("parameters/%s/blend_position" % LOCOMOTION_BLEND, 0.0)


func _add_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(BaldwinAnimConfigScript.MERGED_SCENE, meshy_clip)
	if raw == null:
		return
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


func _clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [BaldwinAnimConfigScript.LIBRARY, clip_name])
