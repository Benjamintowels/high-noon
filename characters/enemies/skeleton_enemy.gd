@tool
extends CharacterBody3D
class_name SkeletonEnemy

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const SkelyScatterRagdollScript := preload("res://characters/enemies/skely_scatter_ragdoll.gd")
const DuelHitTestScript := preload("res://gameplay/duel/duel_hit_test.gd")
const GroyperRagdollScript := preload("res://characters/groyper/groyper_ragdoll.gd")

enum AiState { IDLE, WANDER, CHASE }

const MAX_HEALTH := 1
const WALK_SPEED := 1.35
const CHASE_SPEED := 2.6
const GRAVITY := 18.0
const SIGHT_RANGE := 14.0
const HEARING_RANGE := 16.0
const ROAM_RADIUS := 4.5
const IDLE_MIN := 2.0
const IDLE_MAX := 5.5
const WANDER_ARRIVE_DIST := 0.45
const TOUCH_RANGE := 1.15
const TOUCH_DAMAGE_COOLDOWN := 1.0
const FACING_SPEED := 8.0
const COLLISION_RADIUS := 0.3
const COLLISION_HEIGHT := 1.05
const COLLISION_CENTER_Y := 0.85

const ANIM_CROSSFADE := 0.2
const ANIM_CROSSFADE_FAST := 0.1
const ANIM_ROOT := NodePath("../Model/SkelyGlb")
const LOCOMOTION_ANIM := &"Walk"
const IDLE_ANIM := &"Idle"
const ATTACK_ANIM := &"Attack"

const DEBUG_SKELETON_VISUAL := false
const DEBUG_SKELETON_VISUAL_INTERVAL := 1.0
const DEBUG_SKELETON_VISUAL_NEAR_DIST := 18.0

@export var sight_range := SIGHT_RANGE
@export var hearing_range := HEARING_RANGE
@export var roam_radius := ROAM_RADIUS
@export_group("Bullet Hitboxes")
@export var show_hitbox_debug_meshes := true
@export var show_hitbox_debug_in_game := false
@export var debug_bullet_hits := true
## BulletHitbox mesh supplies radius/height; center and tilt follow animated bones at runtime.
@export var use_editor_bullet_hitbox := true

@export_group("Animation Preview")
@export var editor_preview_animation := &"Idle":
	set(value):
		editor_preview_animation = value
		if Engine.is_editor_hint():
			call_deferred("_play_editor_preview")

const HEAD_BONE := "mixamorig:Head"
const LEFT_FOOT_BONE := "mixamorig:LeftFoot"
const RIGHT_FOOT_BONE := "mixamorig:RightFoot"
const HEAD_BONE_NAMES: Array[String] = [
	"mixamorig:Head",
	"Head",
]
const LEFT_FOOT_BONE_NAMES: Array[String] = [
	"mixamorig:LeftFoot",
	"LeftFoot",
]
const RIGHT_FOOT_BONE_NAMES: Array[String] = [
	"mixamorig:RightFoot",
	"RightFoot",
]
const HIPS_BONE_NAMES: Array[String] = [
	"mixamorig:Hips",
	"Hips",
]

var _anim: AnimationPlayer
var _audio: AudioStreamPlayer3D
var _collision: CollisionShape3D
var _mesh: MeshInstance3D
var _skeleton: Skeleton3D
var _ragdoll: GroyperRagdollScript
var _body_hit_marker: Node3D
var _body_hit_debug_mesh: MeshInstance3D
var _body_hit_radius := 0.42
var _body_hit_half_height := 1.1
var _active_capsule_source := "unknown"

var _health := MAX_HEALTH
var _defeated := false
var _last_hit_info: Dictionary = {}
var _alerted := false
var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _wander_target := Vector3.ZERO
var _spawn_origin := Vector3.ZERO
var _touch_cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var _current_anim := &""
var _debug_visual_timer := 0.0


func _ready() -> void:
	_bind_scene_nodes()
	_sync_hitbox_debug_meshes()
	if Engine.is_editor_hint():
		set_physics_process(false)
		velocity = Vector3.ZERO
		_configure_animation_player()
		_play_editor_preview()
		return

	add_to_group("duel_target")
	add_to_group("cave_enemy")
	_rng.randomize()
	_configure_actor_collision()
	_configure_visual()
	_setup_ragdoll()
	_configure_animation_blending()
	GroyperBodyUtils.configure_ground_physics(self)
	call_deferred("_finalize_spawn_placement")


func _process(_delta: float) -> void:
	var show_debug := show_hitbox_debug_meshes and (
		Engine.is_editor_hint() or show_hitbox_debug_in_game
	)
	if _body_hit_debug_mesh != null:
		_body_hit_debug_mesh.visible = show_debug
	if not show_debug:
		return
	_sync_hitbox_debug_meshes()
	if not Engine.is_editor_hint():
		_position_hitbox_debug_mesh()


func _bind_scene_nodes() -> void:
	_collision = get_node_or_null("CollisionShape3D") as CollisionShape3D
	_audio = get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	_anim = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _anim == null:
		_anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.skin != null:
			_mesh = mesh_inst
			break
	if _mesh == null:
		for node in find_children("*", "MeshInstance3D", true, false):
			_mesh = node as MeshInstance3D
			break
	_skeleton = _resolve_skeleton()
	_body_hit_marker = get_node_or_null("BulletHitbox") as Node3D
	_body_hit_debug_mesh = get_node_or_null("BulletHitbox/BodyDebugMesh") as MeshInstance3D
	_cache_hitbox_dimensions()
	_debug_log_visual("bind_scene_nodes")


func _cache_hitbox_dimensions() -> void:
	_body_hit_radius = 0.42
	_body_hit_half_height = 1.1
	if _body_hit_debug_mesh != null and _body_hit_debug_mesh.mesh is CapsuleMesh:
		var capsule_mesh := _body_hit_debug_mesh.mesh as CapsuleMesh
		_body_hit_radius = capsule_mesh.radius
		_body_hit_half_height = capsule_mesh.height * 0.5
	if _body_hit_marker != null:
		var marker_scale := _body_hit_marker.scale
		_body_hit_radius *= maxf(marker_scale.x, marker_scale.z)
		_body_hit_half_height *= marker_scale.y


func _resolve_skeleton() -> Skeleton3D:
	if _mesh != null and not _mesh.skeleton.is_empty():
		var skinned_skeleton := _mesh.get_node_or_null(_mesh.skeleton) as Skeleton3D
		if skinned_skeleton != null:
			return skinned_skeleton
	return find_child("Skeleton3D", true, false) as Skeleton3D


func _find_bone_id(name_candidates: Array[String]) -> int:
	if _skeleton == null:
		return -1
	for bone_name in name_candidates:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			return bone_id
	for i in _skeleton.get_bone_count():
		var skeleton_bone_name := _skeleton.get_bone_name(i)
		for candidate in name_candidates:
			if skeleton_bone_name == candidate:
				return i
			if skeleton_bone_name.ends_with(":" + candidate) or skeleton_bone_name.ends_with("/" + candidate):
				return i
	return -1


func _get_bone_world_position_by_id(bone_id: int) -> Vector3:
	if _skeleton == null or bone_id < 0:
		return Vector3.ZERO
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin


func _find_bone_world_position(name_candidates: Array[String]) -> Vector3:
	return _get_bone_world_position_by_id(_find_bone_id(name_candidates))


func _has_any_bone(name_candidates: Array[String]) -> bool:
	return _find_bone_id(name_candidates) >= 0


func _get_bone_world_position(bone_name: String) -> Vector3:
	var names: Array[String] = [bone_name]
	return _find_bone_world_position(names)


func _get_feet_world_position() -> Vector3:
	var left := _find_bone_world_position(LEFT_FOOT_BONE_NAMES)
	var right := _find_bone_world_position(RIGHT_FOOT_BONE_NAMES)
	var has_left := _has_any_bone(LEFT_FOOT_BONE_NAMES)
	var has_right := _has_any_bone(RIGHT_FOOT_BONE_NAMES)
	if not has_left and not has_right:
		return global_position
	if not has_left:
		return right
	if not has_right:
		return left
	return left if left.y < right.y else right


func _sync_hitbox_debug_meshes() -> void:
	if _body_hit_debug_mesh == null:
		return
	var mesh := _body_hit_debug_mesh.mesh as CapsuleMesh
	if mesh == null:
		mesh = CapsuleMesh.new()
		_body_hit_debug_mesh.mesh = mesh
	if Engine.is_editor_hint():
		mesh.radius = _body_hit_radius
		mesh.height = _body_hit_half_height * 2.0
		return
	var capsule := get_bullet_capsule()
	mesh.radius = float(capsule.get("radius", _body_hit_radius))
	mesh.height = float(capsule.get("half_height", _body_hit_half_height)) * 2.0


func _position_hitbox_debug_mesh() -> void:
	if _body_hit_debug_mesh == null:
		return
	if Engine.is_editor_hint():
		_body_hit_debug_mesh.position = Vector3.ZERO
		_body_hit_debug_mesh.basis = Basis.IDENTITY
		return
	var body := get_bullet_capsule()
	var axis: Vector3 = body.get("axis", Vector3.UP)
	_body_hit_debug_mesh.global_position = body["center"]
	_body_hit_debug_mesh.global_basis = _basis_from_y_axis(axis)


func _basis_from_y_axis(y_axis: Vector3) -> Basis:
	var y := y_axis.normalized()
	if y.length_squared() < 0.0001:
		return Basis.IDENTITY
	var x := Vector3.UP.cross(y)
	if x.length_squared() < 0.0001:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _setup_ragdoll() -> void:
	if _skeleton == null:
		return
	var model := get_node_or_null("Model") as Node3D
	_ragdoll = SkelyScatterRagdollScript.new()
	_ragdoll.name = "ScatterRagdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	if model != null:
		_ragdoll.model_path = _ragdoll.get_path_to(model)
	_ragdoll.bind_skeleton()


func _configure_animation_blending() -> void:
	_configure_animation_player()


func _configure_animation_player() -> void:
	if _anim == null:
		return
	_anim.root_node = ANIM_ROOT
	_anim.playback_default_blend_time = ANIM_CROSSFADE
	_disable_embedded_glb_animation_player()


func _disable_embedded_glb_animation_player() -> void:
	if _anim.get_parent() == self:
		for node in find_children("*", "AnimationPlayer", true, false):
			var player := node as AnimationPlayer
			if player == null or player == _anim:
				continue
			player.active = false
			if player.is_playing():
				player.stop()


func _play_editor_preview() -> void:
	if not Engine.is_editor_hint() or _anim == null:
		return
	if editor_preview_animation.is_empty():
		return
	if not _anim.has_animation(str(editor_preview_animation)):
		return
	_anim.active = true
	_anim.play(str(editor_preview_animation))
	_current_anim = editor_preview_animation


func _finalize_spawn_placement() -> void:
	_bind_scene_nodes()
	_prime_idle_pose()
	_debug_log_visual("after_prime_idle_pose")
	snap_to_floor()
	_spawn_origin = global_position
	_play_anim(IDLE_ANIM)
	_debug_log_visual("after_finalize_spawn")


func _debug_log_visual(stage: String) -> void:
	if not DEBUG_SKELETON_VISUAL:
		return

	var model_node := get_node_or_null("Model") as Node3D
	var model_global_pos := Vector3.ZERO
	var model_local_pos := Vector3.ZERO
	if model_node != null:
		model_global_pos = model_node.global_position
		model_local_pos = model_node.position

	var mesh_path := "<none>"
	var mesh_pos := Vector3.ZERO
	var mesh_global_scale := Vector3.ONE
	var mesh_visible := false
	var mesh_has_skin := false
	var mesh_aabb_size := Vector3.ZERO
	if _mesh != null:
		mesh_path = str(_mesh.get_path())
		mesh_pos = _mesh.global_position
		mesh_global_scale = _mesh.global_transform.basis.get_scale()
		mesh_visible = _mesh.visible
		mesh_has_skin = _mesh.skin != null
		mesh_aabb_size = _mesh.get_aabb().size

	var anim_name := "<none>"
	var anim_playing := false
	if _anim != null:
		anim_name = str(_anim.current_animation)
		anim_playing = _anim.is_playing()

	var player := _get_player()
	var player_dist := -1.0
	if player != null:
		player_dist = global_position.distance_to(player.global_position)

	print(
		"[SKELETON DEBUG] ",
		stage,
		" path=",
		get_path(),
		" body_pos=",
		global_position,
		" body_scale=",
		scale,
		" model_pos=",
		model_global_pos,
		" model_local_pos=",
		model_local_pos,
		" mesh_path=",
		mesh_path,
		" mesh_pos=",
		mesh_pos,
		" mesh_visible=",
		mesh_visible,
		" mesh_has_skin=",
		mesh_has_skin,
		" mesh_scale=",
		mesh_global_scale,
		" mesh_aabb_size=",
		mesh_aabb_size,
		" body_to_mesh_dist=",
		global_position.distance_to(mesh_pos) if _mesh != null else -1.0,
		" anim=",
		anim_name,
		" anim_playing=",
		anim_playing,
		" anim_found=",
		_anim != null,
		" mesh_found=",
		_mesh != null,
		" player_dist=",
		player_dist
	)


func _configure_visual() -> void:
	if _mesh == null:
		push_warning("SkeletonEnemy: MeshInstance3D not found on " + str(get_path()))
		return
	_mesh.visible = true
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Mixamo bind pose places skinned verts far from the actor origin until a frame is applied.
func _prime_idle_pose() -> void:
	if _anim == null:
		push_warning("SkeletonEnemy: AnimationPlayer not found on " + str(get_path()))
		return
	if not _anim.has_animation(str(IDLE_ANIM)):
		push_warning("SkeletonEnemy: Idle animation missing on " + str(get_path()))
		return
	_anim.active = true
	_anim.play(str(IDLE_ANIM))
	_anim.seek(0.0, true)
	_current_anim = IDLE_ANIM


## Gameplay-sized capsule on an unscaled body. Visual scale lives on Model/SkelyGlb.
func _configure_actor_collision() -> void:
	if _collision == null:
		return
	var capsule := CapsuleShape3D.new()
	capsule.radius = COLLISION_RADIUS
	capsule.height = COLLISION_HEIGHT
	_collision.shape = capsule
	_collision.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, COLLISION_CENTER_Y, 0.0))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _defeated:
		return

	_debug_tick_visual(delta)

	_touch_cooldown = maxf(_touch_cooldown - delta, 0.0)
	_update_alert()
	_update_ai(delta)

	var move_dir := _get_move_direction()
	var speed := CHASE_SPEED if _ai_state == AiState.CHASE else WALK_SPEED
	var horizontal := move_dir * speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	move_and_slide()
	if move_dir.length_squared() > 0.0001:
		var target_yaw := atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, FACING_SPEED * delta)

	_update_locomotion_anim(move_dir.length_squared() > 0.04)
	_try_touch_damage_player()


func snap_to_floor() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return

	_prime_idle_pose()
	var before_y := global_position.y
	var floor_snapped := GroyperBodyUtils.snap_character_to_floor(self)
	_spawn_origin = global_position
	_debug_log_visual("after_snap_to_floor")
	if DEBUG_SKELETON_VISUAL:
		print(
			"[SKELETON DEBUG] snap_y before=",
			before_y,
			" after=",
			global_position.y,
			" snapped=",
			floor_snapped
		)


func _debug_tick_visual(delta: float) -> void:
	if not DEBUG_SKELETON_VISUAL:
		return
	_debug_visual_timer -= delta
	if _debug_visual_timer > 0.0:
		return
	_debug_visual_timer = DEBUG_SKELETON_VISUAL_INTERVAL
	var player := _get_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) > DEBUG_SKELETON_VISUAL_NEAR_DIST:
		return
	_debug_log_visual("near_player")


func alert_to_gunshot(origin: Vector3) -> void:
	if _defeated:
		return
	if global_position.distance_to(origin) <= hearing_range:
		_alerted = true


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return
	_debug_log_bullet_hit(hit_info)
	_alerted = true
	_last_hit_info = hit_info.duplicate(true)
	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health
	if result.killed:
		_die(hit_info)


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if _defeated:
		return false
	var capsule := get_bullet_capsule()
	return DuelHitTestScript.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func suspend_animations_for_ragdoll() -> void:
	if _anim == null:
		return
	_anim.active = false
	_anim.stop()
	_disable_embedded_glb_animation_player()


func get_bullet_capsule() -> Dictionary:
	var bone_capsule := _capsule_from_bones()
	if not bone_capsule.is_empty():
		_active_capsule_source = "bone_full_body"
		return bone_capsule

	if use_editor_bullet_hitbox and _body_hit_marker != null:
		_active_capsule_source = "editor_marker"
		return _capsule_from_marker()

	_active_capsule_source = "fallback_constant"
	return _capsule_from_marker()


func _capsule_from_bones() -> Dictionary:
	var head_id := _find_bone_id(HEAD_BONE_NAMES)
	if head_id < 0:
		return {}

	var radius := _body_hit_radius
	var head := _get_bone_world_position_by_id(head_id)
	var feet := _get_feet_world_position()
	if not _has_any_bone(LEFT_FOOT_BONE_NAMES) and not _has_any_bone(RIGHT_FOOT_BONE_NAMES):
		var hips := _find_bone_world_position(HIPS_BONE_NAMES)
		if hips != Vector3.ZERO:
			feet = hips - Vector3.UP * radius * 0.9
		else:
			feet = global_position

	var raw_axis := head - feet
	if raw_axis.length_squared() < 0.0025:
		return {}

	var axis := raw_axis.normalized()
	var top := head + axis * (radius * 0.12)
	var bottom := feet - axis * (radius * 0.08)
	var span := top.distance_to(bottom)
	var center := (top + bottom) * 0.5
	var half_height := span * 0.5
	if use_editor_bullet_hitbox:
		half_height = maxf(_body_hit_half_height, span * 0.45)

	return {
		"center": center,
		"half_height": half_height,
		"radius": radius,
		"axis": axis,
		"source": "bone_full_body",
	}


func _capsule_from_marker() -> Dictionary:
	if _body_hit_marker != null:
		return {
			"center": _body_hit_marker.global_position,
			"half_height": _body_hit_half_height,
			"radius": _body_hit_radius,
			"axis": Vector3.UP,
			"source": "editor_marker",
		}
	return {
		"center": global_position + Vector3(0.0, COLLISION_CENTER_Y, 0.0),
		"half_height": COLLISION_HEIGHT * 0.5,
		"radius": COLLISION_RADIUS,
		"axis": Vector3.UP,
		"source": "fallback_constant",
	}


func _capsule_from_physics_collision() -> Dictionary:
	if _collision == null or not _collision.shape is CapsuleShape3D:
		return {}
	var capsule := _collision.shape as CapsuleShape3D
	var xform := _collision.global_transform
	var shape_scale := xform.basis.get_scale()
	return {
		"center": xform.origin,
		"half_height": capsule.height * 0.5 * shape_scale.y,
		"radius": capsule.radius * maxf(shape_scale.x, shape_scale.z),
		"axis": xform.basis.y.normalized(),
		"source": "physics_collision_shape",
		"collision_path": str(_collision.get_path()),
	}


func _describe_capsule(capsule: Dictionary) -> String:
	if capsule.is_empty():
		return "<none>"
	return (
		"source="
		+ str(capsule.get("source", "?"))
		+ " center="
		+ str(capsule.get("center", Vector3.ZERO))
		+ " half_h="
		+ str(capsule.get("half_height", 0.0))
		+ " radius="
		+ str(capsule.get("radius", 0.0))
	)


func _resolve_bullet_hit_path(hit_info: Dictionary) -> String:
	if hit_info.has("duel_target") and hit_info.get("duel_target") == self:
		return "duel_capsule_raycast"
	var collider: Object = hit_info.get("collider")
	if collider == null:
		return "unknown_no_collider"
	if collider is Node:
		return "world_physics_collider:" + str((collider as Node).get_path())
	return "world_physics_collider:" + str(collider)


func _debug_log_bullet_hit(hit_info: Dictionary) -> void:
	if not debug_bullet_hits:
		return

	var active_capsule := get_bullet_capsule()
	var editor_capsule := _capsule_from_marker()
	var bone_capsule := _capsule_from_bones()
	var physics_capsule := _capsule_from_physics_collision()
	var hit_position: Vector3 = hit_info.get("position", Vector3.ZERO)
	var hit_path := _resolve_bullet_hit_path(hit_info)
	const RAY_MARGIN := 0.05

	print(
		"[SKELETON HIT DEBUG] path=",
		hit_path,
		" active_source=",
		_active_capsule_source,
		" use_editor_hitbox=",
		use_editor_bullet_hitbox,
		" head_bone_found=",
		_has_any_bone(HEAD_BONE_NAMES),
		" skeleton=",
		_skeleton != null,
		" hit_pos=",
		hit_position,
		"\n  ACTIVE (used for duel raycast): ",
		_describe_capsule(active_capsule),
		"\n  EDITOR marker (BulletHitbox): ",
		_describe_capsule(editor_capsule),
		"\n  BONE span (feet->head): ",
		_describe_capsule(bone_capsule),
		"\n  PHYSICS CollisionShape3D: ",
		_describe_capsule(physics_capsule),
		"\n  hit_in_active=",
		DuelHitTestScript.point_in_capsule(
			hit_position,
			active_capsule.get("center", Vector3.ZERO),
			float(active_capsule.get("half_height", 0.0)),
			float(active_capsule.get("radius", 0.0)),
			active_capsule.get("axis", Vector3.UP),
			RAY_MARGIN
		),
		" (surface hits can be false while raycast still registers)",
		" hit_in_editor=",
		DuelHitTestScript.point_in_capsule(
			hit_position,
			editor_capsule.get("center", Vector3.ZERO),
			float(editor_capsule.get("half_height", 0.0)),
			float(editor_capsule.get("radius", 0.0)),
			editor_capsule.get("axis", Vector3.UP),
			RAY_MARGIN
		),
		" hit_in_physics=",
		DuelHitTestScript.point_in_capsule(
			hit_position,
			physics_capsule.get("center", Vector3.ZERO),
			float(physics_capsule.get("half_height", 0.0)),
			float(physics_capsule.get("radius", 0.0)),
			physics_capsule.get("axis", Vector3.UP),
			RAY_MARGIN
		) if not physics_capsule.is_empty() else false
	)


func is_defeated() -> bool:
	return _defeated


func _update_alert() -> void:
	if _defeated or _alerted:
		return
	var player := _get_player()
	if player == null:
		return
	var flat := player.global_position - global_position
	flat.y = 0.0
	if flat.length_squared() <= sight_range * sight_range:
		_alerted = true


func _update_ai(delta: float) -> void:
	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			if _state_timer <= 0.0:
				if _alerted:
					_ai_state = AiState.CHASE
				else:
					_begin_wander()
		AiState.WANDER:
			if _alerted:
				_ai_state = AiState.CHASE
			elif global_position.distance_to(_wander_target) <= WANDER_ARRIVE_DIST:
				_begin_idle()
		AiState.CHASE:
			var player := _get_player()
			if player == null or not _alerted:
				_begin_idle()
				return
			if global_position.distance_to(player.global_position) <= TOUCH_RANGE:
				velocity = Vector3.ZERO


func _get_move_direction() -> Vector3:
	match _ai_state:
		AiState.WANDER:
			var to_target := _wander_target - global_position
			to_target.y = 0.0
			if to_target.length_squared() < 0.0001:
				return Vector3.ZERO
			return to_target.normalized()
		AiState.CHASE:
			var player := _get_player()
			if player == null:
				return Vector3.ZERO
			var to_player := player.global_position - global_position
			to_player.y = 0.0
			if to_player.length_squared() < 0.0001:
				return Vector3.ZERO
			return to_player.normalized()
	return Vector3.ZERO


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = _rng.randf_range(IDLE_MIN, IDLE_MAX)
	_play_anim(IDLE_ANIM)


func _begin_wander() -> void:
	_ai_state = AiState.WANDER
	var angle := _rng.randf() * TAU
	var distance := _rng.randf_range(1.0, roam_radius)
	var offset := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	_wander_target = _spawn_origin + offset
	_state_timer = 8.0


func _try_touch_damage_player() -> void:
	if not _alerted or _touch_cooldown > 0.0:
		return
	var player := _get_player()
	if player == null:
		return
	var flat := player.global_position - global_position
	flat.y = 0.0
	if flat.length_squared() > TOUCH_RANGE * TOUCH_RANGE:
		return

	var direction := flat.normalized()
	var hit_info := {
		"position": player.global_position + Vector3(0.0, 1.0, 0.0),
		"direction": direction,
		"shooter": self,
		"damage": 1,
		"knockback_speed": 4.0,
		"knockback_up": 0.9,
		"melee": true,
		"force_knockback": true,
	}
	if player.has_method("enter_overworld_combat"):
		player.enter_overworld_combat()
	if player.has_method("receive_bullet_hit"):
		player.receive_bullet_hit(hit_info)
	_touch_cooldown = TOUCH_DAMAGE_COOLDOWN
	_play_anim(ATTACK_ANIM, ANIM_CROSSFADE_FAST)
	_play_attack_sound()


func _die(hit_info: Dictionary = {}) -> void:
	_defeated = true
	velocity = Vector3.ZERO
	if _collision != null:
		_collision.disabled = true
	_play_death_sound()

	var defeat_hit := hit_info if not hit_info.is_empty() else _last_hit_info
	if defeat_hit.is_empty():
		defeat_hit = {
			"position": global_position + Vector3(0.0, COLLISION_CENTER_Y, 0.0),
			"direction": -global_transform.basis.z,
		}

	if _ragdoll != null and not _ragdoll.is_active():
		snap_to_floor()
		suspend_animations_for_ragdoll()
		_ragdoll.activate(defeat_hit, _anim)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	for node in players:
		if node is Node3D and is_instance_valid(node):
			return node as Node3D
	return null


func _update_locomotion_anim(moving: bool) -> void:
	if _defeated:
		return
	if _touch_cooldown > TOUCH_DAMAGE_COOLDOWN - 0.35:
		return
	if moving:
		_play_anim(LOCOMOTION_ANIM)
	else:
		if _ai_state != AiState.IDLE or _state_timer > 0.0:
			_play_anim(IDLE_ANIM)


func _play_anim(anim_name: StringName, blend_time: float = ANIM_CROSSFADE) -> void:
	if _anim == null or _current_anim == anim_name:
		return
	var anim_key := str(anim_name)
	if not _anim.has_animation(anim_key):
		return
	_current_anim = StringName(anim_key)
	_anim.play(anim_key, blend_time)


func _play_attack_sound() -> void:
	if _audio == null:
		return
	_audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyAttack.mp3")
	_audio.play()


func _play_death_sound() -> void:
	if _audio == null:
		return
	_audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyDeath.mp3")
	_audio.play()
