extends RefCounted
class_name GroyperBodyUtils

## Shared lookups for the groyper body scene layout (Body/Armature/Skeleton3D + AnimationPlayer).

const IDLE_NODE := &"Idle"
const LEAN_BLEND_NODE := &"LeanBlend"
const MIX_NODE := &"IdleLeanMix"

## Meshy Groyper FBX meshes face -Z at bind pose. Add this to atan2 yaw on the Model node.
const MODEL_YAW_OFFSET := PI

## Shared vertical lift for Model so groyper feet sit on the actor origin / floor.
## Tune this one value for every groyper (NPCs, overworld player, duelist, duel player).
const ACTOR_MODEL_Y := 0.10

const ACTOR_CAPSULE_CENTER_Y := 0.8
const ACTOR_CAPSULE_RADIUS := 0.35
const ACTOR_CAPSULE_HEIGHT := 1.6


static func apply_model_baseline(model: Node3D) -> void:
	if model == null:
		return
	model.position.y = ACTOR_MODEL_Y
	model.rotation.y = MODEL_YAW_OFFSET


static func facing_yaw_for_direction(direction: Vector3) -> float:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return MODEL_YAW_OFFSET
	return atan2(flat.x, flat.z) + MODEL_YAW_OFFSET


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


## Local axis from a bone toward its first child (elbow for upper arm, wrist for forearm).
static func detect_bone_child_aim_axis(skeleton: Skeleton3D, bone_id: int) -> Vector3:
	var bone_rest := skeleton.get_bone_rest(bone_id)
	for child_id in skeleton.get_bone_count():
		if skeleton.get_bone_parent(child_id) != bone_id:
			continue
		var child_rest := skeleton.get_bone_rest(child_id)
		var local := bone_rest.affine_inverse() * child_rest.origin
		if local.length_squared() > 0.0001:
			return local.normalized()
	return Vector3(-1.0, 0.0, 0.0)


## Shoulder-to-hand axis in upper-arm local space — use for straight-arm gun aim on RightArm.
static func detect_gun_arm_aim_axis(
	skeleton: Skeleton3D,
	arm_bone_name: StringName,
	forearm_bone_name: StringName,
	hand_bone_name: StringName,
	forearm_pose: Quaternion = Quaternion.IDENTITY,
	hand_pose: Quaternion = Quaternion.IDENTITY
) -> Vector3:
	var arm_id := skeleton.find_bone(arm_bone_name)
	if arm_id < 0:
		return Vector3(-1.0, 0.0, 0.0)

	var chain := Transform3D.IDENTITY
	var forearm_id := skeleton.find_bone(forearm_bone_name)
	if forearm_id >= 0:
		chain = (
			chain
			* Transform3D(Basis(forearm_pose), Vector3.ZERO)
			* skeleton.get_bone_rest(forearm_id)
		)
	var hand_id := skeleton.find_bone(hand_bone_name)
	if hand_id >= 0:
		chain = (
			chain
			* Transform3D(Basis(hand_pose), Vector3.ZERO)
			* skeleton.get_bone_rest(hand_id)
		)

	if chain.origin.length_squared() > 0.0001:
		return chain.origin.normalized()

	return detect_bone_child_aim_axis(skeleton, arm_id)


## Distance from CharacterBody3D origin down to the bottom of the physics capsule.
static func get_collision_feet_offset(body: Node3D) -> float:
	for child in body.get_children():
		if child is CollisionShape3D:
			var shape := (child as CollisionShape3D).shape
			if shape is CapsuleShape3D:
				var capsule := shape as CapsuleShape3D
				return child.position.y - capsule.height * 0.5
	return 0.0


static func snap_character_to_floor(body: CharacterBody3D) -> bool:
	var space_state := body.get_world_3d().direct_space_state
	if space_state == null:
		return false

	var from := body.global_position + Vector3(0.0, 2.0, 0.0)
	var to := body.global_position - Vector3(0.0, 6.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return false

	body.global_position.y = hit.position.y - get_collision_feet_offset(body)
	return true


static func snap_position_to_floor(world: World3D, pos: Vector3, feet_offset: float) -> Vector3:
	if world == null:
		return pos

	var space_state := world.direct_space_state
	if space_state == null:
		return pos

	var from := pos + Vector3(0.0, 4.0, 0.0)
	var to := pos - Vector3(0.0, 12.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return pos

	return Vector3(pos.x, hit.position.y - feet_offset, pos.z)


static func sample_floor_y(
	world: World3D,
	from_position: Vector3,
	exclude: Array[RID] = []
) -> float:
	if world == null:
		return from_position.y

	var space_state := world.direct_space_state
	if space_state == null:
		return from_position.y

	var xz := Vector3(from_position.x, 0.0, from_position.z)
	var ray_from := xz + Vector3(0.0, 200.0, 0.0)
	var ray_to := xz - Vector3(0.0, 300.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = 1
	query.exclude = exclude
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		query.collision_mask = 0x7FFFFFFF
		hit = space_state.intersect_ray(query)
	if hit.is_empty():
		return from_position.y
	return hit.position.y


static func collect_collision_rids(root: Node) -> Array[RID]:
	var rids: Array[RID] = []
	if root == null:
		return rids
	if root is CollisionObject3D:
		rids.append((root as CollisionObject3D).get_rid())
	for node: CollisionObject3D in root.find_children("*", "CollisionObject3D", true, false):
		rids.append(node.get_rid())
	return rids


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


static func get_head_hit_sphere(
	skeleton: Skeleton3D,
	fallback_origin: Vector3,
	radius: float = 0.34
) -> Dictionary:
	if skeleton != null:
		var head_id := skeleton.find_bone("Head")
		if head_id >= 0:
			var head_global := skeleton.global_transform * skeleton.get_bone_global_pose(head_id)
			return {
				"center": head_global.origin + head_global.basis * Vector3(0.0, 0.06, 0.05),
				"radius": radius,
			}

	return {
		"center": fallback_origin + Vector3(0.0, 0.72, 0.0),
		"radius": radius,
	}


static func get_lasso_head_attach_point(skeleton: Skeleton3D, actor: Node3D) -> Vector3:
	if skeleton != null:
		var head_id := skeleton.find_bone("Head")
		if head_id >= 0:
			var head_global := skeleton.global_transform * skeleton.get_bone_global_pose(head_id)
			return head_global.origin + head_global.basis * Vector3(0.0, 0.05, 0.03)
	if actor != null:
		return actor.global_position + Vector3(0.0, 1.55, 0.0)
	return Vector3.ZERO


const HIP_HOLSTER_MOUNT_SCENE := preload("res://characters/groyper/hip_holster_mount.tscn")
const BACK_HOLSTER_MOUNT_SCENE := preload("res://characters/groyper/back_holster_mount.tscn")
const HAND_REVOLVER_MOUNT_SCENE := preload("res://characters/groyper/hand_revolver_mount.tscn")

## Tuned on groyper_body.tscn — reused for Meshy bipeds that spawn mounts at runtime.
const DEFAULT_HIP_HOLSTER_MOUNT_TRANSFORM := Transform3D(
	Basis(
		Vector3(0.9787703, -0.09089278, -0.1837034),
		Vector3(-0.18379283, 0.007457584, -0.9829363),
		Vector3(0.090711966, 0.99583334, -0.00940612)
	),
	Vector3(-0.17665698, -0.07426943, 0.5751323)
)
const DEFAULT_BACK_HOLSTER_MOUNT_TRANSFORM := Transform3D(
	Basis(
		Vector3(0.9971582, 0.07339965, -0.016985126),
		Vector3(0.0132373385, 0.051248133, 0.9985982),
		Vector3(0.07416715, -0.9959843, 0.05013083)
	),
	Vector3(0.0019237167, -0.04980486, 0.66743076)
)
const DEFAULT_HAND_REVOLVER_MOUNT_TRANSFORM := Transform3D(
	Basis(
		Vector3(0.14824949, -0.987923, 0.04507328),
		Vector3(-0.98824066, -0.14626691, 0.04452723),
		Vector3(-0.03739664, -0.051144764, -0.99799347)
	),
	Vector3(-0.68369377, -0.006577013, 1.1640106)
)


static func ensure_weapon_mounts(skeleton: Skeleton3D) -> void:
	if skeleton == null:
		return
	if skeleton.get_node_or_null("HipHolsterMount") == null:
		var hip_mount: BoneAttachment3D = HIP_HOLSTER_MOUNT_SCENE.instantiate()
		hip_mount.transform = DEFAULT_HIP_HOLSTER_MOUNT_TRANSFORM
		skeleton.add_child(hip_mount)
	if skeleton.get_node_or_null("BackHolsterMount") == null:
		var back_mount: BoneAttachment3D = BACK_HOLSTER_MOUNT_SCENE.instantiate()
		back_mount.transform = DEFAULT_BACK_HOLSTER_MOUNT_TRANSFORM
		skeleton.add_child(back_mount)
	if skeleton.get_node_or_null("HandRevolverMount") == null:
		var hand_mount: BoneAttachment3D = HAND_REVOLVER_MOUNT_SCENE.instantiate()
		hand_mount.transform = DEFAULT_HAND_REVOLVER_MOUNT_TRANSFORM
		skeleton.add_child(hand_mount)


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
