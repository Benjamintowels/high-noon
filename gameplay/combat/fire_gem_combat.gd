extends RefCounted

## Fire gem combat: ignite on hit while gem stamina is active. No speed mult.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const ElementalGemStamina := preload("res://gameplay/combat/elemental_gem_stamina.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const OnFireStatusScript := preload("res://gameplay/combat/on_fire_status.gd")

const ROOT_PROC_CHANCE := 1.0
const ROOT_PROC_COOLDOWN_MS := 80
const PROC_COOLDOWN_META := &"fire_gem_proc_msec"


static func try_proc_on_hit(shooter: Node, target: Node, weapon_id: int = -1) -> void:
	if shooter == null or target == null:
		return
	if not is_instance_valid(shooter) or not is_instance_valid(target):
		return
	if not shooter.is_in_group("overworld_player") and not shooter.is_in_group("player"):
		return

	var resolved_weapon := weapon_id
	if resolved_weapon < 0:
		var equipped: Variant = shooter.get("_equipped_weapon")
		if equipped != null:
			resolved_weapon = int(equipped)
	if resolved_weapon < 0:
		return
	if not PlayerInventory.weapon_has_gem(resolved_weapon, ElementalGems.FIRE):
		return
	if not ElementalGemStamina.is_effect_active(resolved_weapon):
		return

	var burn_target := _resolve_burn_target(target)
	if not _is_eligible_target(shooter, burn_target):
		return

	var now_ms := Time.get_ticks_msec()
	var last_ms := int(shooter.get_meta(PROC_COOLDOWN_META, -999999))
	if now_ms - last_ms < ROOT_PROC_COOLDOWN_MS:
		return
	if randf() > ROOT_PROC_CHANCE:
		shooter.set_meta(PROC_COOLDOWN_META, now_ms)
		return

	shooter.set_meta(PROC_COOLDOWN_META, now_ms)
	OnFireStatusScript.ignite(burn_target, shooter)


static func _resolve_burn_target(from_node: Node) -> Node:
	var node := from_node
	while node != null:
		if node.has_method("apply_fire_damage"):
			return node
		if node is CharacterBody3D and node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	node = from_node
	while node != null:
		if node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	return from_node


static func _is_eligible_target(shooter: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == shooter:
		return false
	if target.is_in_group("overworld_player") or target.is_in_group("player"):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if target.has_method("apply_fire_damage"):
		return true
	if not target.has_method("receive_bullet_hit"):
		return false
	if FactionAffinityScript.are_allies(shooter, target):
		return false
	return true
