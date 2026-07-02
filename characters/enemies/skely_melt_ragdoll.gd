extends GroyperMeltRagdoll
class_name SkelyMeltRagdoll

## Mixamo skeleton loose-bone collapse — bones detach and fall apart on death.
## Skely's visual scale lives on Model; physics needs that scale on the skeleton instead.

const SkeletonAnimUtilsScript := preload("res://characters/enemies/skeleton_anim_utils.gd")
const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")

var _visual_scale := Vector3.ONE
var _model_node: Node3D


func _init() -> void:
	impulse_scale = 0.55


func activate(hit_info: Dictionary, animation_player: AnimationPlayer = null) -> bool:
	bind_skeleton()
	_prepare_visual_scale_for_physics()
	return super.activate(hit_info, animation_player)


func _prepare_visual_scale_for_physics() -> void:
	_visual_scale = Vector3.ONE
	_model_node = null
	if _skeleton == null:
		return

	var node: Node = _skeleton
	while node != null:
		if node is Node3D and node.name == "Model":
			_model_node = node as Node3D
			break
		node = node.get_parent()

	if _model_node == null or _model_node.scale.is_equal_approx(Vector3.ONE):
		return

	_visual_scale = _model_node.scale
	_skeleton.scale = _skeleton.scale * _visual_scale
	_model_node.scale = Vector3.ONE
	impulse_scale *= _visual_scale.x


func _build_physical_bones() -> void:
	if _skeleton == null:
		return

	_simulator = PhysicalBoneSimulator3D.new()
	_simulator.name = "MeltRagdollSimulator"
	_simulator.active = false
	_skeleton.add_child(_simulator)

	for cfg in RAGDOLL_BONES:
		var mixamo_name: String = SkeletonAnimUtilsScript.GROYPER_TO_SKELY_BONE.get(
			cfg.name,
			cfg.name
		)
		var bone_id := _skeleton.find_bone(mixamo_name)
		if bone_id < 0:
			continue

		var physical_bone := PhysicalBone3D.new()
		physical_bone.name = cfg.name
		physical_bone.bone_name = mixamo_name
		physical_bone.mass = cfg.mass
		physical_bone.gravity_scale = 1.0
		physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
		_configure_bone_shape(physical_bone, bone_id, cfg.radius, cfg.height)
		_simulator.add_child(physical_bone)

	_simulator.physical_bones_stop_simulation()


func _configure_bone_shape(
	physical_bone: PhysicalBone3D,
	bone_id: int,
	radius: float,
	default_height: float
) -> void:
	var bone_rest := _skeleton.get_bone_rest(bone_id)
	var length := default_height
	var axis := GroyperBodyUtilsScript.detect_bone_child_aim_axis(_skeleton, bone_id)
	for child_id in _skeleton.get_bone_children(bone_id):
		var child_rest := _skeleton.get_bone_rest(child_id)
		var local := bone_rest.affine_inverse() * child_rest.origin
		if local.length_squared() > 0.0001:
			length = local.length()
			axis = local.normalized()
			break

	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(length * 0.9, radius * 2.0)

	var collision := CollisionShape3D.new()
	collision.shape = shape
	physical_bone.add_child(collision)
	physical_bone.body_offset = Transform3D(Basis.IDENTITY, axis * length * 0.5)
