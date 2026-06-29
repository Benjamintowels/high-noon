extends CharacterBody3D
class_name TownNpc

const SHERIFF_RIG_SCENE := preload("res://characters/sheriff/sheriff_rig.tscn")
const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const AlertSymbolFX := preload("res://gameplay/fx/alert_symbol_fx.gd")
const TownShootout := preload("res://gameplay/world/town_shootout.gd")
const TownAggroVoiceScript := preload("res://gameplay/audio/town_aggro_voice.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const WALK_SPEED := 2.2
const RUN_SPEED := 5.5
const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const INTERACT_RANGE := 2.75
const CHEST_AIM_HEIGHT := 1.25
const AIM_AGGRO_RANGE := 120.0
const INTERVENE_RANGE := 22.0
const COMBAT_FIRE_DELAY_MIN := 5.0
const COMBAT_FIRE_DELAY_MAX := 10.0
const COMBAT_RELOCATE_MIN := 3.0
const COMBAT_RELOCATE_MAX := 7.0
const COMBAT_ARRIVE_DISTANCE := 0.65
const COMBAT_MISS_DISTANCE_NEAR := 3.0
const COMBAT_MISS_DISTANCE_FAR := 30.0
const COMBAT_AIM_MISS_CHANCE_NEAR := 0.02
const COMBAT_AIM_MISS_CHANCE_FAR := 0.90
const CENTERED_AIM_SPREAD := 0.06
const OFF_BODY_AIM_SPREAD := 1.1
const ALERT_HEAD_OFFSET := 2.45
const ALERT_HEAD_BONE_OFFSET := 0.55
const HITBOX_HALF_HEIGHT := 0.48
const HITBOX_RADIUS := 0.28

enum AiState {
	IDLE,
	WALKING,
	TALKING,
	COMBAT_DRAWING,
	COMBAT_AIMING,
	COMBAT_MOVING,
	DEFEATED,
}

@export var speaker_name := "Sheriff Money Bags"
@export var dialog_lines: PackedStringArray = PackedStringArray([
	"You're not from around here are you?",
	"Welp, don't go causin' any trouble now",
])
@export var idle_duration_min := 5.0
@export var idle_duration_max := 10.0
@export var walk_duration_min := 2.0
@export var walk_duration_max := 5.0

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _interact_area: Area3D = $InteractArea

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _weapon_rig
var _ragdoll
var _aggro_voice: Node

var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _player_in_range: Node3D
var _talking := false

var _aim_target: Node3D
var _combat_active := false
var _defeated := false
var _health := BulletHitDamage.DEFAULT_MAX_HEALTH
var _fire_timer := 0.0
var _fire_timer_duration := 0.0
var _committed_aim_zone := ""
var _aim_spread_offset := Vector3.ZERO
var _smoothed_aim_point := Vector3.ZERO
var _has_locked_aim := false
var _combat_move_target := Vector3.ZERO
var _combat_move_pursue := false
var _saved_ai_state := AiState.IDLE
var _has_fired_in_combat := false
var _standing_down := false
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_ring: LassoRing
var _lasso_rope_length := 8.5


func _ready() -> void:
	add_to_group("town_npc")
	add_to_group("town_sheriff")
	add_to_group("duel_target")
	add_to_group("lassoable")
	GroyperBodyUtils.apply_model_baseline(_model)
	_spawn_rig()
	_setup_locomotion()
	_setup_combat()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_begin_idle()
	call_deferred("_snap_to_floor")


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		return

	_update_aim_aggro()

	if _combat_active and not _defeated:
		_update_player_holster_stand_down()

	if _talking and not _combat_active:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _player_in_range != null:
			_face_position(_player_in_range.global_position, delta)
		_update_locomotion_blend(delta, 0.0)
		return

	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if not _combat_active and _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if not _combat_active and _state_timer <= 0.0:
				_begin_idle()
		AiState.COMBAT_MOVING:
			if _combat_move_pursue:
				if _aim_target == null:
					velocity.x = 0.0
					velocity.z = 0.0
				elif _is_target_in_weapon_range():
					velocity.x = 0.0
					velocity.z = 0.0
					_combat_move_pursue = false
					_begin_combat_aiming()
				else:
					var to_player := _aim_target.global_position - global_position
					to_player.y = 0.0
					if to_player.length_squared() < 0.0001:
						velocity.x = 0.0
						velocity.z = 0.0
					else:
						var move_dir := to_player.normalized()
						velocity.x = move_dir.x * RUN_SPEED
						velocity.z = move_dir.z * RUN_SPEED
						_face_position(global_position + move_dir, delta)
			else:
				var to_target := _combat_move_target - global_position
				to_target.y = 0.0
				if to_target.length_squared() <= COMBAT_ARRIVE_DISTANCE * COMBAT_ARRIVE_DISTANCE:
					velocity.x = 0.0
					velocity.z = 0.0
					_begin_combat_aiming()
				else:
					var move_dir := to_target.normalized()
					velocity.x = move_dir.x * RUN_SPEED
					velocity.z = move_dir.z * RUN_SPEED
					_face_position(global_position + move_dir, delta)
		_:
			velocity.x = 0.0
			velocity.z = 0.0
			if _aim_target != null:
				_face_position(_aim_target.global_position, delta)

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_update_locomotion_blend(delta, horizontal_speed)


func _process(delta: float) -> void:
	if _defeated or _weapon_rig == null or _lasso_captured:
		return

	if _has_locked_aim and _aim_target != null and not _standing_down:
		_update_aim_tracking(delta)
	_weapon_rig.update(delta, _smoothed_aim_point)
	if _standing_down and _weapon_rig.is_holstered():
		_finish_combat_stand_down()
	_update_combat_ai(delta)


func interact(player: Node3D) -> void:
	if _talking or _combat_active or _defeated or player == null:
		return

	_talking = true
	_ai_state = AiState.TALKING
	velocity = Vector3.ZERO
	_player_in_range = player

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	GameAudio.play_npc_voice(self, GameAudio.SHERIFF_INTERACT_VOICE, get_voice_world_position())

	DialogManager.show_dialog_sequence(
		dialog_lines,
		func() -> void:
			_end_dialog(player),
		speaker_name,
		_on_sheriff_dialog_line
	)


func _on_sheriff_dialog_line(line_index: int) -> void:
	if line_index != 1:
		return
	GameAudio.play_npc_voice(
		self,
		GameAudio.SHERIFF_DIALOG_LINE_2_VOICE,
		get_voice_world_position()
	)


func is_talking() -> bool:
	return _talking


func is_defeated() -> bool:
	return _defeated


func is_lassoable() -> bool:
	return not _defeated and not _lasso_captured and not _talking


func get_lasso_attach_point() -> Vector3:
	return GroyperBodyUtils.get_lasso_head_attach_point(_skeleton, self)


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func get_lasso_max_match_speed() -> float:
	return RUN_SPEED


func get_lasso_drag_visual() -> Node3D:
	return _model


func begin_lasso_capture(player: Node3D, rope_length: float, ring: LassoRing = null) -> void:
	_lasso_captured = true
	_lasso_player = player
	_lasso_ring = ring
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	_combat_active = false
	_aim_target = null
	_ai_state = AiState.IDLE


func end_lasso_capture() -> void:
	_lasso_captured = false
	_lasso_player = null
	_lasso_ring = null
	velocity = Vector3.ZERO
	_begin_idle()


func get_lasso_ragdoll():
	return _ragdoll


func get_lasso_animation_player() -> AnimationPlayer:
	return _animation_player


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	const LassoHumanoidDragScript := preload("res://gameplay/lasso/lasso_humanoid_drag.gd")
	LassoHumanoidDragScript.apply(self, self, player, _lasso_ring, _lasso_rope_length, delta)
	LassoHumanoidDragScript.finish_settling_if_needed(self)


func enter_combat(player: Node3D, aimed_at: bool = false) -> void:
	if _defeated or _combat_active:
		return

	if _talking:
		_end_dialog(player)

	if player != null and player.has_method("enter_overworld_combat"):
		player.enter_overworld_combat()

	_combat_active = true
	_has_fired_in_combat = false
	_standing_down = false
	_aim_target = player
	_combat_move_pursue = false
	_saved_ai_state = _ai_state
	_ai_state = AiState.COMBAT_DRAWING
	_velocity_zero()
	_committed_aim_zone = _pick_body_aim_zone()
	_refresh_aim_spread()
	_has_locked_aim = true
	_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset
	_show_alert_fx()
	_weapon_rig.set_prep_aim(false)
	_weapon_rig.begin_draw()
	if _aggro_voice != null:
		if aimed_at:
			_aggro_voice.schedule_easy_there()
		else:
			_aggro_voice.schedule_on_aggro()


func get_voice_world_position() -> Vector3:
	return _get_alert_world_position()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	var shooter: Node3D = hit_info.get("shooter")
	var result := BulletHitDamage.process_hit(self, hit_info, _health)
	_health = result.health

	TownShootout.rally_groypers(shooter, get_tree())
	if not _combat_active:
		enter_combat(shooter)

	if result.killed:
		_activate_defeat_ragdoll(hit_info)


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if _defeated:
		return false
	var capsule := get_bullet_capsule()
	return DuelHitTest.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func get_bullet_capsule() -> Dictionary:
	var torso := _get_torso_transform()
	return {
		"center": torso.origin,
		"half_height": HITBOX_HALF_HEIGHT,
		"radius": HITBOX_RADIUS,
		"axis": torso.basis.y,
	}


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	)


func _end_dialog(player: Node3D) -> void:
	_talking = false
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if not _combat_active:
		_begin_idle()


func _update_aim_aggro() -> void:
	if _combat_active or _defeated:
		return

	var player := _find_player()
	if player == null:
		return

	if _player_is_aiming_at_me(player):
		enter_combat(player, true)
		return

	if _player_is_threatening_nearby_townsperson(player):
		enter_combat(player)


func _player_is_threatening_nearby_townsperson(player: Node3D) -> bool:
	if not player.has_method("is_weapon_aimed_at"):
		return false

	for npc in get_tree().get_nodes_in_group("town_groyper"):
		if not is_instance_valid(npc) or not npc is Node3D:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		var to_townsperson: Vector3 = (npc as Node3D).global_position - global_position
		to_townsperson.y = 0.0
		if to_townsperson.length() > INTERVENE_RANGE:
			continue
		if player.is_weapon_aimed_at(npc):
			return true

	return false


func _player_is_aiming_at_me(player: Node3D) -> bool:
	if not player.has_method("is_weapon_aimed_at"):
		return false
	return player.is_weapon_aimed_at(self, AIM_AGGRO_RANGE)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _update_combat_ai(delta: float) -> void:
	if not _combat_active or _defeated or _standing_down:
		return

	match _ai_state:
		AiState.COMBAT_DRAWING:
			if _weapon_rig.is_aiming():
				if _is_target_in_weapon_range():
					_begin_combat_aiming()
				else:
					_begin_combat_approach()
		AiState.COMBAT_AIMING:
			if not _is_target_in_weapon_range():
				_begin_combat_approach()
				return
			_fire_timer = maxf(_fire_timer - delta, 0.0)
			if _fire_timer <= 0.0:
				_fire_at_target()
		AiState.COMBAT_MOVING:
			pass


func _begin_combat_aiming() -> void:
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return

	_refresh_aim_spread()
	_ai_state = AiState.COMBAT_AIMING
	_fire_timer_duration = randf_range(COMBAT_FIRE_DELAY_MIN, COMBAT_FIRE_DELAY_MAX)
	_fire_timer = _fire_timer_duration


func _begin_combat_approach() -> void:
	if _aim_target == null:
		return
	if _is_target_in_weapon_range():
		_begin_combat_aiming()
		return

	_combat_move_pursue = true
	_ai_state = AiState.COMBAT_MOVING


func _fire_at_target() -> void:
	if _weapon_rig == null or not _weapon_rig.is_aiming():
		return
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return

	_has_fired_in_combat = true
	TownShootout.rally_groypers(_aim_target, get_tree())
	_weapon_rig.fire_at(_smoothed_aim_point)

	if randf() < 0.5:
		_begin_combat_aiming()
	else:
		_begin_combat_relocate()


func _begin_combat_relocate() -> void:
	_combat_move_pursue = false
	_ai_state = AiState.COMBAT_MOVING
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(COMBAT_RELOCATE_MIN, COMBAT_RELOCATE_MAX)
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * distance
	_combat_move_target = global_position + offset
	_combat_move_target.y = global_position.y


func _update_player_holster_stand_down() -> void:
	if _has_fired_in_combat or _standing_down:
		return
	if _aim_target == null:
		return
	if _aim_target.has_method("is_weapon_drawn") and _aim_target.is_weapon_drawn():
		return
	_begin_combat_stand_down()


func _begin_combat_stand_down() -> void:
	if _standing_down:
		return

	_standing_down = true
	_combat_move_pursue = false
	_has_locked_aim = false
	_velocity_zero()
	if _weapon_rig == null or _weapon_rig.is_holstered():
		_finish_combat_stand_down()
	else:
		_weapon_rig.begin_holster()


func _finish_combat_stand_down() -> void:
	_standing_down = false
	_combat_active = false
	_has_fired_in_combat = false
	_aim_target = null
	match _saved_ai_state:
		AiState.WALKING:
			_begin_walk()
		_:
			_begin_idle()


func _pick_body_aim_zone() -> String:
	var roll := randf()
	if roll < 0.58:
		return "chest"
	if roll < 0.82:
		return "head"
	if roll < 0.93:
		return "gut"
	if roll < 0.97:
		return "left_shoulder"
	return "right_shoulder"


func _sample_body_aim_point(zone_id: String) -> Vector3:
	if _aim_target != null and _aim_target.has_method("get_duel_body_aim_point"):
		return _aim_target.get_duel_body_aim_point(zone_id)
	if _aim_target != null:
		return _aim_target.global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	return global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)


func _get_weapon_effective_range() -> float:
	if _weapon_rig == null:
		return GroyperWeapons.get_effective_range(GroyperWeapons.Id.REVOLVER)
	return GroyperWeapons.get_effective_range(_weapon_rig.get_equipped_weapon_id())


func _get_horizontal_distance_to_target() -> float:
	if _aim_target == null:
		return INF
	var to_target := _aim_target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _is_target_in_weapon_range() -> bool:
	return _get_horizontal_distance_to_target() <= _get_weapon_effective_range()


func _get_combat_aim_miss_chance() -> float:
	if _aim_target == null:
		return COMBAT_AIM_MISS_CHANCE_FAR

	var distance := _get_horizontal_distance_to_target()
	if distance <= COMBAT_MISS_DISTANCE_NEAR:
		return COMBAT_AIM_MISS_CHANCE_NEAR
	if distance >= COMBAT_MISS_DISTANCE_FAR:
		return COMBAT_AIM_MISS_CHANCE_FAR

	var t := (distance - COMBAT_MISS_DISTANCE_NEAR) / (COMBAT_MISS_DISTANCE_FAR - COMBAT_MISS_DISTANCE_NEAR)
	t = t * t
	return lerpf(COMBAT_AIM_MISS_CHANCE_NEAR, COMBAT_AIM_MISS_CHANCE_FAR, t)


func _refresh_aim_spread() -> void:
	var body_point := _sample_body_aim_point(_committed_aim_zone)
	_aim_spread_offset = _resolve_aim_point(body_point, _get_combat_aim_miss_chance()) - body_point


func _resolve_aim_point(body_point: Vector3, miss_chance: float) -> Vector3:
	var spread := OFF_BODY_AIM_SPREAD if randf() < miss_chance else CENTERED_AIM_SPREAD
	return body_point + Vector3(
		randf_range(-spread, spread),
		randf_range(-spread * 0.45, spread * 0.45),
		randf_range(-spread, spread)
	)


func _update_aim_tracking(delta: float) -> void:
	var zone_point := _sample_body_aim_point(_committed_aim_zone)
	var target := zone_point + _aim_spread_offset
	var track_step := 1.0 - exp(-8.0 * delta)
	_smoothed_aim_point = _smoothed_aim_point.lerp(target, track_step)


func _activate_defeat_ragdoll(hit_info: Dictionary) -> void:
	if _aggro_voice != null:
		_aggro_voice.stop_for_death()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)
	_defeated = true
	_combat_active = false
	_combat_move_pursue = false
	_ai_state = AiState.DEFEATED
	_velocity_zero()
	if _ragdoll != null and not _ragdoll.is_active():
		_suspend_locomotion_animations()
		_ragdoll.activate(hit_info, _animation_player)


func _suspend_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = false
		if _animation_player.is_playing():
			_animation_player.pause()


func _resume_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.speed_scale = 1.0
		_animation_player.active = true
		if not _animation_player.is_playing():
			_animation_player.play()
	if not has_meta(&"lasso_soft_loco_resume"):
		_locomotion_blend = 0.0
		MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, 0.0)
	else:
		remove_meta(&"lasso_soft_loco_resume")


func _velocity_zero() -> void:
	velocity = Vector3.ZERO


func _spawn_rig() -> void:
	var rig: Node3D = SHERIFF_RIG_SCENE.instantiate()
	_model.add_child(rig)
	_body = rig.get_node("Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)


func _setup_combat() -> void:
	if _skeleton == null:
		push_error("TownNpc: missing skeleton.")
		return

	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, GroyperWeapons.Id.REVOLVER)

	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	_ragdoll.bind_skeleton()

	_aggro_voice = TownAggroVoiceScript.new()
	_aggro_voice.name = "AggroVoice"
	add_child(_aggro_voice)
	_aggro_voice.setup(self)


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("TownNpc: missing AnimationPlayer on sheriff body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	if not MeshyLocomotionUtils.setup_locomotion_library(
		_animation_player,
		SheriffAnimConfig.IDLE_SCENE,
		SheriffAnimConfig.WALK_SCENE
	):
		push_error("TownNpc: failed to build locomotion library.")
		return

	if not MeshyLocomotionUtils.setup_idle_walk_animation_tree(_animation_tree, _animation_player):
		push_error("TownNpc: failed to set up AnimationTree.")


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO


func _begin_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := MeshyLocomotionUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _update_locomotion_blend(delta: float, speed: float) -> void:
	var target := 0.0
	if speed > 0.05:
		target = 1.0
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, _locomotion_blend)


func _get_torso_transform() -> Transform3D:
	if _skeleton == null:
		var no_skeleton := global_transform
		no_skeleton.origin = global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
		return no_skeleton

	for bone_name in ["Spine02", "Spine01", "Spine"]:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
		return Transform3D(
			bone_global.basis,
			bone_global.origin + bone_global.basis * Vector3(0.0, 0.04, 0.02)
		)

	var fallback := global_transform
	fallback.origin = global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	return fallback


func _snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)


func _get_alert_world_position() -> Vector3:
	if _skeleton != null:
		var head_id := _skeleton.find_bone("Head")
		if head_id >= 0:
			var head_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)
			return head_global.origin + Vector3(0.0, ALERT_HEAD_BONE_OFFSET, 0.0)
	return global_position + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0)


func _show_alert_fx() -> void:
	AlertSymbolFX.spawn_above(self, _get_alert_world_position())
