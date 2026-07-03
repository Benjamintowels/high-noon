extends RefCounted
class_name ArcaneNovaFX

const BlastRadiusFXScript := preload("res://gameplay/fx/blast_radius_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")


static func detonate(
	attacker: Node,
	center: Vector3,
	radius: float,
	direction: Vector3,
	damage: int,
	knockback_speed: float,
	knockback_up: float,
	stun_duration: float
) -> void:
	var fx_parent := ImpactFXScript.parent_for(attacker)
	if fx_parent == null:
		return

	BlastRadiusFXScript.spawn(fx_parent, center, radius)
	SmokePuffFXScript.spawn_burst(fx_parent, center + Vector3(0.0, 0.35, 0.0), 8)
	MuzzleFlashFXScript.spawn(
		fx_parent,
		center + Vector3(0.0, 0.5, 0.0),
		&"symmetrical_large",
		0.026
	)
	if attacker is Node3D:
		var flat_dir := direction
		flat_dir.y = 0.0
		if flat_dir.length_squared() < 0.0001:
			flat_dir = Vector3.FORWARD
		SwordCrescentFXScript.spawn_preview(attacker as Node3D, flat_dir.normalized(), radius * 0.85)

	var tree := attacker.get_tree()
	if tree == null:
		return

	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if not (node is Node3D):
				continue
			if not _is_valid_target(attacker, node):
				continue
			var point := _get_target_point(node as Node3D)
			var offset := point - center
			offset.y = 0.0
			if offset.length_squared() > radius * radius:
				continue
			_apply_hit(
				attacker,
				node,
				point,
				offset,
				damage,
				knockback_speed,
				knockback_up,
				stun_duration
			)


static func _apply_hit(
	attacker: Node,
	target: Node,
	hit_position: Vector3,
	offset: Vector3,
	damage: int,
	knockback_speed: float,
	knockback_up: float,
	stun_duration: float
) -> void:
	var direction := offset
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	else:
		direction = direction.normalized()

	var hit_info := {
		"position": hit_position,
		"direction": direction,
		"shooter": attacker,
		"damage": damage,
		"knockback_speed": knockback_speed,
		"knockback_up": knockback_up,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": stun_duration,
		"arcane_nova_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()
	if not target.has_method("receive_bullet_hit"):
		return

	target.receive_bullet_hit(hit_info)
	if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
		return
	if target.has_method("apply_melee_stun"):
		target.apply_melee_stun(stun_duration)
	CombatHitFlashScript.flash_damage(target)
	var fx_parent := ImpactFXScript.parent_for(attacker)
	DirectionalImpactFXScript.spawn(fx_parent, hit_position, direction, 0.022)
	GameAudioScript.play_punch(attacker, hit_position)


static func _is_valid_target(attacker: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == attacker:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if attacker.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(attacker, target):
			return false
	if not target.has_method("receive_bullet_hit"):
		return false
	return true


static func _get_target_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.0, 0.0))
	return target.global_position + Vector3(0.0, 1.0, 0.0)
