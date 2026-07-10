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
const LocomotionAudioScript := preload("res://gameplay/audio/locomotion_audio.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const TownNpcShove := preload("res://gameplay/world/town_npc_shove.gd")
const DEPUTY_STAR_PICKUP_SCENE := preload("res://gameplay/world/deputy_star_pickup.tscn")
const FactionAffinity := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const FactionRally := preload("res://gameplay/faction/faction_rally.gd")

const WALK_SPEED := 2.2
const RUN_SPEED := 5.5
const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const INTERACT_RANGE := 2.75
const CHEST_AIM_HEIGHT := 1.25
const AIM_AGGRO_RANGE := 120.0
const INTERVENE_RANGE := 22.0
const FACTION_THREAT_LOST_GRACE := 0.5
const PLAYER_HOLSTER_DEESCALATE_DELAY := 3.0
const FACTION_STARE_BEFORE_DRAW_DELAY := 1.0
const AIM_THREAT_RANGE := 48.0
const FACTION_ALLY_DRAW_RANGE := 14.0
const FACTION_MAX_ENGAGE_RANGE := 24.0
const COMBAT_FIRE_DELAY_MIN := 5.0
const COMBAT_FIRE_DELAY_MAX := 10.0
const AGGRO_COMBAT_FIRE_DELAY_MIN := 4.0
const AGGRO_COMBAT_FIRE_DELAY_MAX := 8.0
const MAX_HEALTH := BulletHitDamage.DEFAULT_MAX_HEALTH + 2
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
const SHOVE_STUMBLE_SPEED := 2.6
const SHOVE_STUMBLE_COOLDOWN := 1.25
const SHOVE_STEP_WALK_BLEND := 1.0

enum AiState {
	IDLE,
	WALKING,
	TALKING,
	COMBAT_DRAWING,
	COMBAT_AIMING,
	COMBAT_MOVING,
	DEFEATED,
}

signal dialog_finished(player: Node3D)

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
var _health := MAX_HEALTH
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
var _player_holstered_deescalate_timer := 0.0
var _allied_aim_reaction := false
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_ring: LassoRing
var _lasso_rope_length := 8.5
var _npc_locomotion_audio: Node
var _shove_stumbling := false
var _shove_direction := Vector3.ZERO
var _shove_stumble_cooldown := 0.0
var _gentle_shove_stepping := false
var _gentle_shove_step_time := 0.0
var _gentle_shove_step_dir := Vector3.ZERO
var _gentle_shove_step_from := Vector3.ZERO
var _gentle_shove_step_distance := 0.0
var _gentle_shove_step_cooldown := 0.0
var _shove_settling := false
var _shove_settle_time := 0.0
var _shove_settle_from_blend := 0.0
var _shove_saved_ai_state := AiState.IDLE
var _shove_was_in_combat := false
var _stumble_exit_blending := false
var _shove_settle_duration := TownNpcShove.SHOVE_SETTLE_DURATION
var _faction_aggro_level := 0
var _faction_provoker: Node3D
var _faction_stare_target: Node3D
var _faction_threat_lost_timer := 0.0
var _faction_aggro_entered_timer := 0.0
var _player_weapon_threat_active := false
var _collision_mode_combat := false


func _ready() -> void:
	add_to_group(&"camera_ray_exclude")
	add_to_group("town_npc")
	add_to_group("town_sheriff")
	add_to_group("becker_boys")
	add_to_group("faction_npc")
	add_to_group("duel_target")
	add_to_group("lassoable")
	TownNpcShove.configure_npc_collision(self)
	GroyperBodyUtils.apply_model_baseline(_model)
	_spawn_rig()
	_setup_locomotion()
	_setup_npc_locomotion_audio()
	_setup_combat()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_begin_idle()
	call_deferred("_snap_to_floor")


func _physics_process(delta: float) -> void:
	if _defeated:
		_update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	_sync_npc_collision_mode()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		_update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if not _defeated:
		_update_player_weapon_reaction(delta)

	_shove_stumble_cooldown = maxf(_shove_stumble_cooldown - delta, 0.0)
	_gentle_shove_step_cooldown = maxf(_gentle_shove_step_cooldown - delta, 0.0)

	if _shove_stumbling:
		_process_shove_stumble(delta)
		return

	if _gentle_shove_stepping:
		_process_gentle_shove_step(delta)
		return

	if _shove_settling:
		_process_shove_settle(delta)
		return

	if is_npc_shoveable():
		var shove_contact := TownNpcShove.find_strongest_contact(self)
		var shove_level: int = int(shove_contact.get("level", TownNpcShove.Level.NONE))
		if shove_level == TownNpcShove.Level.LETHAL:
			receive_bullet_hit(
				TownNpcShove.build_lethal_hit_info(
					self,
					shove_contact.get("mover") as CharacterBody3D,
					shove_contact.get("push_dir", Vector3.ZERO)
				)
			)
			move_and_slide()
			_update_npc_locomotion_audio(delta, 0.0, false, false)
			return
		if shove_level == TownNpcShove.Level.STUMBLE and _shove_stumble_cooldown <= 0.0:
			_begin_shove_stumble(shove_contact.get("push_dir", Vector3.FORWARD))
			_process_shove_stumble(delta)
			return
		if (
			shove_level == TownNpcShove.Level.GENTLE
			and _gentle_shove_step_cooldown <= 0.0
		):
			_begin_gentle_shove_step(
				shove_contact.get("push_dir", Vector3.FORWARD),
				float(shove_contact.get("speed", 0.0))
			)
			_process_gentle_shove_step(delta)
			return

	_update_faction_aggro(delta)

	if _combat_active and not _defeated:
		_update_player_holster_stand_down(delta)

	if _talking and not _combat_active:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _player_in_range != null:
			_face_position(_player_in_range.global_position, delta)
		_update_locomotion_blend(delta, 0.0)
		_update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _faction_aggro_level == 1 and _faction_stare_target != null:
				_face_position(_faction_stare_target.global_position, delta)
			elif not _combat_active and _faction_aggro_level <= 0 and not _player_weapon_threat_active and _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if not _combat_active and _faction_aggro_level <= 0 and not _player_weapon_threat_active and _state_timer <= 0.0:
				_begin_idle()
		AiState.COMBAT_MOVING:
			if _combat_move_pursue:
				if _aim_target == null:
					velocity.x = 0.0
					velocity.z = 0.0
				elif _is_combat_target_out_of_engagement_range():
					_exit_combat_peaceful()
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
	if not _shove_stumbling and not _gentle_shove_stepping and not _shove_settling:
		_update_locomotion_blend(delta, horizontal_speed)
	_update_npc_locomotion_audio(delta, horizontal_speed, moving, sprinting)


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

	if DeputyQuest.raid_finished and not DeputyQuest.badge_collected:
		_show_post_raid_dialog(player)
		return

	GameAudio.play_npc_voice(self, GameAudio.SHERIFF_INTERACT_VOICE, get_voice_world_position())

	DialogManager.show_dialog_sequence(
		dialog_lines,
		func() -> void:
			_end_dialog(player),
		speaker_name,
		_on_sheriff_dialog_line
	)


func _show_post_raid_dialog(player: Node3D) -> void:
	GameAudio.play_npc_voice(self, GameAudio.SHERIFF_INTERACT_VOICE, get_voice_world_position())
	DialogManager.show_dialog_sequence(
		PackedStringArray([
			"Hot Dog that was intense!",
			"You got any interest in becoming a Deputy?",
		]),
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Yes", "No"]),
				func(choice_index: int) -> void:
					if choice_index == 0:
						_on_player_accepted_deputy(player)
					else:
						_on_player_declined_deputy(player)
			),
		speaker_name,
		func(_line_index: int) -> void:
			GameAudio.play_npc_voice(
				self,
				GameAudio.SHERIFF_DIALOG_LINE_2_VOICE,
				get_voice_world_position()
			)
	)


func _on_player_accepted_deputy(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Put this on"]),
		func() -> void:
			_drop_deputy_star_pickup()
			_end_dialog(player, false),
		speaker_name,
		func(_line_index: int) -> void:
			GameAudio.play_npc_voice(
				self,
				GameAudio.SHERIFF_DIALOG_LINE_2_VOICE,
				get_voice_world_position()
			)
	)


func _on_player_declined_deputy(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Suit yerself"]),
		func() -> void:
			_end_dialog(player, false),
		speaker_name
	)


func _drop_deputy_star_pickup() -> void:
	var pickup = DEPUTY_STAR_PICKUP_SCENE.instantiate()
	get_parent().add_child(pickup)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	pickup.global_position = global_position + forward * 1.35
	pickup.global_position.y = global_position.y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


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
	_play_lasso_capture_voice()


func _play_lasso_capture_voice() -> void:
	if _aggro_voice != null and _aggro_voice.has_method("play_lasso_capture_voice"):
		_aggro_voice.play_lasso_capture_voice()


func play_lasso_drag_voice() -> void:
	if _aggro_voice != null and _aggro_voice.has_method("play_lasso_drag_voice"):
		_aggro_voice.play_lasso_drag_voice()


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
	var allied_aim := aimed_at and player != null
	if _is_friendly_combatant(player) and not allied_aim:
		return
	if _weapon_rig == null:
		return

	if _talking:
		_end_dialog(player)

	if (
		not allied_aim
		and player != null
		and player.is_in_group("overworld_player")
		and player.has_method("enter_overworld_combat")
	):
		player.enter_overworld_combat()

	_combat_active = true
	_allied_aim_reaction = allied_aim
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
	_resume_locomotion_animations()
	if _weapon_rig.is_drawing() and not _weapon_rig.is_aiming():
		_weapon_rig.reset_to_holster()
	_weapon_rig.set_prep_aim(false)
	_weapon_rig.begin_draw()
	if _aggro_voice != null:
		if aimed_at:
			if _aggro_voice.has_method("play_easy_there_now"):
				_aggro_voice.play_easy_there_now()
			else:
				_aggro_voice.schedule_easy_there()
		else:
			_aggro_voice.schedule_on_aggro()


func get_voice_world_position() -> Vector3:
	return _get_alert_world_position()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	var shooter: Node3D = hit_info.get("shooter")

	var result := BulletHitDamage.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health

	TownShootout.rally_becker_boys_on_injury(self, shooter, get_tree())
	if not _combat_active and shooter != null:
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


func get_threat_aim_point() -> Vector3:
	var chest := global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	if _skeleton == null:
		return chest
	var torso := _get_torso_transform()
	var center := torso.origin
	if center.y < global_position.y + 0.35:
		return chest
	if center.distance_squared_to(global_position) > 400.0:
		return chest
	return center


func get_bullet_capsule() -> Dictionary:
	var torso := _get_torso_transform()
	return {
		"center": get_threat_aim_point(),
		"half_height": HITBOX_HALF_HEIGHT,
		"radius": HITBOX_RADIUS,
		"axis": torso.basis.y,
	}


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	)


func _end_dialog(player: Node3D, arm_raid_trigger: bool = true) -> void:
	_talking = false
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if not _combat_active:
		_begin_idle()
	dialog_finished.emit(player)
	if arm_raid_trigger:
		_notify_raid_trigger(player)


func _notify_raid_trigger(player: Node3D) -> void:
	for node in get_tree().get_nodes_in_group("sheriff_raid_trigger"):
		if node.has_method("arm_after_sheriff_dialog"):
			node.call("arm_after_sheriff_dialog", player)

	var stage := get_tree().current_scene
	if stage != null and stage.has_method("arm_sheriff_raid_after_dialog"):
		stage.call("arm_sheriff_raid_after_dialog")


func get_faction_id() -> StringName:
	return FactionIds.BECKER_BOYS


func get_faction_aggro_level() -> int:
	return _faction_aggro_level


func get_faction_aggro_target() -> Node3D:
	if _combat_active:
		return _aim_target
	return _faction_stare_target


func _is_provoked_player(target: Node3D) -> bool:
	if target == null or not target.is_in_group("overworld_player"):
		return false
	if _faction_provoker != target:
		return false
	return _faction_aggro_level >= 2


func _is_valid_combat_target(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if FactionAffinity.are_hostile(self, target):
		return true
	return _is_provoked_player(target)


func set_faction_aggro_level(level: int, target: Node3D = null) -> void:
	if _defeated:
		return

	var previous_level := _faction_aggro_level
	_faction_aggro_level = clampi(level, 0, 3)
	if _faction_aggro_level == 0:
		_faction_provoker = null
		_faction_stare_target = null
		_faction_aggro_entered_timer = 0.0
		if _allied_aim_reaction and _combat_active:
			_exit_combat_peaceful()
		return

	if target != null:
		_faction_provoker = target
	if _faction_aggro_level != previous_level:
		_faction_aggro_entered_timer = 0.0

	match _faction_aggro_level:
		1:
			_faction_stare_target = target
			if _combat_active:
				return
			_velocity_zero()
			_saved_ai_state = _ai_state
			_ai_state = AiState.IDLE
			if target != null:
				_faction_threat_lost_timer = 0.0
		2:
			if target == null:
				return
			if _combat_active and _allied_aim_reaction:
				return
			if not _combat_active:
				var aimed_at := target.is_in_group("overworld_player")
				enter_combat(target, aimed_at)
			else:
				_aim_target = target
			if previous_level < 2:
				FactionRally.propagate_draw_to_allies(
					self,
					get_tree(),
					FACTION_ALLY_DRAW_RANGE
				)
		3:
			if target == null:
				return
			if target.is_in_group("overworld_player") and target.has_method("enter_overworld_combat"):
				target.enter_overworld_combat()
			_allied_aim_reaction = false
			_faction_stare_target = null
			if _combat_active:
				_aim_target = target
				if _ai_state == AiState.COMBAT_AIMING and _fire_timer == INF:
					_fire_timer = _roll_combat_fire_delay()
			else:
				enter_combat(target, false)


func _update_faction_aggro(delta: float) -> void:
	if _defeated:
		return
	_try_deescalate_town_faction_combat()

	if _player_weapon_threat_active:
		if _faction_aggro_level == 1 and not _combat_active:
			_faction_aggro_entered_timer += delta
			_check_faction_aimed_at_response()
			_check_faction_ally_draw_support()
		return

	if _faction_aggro_level == 1 and not _combat_active:
		_faction_threat_lost_timer += delta
		if _faction_threat_lost_timer >= FACTION_THREAT_LOST_GRACE:
			_faction_aggro_level = 0
			_faction_provoker = null
			_faction_stare_target = null
			_faction_threat_lost_timer = 0.0
			_faction_aggro_entered_timer = 0.0
			_begin_idle()
		return
	if _combat_active or _faction_aggro_level >= 2:
		return
	_update_aim_aggro()


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
	if player == null:
		return
	if _faction_aggro_entered_timer < FACTION_STARE_BEFORE_DRAW_DELAY:
		return
	if player.has_method("is_weapon_aimed_at") and player.is_weapon_aimed_at(self, AIM_THREAT_RANGE):
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
		var draw_target: Node3D = null
		if npc.has_method("get_faction_aggro_target"):
			draw_target = npc.get_faction_aggro_target()
		if draw_target == null:
			draw_target = _pick_nearest_hostile_faction_member(FACTION_MAX_ENGAGE_RANGE)
		if draw_target != null:
			set_faction_aggro_level(2, draw_target)
			return


func exit_town_faction_combat_peaceful() -> void:
	if _defeated:
		return

	_player_weapon_threat_active = false
	_faction_threat_lost_timer = 0.0
	_player_holstered_deescalate_timer = 0.0
	_faction_aggro_entered_timer = 0.0
	_faction_aggro_level = 0
	_faction_provoker = null
	_faction_stare_target = null
	_combat_active = false
	_allied_aim_reaction = false
	_combat_move_pursue = false
	_standing_down = false
	_has_fired_in_combat = false
	_aim_target = null
	_has_locked_aim = false
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()
	_velocity_zero()
	_begin_idle()


func _try_deescalate_town_faction_combat() -> void:
	if _defeated:
		return
	if _faction_aggro_level < 2 and not _combat_active:
		return

	if _aim_target != null and is_instance_valid(_aim_target):
		if _aim_target.has_method("is_defeated") and _aim_target.is_defeated():
			exit_town_faction_combat_peaceful()
			return
		if _is_valid_combat_target(_aim_target) and not _is_combat_target_out_of_engagement_range():
			return

	if _pick_nearest_hostile_faction_member(FACTION_MAX_ENGAGE_RANGE) != null:
		return

	exit_town_faction_combat_peaceful()


func _update_aim_aggro() -> void:
	if _combat_active or _defeated or _player_weapon_threat_active:
		return

	var hostile := _pick_nearest_hostile_faction_member(INTERVENE_RANGE)
	if hostile != null:
		if global_position.distance_to(hostile.global_position) <= INTERVENE_RANGE:
			enter_combat(hostile)
			return


func _update_player_weapon_reaction(delta: float) -> void:
	if _defeated or _lasso_captured or _combat_active or _faction_aggro_level >= 2:
		return

	var player := _find_player()
	if player == null:
		return

	var horizontal_dist := _get_horizontal_distance_to(player)
	if horizontal_dist > AIM_THREAT_RANGE:
		return

	var threatening := _player_is_threatening_becker_boy(player, true)

	if threatening:
		_faction_threat_lost_timer = 0.0
		var play_alert := not _player_weapon_threat_active
		_begin_player_weapon_stare(player, play_alert)
		return

	if not _player_weapon_threat_active:
		return

	_faction_threat_lost_timer += delta
	if _faction_threat_lost_timer < FACTION_THREAT_LOST_GRACE:
		return

	_end_player_weapon_stare()


func _begin_player_weapon_stare(player: Node3D, play_alert: bool) -> void:
	_player_weapon_threat_active = true
	var entering := _faction_stare_target != player or _faction_aggro_level < 1
	_faction_stare_target = player
	_velocity_zero()
	if _ai_state != AiState.IDLE and not _combat_active:
		_saved_ai_state = _ai_state
		_ai_state = AiState.IDLE

	if play_alert and entering:
		_show_alert_fx()
		if _aggro_voice != null:
			if _player_is_aiming_at_me(player):
				if _aggro_voice.has_method("play_easy_there_now"):
					_aggro_voice.play_easy_there_now()
				else:
					_aggro_voice.schedule_easy_there(1.0)
			elif _aggro_voice.has_method("play_woah_now"):
				_aggro_voice.play_woah_now()
			elif _aggro_voice.has_method("play_woah_on_alert"):
				_aggro_voice.play_woah_on_alert()

	if _faction_aggro_level < 1:
		set_faction_aggro_level(1, player)
	else:
		_faction_provoker = player
		_faction_threat_lost_timer = 0.0


func _end_player_weapon_stare() -> void:
	_player_weapon_threat_active = false
	_faction_threat_lost_timer = 0.0
	_faction_aggro_entered_timer = 0.0
	_faction_aggro_level = 0
	_faction_provoker = null
	_faction_stare_target = null
	if not _combat_active:
		_begin_idle()


func _player_is_threatening_becker_boy(player: Node3D, include_self: bool = false) -> bool:
	if player == null:
		return false

	if include_self and _is_player_weapon_threatening_target(player, self):
		return true

	for npc in get_tree().get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc) or npc == self or not npc is Node3D:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.are_allies(self, npc):
			continue
		var to_ally: Vector3 = (npc as Node3D).global_position - global_position
		to_ally.y = 0.0
		if to_ally.length() > INTERVENE_RANGE:
			continue
		if _is_player_weapon_threatening_target(player, npc as Node3D):
			return true

	return false


func _is_player_weapon_threatening_target(player: Node3D, target: Node3D) -> bool:
	if player == null or target == null:
		return false

	var horizontal := target.global_position - player.global_position
	horizontal.y = 0.0
	if horizontal.length() > AIM_THREAT_RANGE:
		return false

	if not player.has_method("is_weapon_aimed_at"):
		return false
	return player.is_weapon_aimed_at(target, AIM_THREAT_RANGE)


func _player_is_aiming_at_me(player: Node3D) -> bool:
	return _is_player_weapon_threatening_target(player, self)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _pick_nearest_hostile_faction_member(max_range: float = FACTION_MAX_ENGAGE_RANGE) -> Node3D:
	var max_range_sq := max_range * max_range
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
		if dist_sq > max_range_sq or dist_sq >= nearest_dist_sq:
			continue
		nearest_dist_sq = dist_sq
		nearest = npc as Node3D

	for group_name: StringName in [&"engines_npc", &"bandit"]:
		for npc in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(npc) or npc == self:
				continue
			if npc.has_method("is_defeated") and npc.is_defeated():
				continue
			if not FactionAffinity.is_hostile(my_faction, FactionAffinity.resolve_faction_id(npc)):
				continue
			var dist_sq := global_position.distance_squared_to(npc.global_position)
			if dist_sq > max_range_sq or dist_sq >= nearest_dist_sq:
				continue
			nearest_dist_sq = dist_sq
			nearest = npc as Node3D

	var player := _find_player()
	if player != null and _is_provoked_player(player):
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq <= max_range_sq and dist_sq < nearest_dist_sq:
			nearest = player
	elif (
		player != null
		and FactionAffinity.is_hostile(my_faction, FactionIds.PLAYER)
	):
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq <= max_range_sq and dist_sq < nearest_dist_sq:
			nearest = player

	return nearest


func _get_horizontal_distance_to(target: Node3D) -> float:
	if target == null or not is_instance_valid(target):
		return INF
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _is_combat_target_out_of_engagement_range() -> bool:
	if _aim_target == null or not is_instance_valid(_aim_target):
		return true
	return _get_horizontal_distance_to(_aim_target) > FACTION_MAX_ENGAGE_RANGE


func _exit_combat_peaceful() -> void:
	if not _combat_active and _faction_aggro_level < 2:
		return
	exit_town_faction_combat_peaceful()


func _is_friendly_combatant(other: Node3D) -> bool:
	return FactionAffinity.are_allies(self, other)


func _refresh_combat_target_if_needed() -> void:
	if not _combat_active:
		return

	if _allied_aim_reaction:
		if (
			_aim_target != null
			and is_instance_valid(_aim_target)
			and _player_is_threatening_becker_boy(_aim_target, true)
		):
			return
		_allied_aim_reaction = false
		_exit_combat_peaceful()
		return

	if (
		_aim_target != null
		and is_instance_valid(_aim_target)
		and not (_aim_target.has_method("is_defeated") and _aim_target.is_defeated())
		and _is_valid_combat_target(_aim_target)
		and not _is_combat_target_out_of_engagement_range()
	):
		return

	var hostile := _pick_nearest_hostile_faction_member()
	if hostile == null:
		_exit_combat_peaceful()
		return

	_aim_target = hostile
	_committed_aim_zone = _pick_body_aim_zone()
	_refresh_aim_spread()
	_has_locked_aim = true
	_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset


func _update_combat_ai(delta: float) -> void:
	if not _combat_active or _defeated or _standing_down:
		return

	_refresh_combat_target_if_needed()

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


func _uses_aggro_fire_rate() -> bool:
	if _faction_aggro_level >= 2:
		return true
	if not _combat_active:
		return false
	var target := _aim_target if _aim_target != null else _faction_provoker
	return target != null and target.is_in_group("overworld_player")


func _roll_combat_fire_delay() -> float:
	if _uses_aggro_fire_rate():
		return randf_range(AGGRO_COMBAT_FIRE_DELAY_MIN, AGGRO_COMBAT_FIRE_DELAY_MAX)
	return randf_range(COMBAT_FIRE_DELAY_MIN, COMBAT_FIRE_DELAY_MAX)


func _begin_combat_aiming() -> void:
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return

	_refresh_aim_spread()
	_ai_state = AiState.COMBAT_AIMING
	if _allied_aim_reaction:
		_fire_timer = INF
		return

	_fire_timer_duration = _roll_combat_fire_delay()
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
	if _allied_aim_reaction:
		return
	if _weapon_rig == null or not _weapon_rig.is_aiming():
		return
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return

	_has_fired_in_combat = true
	if _aim_target != null and FactionAffinity.are_hostile(self, _aim_target):
		TownShootout.rally_becker_boys(_aim_target, get_tree())
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


func _update_player_holster_stand_down(delta: float) -> void:
	if _has_fired_in_combat or _standing_down:
		return
	if _aim_target == null:
		return
	if not _aim_target.is_in_group("overworld_player"):
		_player_holstered_deescalate_timer = 0.0
		return
	if _aim_target.has_method("is_weapon_raised") and _aim_target.is_weapon_raised():
		_player_holstered_deescalate_timer = 0.0
		return

	_player_holstered_deescalate_timer += delta
	if _player_holstered_deescalate_timer < PLAYER_HOLSTER_DEESCALATE_DELAY:
		return

	_player_holstered_deescalate_timer = 0.0
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
	exit_town_faction_combat_peaceful()


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

	_body = rig.get_node_or_null("Body") as Node3D
	if _body == null:
		push_error("TownNpc: missing Body on sheriff rig.")
		return

	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)
	if _skeleton == null:
		push_error("TownNpc: missing skeleton on sheriff body.")
	if _animation_player == null:
		push_error("TownNpc: missing AnimationPlayer on sheriff body.")

	_apply_gentleman_appearance()


func _apply_gentleman_appearance() -> void:
	if _body == null:
		return

	var texture := load(SheriffAnimConfig.GENTLEMAN_ALBEDO_TEXTURE) as Texture2D
	if texture == null:
		push_warning(
			"TownNpc: failed to load gentleman texture from %s."
			% SheriffAnimConfig.GENTLEMAN_ALBEDO_TEXTURE
		)
		return

	MeshyCharacterMaterials.apply_outdoor_skin(_body, texture, false)


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

	_register_stumble_clip()

	if not MeshyLocomotionUtils.setup_idle_walk_animation_tree(_animation_tree, _animation_player):
		push_error("TownNpc: failed to set up AnimationTree.")
		return

	MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, 0.0)


func _setup_npc_locomotion_audio() -> void:
	if _npc_locomotion_audio != null:
		return

	_npc_locomotion_audio = LocomotionAudioScript.new()
	_npc_locomotion_audio.name = "NpcLocomotionAudio"
	add_child(_npc_locomotion_audio)
	_npc_locomotion_audio.setup(self, LocomotionAudioScript.Kind.NPC)


func _update_npc_locomotion_audio(
	delta: float,
	horizontal_speed: float,
	moving: bool,
	sprinting: bool
) -> void:
	if _npc_locomotion_audio == null:
		return

	_npc_locomotion_audio.update(
		delta,
		moving,
		sprinting,
		horizontal_speed,
		is_on_floor()
	)


func _register_stumble_clip() -> void:
	if _animation_player == null:
		return

	var library := _animation_player.get_animation_library(SheriffAnimConfig.LOCOMOTION_LIBRARY)
	if library == null:
		return

	if library.has_animation(RigAnimConfig.LOCOMOTION_STUMBLE):
		return

	var raw := RigAnimUtils.load_skeleton_animation(RigAnimConfig.STUMBLE_SCENE)
	if raw == null:
		push_error("TownNpc: failed to load stumble clip from %s." % RigAnimConfig.STUMBLE_SCENE)
		return

	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	library.add_animation(RigAnimConfig.LOCOMOTION_STUMBLE, animation)


func _get_stumble_anim_path() -> StringName:
	return StringName(
		"%s/%s" % [SheriffAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_STUMBLE]
	)


func is_npc_shoveable() -> bool:
	return not _defeated and not _lasso_captured and not _talking


func is_combat_active() -> bool:
	return _combat_active


func _sync_npc_collision_mode() -> void:
	var wants_combat := _combat_active and not _defeated
	if wants_combat == _collision_mode_combat:
		return
	_collision_mode_combat = wants_combat
	TownNpcShove.sync_npc_collision_mode(self, wants_combat)


func is_npc_shove_busy() -> bool:
	return _shove_stumbling or _gentle_shove_stepping or _shove_settling


func get_push_intent() -> Vector3:
	if is_npc_shove_busy() or _defeated or _lasso_captured or _talking:
		return Vector3.ZERO
	match _ai_state:
		AiState.WALKING:
			if _walk_direction.length_squared() > 0.0001:
				return _walk_direction * WALK_SPEED
		AiState.COMBAT_MOVING:
			if _combat_move_pursue and _aim_target != null:
				var to_target := _aim_target.global_position - global_position
				to_target.y = 0.0
				if to_target.length_squared() > 0.0001:
					return to_target.normalized() * RUN_SPEED
			var to_relocate := _combat_move_target - global_position
			to_relocate.y = 0.0
			if to_relocate.length_squared() > 0.0001:
				return to_relocate.normalized() * RUN_SPEED
	return Vector3(velocity.x, 0.0, velocity.z)


func _capture_shove_resume_state() -> void:
	_shove_saved_ai_state = _ai_state
	_shove_was_in_combat = _combat_active


func _resume_after_shove() -> void:
	if _defeated:
		return
	if _combat_active or _shove_was_in_combat:
		_ai_state = _shove_saved_ai_state
		return
	_begin_idle()


func _get_shove_settle_target_blend() -> float:
	if _ai_state == AiState.WALKING or _ai_state == AiState.COMBAT_MOVING:
		return SHOVE_STEP_WALK_BLEND
	return 0.0


func _begin_shove_settle(
	from_blend: float,
	duration: float = TownNpcShove.SHOVE_SETTLE_DURATION
) -> void:
	_shove_settling = true
	_shove_settle_time = 0.0
	_shove_settle_from_blend = from_blend
	_shove_settle_duration = duration
	_set_shove_step_locomotion(from_blend)


func _process_shove_settle(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = 0.0
	velocity.z = 0.0

	if _combat_active and _aim_target != null:
		_face_position(_aim_target.global_position, delta)

	_shove_settle_time += delta
	var t := clampf(_shove_settle_time / _shove_settle_duration, 0.0, 1.0)
	var eased := TownNpcShove.settle_ease(t)
	var target := _get_shove_settle_target_blend()
	var blend := lerpf(_shove_settle_from_blend, target, eased)
	_set_shove_step_locomotion(blend)

	move_and_slide()
	_update_npc_locomotion_audio(delta, 0.0, false, false)

	if t >= 1.0:
		_shove_settling = false
		_locomotion_blend = target


func _set_shove_step_locomotion(blend: float) -> void:
	_locomotion_blend = blend
	MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, blend)


func _begin_gentle_shove_step(push_dir: Vector3, speed: float) -> void:
	_capture_shove_resume_state()
	_gentle_shove_stepping = true
	_gentle_shove_step_time = 0.0
	_gentle_shove_step_dir = push_dir
	if _gentle_shove_step_dir.length_squared() < 0.0001:
		_gentle_shove_step_dir = -global_transform.basis.z
	_gentle_shove_step_dir.y = 0.0
	_gentle_shove_step_dir = _gentle_shove_step_dir.normalized()
	_gentle_shove_step_from = global_position
	var speed_ratio := clampf(speed / TownNpcShove.GENTLE_MAX_SPEED, 0.65, 1.15)
	_gentle_shove_step_distance = TownNpcShove.SHOVE_STEP_DISTANCE * speed_ratio
	_velocity_zero()
	_face_position(global_position + _gentle_shove_step_dir, 0.016)


func _process_gentle_shove_step(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_gentle_shove_step_time += delta
	var t := clampf(_gentle_shove_step_time / TownNpcShove.SHOVE_STEP_DURATION, 0.0, 1.0)
	var move_t := TownNpcShove.gentle_step_ease(t)
	var blend := TownNpcShove.gentle_step_walk_blend(t, SHOVE_STEP_WALK_BLEND)
	_set_shove_step_locomotion(blend)

	var target_pos := (
		_gentle_shove_step_from
		+ _gentle_shove_step_dir * (_gentle_shove_step_distance * move_t)
	)
	global_position = TownNpcShove.clip_step_position(
		self,
		_gentle_shove_step_from,
		target_pos
	)
	_face_position(global_position + _gentle_shove_step_dir, delta)

	move_and_slide()
	_update_npc_locomotion_audio(
		delta,
		_gentle_shove_step_distance / TownNpcShove.SHOVE_STEP_DURATION,
		true,
		false
	)

	if t >= 1.0:
		_end_gentle_shove_step()


func _end_gentle_shove_step() -> void:
	_gentle_shove_stepping = false
	_gentle_shove_step_time = 0.0
	_gentle_shove_step_cooldown = TownNpcShove.SHOVE_STEP_COOLDOWN
	_begin_shove_settle(_locomotion_blend)
	_resume_after_shove()


func _begin_shove_stumble(push_dir: Vector3) -> void:
	_capture_shove_resume_state()
	_stumble_exit_blending = false
	_shove_stumbling = true
	_shove_direction = push_dir
	if _shove_direction.length_squared() < 0.0001:
		_shove_direction = -global_transform.basis.z
	_shove_direction.y = 0.0
	_shove_direction = _shove_direction.normalized()
	_shove_stumble_cooldown = SHOVE_STUMBLE_COOLDOWN
	_velocity_zero()

	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = true
		_animation_player.speed_scale = 1.0
		var stumble_path := _get_stumble_anim_path()
		if _animation_player.has_animation(stumble_path):
			if not _animation_player.animation_finished.is_connected(_on_shove_stumble_anim_finished):
				_animation_player.animation_finished.connect(_on_shove_stumble_anim_finished)
			_animation_player.play(stumble_path)

	if _aggro_voice != null and _aggro_voice.has_method("play_woah_now"):
		_aggro_voice.play_woah_now()


func _get_stumble_exit_blend() -> float:
	return SHOVE_STEP_WALK_BLEND


func _get_stumble_exit_speed_scale() -> float:
	if _animation_player == null:
		return 0.0

	var stumble_path := _get_stumble_anim_path()
	var anim := _animation_player.get_animation(stumble_path)
	if anim == null or anim.length <= 0.001:
		return 0.0

	var remaining := anim.length - _animation_player.current_animation_position
	var t := 1.0 - clampf(remaining / TownNpcShove.STUMBLE_EXIT_BLEND_DURATION, 0.0, 1.0)
	return 1.0 - TownNpcShove.settle_ease(t)


func _activate_locomotion_for_stumble_exit() -> void:
	var exit_blend := _get_stumble_exit_blend()
	_locomotion_blend = exit_blend
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, exit_blend)
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.active = true
		_animation_player.speed_scale = 1.0


func _try_begin_stumble_exit_blend() -> void:
	if _stumble_exit_blending or _animation_player == null:
		return

	var stumble_path := _get_stumble_anim_path()
	if _animation_player.current_animation != stumble_path:
		return

	var anim := _animation_player.get_animation(stumble_path)
	if anim == null:
		return

	var remaining := anim.length - _animation_player.current_animation_position
	if remaining > TownNpcShove.STUMBLE_EXIT_BLEND_DURATION:
		return

	_stumble_exit_blending = true
	_activate_locomotion_for_stumble_exit()


func _process_shove_stumble(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_try_begin_stumble_exit_blend()

	var speed_scale := _get_stumble_exit_speed_scale() if _stumble_exit_blending else 1.0
	velocity.x = _shove_direction.x * SHOVE_STUMBLE_SPEED * speed_scale
	velocity.z = _shove_direction.z * SHOVE_STUMBLE_SPEED * speed_scale
	_face_position(global_position + _shove_direction, delta)
	move_and_slide()
	_update_npc_locomotion_audio(
		delta,
		Vector2(velocity.x, velocity.z).length(),
		true,
		false
	)


func _on_shove_stumble_anim_finished(anim_name: StringName) -> void:
	if anim_name != _get_stumble_anim_path():
		return
	if _animation_player != null and _animation_player.animation_finished.is_connected(
		_on_shove_stumble_anim_finished
	):
		_animation_player.animation_finished.disconnect(_on_shove_stumble_anim_finished)
	_end_shove_stumble()


func _end_shove_stumble() -> void:
	_shove_stumbling = false
	_shove_direction = Vector3.ZERO
	_stumble_exit_blending = false
	_velocity_zero()
	if _animation_player != null:
		if _animation_player.animation_finished.is_connected(_on_shove_stumble_anim_finished):
			_animation_player.animation_finished.disconnect(_on_shove_stumble_anim_finished)
		if _animation_player.is_playing():
			_animation_player.stop()
	_activate_locomotion_for_stumble_exit()
	_begin_shove_settle(_get_stumble_exit_blend(), TownNpcShove.STUMBLE_SETTLE_DURATION)
	_resume_after_shove()


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


func _update_locomotion_blend(delta: float, speed: float, _sprinting: bool = false) -> void:
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
