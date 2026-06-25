extends Node3D

## Runtime preview only. Edit poses in groyper_body.tscn with Godot's Animation panel.

@export_range(0.0, 1.0, 0.01) var preview_blend_amount := 1.0

@onready var _body: Node3D = $Body
@onready var _animation_tree: AnimationTree = $AnimationTree

var _animation_player: AnimationPlayer
var _preview_position := Vector2.ZERO


func _ready() -> void:
	_animation_player = GroyperBodyUtils.find_animation_player(_body)
	if _animation_player == null:
		push_error("LeanPoseEditor: missing AnimationPlayer on Body.")
		return

	var idle_name := GroyperBodyUtils.find_idle_animation_name(_animation_player)
	if not idle_name.is_empty():
		_animation_player.play(idle_name)

	_setup_preview_animation_tree()


func _process(delta: float) -> void:
	_update_preview_input(delta)
	_apply_preview_tree()


func _setup_preview_animation_tree() -> void:
	var idle_name := GroyperBodyUtils.find_idle_animation_name(_animation_player)
	if idle_name.is_empty():
		push_error("LeanPoseEditor: could not find idle animation for preview.")
		return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_name

	var lean_blend := AnimationNodeBlendSpace2D.new()
	lean_blend.min_space = Vector2(-1.0, -1.0)
	lean_blend.max_space = Vector2(1.0, 1.0)
	lean_blend.sync = true
	lean_blend.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED

	for pose_name: String in LeanPoseConfig.POSE_BLEND_POSITIONS.keys():
		var pose_node := AnimationNodeAnimation.new()
		pose_node.animation = LeanPoseConfig.get_animation_path(pose_name)
		lean_blend.add_blend_point(pose_node, LeanPoseConfig.POSE_BLEND_POSITIONS[pose_name])

	var mix_node := AnimationNodeBlend2.new()
	mix_node.sync = true
	LeanPoseConfig.configure_idle_lean_mix_filter(mix_node)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(&"Idle", idle_node)
	blend_tree.add_node(&"LeanBlend", lean_blend)
	blend_tree.add_node(&"IdleLeanMix", mix_node)
	blend_tree.connect_node(&"IdleLeanMix", 0, &"Idle")
	blend_tree.connect_node(&"IdleLeanMix", 1, &"LeanBlend")
	blend_tree.connect_node(&"output", 0, &"IdleLeanMix")

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true


func _update_preview_input(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y -= 1.0

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var snap_pose := _read_pose_hotkey()
	if snap_pose != "":
		_preview_position = LeanPoseConfig.POSE_BLEND_POSITIONS[snap_pose]
	elif direction.length_squared() > 0.0001:
		var step := 1.0 - exp(-9.0 * delta)
		_preview_position = _preview_position.lerp(direction, step)
	else:
		var reset_step := 1.0 - exp(-12.0 * delta)
		_preview_position = _preview_position.lerp(Vector2.ZERO, reset_step)


func _read_pose_hotkey() -> String:
	var hotkeys := {
		KEY_1: "neutral",
		KEY_2: "forwards",
		KEY_3: "back",
		KEY_4: "left",
		KEY_5: "right",
	}
	for key in hotkeys:
		if Input.is_key_pressed(key):
			return hotkeys[key]
	return ""


func _apply_preview_tree() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return

	var depth := preview_blend_amount
	if Input.is_key_pressed(KEY_SHIFT):
		depth = 1.0

	_animation_tree.set("parameters/LeanBlend/blend_position", _preview_position * depth)
	_animation_tree.set("parameters/IdleLeanMix/blend_amount", depth)
