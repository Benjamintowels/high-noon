extends RefCounted
## Chief Getcha bow visuals + firing. Bone mounts use Adjust nodes so offsets
## can be tuned from ChiefGetchaNpc exports without rebinding the skeleton.

const RECURVE_BOW_SCENE := preload("res://Assets/Weapons/Bow/recurve_bow.tscn")
const ARROW_PROJECTILE_SCENE := preload("res://gameplay/shooting/arrow_projectile.tscn")
const BrawlAuraFXScript := preload("res://gameplay/fx/brawl_aura_fx.gd")

const BACK_BONE := "Spine02"
const HAND_BONE := "RightHand"
const ARROW_SPEED := 18.0
const THREAT_OUTLINE_COLOR := Color(1.0, 0.08, 0.05, 0.9)
const THREAT_OUTLINE_GROW := 0.07

var back_mount: BoneAttachment3D
var back_adjust: Node3D
var back_bow: Node3D
var hand_mount: BoneAttachment3D
var hand_adjust: Node3D
var hand_bow: Node3D
var muzzle: Marker3D
var _equipped := false


func ensure_mounted(skeleton: Skeleton3D) -> void:
	if skeleton == null:
		return
	if back_mount == null or not is_instance_valid(back_mount):
		back_mount = BoneAttachment3D.new()
		back_mount.name = "ChiefBowBackMount"
		back_mount.bone_name = BACK_BONE
		skeleton.add_child(back_mount)
		back_adjust = Node3D.new()
		back_adjust.name = "BowBackAdjust"
		back_mount.add_child(back_adjust)
		back_bow = RECURVE_BOW_SCENE.instantiate()
		back_bow.name = "RecurveBow"
		back_adjust.add_child(back_bow)
	if hand_mount == null or not is_instance_valid(hand_mount):
		hand_mount = BoneAttachment3D.new()
		hand_mount.name = "ChiefBowHandMount"
		hand_mount.bone_name = HAND_BONE
		skeleton.add_child(hand_mount)
		hand_adjust = Node3D.new()
		hand_adjust.name = "BowHandAdjust"
		hand_mount.add_child(hand_adjust)
		hand_bow = RECURVE_BOW_SCENE.instantiate()
		hand_bow.name = "RecurveBow"
		hand_adjust.add_child(hand_bow)
		muzzle = Marker3D.new()
		muzzle.name = "Muzzle"
		muzzle.position = Vector3(-0.24, 0.0, 0.0)
		hand_adjust.add_child(muzzle)
	set_equipped(false)


func apply_offsets(
	back_position: Vector3,
	back_rotation_deg: Vector3,
	hand_position: Vector3,
	hand_rotation_deg: Vector3
) -> void:
	if back_adjust != null and is_instance_valid(back_adjust):
		back_adjust.transform = Transform3D(
			Basis.from_euler(back_rotation_deg * (PI / 180.0)),
			back_position
		)
	if hand_adjust != null and is_instance_valid(hand_adjust):
		hand_adjust.transform = Transform3D(
			Basis.from_euler(hand_rotation_deg * (PI / 180.0)),
			hand_position
		)


func set_equipped(in_hand: bool) -> void:
	_equipped = in_hand
	if back_bow != null and is_instance_valid(back_bow):
		back_bow.visible = not in_hand
	if hand_bow != null and is_instance_valid(hand_bow):
		hand_bow.visible = in_hand


func is_equipped() -> bool:
	return _equipped


func get_fire_origin() -> Vector3:
	if muzzle != null and is_instance_valid(muzzle):
		return muzzle.global_position
	if hand_adjust != null and is_instance_valid(hand_adjust):
		return hand_adjust.global_position
	return Vector3.ZERO


func fire_at(target_world: Vector3, shooter: Node3D, scene_root: Node) -> Node3D:
	if scene_root == null or shooter == null:
		return null
	var origin := get_fire_origin()
	if origin.is_equal_approx(Vector3.ZERO):
		origin = shooter.global_position + Vector3(0.0, 1.2, 0.0)
	var direction := target_world - origin
	if direction.length_squared() < 0.0001:
		direction = -shooter.global_transform.basis.z
	direction = direction.normalized()

	var arrow: Node3D = ARROW_PROJECTILE_SCENE.instantiate()
	scene_root.add_child(arrow)
	arrow.setup(origin, direction, ARROW_SPEED, [shooter], shooter)
	if arrow.has_method("enable_threat_outline"):
		arrow.enable_threat_outline(THREAT_OUTLINE_COLOR, THREAT_OUTLINE_GROW)
	else:
		BrawlAuraFXScript.apply(arrow)
	return arrow
