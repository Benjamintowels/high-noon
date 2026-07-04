extends RedoActor
class_name RedoNpc

const RedoAnimConfigScript := preload("res://characters/redo/redo_anim_config.gd")
const RedoAnimUtilsScript := preload("res://characters/redo/redo_anim_utils.gd")
const RedoMeleeStrikeScript := preload("res://characters/redo/redo_melee_strike.gd")
const RedoMageSpellScript := preload("res://characters/redo/redo_mage_spell.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const DuelHitTestScript := preload("res://gameplay/duel/duel_hit_test.gd")
const NpcCombatNavigationScript := preload("res://gameplay/navigation/npc_combat_navigation.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

enum AiState {
	PATROL_IDLE,
	PATROL_WALK,
	CHASE,
	COMBAT_DECIDING,
	BLOCKING,
	ATTACK_WINDUP,
	ATTACKING,
	ROLLING,
	RELOCATING,
	PARRY_STUNNED,
	SPELL_BURSTING,
}

enum AttackKind {
	MELEE,
	SPELL,
}

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const WALK_SPEED := 2.1
const RUN_SPEED := 4.8
const BLEND_SPEED := 8.0
const LOCOMOTION_STOP_SPEED := 0.08
const LOCOMOTION_RUN_SPEED := 3.2
const DETECT_RANGE := 14.0
const ATTACK_RANGE := RedoMeleeStrikeScript.RANGE
const ATTACK_STRIKE_FRACTION := RedoMeleeStrikeScript.STRIKE_FRACTION
const SPELL_MIN_RANGE := RedoMageSpellScript.SPELL_MIN_RANGE
const SPELL_MAX_RANGE := RedoMageSpellScript.SPELL_MAX_RANGE
const SPELL_CAST_CHANCE := 0.38
const ROLL_SPELL_BURST_CHANCE := 0.16
const SPELL_BURST_COUNT := 3
const SPELL_BURST_INTERVAL := 0.2
const DECISION_MIN := 1.5
const DECISION_MAX := 4.0
const MELEE_DECISION_MIN := 0.25
const MELEE_DECISION_MAX := 0.55
const MELEE_ATTACK_CHANCE := 0.40
const MELEE_BLOCK_CHANCE := 0.22
const BLOCK_DURATION_MIN := 1.2
const BLOCK_DURATION_MAX := 2.4
const CHASE_BLOCK_CHANCE := 0.12
const PARRY_FOLLOWUP_ATTACK_CHANCE := 0.60
const PARRY_FOLLOWUP_REBLOCK_CHANCE := 0.30
const PARRY_REBLOCK_HOLD_MIN := 1.0
const PARRY_REBLOCK_HOLD_MAX := 2.0
const PATROL_IDLE_MIN := 2.0
const PATROL_IDLE_MAX := 5.0
const PATROL_WALK_MIN := 2.0
const PATROL_WALK_MAX := 4.5
const ROAM_RADIUS := 5.5
const MAX_HEALTH := BulletHitDamageScript.DEFAULT_MAX_HEALTH
const BLOCK_FACING_DOT_MIN := 0.32
const ROLL_SPEED := 6.2
const RELOCATE_ARRIVE_DIST := 0.85
const AIM_THREAT_RANGE := 48.0
const GUN_AIM_ROLL_DELAY_MIN := 0.2
const GUN_AIM_ROLL_DELAY_MAX := 1.5
const GUN_AIM_ROLL_COOLDOWN := 2.5

@export var sight_range := DETECT_RANGE
@export var roam_radius := ROAM_RADIUS
@export var prefer_last_attack_target := false
@export_group("Sword Block Animations")
@export var parry_hold_meshy_clip: StringName = RedoAnimConfigScript.MESHY_SWORD_PARRY
@export var parry_clash_meshy_clip: StringName = RedoAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD
@export_group("Bullet Hitboxes")
@export var show_hitbox_debug_meshes := true
@export var show_hitbox_debug_in_game := false

@export_group("Animation Preview")
@export var editor_preview_animation := &"idle":
	set(value):
		editor_preview_animation = value
		if Engine.is_editor_hint():
			call_deferred("_play_editor_preview")

var _ai_state := AiState.PATROL_IDLE
var _state_timer := 0.0
var _decision_timer := 0.0
var _windup_timer := 0.0
var _combat_target: Node3D
var _last_attack_target: Node3D
var _blocking_approach := false
var _post_roll_block_approach := false
var _post_roll_spell_burst := false
var _spell_burst_remaining := 0
var _spell_burst_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _roam_center := Vector3.ZERO
var _health := MAX_HEALTH
var _defeated := false
var _blocking := false
var _attack_kind := AttackKind.MELEE
var _attack_elapsed := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_direction := Vector3.FORWARD
var _attack_cooldown := 0.0
var _roll_direction := Vector3.ZERO
var _roll_timer := 0.0
var _roll_duration := 0.0
var _relocate_target := Vector3.ZERO
var _combat_nav: NpcCombatNavigation
var _body_hit_marker: Node3D
var _body_hit_debug_mesh: MeshInstance3D
var _head_hit_marker: Node3D
var _head_hit_debug_mesh: MeshInstance3D
var _melee_hit_absorbed := false
var _block_blend_tween: Tween
var _ragdoll
var _gun_aim_roll_pending := false
var _gun_aim_roll_committed := false
var _gun_aim_roll_timer := 0.0
var _gun_aim_roll_threat: Node3D
var _gun_aim_roll_cooldown := 0.0


func _on_actor_ready() -> void:
	add_to_group("redo_npc")
	add_to_group("cave_enemy")
	add_to_group("duel_target")
	_bind_hitbox_nodes()
	_setup_animation_library()
	_setup_animation_tree()
	_setup_combat_navigation()
	_setup_combat_ragdoll()
	setup_npc_locomotion_audio()
	call_deferred("_finalize_spawn")


func _finalize_spawn() -> void:
	refresh_patrol_anchor()


func refresh_patrol_anchor() -> void:
	snap_to_floor()
	_roam_center = global_position
	_prime_idle_pose()
	_sync_hitbox_debug_visibility()
	_begin_patrol_idle()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _defeated:
		return

	tick_melee_stun(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_gun_aim_roll_cooldown = maxf(_gun_aim_roll_cooldown - delta, 0.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_update_combat_target()
	_update_player_gun_aim_threat(delta)
	_try_execute_committed_gun_aim_roll()
	match _ai_state:
		AiState.PATROL_IDLE:
			_process_patrol_idle(delta)
		AiState.PATROL_WALK:
			_process_patrol_walk(delta)
		AiState.CHASE:
			_process_chase(delta)
		AiState.COMBAT_DECIDING:
			_process_combat_deciding(delta)
		AiState.BLOCKING:
			_process_blocking(delta)
		AiState.ATTACK_WINDUP:
			_process_attack_windup(delta)
		AiState.ATTACKING:
			_process_attacking(delta)
		AiState.ROLLING:
			_process_rolling(delta)
		AiState.RELOCATING:
			_process_relocating(delta)
		AiState.PARRY_STUNNED:
			_process_parry_stunned(delta)
		AiState.SPELL_BURSTING:
			_process_spell_bursting(delta)

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if _ai_state not in [
		AiState.ATTACKING,
		AiState.BLOCKING,
		AiState.PARRY_STUNNED,
		AiState.ATTACK_WINDUP,
		AiState.SPELL_BURSTING,
	]:
		_update_locomotion_blend(delta, horizontal_speed)
	update_npc_locomotion_audio(
		delta,
		horizontal_speed,
		horizontal_speed > LOCOMOTION_STOP_SPEED,
		horizontal_speed >= LOCOMOTION_RUN_SPEED
	)


func _process(_delta: float) -> void:
	_sync_hitbox_debug_visibility()


func _sync_hitbox_debug_visibility() -> void:
	var show_debug := show_hitbox_debug_meshes and (
		Engine.is_editor_hint() or show_hitbox_debug_in_game
	)
	if _body_hit_debug_mesh != null:
		_body_hit_debug_mesh.visible = show_debug
	if _head_hit_debug_mesh != null:
		_head_hit_debug_mesh.visible = show_debug
	if show_debug:
		_sync_hitbox_debug_mesh()


func get_faction_id() -> StringName:
	return FactionIdsScript.REDO


func get_punch_facing_direction() -> Vector3:
	if _attack_direction.length_squared() > 0.0001:
		return _attack_direction
	return _get_flat_forward()


func is_defeated() -> bool:
	return _defeated


func is_blocking() -> bool:
	return _ai_state == AiState.BLOCKING


func _can_block_melee(hit_info: Dictionary) -> bool:
	return (
		_blocking
		and _ai_state == AiState.BLOCKING
		and bool(hit_info.get("melee", false))
		and _is_facing_attack(hit_info)
	)


func apply_melee_stun(duration: float) -> void:
	if _ai_state == AiState.PARRY_STUNNED:
		return
	_melee_stun_timer = maxf(_melee_stun_timer, duration)


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	_melee_hit_absorbed = false

	if _can_block_melee(hit_info):
		_melee_hit_absorbed = true
		_on_attack_blocked(hit_info)
		return

	_focus_attacker_from_hit(hit_info)

	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health
	CombatHitFlashScript.flash_damage(self)
	if result.knockback_applied:
		hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if result.killed:
		_die(hit_info)


func get_bullet_capsule() -> Dictionary:
	return GroyperBodyUtils.get_town_bullet_capsule(_skeleton, global_position)


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_town_head_hit_sphere(_skeleton, global_position)


func get_threat_aim_point() -> Vector3:
	return GroyperBodyUtils.get_threat_aim_point(_skeleton, global_position)


func _finalize_combat_nav_agent() -> void:
	if _combat_nav != null:
		_combat_nav.mark_agent_ready()


func _bind_hitbox_nodes() -> void:
	_body_hit_marker = get_node_or_null("BulletHitbox") as Node3D
	_body_hit_debug_mesh = get_node_or_null("BulletHitbox/BodyDebugMesh") as MeshInstance3D
	_head_hit_debug_mesh = get_node_or_null("BulletHitbox/HeadDebugMesh") as MeshInstance3D
	_head_hit_marker = _head_hit_debug_mesh


func _sync_hitbox_debug_mesh() -> void:
	GroyperBodyUtils.sync_bullet_hitbox_debug_meshes(
		_body_hit_marker,
		_body_hit_debug_mesh,
		_head_hit_marker,
		_head_hit_debug_mesh,
		_skeleton,
		global_position
	)


func _setup_animation_library() -> void:
	if _animation_player == null:
		push_error("RedoNpc: missing AnimationPlayer.")
		return
	var library := load(RedoAnimConfigScript.LIB_PATH) as AnimationLibrary
	if library == null:
		push_error("RedoNpc: failed to load animation library.")
		return
	if _animation_player.has_animation_library(RedoAnimConfigScript.LIBRARY):
		_animation_player.remove_animation_library(RedoAnimConfigScript.LIBRARY)
	_animation_player.add_animation_library(RedoAnimConfigScript.LIBRARY, library)
	_apply_block_clip_overrides()


func _apply_block_clip_overrides() -> void:
	if (
		parry_hold_meshy_clip == RedoAnimConfigScript.MESHY_SWORD_PARRY
		and parry_clash_meshy_clip == RedoAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD
	):
		return

	var library := _animation_player.get_animation_library(RedoAnimConfigScript.LIBRARY)
	if library == null:
		return

	var hold_pose := RedoAnimUtilsScript.bake_parry_pose(parry_hold_meshy_clip)
	if hold_pose != null:
		library.add_animation(RedoAnimConfigScript.CLIP_PARRY_POSE, hold_pose)

	var clash := RedoAnimUtilsScript.load_merged_clip(
		parry_clash_meshy_clip,
		Animation.LOOP_NONE
	)
	if clash != null:
		clash.resource_name = "parry_backward"
		library.add_animation(RedoAnimConfigScript.CLIP_PARRY_BACKWARD, clash)


func _setup_animation_tree() -> void:
	if _animation_tree == null or _animation_player == null:
		return

	var idle_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_IDLE)
	var walk_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_WALK)
	var run_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_RUN)
	var hammer_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_HEAVY_HAMMER)
	var mage_spell_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_MAGE_SPELL)
	var parry_pose_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_PARRY_POSE)
	var parry_backward_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_PARRY_BACKWARD)
	var roll_path := RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_ROLL_DODGE)

	for clip_path: StringName in [
		idle_path, walk_path, run_path, hammer_path, mage_spell_path,
		parry_pose_path, parry_backward_path, roll_path
	]:
		if not _animation_player.has_animation(clip_path):
			push_error("RedoNpc: missing clip %s" % clip_path)
			return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var locomotion_blend := AnimationNodeBlendSpace1D.new()
	locomotion_blend.add_blend_point(idle_node, 0.0)
	locomotion_blend.add_blend_point(walk_node, 0.5)
	locomotion_blend.add_blend_point(run_node, 1.0)
	locomotion_blend.min_space = 0.0
	locomotion_blend.max_space = 1.0

	var parry_pose_node := AnimationNodeAnimation.new()
	parry_pose_node.animation = parry_pose_path
	var block_blend := AnimationNodeBlend2.new()
	RedoAnimUtilsScript.configure_block_pose_blend(block_blend)

	var hammer_node := AnimationNodeAnimation.new()
	hammer_node.animation = hammer_path
	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	var mage_spell_node := AnimationNodeAnimation.new()
	mage_spell_node.animation = mage_spell_path
	var spell_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		spell_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	var parry_backward_node := AnimationNodeAnimation.new()
	parry_backward_node.animation = parry_backward_path
	var parry_stun_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		parry_stun_shot,
		CombatAnimTransitionsScript.PARRY_CLASH_FADEIN,
		CombatAnimTransitionsScript.PARRY_CLASH_FADEOUT,
		true
	)

	var roll_node := AnimationNodeAnimation.new()
	roll_node.animation = roll_path
	var roll_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		roll_shot,
		CombatAnimTransitionsScript.ROLL_FADEIN,
		CombatAnimTransitionsScript.ROLL_FADEOUT
	)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(RedoAnimConfigScript.LOCOMOTION_BLEND, locomotion_blend)
	blend_tree.add_node(RedoAnimConfigScript.BLOCK_BLEND, block_blend)
	blend_tree.add_node(&"ParryPoseAnim", parry_pose_node)
	blend_tree.add_node(&"HeavyHammerAnim", hammer_node)
	blend_tree.add_node(RedoAnimConfigScript.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(&"MageSpellAnim", mage_spell_node)
	blend_tree.add_node(RedoAnimConfigScript.SPELL_ONE_SHOT, spell_shot)
	blend_tree.add_node(&"ParryBackwardAnim", parry_backward_node)
	blend_tree.add_node(RedoAnimConfigScript.PARRY_STUN_ONE_SHOT, parry_stun_shot)
	blend_tree.add_node(&"RollAnim", roll_node)
	blend_tree.add_node(RedoAnimConfigScript.ROLL_ONE_SHOT, roll_shot)

	blend_tree.connect_node(&"output", 0, RedoAnimConfigScript.ROLL_ONE_SHOT)
	blend_tree.connect_node(RedoAnimConfigScript.ROLL_ONE_SHOT, 0, RedoAnimConfigScript.PARRY_STUN_ONE_SHOT)
	blend_tree.connect_node(RedoAnimConfigScript.ROLL_ONE_SHOT, 1, &"RollAnim")
	blend_tree.connect_node(RedoAnimConfigScript.PARRY_STUN_ONE_SHOT, 0, RedoAnimConfigScript.SPELL_ONE_SHOT)
	blend_tree.connect_node(RedoAnimConfigScript.PARRY_STUN_ONE_SHOT, 1, &"ParryBackwardAnim")
	blend_tree.connect_node(RedoAnimConfigScript.SPELL_ONE_SHOT, 0, RedoAnimConfigScript.ATTACK_ONE_SHOT)
	blend_tree.connect_node(RedoAnimConfigScript.SPELL_ONE_SHOT, 1, &"MageSpellAnim")
	blend_tree.connect_node(RedoAnimConfigScript.ATTACK_ONE_SHOT, 0, RedoAnimConfigScript.BLOCK_BLEND)
	blend_tree.connect_node(RedoAnimConfigScript.ATTACK_ONE_SHOT, 1, &"HeavyHammerAnim")
	blend_tree.connect_node(RedoAnimConfigScript.BLOCK_BLEND, 0, RedoAnimConfigScript.LOCOMOTION_BLEND)
	blend_tree.connect_node(RedoAnimConfigScript.BLOCK_BLEND, 1, &"ParryPoseAnim")

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	_animation_tree.set("parameters/BlockBlend/blend_amount", 0.0)


func _setup_combat_navigation() -> void:
	_combat_nav = NpcCombatNavigationScript.new()
	_combat_nav.setup(self)


func _prime_idle_pose() -> void:
	if _animation_player == null:
		return
	var idle_path := String(RedoAnimUtilsScript.clip_path(RedoAnimConfigScript.CLIP_IDLE))
	if not _animation_player.has_animation(idle_path):
		return
	if _animation_tree != null:
		_animation_tree.active = true
	_set_locomotion_blend(0.0)


func _play_editor_preview() -> void:
	if not Engine.is_editor_hint() or _animation_player == null:
		return
	var clip := String(editor_preview_animation)
	if not _animation_player.has_animation("%s/%s" % [RedoAnimConfigScript.LIBRARY, clip]):
		return
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.active = false
	_animation_player.play("%s/%s" % [RedoAnimConfigScript.LIBRARY, clip])


func _update_combat_target() -> void:
	if _combat_target != null and is_instance_valid(_combat_target):
		if not _is_valid_combat_target(_combat_target):
			_combat_target = null
	else:
		_combat_target = null

	if _combat_target != null:
		var nearest := _find_nearest_hostile()
		if (
			nearest != null
			and nearest != _combat_target
			and _should_switch_to_closer_target(nearest)
		):
			_combat_target = nearest
		return

	if prefer_last_attack_target and _last_attack_target != null:
		if _is_valid_combat_target(_last_attack_target):
			_combat_target = _last_attack_target
			return

	_combat_target = _find_nearest_hostile()


func _process_patrol_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _combat_target != null:
		_begin_chase()
		return
	_state_timer -= delta
	if _state_timer <= 0.0:
		_begin_patrol_walk()


func _process_patrol_walk(delta: float) -> void:
	if _combat_target != null:
		_begin_chase()
		return
	_move_in_direction(_walk_direction, WALK_SPEED, delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_begin_patrol_idle()


func _process_chase(delta: float) -> void:
	if _combat_target == null:
		_begin_patrol_idle()
		return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= ATTACK_RANGE:
		if randf() < CHASE_BLOCK_CHANCE:
			_begin_blocking(true)
		else:
			_begin_combat_deciding()
		return
	if distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE:
		_begin_combat_deciding()
		return

	_move_toward(_combat_target.global_position, RUN_SPEED, delta)
	if _combat_nav != null and _combat_nav.is_available():
		_combat_nav.set_target_if_needed(_combat_target.global_position)
		var nav_dir: Vector3 = _combat_nav.get_move_direction(delta)
		if nav_dir.length_squared() > 0.0001:
			_move_in_direction(nav_dir, RUN_SPEED, delta)


func _process_combat_deciding(delta: float) -> void:
	_stop_horizontal_velocity()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return

	if _combat_target == null:
		_begin_patrol_idle()
		return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var in_melee := distance <= ATTACK_RANGE + 0.35
	var in_spell_range := distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE
	if not in_melee and not in_spell_range:
		_begin_chase()
		return

	if in_spell_range and not in_melee:
		var far_roll := randf()
		if _attack_cooldown <= 0.0:
			if far_roll < ROLL_SPELL_BURST_CHANCE:
				_begin_roll_spell_burst()
				return
			if far_roll < ROLL_SPELL_BURST_CHANCE + SPELL_CAST_CHANCE:
				_begin_spell_windup()
				return
		if far_roll < 0.62:
			_begin_chase()
		else:
			_pick_random_combat_action()
		return

	var roll := randf()
	if _attack_cooldown <= 0.0 and roll < ROLL_SPELL_BURST_CHANCE:
		_begin_roll_spell_burst()
		return
	if _attack_cooldown <= 0.0 and roll < ROLL_SPELL_BURST_CHANCE + MELEE_ATTACK_CHANCE:
		_begin_attack_windup()
	elif roll < ROLL_SPELL_BURST_CHANCE + MELEE_ATTACK_CHANCE + MELEE_BLOCK_CHANCE:
		_begin_blocking()
	else:
		_pick_random_combat_action()


func _process_blocking(delta: float) -> void:
	_blocking = true
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		if _blocking_approach:
			var to_target := _combat_target.global_position - global_position
			to_target.y = 0.0
			if to_target.length() > ATTACK_RANGE * 0.85:
				_move_in_direction(to_target.normalized(), WALK_SPEED, delta)
			else:
				_stop_horizontal_velocity()
		else:
			_stop_horizontal_velocity()
	else:
		_stop_horizontal_velocity()

	_state_timer -= delta
	if _state_timer <= 0.0:
		_end_blocking()
		_begin_combat_deciding()


func _process_attack_windup(delta: float) -> void:
	_stop_horizontal_velocity()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _get_attack_direction()
	else:
		_attack_direction = _get_attack_direction()

	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_begin_attacking()


func _process_attacking(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	_stop_horizontal_velocity()

	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _get_attack_direction()

	var strike_fraction := _get_attack_strike_fraction()
	var strike_time := _get_attack_length() * strike_fraction
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		if _combat_target != null and is_instance_valid(_combat_target):
			_last_attack_target = _combat_target
		var strike_dir := _get_attack_direction()
		if _attack_kind == AttackKind.SPELL:
			RedoMageSpellScript.launch_wave(self, strike_dir, _combat_target)
		else:
			RedoMeleeStrikeScript.play_strike_presentation(self, strike_dir, _combat_target)
			RedoMeleeStrikeScript.apply_strike(self, strike_dir, _combat_target)

	if _attack_timer <= 0.0:
		_end_attacking()


func _process_rolling(delta: float) -> void:
	_roll_timer -= delta
	_move_in_direction(_roll_direction, ROLL_SPEED, delta)
	if _roll_timer <= 0.0:
		_end_rolling()


func _process_spell_bursting(delta: float) -> void:
	_stop_horizontal_velocity()
	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, delta)
		_attack_direction = RedoMageSpellScript.get_cast_direction(self, _combat_target)

	_spell_burst_timer -= delta
	if _spell_burst_timer > 0.0:
		return

	_fire_spell_burst_wave()
	_spell_burst_remaining -= 1
	if _spell_burst_remaining <= 0:
		_begin_combat_deciding()
	else:
		_spell_burst_timer = SPELL_BURST_INTERVAL


func _process_relocating(delta: float) -> void:
	var to_target := _relocate_target - global_position
	to_target.y = 0.0
	if to_target.length() <= RELOCATE_ARRIVE_DIST:
		_begin_combat_deciding()
		return
	_move_in_direction(to_target.normalized(), RUN_SPEED, delta)


func _process_parry_stunned(delta: float) -> void:
	_state_timer -= delta
	if _state_timer > 0.0:
		return

	_melee_stun_timer = 0.0
	_abort_parry_stun_anim()
	_finish_parry_followup()


func _begin_patrol_idle() -> void:
	_ai_state = AiState.PATROL_IDLE
	_state_timer = randf_range(PATROL_IDLE_MIN, PATROL_IDLE_MAX)
	_walk_direction = Vector3.ZERO
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false


func _begin_patrol_walk() -> void:
	_ai_state = AiState.PATROL_WALK
	_state_timer = randf_range(PATROL_WALK_MIN, PATROL_WALK_MAX)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	_clamp_walk_to_roam()


func _begin_chase() -> void:
	_ai_state = AiState.CHASE
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false


func _begin_combat_deciding() -> void:
	_ai_state = AiState.COMBAT_DECIDING
	if _combat_target != null:
		var to_target := _combat_target.global_position - global_position
		to_target.y = 0.0
		var distance := to_target.length()
		var in_melee := distance <= ATTACK_RANGE + 0.35
		var in_spell_range := distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE
		if in_melee:
			_decision_timer = randf_range(MELEE_DECISION_MIN, MELEE_DECISION_MAX)
		elif in_spell_range:
			_decision_timer = randf_range(0.35, 0.9)
		else:
			_decision_timer = randf_range(DECISION_MIN, DECISION_MAX)
	else:
		_decision_timer = randf_range(DECISION_MIN, DECISION_MAX)
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false


func _begin_blocking(approach := false, from_parry := false, hold_duration := -1.0) -> void:
	_ai_state = AiState.BLOCKING
	if hold_duration > 0.0:
		_state_timer = hold_duration
	elif from_parry:
		_state_timer = randf_range(BLOCK_DURATION_MIN, BLOCK_DURATION_MAX)
	elif approach:
		_state_timer = randf_range(BLOCK_DURATION_MIN, BLOCK_DURATION_MAX)
	else:
		_state_timer = randf_range(BLOCK_DURATION_MIN, BLOCK_DURATION_MAX)
	_blocking = true
	_blocking_approach = approach
	_locomotion_blend = 0.0
	_set_locomotion_blend(0.0)
	_tween_block_blend(1.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_IN)


func _end_blocking() -> void:
	_blocking = false
	_blocking_approach = false
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)


func _begin_attack_windup() -> void:
	_attack_kind = AttackKind.MELEE
	_ai_state = AiState.ATTACK_WINDUP
	var in_melee := false
	if _combat_target != null:
		var to_target := _combat_target.global_position - global_position
		to_target.y = 0.0
		in_melee = to_target.length() <= ATTACK_RANGE + 0.35
	if in_melee:
		_windup_timer = randf_range(0.45, 1.1)
	else:
		_windup_timer = randf_range(RedoMeleeStrikeScript.WINDUP_MIN, RedoMeleeStrikeScript.WINDUP_MAX)
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false


func _begin_spell_windup() -> void:
	_attack_kind = AttackKind.SPELL
	_ai_state = AiState.ATTACK_WINDUP
	_windup_timer = randf_range(RedoMageSpellScript.WINDUP_MIN, RedoMageSpellScript.WINDUP_MAX)
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false


func _begin_attacking() -> void:
	_ai_state = AiState.ATTACKING
	_attack_elapsed = 0.0
	_attack_timer = _get_attack_length()
	_attack_struck = false
	if _attack_kind == AttackKind.SPELL:
		_attack_cooldown = RedoMageSpellScript.COOLDOWN
	else:
		_attack_cooldown = RedoMeleeStrikeScript.COOLDOWN
	if _animation_tree != null:
		var one_shot_name := (
			RedoAnimConfigScript.SPELL_ONE_SHOT
			if _attack_kind == AttackKind.SPELL
			else RedoAnimConfigScript.ATTACK_ONE_SHOT
		)
		_animation_tree.set(
			"parameters/%s/request" % one_shot_name,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _end_attacking() -> void:
	_attack_struck = false
	_begin_post_attack_disengage()


func _begin_post_attack_disengage() -> void:
	if _combat_target == null:
		_begin_patrol_idle()
		return

	if randf() < 0.4:
		var refreshed := _find_nearest_hostile()
		if refreshed != null:
			_combat_target = refreshed

	if randf() < 0.5:
		var away := global_position - _combat_target.global_position
		away.y = 0.0
		if away.length_squared() < 0.0001:
			away = -_get_flat_forward()
		_begin_roll(away.normalized())
	else:
		_begin_relocate()


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("overworld_player"):
		if node is Node3D and _is_valid_hostile(node):
			return node as Node3D
	return null


func _is_player_pointing_gun_at_me(player: Node3D) -> bool:
	if player == null or not _is_valid_hostile(player):
		return false
	var weapon_rig := player.get_node_or_null("WeaponRig")
	if weapon_rig == null or not weapon_rig.has_method("is_aiming") or not weapon_rig.is_aiming():
		return false
	if weapon_rig.has_method("get_equipped_weapon_id"):
		var weapon_id = weapon_rig.get_equipped_weapon_id()
		if (
			GroyperWeaponsScript.is_bow(weapon_id)
			or GroyperWeaponsScript.is_lasso(weapon_id)
		):
			return false
	if player.has_method("is_weapon_aimed_at"):
		return player.is_weapon_aimed_at(self, AIM_THREAT_RANGE)
	return false


func _update_player_gun_aim_threat(delta: float) -> void:
	if _gun_aim_roll_committed:
		return

	var player := _find_player()
	var aimed := player != null and _is_player_pointing_gun_at_me(player)
	if aimed:
		_focus_hostile(player)
		if _gun_aim_roll_cooldown > 0.0:
			return
		if not _gun_aim_roll_pending:
			_gun_aim_roll_pending = true
			_gun_aim_roll_timer = randf_range(GUN_AIM_ROLL_DELAY_MIN, GUN_AIM_ROLL_DELAY_MAX)
			_gun_aim_roll_threat = player
			return

		_gun_aim_roll_timer -= delta
		if _gun_aim_roll_timer <= 0.0:
			_gun_aim_roll_pending = false
			_gun_aim_roll_committed = true
		return

	if _gun_aim_roll_pending:
		_clear_gun_aim_roll_pending()


func _clear_gun_aim_roll_pending() -> void:
	_gun_aim_roll_pending = false
	_gun_aim_roll_timer = 0.0
	if not _gun_aim_roll_committed:
		_gun_aim_roll_threat = null


func _clear_gun_aim_roll_response() -> void:
	_clear_gun_aim_roll_pending()
	_gun_aim_roll_committed = false
	_gun_aim_roll_threat = null


func _can_perform_gun_aim_roll() -> bool:
	if _defeated or _gun_aim_roll_cooldown > 0.0:
		return false
	if _ai_state in [
		AiState.ROLLING,
		AiState.ATTACK_WINDUP,
		AiState.ATTACKING,
		AiState.PARRY_STUNNED,
		AiState.SPELL_BURSTING,
	]:
		return false
	return true


func _try_execute_committed_gun_aim_roll() -> void:
	if not _gun_aim_roll_committed or not _can_perform_gun_aim_roll():
		return
	if _gun_aim_roll_threat == null or not is_instance_valid(_gun_aim_roll_threat):
		_clear_gun_aim_roll_response()
		return

	_gun_aim_roll_committed = false
	_gun_aim_roll_cooldown = GUN_AIM_ROLL_COOLDOWN
	if _blocking:
		_end_blocking()
	_begin_roll(_get_random_roll_direction())
	_gun_aim_roll_threat = null


func _begin_roll(direction: Vector3) -> void:
	_ai_state = AiState.ROLLING
	_roll_direction = direction
	if _roll_direction.length_squared() < 0.0001:
		_roll_direction = _get_flat_forward()
	_roll_duration = _get_clip_length(RedoAnimConfigScript.CLIP_ROLL_DODGE, 0.7)
	_roll_timer = _roll_duration
	if _animation_tree != null:
		_animation_tree.set(
			"parameters/%s/request" % RedoAnimConfigScript.ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _end_rolling() -> void:
	if _post_roll_block_approach:
		_post_roll_block_approach = false
		_begin_blocking(true)
		return
	if _post_roll_spell_burst:
		_post_roll_spell_burst = false
		_begin_spell_burst()
		return
	_begin_combat_deciding()


func _begin_roll_spell_burst() -> void:
	if _combat_target == null:
		return
	var away := global_position - _combat_target.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = _get_strafe_roll_direction()
	if _blocking:
		_end_blocking()
	_post_roll_spell_burst = true
	_begin_roll(away.normalized())


func _begin_spell_burst() -> void:
	_ai_state = AiState.SPELL_BURSTING
	_spell_burst_remaining = SPELL_BURST_COUNT
	_spell_burst_timer = 0.0
	_attack_cooldown = RedoMageSpellScript.COOLDOWN
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)
	_blocking = false
	if _animation_tree != null:
		_animation_tree.set(
			"parameters/%s/request" % RedoAnimConfigScript.SPELL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _fire_spell_burst_wave() -> void:
	var strike_dir := RedoMageSpellScript.get_cast_direction(self, _combat_target)
	RedoMageSpellScript.launch_wave(self, strike_dir, _combat_target)


func _begin_relocate() -> void:
	_ai_state = AiState.RELOCATING
	_relocate_target = _pick_relocate_point()
	if _relocate_target.distance_squared_to(global_position) < 0.25:
		_begin_combat_deciding()


func _pick_random_combat_action() -> void:
	if _combat_target == null:
		_begin_patrol_idle()
		return

	var roll := randf()
	if roll < 0.28:
		_begin_relocate()
	elif roll < 0.5:
		var away := global_position - _combat_target.global_position
		away.y = 0.0
		if away.length_squared() < 0.0001:
			away = -_get_flat_forward()
		_begin_roll(away.normalized())
	elif roll < 0.45 and _attack_cooldown <= 0.0:
		_begin_attack_windup()
	elif roll < 0.82:
		_begin_blocking()
	else:
		_begin_combat_deciding()


func _on_attack_blocked(hit_info: Dictionary) -> void:
	_focus_attacker_from_hit(hit_info)
	var attacker: Node = hit_info.get("shooter")
	MeleeClashScript.resolve(self, attacker, hit_info)


func on_melee_clash_blocked(
	_attacker: Node,
	_hit_info: Dictionary,
	stun_duration: float
) -> void:
	hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	_enter_parry_clash_stun(stun_duration)


func on_melee_clash_attacker(
	_defender: Node,
	_hit_info: Dictionary,
	stun_duration: float
) -> void:
	hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if _ai_state in [AiState.ATTACKING, AiState.ATTACK_WINDUP]:
		_attack_struck = true
		_attack_timer = 0.0
		_abort_attack_one_shot()
	_enter_parry_clash_stun(stun_duration)


func _abort_attack_one_shot() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	for one_shot_name: StringName in [
		RedoAnimConfigScript.ATTACK_ONE_SHOT,
		RedoAnimConfigScript.SPELL_ONE_SHOT,
	]:
		_animation_tree.set(
			"parameters/%s/request" % one_shot_name,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)


func _enter_parry_clash_stun(stun_duration: float) -> void:
	_ai_state = AiState.PARRY_STUNNED
	_state_timer = stun_duration
	_melee_stun_timer = stun_duration
	_blocking = false
	_blocking_approach = false
	_locomotion_blend = 0.0

	if _animation_tree != null:
		_set_locomotion_blend(0.0)
		_tween_block_blend(0.0, CombatAnimTransitionsScript.CLASH_BLOCK_BLEND_OUT)
		_animation_tree.set(
			"parameters/%s/request" % RedoAnimConfigScript.PARRY_STUN_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _finish_parry_followup() -> void:
	if _combat_target == null:
		_begin_patrol_idle()
		return

	var roll := randf()
	if roll < PARRY_FOLLOWUP_ATTACK_CHANCE:
		var to_target := _combat_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > ATTACK_RANGE + 0.35:
			_begin_chase()
		elif _attack_cooldown <= 0.0:
			_begin_attack_windup()
		else:
			_begin_chase()
		return

	if roll < PARRY_FOLLOWUP_ATTACK_CHANCE + PARRY_FOLLOWUP_REBLOCK_CHANCE:
		_begin_blocking(
			false,
			true,
			randf_range(PARRY_REBLOCK_HOLD_MIN, PARRY_REBLOCK_HOLD_MAX)
		)
		return

	_begin_post_block_reposition()


func _begin_post_block_reposition() -> void:
	if _combat_target == null:
		_begin_combat_deciding()
		return

	if randf() < 0.5:
		var refreshed := _find_nearest_hostile()
		if refreshed != null:
			_combat_target = refreshed

	if randf() < 0.5:
		var away := global_position - _combat_target.global_position
		away.y = 0.0
		if away.length_squared() < 0.0001:
			away = _get_strafe_roll_direction()
		_begin_roll(away.normalized())
	else:
		_begin_relocate()


func _abort_parry_stun_anim() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/request" % RedoAnimConfigScript.PARRY_STUN_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	)


func _get_flat_attack_direction(hit_info: Dictionary) -> Vector3:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = _get_flat_forward()
	return direction.normalized()


func _is_facing_attack(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return _get_flat_forward().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN

	var attack_dir := _get_flat_attack_direction(hit_info)
	return _get_flat_forward().dot(attack_dir) <= -BLOCK_FACING_DOT_MIN


func _get_strafe_roll_direction() -> Vector3:
	var side := _get_flat_forward().cross(Vector3.UP)
	if randf() < 0.5:
		side = -side
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	return side.normalized()


func _get_random_roll_direction() -> Vector3:
	var angle := randf() * TAU
	return Vector3(sin(angle), 0.0, cos(angle))


func _is_valid_combat_target(node: Node) -> bool:
	if not _is_valid_hostile(node):
		return false
	var offset := (node as Node3D).global_position - global_position
	offset.y = 0.0
	return offset.length_squared() <= sight_range * sight_range * 1.35


func _focus_hostile(target: Node3D) -> void:
	if target == null or not _is_valid_hostile(target):
		return
	_combat_target = target
	if _ai_state in [AiState.PATROL_IDLE, AiState.PATROL_WALK]:
		_begin_chase()


func _focus_attacker_from_hit(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		_focus_hostile(attacker as Node3D)


func _should_switch_to_closer_target(nearest: Node3D) -> bool:
	if _combat_target == null:
		return true
	var current_offset := _combat_target.global_position - global_position
	var nearest_offset := nearest.global_position - global_position
	current_offset.y = 0.0
	nearest_offset.y = 0.0
	var current_dist_sq := current_offset.length_squared()
	var nearest_dist_sq := nearest_offset.length_squared()
	if nearest_dist_sq < current_dist_sq * 0.64:
		return true
	if prefer_last_attack_target and nearest == _last_attack_target:
		return true
	return false


func _reset_combat_anim_overlays() -> void:
	_set_block_blend(0.0)
	if _animation_tree == null or not _animation_tree.active:
		return
	for one_shot_name: StringName in [
		RedoAnimConfigScript.PARRY_STUN_ONE_SHOT,
		RedoAnimConfigScript.ATTACK_ONE_SHOT,
		RedoAnimConfigScript.SPELL_ONE_SHOT,
		RedoAnimConfigScript.ROLL_ONE_SHOT,
	]:
		_animation_tree.set(
			"parameters/%s/request" % one_shot_name,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)


func _setup_combat_ragdoll() -> void:
	if _skeleton == null:
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


func _die(hit_info: Dictionary) -> void:
	if _defeated:
		return
	var hit_position: Vector3 = hit_info.get("position", global_position + Vector3(0.0, 1.0, 0.0))
	GameAudioScript.play_death_sound(self, hit_position)
	BloodSplatterFXScript.spawn_big_for_hit(self, hit_info)
	_defeated = true
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


func _find_nearest_hostile() -> Node3D:
	var best: Node3D = null
	var best_dist_sq := sight_range * sight_range
	for group_name: StringName in [&"overworld_player", &"crusader_npc"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not (node is Node3D):
				continue
			if not _is_valid_hostile(node):
				continue
			var offset := (node as Node3D).global_position - global_position
			offset.y = 0.0
			var dist_sq := offset.length_squared()
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = node
	return best


func _is_valid_hostile(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_defeated") and node.is_defeated():
		return false
	return FactionAffinityScript.are_hostile(self, node)


func _pick_relocate_point() -> Vector3:
	var center := global_position
	if _combat_target != null:
		center = _combat_target.global_position
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(3.5, 7.5)
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * distance
	return center + offset


func _get_attack_length() -> float:
	if _attack_kind == AttackKind.SPELL:
		return _get_clip_length(RedoAnimConfigScript.CLIP_MAGE_SPELL, 2.3)
	return _get_clip_length(RedoAnimConfigScript.CLIP_HEAVY_HAMMER, 0.95)


func _get_attack_strike_fraction() -> float:
	if _attack_kind == AttackKind.SPELL:
		return RedoMageSpellScript.CAST_FRACTION
	return ATTACK_STRIKE_FRACTION


func _get_attack_direction() -> Vector3:
	if _attack_kind == AttackKind.SPELL:
		return RedoMageSpellScript.get_cast_direction(self, _combat_target)
	return RedoMeleeStrikeScript.get_strike_direction(self, _combat_target)


func _get_clip_length(clip_name: StringName, fallback: float) -> float:
	if _animation_player == null:
		return fallback
	var clip_path := String(RedoAnimUtilsScript.clip_path(clip_name))
	if _animation_player.has_animation(clip_path):
		return _animation_player.get_animation(clip_path).length
	return fallback


func _update_locomotion_blend(delta: float, horizontal_speed: float) -> void:
	var target := 0.0
	if horizontal_speed > LOCOMOTION_STOP_SPEED:
		target = 1.0 if horizontal_speed >= LOCOMOTION_RUN_SPEED else 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_set_locomotion_blend(_locomotion_blend)


func _set_locomotion_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set("parameters/LocomotionBlend/blend_position", value)


func _set_block_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set("parameters/BlockBlend/blend_amount", clampf(value, 0.0, 1.0))


func _tween_block_blend(target: float, duration: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	if _block_blend_tween != null and _block_blend_tween.is_valid():
		_block_blend_tween.kill()
	if duration <= 0.0:
		_set_block_blend(target)
		return
	_block_blend_tween = CombatAnimTransitionsScript.tween_tree_float(
		self,
		_animation_tree,
		"BlockBlend/blend_amount",
		target,
		duration
	)


func _move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		_stop_horizontal_velocity()
		return
	var flat_dir := direction.normalized()
	velocity.x = flat_dir.x * speed
	velocity.z = flat_dir.z * speed
	_face_direction(flat_dir, delta)


func _move_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		_stop_horizontal_velocity()
		return
	_move_in_direction(to_target.normalized(), speed, delta)


func _stop_horizontal_velocity() -> void:
	if should_preserve_knockback_velocity():
		return
	velocity.x = 0.0
	velocity.z = 0.0


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	_face_direction(to_target.normalized(), delta)


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(direction)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _get_flat_forward() -> Vector3:
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _clamp_walk_to_roam() -> void:
	var next_pos := global_position + _walk_direction * WALK_SPEED * PATROL_WALK_MAX
	var offset := next_pos - _roam_center
	offset.y = 0.0
	if offset.length() > roam_radius:
		_walk_direction = (_roam_center - global_position).normalized()
		_walk_direction.y = 0.0
