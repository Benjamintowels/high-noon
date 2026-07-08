extends GroypetteActor
class_name GroypetteCivilianNpc

const AlertSymbolFX := preload("res://gameplay/fx/alert_symbol_fx.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const TownShootout := preload("res://gameplay/world/town_shootout.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const LassoHumanoidDragScript := preload("res://gameplay/lasso/lasso_humanoid_drag.gd")
const MeshyLassoStandupScript := preload("res://characters/groypette/meshy_lasso_standup.gd")
const MeshyCivilianNpcShove := preload("res://gameplay/world/meshy_civilian_npc_shove.gd")

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const WALK_SPEED := 2.0
const RUN_SPEED := 5.0
const AIM_THREAT_RANGE := 48.0
const GUNSHOT_HEAR_RANGE := 42.0
const NEARBY_COMBAT_RANGE := 30.0
const FLEE_SAFE_DISTANCE := 16.0
const FLEE_MAX_DURATION := 8.0
const SOCIAL_TALK_RANGE := 3.25
const SOCIAL_TALK_MIN := 4.0
const SOCIAL_TALK_MAX := 8.0
const SOCIAL_TALK_COOLDOWN := 12.0
const CHEST_AIM_HEIGHT := 1.2
const ALERT_HEAD_OFFSET := 2.1
const HITBOX_HALF_HEIGHT := 0.48
const HITBOX_RADIUS := 0.28
const MAX_HEALTH := 2

enum AiState {
	IDLE,
	WALKING,
	STARING,
	FLEEING,
	SOCIAL_TALK,
	CHEERING,
	DEFEATED,
}

@export var idle_duration_min := 4.0
@export var idle_duration_max := 9.0
@export var walk_duration_min := 2.0
@export var walk_duration_max := 5.0

var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _move_blend := 0.0
var _walk_run_blend := 0.0
var _run_variant := 0.0
var _active_idle_state := GroypetteAnimConfig.IDLE_6
var _idle_variant_timer := 0.0
var _idle_variant_delay := GroypetteAnimConfig.IDLE_VARIANT_DELAY_MIN
var _aim_target: Node3D
var _defeated := false
var _health := MAX_HEALTH
var _player_weapon_threat_active := false
var _flee_origin := Vector3.ZERO
var _social_partner: Node3D
var _social_talk_cooldown := 0.0
var _saved_ai_state := AiState.IDLE
var _voice_player: AudioStreamPlayer3D
var _roam_center := Vector3.ZERO
var _roam_half_extents := Vector2(6.0, 36.0)
var _ragdoll
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_ring: LassoRing
var _lasso_rope_length := 8.5
var _lasso_standup_active := false
var _lasso_standup_time := 0.0
var _lasso_standup_blend := 0.0
var _lasso_standup_nodes_ready := false
var _lasso_standup_model_sink := 0.0
var _standup_anim_path := StringName()
var _locomotion_output_node := GroypetteAnimConfig.MOVE_BLEND_NODE
var _player_shove := MeshyCivilianNpcShove.new()
var _shove_saved_ai_state := AiState.IDLE


func _on_actor_ready() -> void:
	add_to_group("town_npc")
	add_to_group("becker_boys")
	add_to_group("civilian")
	add_to_group("groypette_npc")
	add_to_group("faction_npc")
	add_to_group("duel_target")
	add_to_group("lassoable")
	_setup_locomotion()
	_setup_lasso_ragdoll()
	setup_npc_locomotion_audio()
	_player_shove.bind(self)
	_begin_idle()
	call_deferred("_finalize_spawn")


func get_faction_id() -> StringName:
	return FactionIds.BECKER_BOYS


func _finalize_spawn() -> void:
	snap_to_floor()
	_roam_center = global_position


func _physics_process(delta: float) -> void:
	if _defeated:
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if _player_shove.process_physics(delta):
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_social_talk_cooldown = maxf(_social_talk_cooldown - delta, 0.0)
	_state_timer -= delta

	if not _defeated and _ai_state not in [AiState.FLEEING, AiState.CHEERING]:
		_update_player_weapon_reaction(delta)
		_check_nearby_combat_threat()

	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer <= 0.0:
				_try_begin_social_talk()
			if _ai_state == AiState.IDLE and _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if _state_timer <= 0.0:
				_try_begin_social_talk()
			if _ai_state == AiState.WALKING and _state_timer <= 0.0:
				_begin_idle()
		AiState.STARING:
			velocity.x = 0.0
			velocity.z = 0.0
			if _aim_target != null:
				_face_position(_aim_target.global_position, delta)
		AiState.FLEEING:
			_process_flee(delta)
		AiState.SOCIAL_TALK:
			velocity.x = 0.0
			velocity.z = 0.0
			if _social_partner != null and is_instance_valid(_social_partner):
				_face_position(_social_partner.global_position, delta)
			if _state_timer <= 0.0:
				_end_social_talk()
		AiState.CHEERING:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer <= 0.0:
				_begin_idle()

	move_and_slide()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var sprinting := _ai_state == AiState.FLEEING
	if not _player_shove.is_busy():
		_update_locomotion_blend(delta, horizontal_speed, sprinting)
	_update_idle_variant(delta)
	update_npc_locomotion_audio(delta, horizontal_speed, horizontal_speed > 0.05, sprinting)


func _process(_delta: float) -> void:
	if _voice_player == null or not is_instance_valid(_voice_player) or not _voice_player.playing:
		return
	_voice_player.global_position = get_voice_world_position()


func alert_to_gunshot(origin: Vector3) -> void:
	if _defeated or _lasso_captured or _ai_state == AiState.CHEERING:
		return
	if global_position.distance_to(origin) > GUNSHOT_HEAR_RANGE:
		return
	_begin_flee(origin)


func celebrate_town_event() -> void:
	if _defeated or _lasso_captured or _ai_state in [AiState.FLEEING, AiState.CHEERING]:
		return

	_stop_social_talk_immediate()
	_end_weapon_stare(false)
	_saved_ai_state = _ai_state
	_ai_state = AiState.CHEERING
	velocity = Vector3.ZERO
	_set_move_blend(0.0)
	_travel_idle_state(GroypetteAnimConfig.IDLE_CHEER)
	_state_timer = _cheer_duration()
	_play_cute_voice()


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
	_stop_social_talk_immediate()
	_end_weapon_stare(false)
	_lasso_captured = true
	_lasso_player = player
	_lasso_ring = ring
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	_ai_state = AiState.IDLE
	_play_scared_voice()


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


func play_lasso_drag_voice() -> void:
	_play_scared_voice()


func is_lasso_standup_active() -> bool:
	return _lasso_standup_active


func has_lasso_standup_animation() -> bool:
	return _lasso_standup_nodes_ready


func begin_lasso_drag_standup() -> bool:
	if not has_lasso_standup_animation() or _ragdoll == null:
		return false
	if not _ragdoll.is_lasso_drag_mode():
		return false
	_lasso_standup_active = true
	_lasso_standup_time = 0.0
	_lasso_standup_blend = 1.0
	_lasso_standup_model_sink = 0.0
	MeshyLassoStandupScript.set_stand_seek(_animation_tree, 0.0)
	MeshyLassoStandupScript.set_stand_playback_speed(
		_animation_tree,
		MeshyLassoStandupScript.PLAYBACK_SPEED
	)
	MeshyLassoStandupScript.set_blend(_animation_tree, 1.0)
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.speed_scale = 1.0
		_animation_player.active = true
	_move_blend = 0.0
	_set_move_blend(0.0)
	return true


func update_lasso_drag_standup(delta: float) -> void:
	if not _lasso_standup_active or not has_lasso_standup_animation():
		return
	_lasso_standup_time += delta
	var duration := MeshyLassoStandupScript.get_stand_duration(_animation_player, _standup_anim_path)
	var progress := clampf(_lasso_standup_time / duration, 0.0, 1.0)
	_lasso_standup_blend = MeshyLassoStandupScript.update_smoothed_blend(
		_lasso_standup_blend,
		progress,
		delta
	)
	MeshyLassoStandupScript.set_blend(_animation_tree, _lasso_standup_blend)
	if _ragdoll != null and _ragdoll.is_lasso_animation_standup():
		_ragdoll.set_standup_body_progress(progress)
	_lasso_standup_model_sink = MeshyLassoStandupScript.apply_model_ground_sink(
		_model,
		progress,
		_lasso_standup_model_sink,
		delta
	)
	if MeshyLassoStandupScript.should_finish(progress, _lasso_standup_blend):
		_finish_lasso_standup()


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	LassoHumanoidDragScript.apply(self, self, player, _lasso_ring, _lasso_rope_length, delta)
	LassoHumanoidDragScript.finish_settling_if_needed(self)


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.55, 0.0)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	var shooter: Node3D = hit_info.get("shooter")
	var result := BulletHitDamage.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health

	TownShootout.rally_becker_boys_on_injury(self, shooter, get_tree())

	if not result.killed and shooter != null:
		_begin_flee(shooter.global_position)

	if result.killed:
		_activate_defeat_ragdoll(hit_info)


func get_bullet_capsule() -> Dictionary:
	var torso := GroyperBodyUtils.get_torso_transform(
		_skeleton,
		global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	)
	return {
		"center": global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0),
		"half_height": HITBOX_HALF_HEIGHT,
		"radius": HITBOX_RADIUS,
		"axis": torso.basis.y,
	}


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	)


func _check_nearby_combat_threat() -> void:
	if _defeated or _lasso_captured or _ai_state in [AiState.FLEEING, AiState.CHEERING]:
		return

	for node in get_tree().get_nodes_in_group("town_npc"):
		if node == self or not (node is Node3D):
			continue
		if node.is_in_group("civilian"):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		if not node.has_method("get_faction_aggro_level"):
			continue
		if node.get_faction_aggro_level() < 2:
			continue
		var other := node as Node3D
		if global_position.distance_to(other.global_position) > NEARBY_COMBAT_RANGE:
			continue
		_begin_flee(other.global_position)
		return


func _update_player_weapon_reaction(_delta: float) -> void:
	if _defeated or _lasso_captured or _ai_state in [AiState.SOCIAL_TALK, AiState.CHEERING]:
		return

	var player := _find_player()
	if player == null:
		if _player_weapon_threat_active:
			_end_weapon_stare(true)
		return

	if global_position.distance_to(player.global_position) > AIM_THREAT_RANGE:
		if _player_weapon_threat_active:
			_end_weapon_stare(true)
		return

	if _player_is_aiming_at_me(player):
		var play_alert := not _player_weapon_threat_active
		_begin_weapon_stare(player, play_alert)
		return

	if _player_weapon_threat_active:
		_end_weapon_stare(true)


func _begin_weapon_stare(player: Node3D, play_alert: bool) -> void:
	_player_weapon_threat_active = true
	var entering := _ai_state != AiState.STARING or _aim_target != player
	_aim_target = player
	if _ai_state != AiState.STARING:
		_saved_ai_state = _ai_state
		_ai_state = AiState.STARING
		velocity = Vector3.ZERO

	_travel_idle_state(GroypetteAnimConfig.IDLE_6)

	if play_alert and entering:
		_show_alert_fx()
		_play_scared_voice()


func _end_weapon_stare(run_away: bool) -> void:
	if not _player_weapon_threat_active:
		return

	_player_weapon_threat_active = false
	var was_staring := _ai_state == AiState.STARING
	_aim_target = null

	if not was_staring:
		return

	if run_away:
		var flee_origin := global_position
		var player := _find_player()
		if player != null:
			flee_origin = player.global_position
		_play_scared_voice()
		_begin_flee(flee_origin, false)
		return

	_ai_state = _saved_ai_state
	if _ai_state == AiState.IDLE:
		_state_timer = randf_range(idle_duration_min, idle_duration_max)
		_reset_idle_anim()


func _begin_flee(origin: Vector3, play_voice: bool = true) -> void:
	if _defeated or _lasso_captured or _ai_state == AiState.CHEERING:
		return

	_stop_social_talk_immediate()
	_player_weapon_threat_active = false
	_aim_target = null
	_ai_state = AiState.FLEEING
	_flee_origin = origin
	_state_timer = FLEE_MAX_DURATION
	_run_variant = 1.0 if randf() > 0.5 else 0.0
	_set_run_variant(_run_variant)
	if play_voice:
		_play_scared_voice()


func _process_flee(delta: float) -> void:
	_state_timer -= delta
	var away := global_position - _flee_origin
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -global_transform.basis.z
	away = away.normalized()

	velocity.x = away.x * RUN_SPEED
	velocity.z = away.z * RUN_SPEED
	_face_position(global_position + away, delta)

	if (
		_state_timer <= 0.0
		or global_position.distance_to(_flee_origin) >= FLEE_SAFE_DISTANCE
	):
		_begin_idle()


func _try_begin_social_talk() -> void:
	if _social_talk_cooldown > 0.0 or _player_weapon_threat_active:
		return

	var partner := _find_nearby_townsperson()
	if partner == null:
		return

	_saved_ai_state = _ai_state
	_ai_state = AiState.SOCIAL_TALK
	_social_partner = partner
	_state_timer = randf_range(SOCIAL_TALK_MIN, SOCIAL_TALK_MAX)
	_social_talk_cooldown = SOCIAL_TALK_COOLDOWN
	_play_social_talk_anim()
	_play_cute_voice()


func _end_social_talk() -> void:
	_social_partner = null
	_ai_state = _saved_ai_state
	_reset_idle_anim()
	if _ai_state == AiState.IDLE:
		_state_timer = randf_range(idle_duration_min, idle_duration_max)
	elif _ai_state == AiState.WALKING:
		_state_timer = randf_range(walk_duration_min, walk_duration_max)


func _stop_social_talk_immediate() -> void:
	if _ai_state != AiState.SOCIAL_TALK:
		return
	_social_partner = null


func _find_nearby_townsperson() -> Node3D:
	var best: Node3D
	var best_dist_sq := SOCIAL_TALK_RANGE * SOCIAL_TALK_RANGE
	for node in get_tree().get_nodes_in_group("town_npc"):
		if node == self or not (node is Node3D):
			continue
		if node.is_in_group("civilian") and not node.is_in_group("groypette_npc"):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		var other := node as Node3D
		var dist_sq := global_position.distance_squared_to(other.global_position)
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			best = other
	return best


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO
	_reset_idle_anim()


func _begin_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	_clamp_walk_direction_to_roam()


func _clamp_walk_direction_to_roam() -> void:
	var offset := global_position - _roam_center
	if absf(offset.x) > _roam_half_extents.x:
		_walk_direction.x = -signf(offset.x)
	if absf(offset.z) > _roam_half_extents.y:
		_walk_direction.z = -signf(offset.z)
	if _walk_direction.length_squared() < 0.0001:
		var angle := randf_range(0.0, TAU)
		_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := MeshyLocomotionUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _player_is_aiming_at_me(player: Node3D) -> bool:
	if player == null or not player.has_method("is_weapon_aimed_at"):
		return false
	return player.is_weapon_aimed_at(self, AIM_THREAT_RANGE)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _show_alert_fx() -> void:
	AlertSymbolFX.spawn_above(self, global_position + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0))


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("GroypetteCivilianNpc: missing AnimationPlayer on Groypette body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	for state_name: StringName in GroypetteAnimConfig.IDLE_CLIP_BY_STATE.keys():
		var meshy_clip: StringName = GroypetteAnimConfig.IDLE_CLIP_BY_STATE[state_name]
		var loop_once := state_name in GroypetteAnimConfig.LOOP_ONCE_STATES
		_add_meshy_clip(library, state_name, meshy_clip, not loop_once)
	_add_meshy_clip(library, GroypetteAnimConfig.LOCOMOTION_WALK, GroypetteAnimConfig.MESHY_WALK)
	_add_meshy_clip(library, GroypetteAnimConfig.LOCOMOTION_RUN_A, GroypetteAnimConfig.MESHY_RUN_A)
	_add_meshy_clip(library, GroypetteAnimConfig.LOCOMOTION_RUN_B, GroypetteAnimConfig.MESHY_RUN_B)

	if _animation_player.has_animation_library(GroypetteAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(GroypetteAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(GroypetteAnimConfig.LOCOMOTION_LIBRARY, library)

	var idle_paths := _required_anim_paths(GroypetteAnimConfig.IDLE_CLIP_BY_STATE.keys())
	var walk_path := _anim_path(GroypetteAnimConfig.LOCOMOTION_WALK)
	var run_a_path := _anim_path(GroypetteAnimConfig.LOCOMOTION_RUN_A)
	var run_b_path := _anim_path(GroypetteAnimConfig.LOCOMOTION_RUN_B)
	if idle_paths.is_empty() or not _animation_player.has_animation(walk_path):
		push_error("GroypetteCivilianNpc: locomotion clips missing on AnimationPlayer.")
		return

	var idle_sm := _build_idle_state_machine(idle_paths)
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_a_node := AnimationNodeAnimation.new()
	run_a_node.animation = run_a_path
	var run_b_node := AnimationNodeAnimation.new()
	run_b_node.animation = run_b_path

	var run_variant_space := AnimationNodeBlendSpace1D.new()
	run_variant_space.add_blend_point(run_a_node, 0.0)
	run_variant_space.add_blend_point(run_b_node, 1.0)
	run_variant_space.min_space = 0.0
	run_variant_space.max_space = 1.0

	var walk_run_space := AnimationNodeBlendSpace1D.new()
	walk_run_space.add_blend_point(walk_node, 0.0)
	walk_run_space.add_blend_point(run_variant_space, 1.0)
	walk_run_space.min_space = 0.0
	walk_run_space.max_space = 1.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(GroypetteAnimConfig.IDLE_STATE_NODE, idle_sm)
	blend_tree.add_node(GroypetteAnimConfig.RUN_VARIANT_NODE, run_variant_space)
	blend_tree.add_node(GroypetteAnimConfig.LOCOMOTION_BLEND_NODE, walk_run_space)
	blend_tree.add_node(GroypetteAnimConfig.MOVE_BLEND_NODE, move_blend)
	blend_tree.connect_node(GroypetteAnimConfig.MOVE_BLEND_NODE, 0, GroypetteAnimConfig.IDLE_STATE_NODE)
	blend_tree.connect_node(
		GroypetteAnimConfig.MOVE_BLEND_NODE,
		1,
		GroypetteAnimConfig.LOCOMOTION_BLEND_NODE
	)
	_locomotion_output_node = GroypetteAnimConfig.MOVE_BLEND_NODE

	_lasso_standup_nodes_ready = MeshyLassoStandupScript.attach_standup_branch(
		blend_tree,
		_locomotion_output_node,
		_animation_player,
		GroypetteAnimConfig.STANDUP_LIBRARY,
		GroypetteAnimConfig.STAND_UP,
		GroypetteAnimConfig.MERGED_SCENE,
		GroypetteAnimConfig.MESHY_STAND_UP
	)
	_standup_anim_path = StringName(
		"%s/%s" % [GroypetteAnimConfig.STANDUP_LIBRARY, GroypetteAnimConfig.STAND_UP]
	)
	if _lasso_standup_nodes_ready:
		blend_tree.connect_node(&"output", 0, MeshyLassoStandupScript.BLEND_NODE)
		MeshyLassoStandupScript.init_tree_state(_animation_tree)
	else:
		blend_tree.connect_node(&"output", 0, _locomotion_output_node)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_player.stop()
	_reset_idle_anim()
	_set_move_blend(0.0)
	_set_walk_run_blend(0.0)
	_set_run_variant(0.0)


func _required_anim_paths(clip_names: Array) -> Dictionary:
	var paths := {}
	for clip_name: StringName in clip_names:
		var path := _anim_path(clip_name)
		if not _animation_player.has_animation(path):
			push_error("GroypetteCivilianNpc: missing clip '%s'." % clip_name)
			return {}
		paths[clip_name] = path
	return paths


func _anim_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [GroypetteAnimConfig.LOCOMOTION_LIBRARY, clip_name])


func _build_idle_state_machine(idle_paths: Dictionary) -> AnimationNodeStateMachine:
	var idle_sm := AnimationNodeStateMachine.new()
	var state_names: Array[StringName] = []
	for state_name: StringName in idle_paths.keys():
		state_names.append(state_name)
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = idle_paths[state_name]
		idle_sm.add_node(state_name, anim_node)

	var start_transition := AnimationNodeStateMachineTransition.new()
	idle_sm.add_transition(&"Start", GroypetteAnimConfig.IDLE_6, start_transition)

	var cheer_to_idle := AnimationNodeStateMachineTransition.new()
	cheer_to_idle.xfade_time = GroypetteAnimConfig.IDLE_CROSSFADE
	cheer_to_idle.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
	idle_sm.add_transition(GroypetteAnimConfig.IDLE_CHEER, GroypetteAnimConfig.IDLE_6, cheer_to_idle)

	for from_state: StringName in state_names:
		for to_state: StringName in state_names:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = GroypetteAnimConfig.IDLE_CROSSFADE
			idle_sm.add_transition(from_state, to_state, transition)

	return idle_sm


func _add_meshy_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop: bool = true
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(GroypetteAnimConfig.MERGED_SCENE, meshy_clip)
	if raw == null:
		push_error("GroypetteCivilianNpc: failed to load clip '%s'." % meshy_clip)
		return
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	library.add_animation(clip_name, animation)


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return

	var moving := speed > 0.05 and _ai_state not in [AiState.SOCIAL_TALK, AiState.CHEERING, AiState.STARING]
	if moving:
		_move_blend = lerpf(_move_blend, 1.0, BLEND_SPEED * delta)
		var walk_run_target := 1.0 if sprinting else 0.0
		_walk_run_blend = lerpf(_walk_run_blend, walk_run_target, BLEND_SPEED * delta)
		_set_move_blend(_move_blend)
		_set_walk_run_blend(_walk_run_blend)
	else:
		_move_blend = 0.0
		_walk_run_blend = 0.0
		_set_move_blend(0.0)
		_set_walk_run_blend(0.0)
		if _ai_state not in [AiState.STARING, AiState.CHEERING, AiState.SOCIAL_TALK]:
			_reset_idle_anim()


func _update_idle_variant(delta: float) -> void:
	if _defeated or _lasso_captured or _animation_tree == null or not _animation_tree.active:
		return
	if _move_blend > 0.05 or _ai_state in [AiState.FLEEING, AiState.STARING, AiState.CHEERING, AiState.SOCIAL_TALK]:
		_idle_variant_timer = 0.0
		return

	_idle_variant_timer += delta
	if _idle_variant_timer >= _idle_variant_delay:
		_idle_variant_timer = 0.0
		_idle_variant_delay = randf_range(
			GroypetteAnimConfig.IDLE_VARIANT_DELAY_MIN,
			GroypetteAnimConfig.IDLE_VARIANT_DELAY_MAX
		)
		_pick_random_idle_variant()


func _pick_random_idle_variant() -> void:
	var next_state: StringName = GroypetteAnimConfig.IDLE_VARIANTS[
		randi() % GroypetteAnimConfig.IDLE_VARIANTS.size()
	]
	_travel_idle_state(next_state)


func _play_social_talk_anim() -> void:
	_pick_random_idle_variant()


func _set_move_blend(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % GroypetteAnimConfig.MOVE_BLEND_NODE,
		value
	)


func _set_walk_run_blend(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_position" % GroypetteAnimConfig.LOCOMOTION_BLEND_NODE,
		value
	)


func _set_run_variant(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_position" % GroypetteAnimConfig.RUN_VARIANT_NODE,
		value
	)


func _reset_idle_anim() -> void:
	_idle_variant_timer = 0.0
	_idle_variant_delay = randf_range(
		GroypetteAnimConfig.IDLE_VARIANT_DELAY_MIN,
		GroypetteAnimConfig.IDLE_VARIANT_DELAY_MAX
	)
	_active_idle_state = GroypetteAnimConfig.IDLE_VARIANTS[
		randi() % GroypetteAnimConfig.IDLE_VARIANTS.size()
	]
	_travel_idle_state(_active_idle_state)


func _travel_idle_state(state_name: StringName) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var playback: AnimationNodeStateMachinePlayback = _animation_tree.get(
		"parameters/%s/playback" % GroypetteAnimConfig.IDLE_STATE_NODE
	)
	if playback == null:
		return
	if playback.get_current_node() == state_name:
		_active_idle_state = state_name
		return
	playback.travel(state_name)
	_active_idle_state = state_name


func _cheer_duration() -> float:
	var cheer_path := _anim_path(GroypetteAnimConfig.IDLE_CHEER)
	if _animation_player != null and _animation_player.has_animation(cheer_path):
		return _animation_player.get_animation(cheer_path).length
	return 2.5


func _play_voice(stream: AudioStream, extra_pitch_jitter := 0.0) -> void:
	if stream == null:
		return
	_stop_voice()
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "GroypetteVoice"
	_voice_player.stream = stream
	_voice_player.max_distance = 48.0
	_voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice_player.unit_size = 2.0
	var pitch_min := GameAudio.PITCH_MIN - extra_pitch_jitter
	var pitch_max := GameAudio.PITCH_MAX + extra_pitch_jitter
	_voice_player.pitch_scale = randf_range(pitch_min, pitch_max)
	_voice_player.volume_db = randf_range(
		-GameAudio.VOLUME_JITTER_DB * 0.75,
		GameAudio.VOLUME_JITTER_DB * 0.75
	)
	add_child(_voice_player)
	_voice_player.global_position = get_voice_world_position()
	_voice_player.finished.connect(_on_voice_finished)
	_voice_player.play()


func _play_scared_voice() -> void:
	_play_voice(GroypetteAudio.pick_scared_voice(), 0.08)


func _play_cute_voice() -> void:
	_play_voice(GroypetteAudio.pick_cute_voice())


func _stop_voice() -> void:
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.queue_free()
	_voice_player = null


func _on_voice_finished() -> void:
	_stop_voice()


func _finish_lasso_standup() -> void:
	if not _lasso_standup_active:
		return
	_lasso_standup_active = false
	_lasso_standup_model_sink = 0.0
	if _model != null:
		GroyperBodyUtils.apply_model_baseline(_model)
	if _ragdoll != null:
		_ragdoll.finish_animation_standup()


func _activate_defeat_ragdoll(hit_info: Dictionary) -> void:
	if _defeated and _ragdoll != null and _ragdoll.is_active():
		return

	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)

	_lasso_captured = false
	_lasso_player = null
	_lasso_ring = null
	_stop_social_talk_immediate()
	_end_weapon_stare(false)
	_stop_voice()

	_defeated = true
	_ai_state = AiState.DEFEATED
	velocity = Vector3.ZERO

	_bind_rig()
	if _ragdoll != null and _skeleton != null:
		_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
		if _model != null:
			_ragdoll.model_path = _ragdoll.get_path_to(_model)
		_ragdoll.bind_skeleton()

	if _ragdoll != null and not _ragdoll.is_active():
		_suspend_locomotion_animations()
		_ragdoll.activate(hit_info, _animation_player)

	_on_defeated()


func _on_defeated() -> void:
	pass


func _setup_lasso_ragdoll() -> void:
	if _skeleton == null:
		push_error("GroypetteCivilianNpc: missing skeleton for lasso ragdoll.")
		return

	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	if _model != null:
		_ragdoll.model_path = _ragdoll.get_path_to(_model)
	_ragdoll.bind_skeleton()


func _suspend_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = false
		if _animation_player.is_playing():
			_animation_player.pause()


func is_npc_shoveable() -> bool:
	return (
		not _defeated
		and not _lasso_captured
		and _ai_state not in [AiState.FLEEING, AiState.CHEERING, AiState.DEFEATED]
	)


func play_npc_shove_stumble_voice() -> void:
	_play_scared_voice()


func _capture_shove_resume_state() -> void:
	_shove_saved_ai_state = _ai_state


func _resume_after_shove() -> void:
	if _defeated:
		return
	_ai_state = _shove_saved_ai_state
	if _ai_state == AiState.IDLE:
		_state_timer = randf_range(idle_duration_min, idle_duration_max)


func _set_shove_step_locomotion(blend: float) -> void:
	_move_blend = blend
	_set_move_blend(blend)
	_set_walk_run_blend(0.0)


func _get_shove_step_blend() -> float:
	return _move_blend


func _get_shove_settle_target_blend() -> float:
	if _ai_state == AiState.WALKING:
		return MeshyCivilianNpcShove.SHOVE_STEP_WALK_BLEND
	return 0.0


func _set_shove_move_blend(value: float) -> void:
	_move_blend = value
