extends RefCounted

## Ice gem combat: stackable chill → freeze while gem stamina is active.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const ElementalGemStamina := preload("res://gameplay/combat/elemental_gem_stamina.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")
const IceStatusScript := preload("res://gameplay/combat/ice_status.gd")
const IceBlockStatusScript := preload("res://gameplay/combat/ice_block_status.gd")

const ROOT_PROC_CHANCE := 1.0
const ROOT_PROC_COOLDOWN_MS := 80
const PROC_COOLDOWN_META := &"ice_gem_proc_msec"
const PENDING_DEATH_META := &"ice_pending_death"


static func try_proc_on_hit(shooter: Node, target: Node, weapon_id: int = -1) -> void:
	if shooter == null or target == null:
		return
	if not is_instance_valid(shooter) or not is_instance_valid(target):
		return
	if not shooter.is_in_group("overworld_player") and not shooter.is_in_group("player"):
		return

	var resolved_weapon := _resolve_weapon_id(shooter, weapon_id)
	if resolved_weapon < 0:
		return
	if not PlayerInventory.weapon_has_gem(resolved_weapon, ElementalGems.ICE):
		return
	if not ElementalGemStamina.is_effect_active(resolved_weapon):
		return

	var chill_target := _resolve_target(target)
	if not _is_eligible_target(shooter, chill_target):
		return
	# Already frozen — don't restack chill through the ice shell.
	if IceBlockStatusScript.is_frozen(chill_target):
		return

	var now_ms := Time.get_ticks_msec()
	var last_ms := int(shooter.get_meta(PROC_COOLDOWN_META, -999999))
	if now_ms - last_ms < ROOT_PROC_COOLDOWN_MS:
		return
	if randf() > ROOT_PROC_CHANCE:
		shooter.set_meta(PROC_COOLDOWN_META, now_ms)
		return

	shooter.set_meta(PROC_COOLDOWN_META, now_ms)
	IceStatusScript.apply_chill(chill_target, shooter)


## True when the next chill stack would freeze this target (2 stacks, ice gem live).
static func is_freeze_ready(host: Node, hit_info: Dictionary = {}) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if bool(hit_info.get("ice_shatter_hit", false)) or bool(hit_info.get("ice_thaw_kill", false)):
		return false
	if BossGunResilienceScript.uses_boss_hud_poise(host):
		return false
	if IceBlockStatusScript.is_frozen(host):
		return false
	var shooter: Node = hit_info.get("shooter") as Node
	if shooter == null or not is_instance_valid(shooter):
		return false
	if not shooter.is_in_group("overworld_player") and not shooter.is_in_group("player"):
		return false
	var weapon_id := _resolve_weapon_id(shooter, int(hit_info.get("weapon_id", -1)))
	if weapon_id < 0:
		return false
	if not PlayerInventory.weapon_has_gem(weapon_id, ElementalGems.ICE):
		return false
	if not ElementalGemStamina.is_effect_active(weapon_id):
		return false
	return IceStatusScript.get_chill_stacks(host) >= IceStatusScript.MAX_CHILL_STACKS


## Mark hit_info so a lethal freeze-shot skips loot/death side-effects in process_hit.
static func mark_skip_kill_effects_if_freeze_ready(host: Node, hit_info: Dictionary) -> void:
	if is_freeze_ready(host, hit_info):
		hit_info["skip_kill_effects"] = true


## After a lethal hit: keep the host alive so ice can freeze them; die on melt/shatter.
static func try_defer_lethal_kill(host: Node, hit_info: Dictionary) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if not is_freeze_ready(host, hit_info):
		return false
	host.set_meta(PENDING_DEATH_META, true)
	return true


static func has_pending_death(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return bool(host.get_meta(PENDING_DEATH_META, false))


static func force_pending_death(host: Node, source: Node = null) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not has_pending_death(host):
		return
	host.remove_meta(PENDING_DEATH_META)
	if not host.has_method("receive_bullet_hit"):
		return
	host.receive_bullet_hit({
		"position": (host as Node3D).global_position + Vector3(0.0, 1.0, 0.0) if host is Node3D else Vector3.ZERO,
		"direction": Vector3.UP,
		"shooter": source,
		"damage": 99,
		"lethal": true,
		"skip_knockback": true,
		"ice_thaw_kill": true,
		"melee": false,
		"force_knockback": false,
	})


static func _resolve_weapon_id(shooter: Node, weapon_id: int) -> int:
	var resolved_weapon := weapon_id
	if resolved_weapon < 0:
		var equipped: Variant = shooter.get("_equipped_weapon")
		if equipped != null:
			resolved_weapon = int(equipped)
	return resolved_weapon


static func _resolve_target(from_node: Node) -> Node:
	var node := from_node
	while node != null:
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
	if target.is_in_group(&"ice_block"):
		return false
	# Pending ice death still counts as alive for the freeze proc.
	if has_pending_death(target):
		pass
	elif target.has_method("is_defeated") and target.is_defeated():
		return false
	if not target.has_method("receive_bullet_hit"):
		return false
	if FactionAffinityScript.are_allies(shooter, target):
		return false
	return true
