extends "res://characters/meshy_biped_actor.gd"
class_name NpcMeleeCombatant

## Shared combat plumbing for the melee combat NPCs (Pavel, Redo, Undead,
## TC, Chief Getcha). Holds only code that was byte-identical across the
## per-character NPC scripts (or identical modulo a tuning constant now
## routed through a getter): health/defeat state, bullet-hit handling,
## hostile checks, hitbox debug meshes, ragdoll/nav setup, and shared
## facing/movement/blend helpers.
##
## IMPORTANT: per-character animation setup (libraries, clip paths,
## blend-tree wiring) stays in each character's script and its
## *_anim_config.gd. Clips are distinct per-rig resources even when the
## names match — never move animation-library setup or clip paths here.
##
## Subclass hooks:
## - _get_max_health() — every combatant overrides with its MAX_HEALTH.
## - _get_facing_speed(), _get_aim_threat_range() — tuning overrides.
## - _can_block_melee(), _focus_hostile(), _die() — behavior overrides.

const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const NpcCombatNavigationScript := preload("res://gameplay/navigation/npc_combat_navigation.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const NpcAttackRecoveryScript := preload("res://gameplay/combat/npc_attack_recovery.gd")

const BLOCK_FACING_DOT_MIN := 0.32

@export_group("Bullet Hitboxes")
@export var show_hitbox_debug_meshes := true
@export var show_hitbox_debug_in_game := false

@export_group("Combat Pacing")
## -1 uses NpcAttackRecovery.base_seconds (default 2s). Harder difficulty uses
## NpcAttackRecovery.difficulty_mult (smaller = shorter opening).
@export var post_attack_recovery_seconds := -1.0

var _health: int = _get_max_health()
var _defeated := false
var _blocking := false
var _blocking_approach := false
var _attack_direction := Vector3.FORWARD
var _melee_hit_absorbed := false
var _combat_nav: NpcCombatNavigation
var _body_hit_marker: Node3D
var _body_hit_debug_mesh: MeshInstance3D
var _head_hit_marker: Node3D
var _head_hit_debug_mesh: MeshInstance3D
var _block_blend_tween: Tween
var _ragdoll


func get_post_attack_recovery_seconds() -> float:
	return NpcAttackRecoveryScript.get_seconds(post_attack_recovery_seconds)


func _process(_delta: float) -> void:
	_sync_hitbox_debug_visibility()


## Max health for this combatant; subclasses return their MAX_HEALTH.
func _get_max_health() -> int:
	return BulletHitDamageScript.DEFAULT_MAX_HEALTH


## Model turn speed used by _face_direction (TC overrides the whole
## facing function instead and keeps its own constant).
func _get_facing_speed() -> float:
	return 10.0


## Range used by _is_player_pointing_gun_at_me.
func _get_aim_threat_range() -> float:
	return 48.0


func is_defeated() -> bool:
	return _defeated


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func get_punch_facing_direction() -> Vector3:
	if _attack_direction.length_squared() > 0.0001:
		return _attack_direction
	return _get_flat_forward()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	_melee_hit_absorbed = false

	if _can_block_melee(hit_info):
		_melee_hit_absorbed = true
		_on_attack_blocked(hit_info)
		return

	_focus_attacker_from_hit(hit_info)

	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, _get_max_health())
	_health = result.health
	CombatHitFlashScript.flash_damage(self)
	if result.knockback_applied:
		hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if result.killed:
		_die(hit_info)


## Whether an incoming melee hit is absorbed by an active block.
## Default: no blocking. Subclasses with a BLOCKING state override.
func _can_block_melee(_hit_info: Dictionary) -> bool:
	return false


func _on_attack_blocked(hit_info: Dictionary) -> void:
	_focus_attacker_from_hit(hit_info)
	var attacker: Node = hit_info.get("shooter")
	MeleeClashScript.resolve(self, attacker, hit_info)


## Death handling is per-character; every subclass overrides.
func _die(_hit_info: Dictionary) -> void:
	pass


func get_bullet_capsule() -> Dictionary:
	return GroyperBodyUtils.get_town_bullet_capsule(_skeleton, global_position)


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_town_head_hit_sphere(_skeleton, global_position)


func get_threat_aim_point() -> Vector3:
	return GroyperBodyUtils.get_threat_aim_point(_skeleton, global_position)


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("overworld_player"):
		if node is Node3D and _is_valid_hostile(node):
			return node as Node3D
	return null


func _is_valid_hostile(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_defeated") and node.is_defeated():
		return false
	return FactionAffinityScript.are_hostile(self, node)


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
		return player.is_weapon_aimed_at(self, _get_aim_threat_range())
	return false


## Retarget onto a hostile; per-character (FSM state entry differs).
func _focus_hostile(_target: Node3D) -> void:
	pass


func _focus_attacker_from_hit(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		_focus_hostile(attacker as Node3D)


func _end_blocking() -> void:
	_blocking = false
	_blocking_approach = false
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)


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


func _bind_hitbox_nodes() -> void:
	_body_hit_marker = get_node_or_null("BulletHitbox") as Node3D
	_body_hit_debug_mesh = get_node_or_null("BulletHitbox/BodyDebugMesh") as MeshInstance3D
	_head_hit_debug_mesh = get_node_or_null("BulletHitbox/HeadDebugMesh") as MeshInstance3D
	_head_hit_marker = _head_hit_debug_mesh


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


func _sync_hitbox_debug_mesh() -> void:
	GroyperBodyUtils.sync_bullet_hitbox_debug_meshes(
		_body_hit_marker,
		_body_hit_debug_mesh,
		_head_hit_marker,
		_head_hit_debug_mesh,
		_skeleton,
		global_position
	)


func _setup_combat_navigation() -> void:
	_combat_nav = NpcCombatNavigationScript.new()
	_combat_nav.setup(self)


func _finalize_combat_nav_agent() -> void:
	if _combat_nav != null:
		_combat_nav.mark_agent_ready()


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
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, _get_facing_speed() * delta)


func _get_flat_forward() -> Vector3:
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


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
