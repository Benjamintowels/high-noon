extends GroyperActor
class_name GroyperTownNpc

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const HAT_BASE_MATERIAL := preload("res://characters/groyper/cowboy_hat_material.tres")
const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const AlertSymbolFX := preload("res://gameplay/fx/alert_symbol_fx.gd")
const TownShootout := preload("res://gameplay/world/town_shootout.gd")
const TownAggroVoiceScript := preload("res://gameplay/audio/town_aggro_voice.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const FactionAffinity := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const FactionRally := preload("res://gameplay/faction/faction_rally.gd")
const FactionShowdown := preload("res://gameplay/faction/faction_showdown.gd")

const LOCOMOTION_BLEND := &"LocomotionBlend"

const WALK_SPEED := 2.2
const RUN_SPEED := 5.5
const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const THREATEN_RANGE := 18.0
const CHEST_AIM_HEIGHT := 1.25
const COMBAT_FIRE_DELAY_MIN := 1.5
const COMBAT_FIRE_DELAY_MAX := 3.0
const COMBAT_RELOCATE_MIN := 4.0
const COMBAT_RELOCATE_MAX := 9.0
const COMBAT_ARRIVE_DISTANCE := 0.65
const COMBAT_MISS_DISTANCE_NEAR := 3.0
const COMBAT_MISS_DISTANCE_FAR := 30.0
const COMBAT_AIM_MISS_CHANCE_NEAR := 0.02
const COMBAT_AIM_MISS_CHANCE_FAR := 0.90
const CENTERED_AIM_SPREAD := 0.06
const OFF_BODY_AIM_SPREAD := 1.1
const ALERT_HEAD_OFFSET := 2.45
const ALERT_HEAD_BONE_OFFSET := 0.55
const FACTION_ESCALATE_MIN := 5.0
const FACTION_ESCALATE_MAX := 10.0
const FACTION_ESCALATE_CHANCE := 0.30
const FACTION_ALLY_DRAW_RANGE := 14.0

enum AiState {
	IDLE,
	WALKING,
	STARING,
	COMBAT_DRAWING,
	COMBAT_AIMING,
	COMBAT_MOVING,
	DEFEATED,
}

const HAT_COLOR_PALETTE: Array[Color] = [
	Color(0.72, 0.18, 0.14),
	Color(0.15, 0.35, 0.75),
	Color(0.2, 0.6, 0.25),
	Color(0.94, 0.82, 0.2),
	Color(0.94, 0.94, 0.92),
	Color(0.55, 0.28, 0.62),
	Color(0.35, 0.22, 0.14),
	Color(0.08, 0.08, 0.1),
]

@export var random_hat_color := true
@export var hat_color := Color(0.72, 0.18, 0.14)
@export var equipped_weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.REVOLVER
@export var idle_duration_min := 5.0
@export var idle_duration_max := 10.0
@export var walk_duration_min := 2.0
@export var walk_duration_max := 5.0

const HITBOX_HALF_HEIGHT := 0.48
const HITBOX_RADIUS := 0.28

var _weapon_rig
var _ragdoll
var _duel_hat
var _aggro_voice: Node

var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
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
var _roam_center := Vector3.ZERO
var _roam_half_extents := Vector2(4.5, 42.0)
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_ring: LassoRing
var _lasso_rope_length := 8.5
var _faction_id: StringName = &""
var _faction_standoff_active := false
var _faction_aggro_level := 0
var _faction_escalation_timer := 0.0


func _on_actor_ready() -> void:
	add_to_group("town_npc")
	add_to_group(get_town_character_group())
	add_to_group("duel_target")
	add_to_group("lassoable")
	_setup_locomotion()
	setup_npc_locomotion_audio()
	_setup_combat()
	_begin_idle()
	call_deferred("_finalize_spawn")


func get_town_character_group() -> StringName:
	return &"town_groyper"


func _finalize_spawn() -> void:
	snap_to_floor()
	_roam_center = global_position


func _physics_process(delta: float) -> void:
	if _defeated:
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if _faction_standoff_active:
		_update_faction_standoff(delta)
	else:
		_update_threat_stare()

	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if not _combat_active and not _faction_standoff_active and _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if not _combat_active and not _faction_standoff_active and _state_timer <= 0.0:
				_begin_idle()
		AiState.STARING:
			velocity.x = 0.0
			velocity.z = 0.0
			if _aim_target != null:
				_face_position(_aim_target.global_position, delta)
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
	var sprinting := _ai_state == AiState.COMBAT_MOVING
	var moving := (
		_ai_state == AiState.WALKING
		or _ai_state == AiState.COMBAT_MOVING
	)
	_update_locomotion_blend(delta, horizontal_speed, sprinting)
	update_npc_locomotion_audio(delta, horizontal_speed, moving, sprinting)

	_state_timer -= delta


func _process(delta: float) -> void:
	if _defeated or _weapon_rig == null or _lasso_captured:
		return

	if _has_locked_aim and _aim_target != null:
		_update_aim_tracking(delta)
	_weapon_rig.update(delta, _smoothed_aim_point)
	_update_combat_ai(delta)


func set_hat_color(color: Color) -> void:
	hat_color = color
	if _duel_hat != null and _skeleton != null:
		_duel_hat.bind_skeleton(_skeleton, _create_hat_material(color))
		_duel_hat.prepare_for_round(false)


func get_faction_id() -> StringName:
	if _faction_id != &"":
		return _faction_id
	return FactionIds.TOWNSPEOPLE


func get_faction_aggro_level() -> int:
	return _faction_aggro_level


func is_faction_standoff_active() -> bool:
	return _faction_standoff_active


func celebrate_faction_showdown_victory() -> void:
	if _defeated:
		return
	exit_faction_standoff_peaceful()
	if _aggro_voice != null:
		_aggro_voice.play_cheer()


func exit_faction_standoff_peaceful() -> void:
	if _defeated:
		return

	_faction_standoff_active = false
	_faction_aggro_level = 0
	_faction_escalation_timer = 0.0
	_combat_active = false
	_combat_move_pursue = false
	_aim_target = null
	_has_locked_aim = false
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()
	_velocity_zero()
	_begin_idle()


func configure_faction_standoff(faction_id: StringName, stare_target: Node3D = null) -> void:
	_faction_id = faction_id
	_faction_standoff_active = true
	add_to_group("faction_npc")
	set_faction_aggro_level(1, stare_target)


func set_faction_aggro_level(level: int, target: Node3D = null) -> void:
	if _defeated:
		return

	_faction_aggro_level = clampi(level, 0, 3)

	match _faction_aggro_level:
		1:
			_combat_active = false
			_combat_move_pursue = false
			_has_locked_aim = false
			if _weapon_rig != null and _weapon_rig.is_aiming():
				_weapon_rig.begin_holster()
			_aim_target = target if target != null else _pick_nearest_hostile_faction_member()
			_saved_ai_state = AiState.STARING
			_ai_state = AiState.STARING
			_velocity_zero()
			_snap_face_toward_target()
			_schedule_faction_escalation()
		2, 3:
			var combat_target := target
			if combat_target == null:
				combat_target = _aim_target
			if combat_target == null:
				combat_target = _pick_nearest_hostile_faction_member()
			if combat_target == null:
				return
			if not _combat_active:
				enter_combat(combat_target)
			else:
				_aim_target = combat_target
			if _faction_aggro_level >= 2:
				_schedule_faction_escalation()
			if _faction_aggro_level == 2:
				FactionRally.propagate_draw_to_allies(
					self,
					get_tree(),
					FACTION_ALLY_DRAW_RANGE
				)


func is_weapon_aimed_at(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if _weapon_rig == null or not _weapon_rig.is_aiming():
		return false
	if target == null or not target.has_method("get_bullet_capsule"):
		return false

	var origin: Vector3 = _weapon_rig.get_muzzle_global_position()
	var to_target: Vector3 = _smoothed_aim_point - origin
	if to_target.length_squared() < 0.0001:
		return false

	var direction: Vector3 = to_target.normalized()
	var capsule: Dictionary = target.get_bullet_capsule()
	var hit_t := DuelHitTest.raycast_capsule(
		origin,
		direction,
		max_range,
		capsule.get("center", Vector3.ZERO),
		capsule.get("half_height", 0.75),
		capsule.get("radius", 0.5) + 0.05,
		capsule.get("axis", Vector3.UP)
	)
	return hit_t >= 0.0


func enter_combat(player: Node3D) -> void:
	if _defeated or _combat_active:
		return

	_combat_active = true
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
		_aggro_voice.schedule_on_aggro()


func get_voice_world_position() -> Vector3:
	return _get_alert_world_position()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	var shooter: Node3D = hit_info.get("shooter")
	var result := BulletHitDamage.process_hit(self, hit_info, _health)
	_health = result.health

	if _faction_standoff_active:
		FactionRally.rally_faction_on_injury(self, shooter, get_tree(), 3)
	elif not _combat_active:
		_trigger_town_shootout(shooter)

	if result.killed:
		_activate_defeat_ragdoll(hit_info)
		if _faction_standoff_active:
			FactionShowdown.check_after_death(self, get_tree())


func is_defeated() -> bool:
	return _defeated


func is_lassoable() -> bool:
	return not _defeated and not _lasso_captured


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


func get_hat_collectible_id() -> StringName:
	return GroyperHatCatalog.id_for_color(hat_color)


func get_lasso_hat_drop_anchor() -> Vector3:
	var pos := global_position
	pos.y = GroyperBodyUtils.snap_position_to_floor(
		get_world_3d(),
		pos,
		GroyperBodyUtils.ACTOR_MODEL_Y
	).y
	return pos


func get_lasso_hat_skeleton() -> Skeleton3D:
	return _skeleton


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


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


func _trigger_town_shootout(shooter: Node3D) -> void:
	TownShootout.rally_groypers(shooter, get_tree())


func _update_faction_standoff(delta: float) -> void:
	if _defeated or not _faction_standoff_active:
		return

	if _faction_aggro_level == 1:
		if _aim_target == null or not is_instance_valid(_aim_target):
			_aim_target = _pick_nearest_hostile_faction_member()
		_check_faction_aimed_at_response()
		_check_faction_ally_draw_support()
		_tick_faction_escalation(delta, 2)
	elif _faction_aggro_level == 2:
		_tick_faction_escalation(delta, 3)


func _check_faction_aimed_at_response() -> void:
	if _faction_aggro_level != 1:
		return

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.is_hostile(get_faction_id(), FactionAffinity.resolve_faction_id(npc)):
			continue
		if npc.has_method("get_faction_aggro_level") and npc.get_faction_aggro_level() < 2:
			continue
		if npc.has_method("is_weapon_aimed_at") and npc.is_weapon_aimed_at(self):
			set_faction_aggro_level(2, npc as Node3D)
			return

	var player := _find_player()
	if (
		player != null
		and FactionAffinity.is_hostile(get_faction_id(), FactionIds.PLAYER)
		and player.has_method("is_weapon_aimed_at")
		and player.is_weapon_aimed_at(self)
	):
		set_faction_aggro_level(2, player)


func _check_faction_ally_draw_support() -> void:
	if _faction_aggro_level != 1:
		return

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if not npc.has_method("get_faction_id") or npc.get_faction_id() != get_faction_id():
			continue
		if not npc.has_method("get_faction_aggro_level") or npc.get_faction_aggro_level() < 2:
			continue
		if global_position.distance_to(npc.global_position) > FACTION_ALLY_DRAW_RANGE:
			continue
		var target := _pick_nearest_hostile_faction_member()
		if target != null:
			set_faction_aggro_level(2, target)
			return


func _tick_faction_escalation(delta: float, next_level: int) -> void:
	_faction_escalation_timer -= delta
	if _faction_escalation_timer > 0.0:
		return

	_schedule_faction_escalation()
	if randf() >= FACTION_ESCALATE_CHANCE:
		return

	var target := _aim_target
	if target == null or not is_instance_valid(target):
		target = _pick_nearest_hostile_faction_member()
	if target == null:
		return

	set_faction_aggro_level(next_level, target)


func _schedule_faction_escalation() -> void:
	_faction_escalation_timer = randf_range(FACTION_ESCALATE_MIN, FACTION_ESCALATE_MAX)


func _pick_nearest_hostile_faction_member() -> Node3D:
	var my_faction := get_faction_id()
	var nearest: Node3D
	var nearest_dist_sq := INF

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.is_hostile(my_faction, FactionAffinity.resolve_faction_id(npc)):
			continue
		var dist_sq := global_position.distance_squared_to(npc.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = npc as Node3D

	var player := _find_player()
	if (
		player != null
		and FactionAffinity.is_hostile(my_faction, FactionIds.PLAYER)
	):
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq < nearest_dist_sq:
			nearest = player

	return nearest


func _update_threat_stare() -> void:
	if _faction_standoff_active or _combat_active or _defeated:
		return

	var player := _find_player()
	if player == null:
		if _ai_state == AiState.STARING:
			_resume_peaceful_ai()
		return

	if _player_is_threatening(player):
		if _ai_state != AiState.STARING:
			_saved_ai_state = _ai_state
			_ai_state = AiState.STARING
			_velocity_zero()
			_show_alert_fx()
			if _aggro_voice != null:
				_aggro_voice.play_woah_on_alert()
		_aim_target = player
	elif _ai_state == AiState.STARING:
		_resume_peaceful_ai()


func _resume_peaceful_ai() -> void:
	_aim_target = null
	match _saved_ai_state:
		AiState.WALKING:
			_begin_walk()
		_:
			_begin_idle()


func _player_is_threatening(player: Node3D) -> bool:
	if player.global_position.distance_to(global_position) > THREATEN_RANGE:
		return false
	if not player.has_method("is_weapon_aimed_at"):
		return false
	return player.is_weapon_aimed_at(self)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _update_combat_ai(delta: float) -> void:
	if not _combat_active or _defeated:
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
	if _faction_standoff_active and _faction_aggro_level < 3:
		_begin_combat_aiming()
		return

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
		return GroyperWeapons.get_effective_range(GroyperWeapons.get_enemy_weapon())
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

	var to_target := _aim_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
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
		if _animation_tree != null:
			_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	else:
		remove_meta(&"lasso_soft_loco_resume")


func _velocity_zero() -> void:
	velocity = Vector3.ZERO


func _setup_combat() -> void:
	if _skeleton == null:
		push_error("GroyperTownNpc: missing skeleton.")
		return

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, equipped_weapon_id)

	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	_ragdoll.bind_skeleton()

	if random_hat_color:
		hat_color = _pick_random_hat_color()

	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton, _create_hat_material(hat_color))
	_duel_hat.prepare_for_round(false)

	_aggro_voice = _create_aggro_voice()


func _create_aggro_voice() -> Node:
	var voice := TownAggroVoiceScript.new()
	voice.name = "AggroVoice"
	add_child(voice)
	voice.setup(self)
	return voice


func _pick_random_hat_color() -> Color:
	return HAT_COLOR_PALETTE[randi() % HAT_COLOR_PALETTE.size()]


func _create_hat_material(color: Color) -> StandardMaterial3D:
	var mat := HAT_BASE_MATERIAL.duplicate() as StandardMaterial3D
	# Drop the shared hat texture so albedo_color reads as a solid hat tint.
	mat.albedo_texture = null
	mat.albedo_color = color
	return mat


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("GroyperTownNpc: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
	):
		push_error("GroyperTownNpc: locomotion clips missing on AnimationPlayer.")
		return

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


func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperTownNpc: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO


func _begin_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	_clamp_walk_direction_to_roam()


func _clamp_walk_direction_to_roam() -> void:
	var offset := global_position - _roam_center
	offset.y = 0.0
	var next_pos := global_position + _walk_direction * WALK_SPEED * walk_duration_max
	var next_offset := next_pos - _roam_center
	next_offset.y = 0.0

	if absf(next_offset.x) > _roam_half_extents.x:
		_walk_direction.x *= -1.0
	if absf(next_offset.z) > _roam_half_extents.y:
		_walk_direction.z *= -1.0

	if _walk_direction.length_squared() < 0.0001:
		_walk_direction = Vector3(-offset.x, 0.0, -offset.z).normalized()


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := GroyperBodyUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _snap_face_toward_target() -> void:
	if _aim_target == null:
		return
	var flat_target := Vector3(
		_aim_target.global_position.x,
		global_position.y,
		_aim_target.global_position.z
	)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	_model.rotation.y = GroyperBodyUtils.facing_yaw_for_direction(to_target.normalized())


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	var target := 0.0
	if speed > 0.05:
		target = 1.0 if sprinting else 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)


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


func _get_alert_world_position() -> Vector3:
	if _skeleton != null:
		var head_id := _skeleton.find_bone("Head")
		if head_id >= 0:
			var head_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)
			return head_global.origin + Vector3(0.0, ALERT_HEAD_BONE_OFFSET, 0.0)
	return global_position + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0)


func _show_alert_fx() -> void:
	AlertSymbolFX.spawn_above(self, _get_alert_world_position())
