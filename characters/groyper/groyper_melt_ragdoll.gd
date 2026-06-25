extends Node
class_name GroyperMeltRagdoll

## Loose, unconstrained ragdoll saved for the future Laser Gun weapon (melts / liquifies targets).
## Bones are not jointed together, so the mesh collapses into a floppy pile.

const RAGDOLL_BONES := [
	{"name": "Hips", "radius": 0.14, "height": 0.18, "mass": 2.4},
	{"name": "Spine", "radius": 0.11, "height": 0.18, "mass": 1.8},
	{"name": "Spine01", "radius": 0.1, "height": 0.16, "mass": 1.6},
	{"name": "Spine02", "radius": 0.09, "height": 0.14, "mass": 1.4},
	{"name": "Head", "radius": 0.1, "height": 0.14, "mass": 1.2},
	{"name": "LeftArm", "radius": 0.05, "height": 0.22, "mass": 0.8},
	{"name": "RightArm", "radius": 0.05, "height": 0.22, "mass": 0.8},
	{"name": "LeftForeArm", "radius": 0.04, "height": 0.18, "mass": 0.6},
	{"name": "RightForeArm", "radius": 0.04, "height": 0.18, "mass": 0.6},
	{"name": "LeftUpLeg", "radius": 0.07, "height": 0.28, "mass": 1.4},
	{"name": "RightUpLeg", "radius": 0.07, "height": 0.28, "mass": 1.4},
	{"name": "LeftLeg", "radius": 0.06, "height": 0.24, "mass": 1.0},
	{"name": "RightLeg", "radius": 0.06, "height": 0.24, "mass": 1.0},
]

const IMPULSE := preload("res://characters/groyper/groyper_ragdoll_impulse.gd")

@export var skeleton_path: NodePath
@export var impulse_scale := 1.6

var _skeleton: Skeleton3D
var _simulator: PhysicalBoneSimulator3D
var _active := false


func _ready() -> void:
	if not skeleton_path.is_empty():
		_skeleton = get_node(skeleton_path) as Skeleton3D
	_build_physical_bones()


func is_active() -> bool:
	return _active


func activate(hit_info: Dictionary, animation_player: AnimationPlayer = null) -> void:
	if _active or _skeleton == null or _simulator == null:
		return

	_active = true

	if animation_player != null:
		animation_player.stop()

	_simulator.physical_bones_start_simulation()
	IMPULSE.apply_hit_impulse(_simulator, _skeleton, hit_info, impulse_scale)


func _build_physical_bones() -> void:
	if _skeleton == null:
		return

	_simulator = PhysicalBoneSimulator3D.new()
	_simulator.name = "MeltRagdollSimulator"
	_skeleton.add_child(_simulator)

	for cfg in RAGDOLL_BONES:
		if _skeleton.find_bone(cfg.name) < 0:
			continue

		var physical_bone := PhysicalBone3D.new()
		physical_bone.name = cfg.name
		physical_bone.bone_name = cfg.name
		physical_bone.mass = cfg.mass
		physical_bone.gravity_scale = 1.0
		physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_NONE

		var shape := CapsuleShape3D.new()
		shape.radius = cfg.radius
		shape.height = cfg.height

		var collision := CollisionShape3D.new()
		collision.shape = shape
		physical_bone.add_child(collision)
		_simulator.add_child(physical_bone)

	_simulator.physical_bones_stop_simulation()
