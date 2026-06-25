extends RefCounted
class_name GroyperBodyUtils

## Shared lookups for the groyper body scene layout (Body/Armature/Skeleton3D + AnimationPlayer).

const IDLE_NODE := &"Idle"
const LEAN_BLEND_NODE := &"LeanBlend"
const MIX_NODE := &"IdleLeanMix"

const HOLSTERED_ARM_BONE := "RightArm"
const HOLSTERED_FOREARM_BONE := "RightForeArm"
const HOLSTERED_HAND_BONE := "RightHand"
const HOLSTERED_LEFT_ARM_BONE := "LeftArm"
const HOLSTERED_LEFT_FOREARM_BONE := "LeftForeArm"
const HOLSTERED_LEFT_HAND_BONE := "LeftHand"
const DEFAULT_HOLSTERED_ARM_ROTATION_DEG := Vector3(45.0, 0.0, 0.0)
const DEFAULT_HOLSTERED_LEFT_ARM_ROTATION_DEG := Vector3(45.0, 0.0, 0.0)
## Fade holstered arm offset during the first part of the draw reach so IK uses a neutral chain.
const HOLSTER_REST_FADE_REACH := 0.35
const DEFAULT_HOLSTER_REACH_OUTWARD := 0.52
const DEFAULT_HOLSTER_REACH_FORWARD := 0.08
const DEFAULT_HOLSTER_REACH_DOWN := 0.12
const DEFAULT_HOLSTER_REACH_INWARD_START := 0.5
const DEFAULT_HOLSTER_REACH_ABDUCT_DEG := 24.0


static func compute_holster_arm_guide_target(
	skeleton: Skeleton3D,
	holster_target: Vector3,
	reach_alpha: float,
	outward: float = DEFAULT_HOLSTER_REACH_OUTWARD,
	forward: float = DEFAULT_HOLSTER_REACH_FORWARD,
	down: float = DEFAULT_HOLSTER_REACH_DOWN,
	inward_blend_start: float = DEFAULT_HOLSTER_REACH_INWARD_START
) -> Vector3:
	if skeleton == null:
		return holster_target

	var shoulder_id := skeleton.find_bone("RightShoulder")
	var arm_id := skeleton.find_bone("RightArm")
	var spine_id := skeleton.find_bone("Spine02")
	var pivot_id := shoulder_id if shoulder_id >= 0 else arm_id
	if pivot_id < 0:
		return holster_target

	var pivot_global := skeleton.global_transform * skeleton.get_bone_global_pose(pivot_id)
	var outward_dir := _get_reach_outward_dir(skeleton, holster_target, spine_id, pivot_global.origin)
	var forward_dir := (-skeleton.global_transform.basis.z).normalized()

	var wide_point := (
		pivot_global.origin
		+ outward_dir * outward
		+ forward_dir * forward
		+ Vector3.DOWN * down
	)

	var inward_t := clampf(
		(reach_alpha - inward_blend_start) / maxf(1.0 - inward_blend_start, 0.001),
		0.0,
		1.0
	)
	inward_t = inward_t * inward_t * (3.0 - 2.0 * inward_t)
	return wide_point.lerp(holster_target, inward_t)


static func _get_reach_outward_dir(
	skeleton: Skeleton3D,
	holster_target: Vector3,
	spine_id: int,
	pivot_pos: Vector3
) -> Vector3:
	if spine_id >= 0:
		var spine_pos := (
			skeleton.global_transform * skeleton.get_bone_global_pose(spine_id)
		).origin
		var outward := holster_target - spine_pos
		outward.y = 0.0
		if outward.length_squared() > 0.0001:
			return outward.normalized()

	var fallback := pivot_pos - skeleton.global_position
	fallback.y = 0.0
	if fallback.length_squared() > 0.0001:
		return fallback.normalized()
	return (-skeleton.global_transform.basis.x).normalized()


static func reach_abduction_offset(reach_alpha: float, abduct_deg: float) -> Quaternion:
	var amount := clampf(1.0 - reach_alpha, 0.0, 1.0)
	amount = amount * amount
	return Quaternion(Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(abduct_deg * amount))))


static func holstered_bone_pose_rotation(
	bone_name: String,
	arm_rotation_deg: Vector3 = DEFAULT_HOLSTERED_ARM_ROTATION_DEG
) -> Quaternion:
	if bone_name == HOLSTERED_ARM_BONE:
		return Quaternion(Basis.from_euler(arm_rotation_deg * (PI / 180.0)))
	if bone_name == HOLSTERED_FOREARM_BONE or bone_name == HOLSTERED_HAND_BONE:
		return Quaternion.IDENTITY
	return Quaternion.IDENTITY


static func holstered_support_arm_pose_rotation(
	bone_name: String,
	arm_rotation_deg: Vector3 = DEFAULT_HOLSTERED_LEFT_ARM_ROTATION_DEG
) -> Quaternion:
	if bone_name == HOLSTERED_LEFT_ARM_BONE:
		return Quaternion(Basis.from_euler(arm_rotation_deg * (PI / 180.0)))
	if bone_name == HOLSTERED_LEFT_FOREARM_BONE or bone_name == HOLSTERED_LEFT_HAND_BONE:
		return Quaternion.IDENTITY
	return Quaternion.IDENTITY


static func find_skeleton(body: Node) -> Skeleton3D:
	return body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D


static func find_animation_player(body: Node) -> AnimationPlayer:
	return body.get_node_or_null("AnimationPlayer") as AnimationPlayer


static func find_idle_animation_name(animation_player: AnimationPlayer) -> StringName:
	if animation_player == null:
		return StringName()

	var neutral_path := LeanPoseConfig.get_animation_path(&"neutral")
	if animation_player.has_animation(neutral_path):
		return neutral_path

	for library_name: String in animation_player.get_animation_library_list():
		if library_name == LeanPoseConfig.LIBRARY_NAME:
			continue
		var library: AnimationLibrary = animation_player.get_animation_library(library_name)
		for animation_name: String in library.get_animation_list():
			if "idle" in animation_name.to_lower():
				if library_name.is_empty():
					return StringName(animation_name)
				return StringName("%s/%s" % [library_name, animation_name])

	var fallback := animation_player.get_animation_list()
	if fallback.is_empty():
		return StringName()
	return StringName(fallback[0])


static func setup_idle_animation_tree(
	animation_tree: AnimationTree,
	animation_player: AnimationPlayer
) -> bool:
	if animation_tree == null or animation_player == null:
		return false

	var idle_animation_name := find_idle_animation_name(animation_player)
	if idle_animation_name.is_empty():
		push_error("GroyperBodyUtils: could not find idle animation.")
		return false

	if not animation_player.has_animation_library(LeanPoseConfig.LIBRARY_NAME):
		push_error(
			"GroyperBodyUtils: missing authored lean library '%s' on Body."
			% LeanPoseConfig.LIBRARY_NAME
		)
		return false

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_animation_name
	if animation_player.has_animation(idle_animation_name):
		var idle_anim := animation_player.get_animation(idle_animation_name)
		if idle_anim != null:
			idle_anim.loop_mode = Animation.LOOP_LINEAR

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
	blend_tree.add_node(IDLE_NODE, idle_node)
	blend_tree.add_node(LEAN_BLEND_NODE, lean_blend)
	blend_tree.add_node(MIX_NODE, mix_node)
	blend_tree.connect_node(MIX_NODE, 0, IDLE_NODE)
	blend_tree.connect_node(MIX_NODE, 1, LEAN_BLEND_NODE)
	blend_tree.connect_node(&"output", 0, MIX_NODE)

	animation_tree.tree_root = blend_tree
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.process_priority = -100
	animation_tree.active = true
	return true
