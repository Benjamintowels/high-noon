extends RefCounted
class_name BossGunResilience

## Shared gun-resilience helpers for boss fights: reactive block, BlockPoise
## absorb (refill only on break), gun softcap, vulnerability window, and
## melee execute floor. Boss AI / state machines stay on the boss scripts.

const BlockPoiseScript := preload("res://gameplay/combat/block_poise.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const DuelHitTestScript := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletScene := preload("res://gameplay/shooting/bullet.tscn")
const ShotgunPelletScene := preload("res://gameplay/shooting/shotgun_pellet.tscn")
const ArrowProjectileScene := preload("res://gameplay/shooting/arrow_projectile.tscn")

const REFLECT_SPAWN_NUDGE := 0.45
const DEFAULT_BULLET_SPEED := 185.0
const DEFAULT_ARROW_SPEED := 28.0
## Explosives: hard sponge chip, heavy open-hit punish.
const EXPLOSIVE_SHIELD_CHIP := 15.0
const EXPLOSIVE_OPEN_DAMAGE := 20
const EXPLOSIVE_KNOCKBACK_SPEED := 14.0
const EXPLOSIVE_KNOCKBACK_UP := 9.5
const EXPLOSIVE_PLAYER_DAMAGE_SCALE := 0.34

const DEFAULT_BLOCK_POISE := 20.0
const GUN_SOFTCAP := 0.5
const EXECUTE_FLOOR := 2
## Guard-break vulnerability: stumble + idle rock + blue/white/red flash.
const VULNERABILITY_DURATION := 3.0
const VULNERABLE_UNTIL_META := &"boss_vulnerable_until_msec"
## While blocking guns: every quarter of max poise drained → roll for rage.
const BLOCK_QUARTER_FRACTION := 0.25
const BLOCK_RAGE_CHANCE := 0.5
const BLOCK_RAGE_DURATION := 5.0
const BLOCK_RAGE_SPEED := 1.5
const BLOCK_RAGE_UNTIL_META := &"boss_block_rage_until_msec"
## Chance to interrupt a gun-block absorb into a counter attack.
const BLOCK_COUNTER_CHANCE := 0.45

enum Outcome {
	BLOCKED,
	BROKEN,
	APPLY,
}


static func is_execute_capable(hit_info: Dictionary) -> bool:
	if bool(hit_info.get("melee", false)):
		return true
	if bool(hit_info.get("punch_hit", false)):
		return true
	if bool(hit_info.get("sword_hit", false)):
		return true
	if bool(hit_info.get("explosion", false)):
		return true
	return false


static func is_explosive_hit(hit_info: Dictionary) -> bool:
	return bool(hit_info.get("explosion", false))


static func is_ranged_gun_hit(hit_info: Dictionary) -> bool:
	return not is_execute_capable(hit_info)


## Guns + explosives share the boss sponge shield (poise absorb / reflect).
static func is_shield_absorb_hit(hit_info: Dictionary) -> bool:
	return is_ranged_gun_hit(hit_info) or is_explosive_hit(hit_info)


static func mark_vulnerable(boss: Node, duration: float = VULNERABILITY_DURATION) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var until_msec := Time.get_ticks_msec() + int(maxf(duration, 0.0) * 1000.0)
	boss.set_meta(VULNERABLE_UNTIL_META, until_msec)


static func clear_vulnerable(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	if boss.has_meta(VULNERABLE_UNTIL_META):
		boss.remove_meta(VULNERABLE_UNTIL_META)


static func is_vulnerable(boss: Node) -> bool:
	if boss == null or not is_instance_valid(boss):
		return false
	if boss.has_method("is_boss_guard_broken") and bool(boss.call("is_boss_guard_broken")):
		return true
	if not boss.has_meta(VULNERABLE_UNTIL_META):
		return false
	return Time.get_ticks_msec() < int(boss.get_meta(VULNERABLE_UNTIL_META))


## Back-compat alias used by earlier wiring.
static func mark_guard_break_open(boss: Node) -> void:
	mark_vulnerable(boss, VULNERABILITY_DURATION)


static func is_guard_break_open(boss: Node) -> bool:
	return is_vulnerable(boss)


static func mark_block_rage(boss: Node, duration: float = BLOCK_RAGE_DURATION) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var until_msec := Time.get_ticks_msec() + int(maxf(duration, 0.0) * 1000.0)
	boss.set_meta(BLOCK_RAGE_UNTIL_META, until_msec)


static func clear_block_rage(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	if boss.has_meta(BLOCK_RAGE_UNTIL_META):
		boss.remove_meta(BLOCK_RAGE_UNTIL_META)


static func is_block_raging(boss: Node) -> bool:
	if boss == null or not is_instance_valid(boss):
		return false
	if boss.has_method("is_boss_block_raging") and bool(boss.call("is_boss_block_raging")):
		return true
	if not boss.has_meta(BLOCK_RAGE_UNTIL_META):
		return false
	return Time.get_ticks_msec() < int(boss.get_meta(BLOCK_RAGE_UNTIL_META))


static func crossed_block_quarter(before: float, after: float, poise_max: float) -> bool:
	if poise_max <= 0.0 or after <= 0.0001:
		return false
	var quarter := poise_max * BLOCK_QUARTER_FRACTION
	if quarter <= 0.0:
		return false
	var before_idx := int(ceil(before / quarter - 0.0001))
	var after_idx := int(ceil(after / quarter - 0.0001))
	return after_idx < before_idx


## Bounce guns back off a blocking / block-raging boss.
## Explosives detonate and sponge on poise instead of reflecting.
static func try_reflect_ranged(boss: Node, hit_info: Dictionary) -> void:
	if boss == null or not is_instance_valid(boss) or not (boss is Node3D):
		return
	if not is_ranged_gun_hit(hit_info):
		return
	if bool(hit_info.get("reflected_hit", false)) or bool(hit_info.get("boss_reflected", false)):
		return
	var boss_3d := boss as Node3D
	var contact: Vector3 = hit_info.get(
		"position",
		boss_3d.global_position + Vector3(0.0, 1.1, 0.0)
	)
	var incoming: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	if incoming.length_squared() < 0.0001:
		incoming = Vector3.FORWARD
	else:
		incoming = incoming.normalized()
	var normal := get_boss_entry_normal(boss_3d, contact, hit_info)
	var direction := get_boss_reflect_direction(boss_3d, hit_info)
	var fx_parent := ImpactFXScript.parent_for(boss)
	if fx_parent is Node3D:
		ImpactFXScript.spawn_metal_impact(fx_parent as Node3D, contact, normal, incoming)
	_spawn_reflected_gun_projectile(boss_3d, hit_info, contact, direction)


## Shared explosive hit payload for BlastDamage / DynamiteExplosion.
## `open_damage` is the non-player HP hit; players take ceil(open_damage * scale).
## Boss shield absorb still chips `EXPLOSIVE_SHIELD_CHIP` while blocking.
static func build_explosive_hit_info(
	target_point: Vector3,
	blast_dir: Vector3,
	shooter: Node,
	is_player: bool,
	open_damage: int = EXPLOSIVE_OPEN_DAMAGE,
	extra: Dictionary = {}
) -> Dictionary:
	var dir := blast_dir
	if dir.length_squared() < 0.0001:
		dir = Vector3.UP
	else:
		dir = dir.normalized()
	var base_damage := maxi(1, open_damage)
	var damage := base_damage
	if is_player:
		damage = maxi(1, int(ceil(float(base_damage) * EXPLOSIVE_PLAYER_DAMAGE_SCALE)))
	var hit_info := {
		"position": target_point,
		"normal": -dir,
		"direction": dir,
		"explosion": true,
		"damage": damage,
		"chip_damage": EXPLOSIVE_SHIELD_CHIP,
		"lethal": false,
		"knockback_speed": EXPLOSIVE_KNOCKBACK_SPEED,
		"knockback_up": EXPLOSIVE_KNOCKBACK_UP,
		"force_knockback": true,
		"melee_stun_duration": 1.1,
		"shooter": shooter,
		"open_damage": base_damage,
	}
	for key in extra:
		hit_info[key] = extra[key]
	return hit_info


static func get_boss_entry_normal(boss: Node3D, contact: Vector3, hit_info: Dictionary) -> Vector3:
	# Prefer head sphere when the impact lands in the head volume.
	if boss.has_method("get_head_hit_sphere"):
		var head: Dictionary = boss.call("get_head_hit_sphere")
		var head_center: Vector3 = head.get("center", Vector3.ZERO)
		var head_radius := float(head.get("radius", 0.0))
		if head_radius > 0.0 and contact.distance_to(head_center) <= head_radius + 0.12:
			var head_n := DuelHitTestScript.sphere_normal_at(contact, head_center)
			return _facing_out_normal(head_n, hit_info.get("direction", Vector3.FORWARD))

	if boss.has_method("get_bullet_capsule"):
		var capsule: Dictionary = BulletHitDamageScript.get_cached_bullet_capsule(boss)
		var capsule_n := DuelHitTestScript.capsule_normal_at(
			contact,
			capsule.get("center", boss.global_position),
			float(capsule.get("half_height", 0.75)),
			float(capsule.get("radius", 0.5)),
			capsule.get("axis", Vector3.UP)
		)
		return _facing_out_normal(capsule_n, hit_info.get("direction", Vector3.FORWARD))

	# Fallback: any physics normal on the hit, else reverse incoming.
	var hit_normal: Vector3 = hit_info.get("normal", Vector3.ZERO)
	if hit_normal.length_squared() > 0.0001:
		return _facing_out_normal(hit_normal.normalized(), hit_info.get("direction", Vector3.FORWARD))
	var incoming: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	if incoming.length_squared() > 0.0001:
		return -incoming.normalized()
	return Vector3.FORWARD


static func get_boss_reflect_direction(boss: Node3D, hit_info: Dictionary) -> Vector3:
	var incoming: Vector3 = hit_info.get("direction", Vector3.ZERO)
	if incoming.length_squared() < 0.0001:
		incoming = Vector3.FORWARD
	else:
		incoming = incoming.normalized()
	var contact: Vector3 = hit_info.get(
		"position",
		boss.global_position + Vector3(0.0, 1.1, 0.0)
	)
	var normal := get_boss_entry_normal(boss, contact, hit_info)
	var reflected := incoming.bounce(normal)
	if reflected.length_squared() < 0.0001:
		return -incoming
	return reflected.normalized()


static func _facing_out_normal(normal: Vector3, incoming: Vector3) -> Vector3:
	var n := normal
	if n.length_squared() < 0.0001:
		return Vector3.FORWARD
	n = n.normalized()
	var inc := incoming
	if inc.length_squared() > 0.0001 and inc.normalized().dot(n) > 0.0:
		n = -n
	return n


static func _spawn_reflected_gun_projectile(
	boss: Node3D,
	hit_info: Dictionary,
	contact: Vector3,
	direction: Vector3
) -> void:
	var tree := boss.get_tree()
	if tree == null:
		return
	var parent: Node = tree.current_scene
	if parent == null:
		parent = ImpactFXScript.parent_for(boss)
	if parent == null:
		return

	var kind: StringName = hit_info.get("projectile_kind", &"")
	if kind == &"":
		if bool(hit_info.get("pellet_hit", false)):
			kind = &"pellet"
		elif bool(hit_info.get("arrow_hit", false)):
			kind = &"arrow"
		else:
			kind = &"bullet"
	var origin := contact + direction * REFLECT_SPAWN_NUDGE
	var exclude: Array = [boss]
	var hitbox := boss.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)

	match kind:
		&"pellet":
			var pellet_node := ShotgunPelletScene.instantiate()
			if pellet_node == null or not (pellet_node is Node3D):
				return
			var pellet := pellet_node as Node3D
			parent.add_child(pellet)
			if not pellet.has_method("setup"):
				pellet.queue_free()
				return
			pellet.call(
				"setup",
				origin,
				direction,
				Vector3.ZERO,
				0.0,
				0.0,
				exclude,
				boss,
				int(hit_info.get("weapon_id", -1)),
				float(hit_info.get("pellet_max_range", -1.0)),
				float(hit_info.get("pellet_chip_damage", hit_info.get("chip_damage", -1.0)))
			)
			if pellet.has_method("mark_as_boss_reflected"):
				pellet.call("mark_as_boss_reflected")
		&"arrow":
			var arrow_node := ArrowProjectileScene.instantiate()
			if arrow_node == null or not (arrow_node is Node3D):
				return
			var arrow := arrow_node as Node3D
			parent.add_child(arrow)
			if not arrow.has_method("setup"):
				arrow.queue_free()
				return
			var arrow_speed := float(hit_info.get("projectile_speed", DEFAULT_ARROW_SPEED))
			if arrow_speed <= 0.0:
				arrow_speed = DEFAULT_ARROW_SPEED
			arrow.call("setup", origin, direction, arrow_speed, exclude, boss)
			if arrow.has_method("mark_as_boss_reflected"):
				arrow.call("mark_as_boss_reflected")
		_:
			var bullet_node := BulletScene.instantiate()
			if bullet_node == null or not (bullet_node is Node3D):
				return
			var bullet := bullet_node as Node3D
			parent.add_child(bullet)
			if not bullet.has_method("setup"):
				bullet.queue_free()
				return
			var bullet_speed := float(
				hit_info.get("projectile_speed", hit_info.get("speed", DEFAULT_BULLET_SPEED))
			)
			if bullet_speed <= 0.0:
				bullet_speed = DEFAULT_BULLET_SPEED
			bullet.call("setup", origin, direction, exclude, boss, bullet_speed)
			if bullet.has_method("mark_as_boss_reflected"):
				bullet.call("mark_as_boss_reflected")


## Call from boss receive_bullet_hit after invuln / phase gates.
## Returns { "outcome": Outcome, "hit_info": Dictionary, "chip_amount": float }.
static func handle_incoming(boss: Node, hit_info: Dictionary) -> Dictionary:
	var resolved := hit_info.duplicate(true)
	# Block-rage is full invuln — caller should early-out, but belt-and-suspenders.
	if is_block_raging(boss):
		try_reflect_ranged(boss, resolved)
		return {
			"outcome": Outcome.BLOCKED,
			"hit_info": resolved,
			"chip_amount": 0.0,
		}
	# No reactive re-block while vulnerable — that window is the punish opening.
	if (
		is_shield_absorb_hit(resolved)
		and not is_vulnerable(boss)
		and boss.has_method("try_reactive_boss_block")
	):
		boss.call("try_reactive_boss_block", resolved)

	if _boss_can_block(boss, resolved):
		return _absorb_blocked_hit(boss, resolved)

	return {
		"outcome": Outcome.APPLY,
		"hit_info": prepare_open_hit(boss, resolved),
		"chip_amount": 0.0,
	}


## Guns always softcap when they land on open HP (including vulnerability).
## Explosives keep their caller open damage (blast_damage). Melee unchanged.
static func prepare_open_hit(boss: Node, hit_info: Dictionary) -> Dictionary:
	var resolved := hit_info.duplicate(true)
	if is_explosive_hit(resolved):
		var open := int(resolved.get("open_damage", resolved.get("damage", EXPLOSIVE_OPEN_DAMAGE)))
		if open <= 0:
			open = EXPLOSIVE_OPEN_DAMAGE
		resolved["damage"] = open
		resolved["chip_damage"] = float(open)
		resolved["knockback_speed"] = EXPLOSIVE_KNOCKBACK_SPEED
		resolved["knockback_up"] = EXPLOSIVE_KNOCKBACK_UP
		resolved["force_knockback"] = true
		resolved["lethal"] = false
		return resolved
	if not is_ranged_gun_hit(resolved):
		return resolved

	var raw := _estimate_raw_damage(boss, resolved)
	var scaled := raw * GUN_SOFTCAP
	resolved.erase("damage")
	resolved["chip_damage"] = scaled
	return resolved


## After BulletHitDamage.process_hit, clamp gun damage so HP cannot drop below
## EXECUTE_FLOOR (melee / explosions bypass).
static func clamp_execute_floor(
	hit_info: Dictionary,
	previous_health: int,
	new_health: int
) -> Dictionary:
	if is_execute_capable(hit_info):
		return {
			"health": new_health,
			"killed": new_health <= 0,
			"floor_clamped": false,
		}
	if previous_health <= EXECUTE_FLOOR:
		return {
			"health": previous_health,
			"killed": false,
			"floor_clamped": true,
		}
	if new_health < EXECUTE_FLOOR:
		return {
			"health": EXECUTE_FLOOR,
			"killed": false,
			"floor_clamped": true,
		}
	return {
		"health": new_health,
		"killed": new_health <= 0,
		"floor_clamped": false,
	}


static func uses_boss_hud_poise(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	return actor.is_in_group("tc_boss") or actor.is_in_group("chief_getcha_boss")


static func _boss_can_block(boss: Node, hit_info: Dictionary) -> bool:
	if is_vulnerable(boss):
		return false
	if boss.has_method("_can_block_hit"):
		return bool(boss.call("_can_block_hit", hit_info))
	if boss.has_method("_can_block_melee"):
		return bool(boss.call("_can_block_melee", hit_info))
	return false


static func _absorb_blocked_hit(boss: Node, hit_info: Dictionary) -> Dictionary:
	var resolved := _ensure_block_chip_amount(boss, hit_info)
	var chip_amount := _block_chip_amount(resolved)
	if boss.has_method("_focus_attacker_from_hit"):
		boss.call("_focus_attacker_from_hit", resolved)

	var poise_before := BlockPoiseScript.get_current(boss)
	var result: BlockPoiseScript.Result = BlockPoiseScript.apply_hit(boss, resolved)
	if result == BlockPoiseScript.Result.BROKEN:
		# Remaining ≥1 poise still cancels ALL overflow HP from a >1 chip hit.
		resolved["block_overflow_cancelled"] = poise_before >= 1.0 and chip_amount > 1.0
		var attacker: Node = resolved.get("shooter")
		BlockPoiseScript.break_block(boss, attacker, resolved)
		return {
			"outcome": Outcome.BROKEN,
			"hit_info": resolved,
			"chip_amount": chip_amount,
			"overflow_cancelled": bool(resolved.get("block_overflow_cancelled", false)),
		}

	if boss.has_method("_play_block_react"):
		boss.call("_play_block_react")
	if is_explosive_hit(resolved):
		# Detonation is absorbed by the sponge — flash only, no reflect.
		CombatHitFlashScript.flash_block(boss)
	elif (
		bool(resolved.get("melee", false))
		or bool(resolved.get("punch_hit", false))
		or bool(resolved.get("sword_hit", false))
	):
		var attacker_melee: Node = resolved.get("shooter")
		MeleeClashScript.resolve(boss, attacker_melee, resolved)
	else:
		CombatHitFlashScript.flash_block(boss)
		# Guns bounce off the block — angle the shot or eat the return.
		try_reflect_ranged(boss, resolved)

	# Shield pressure: quarter-rage, then chance counter, then banked chip hooks.
	if is_shield_absorb_hit(resolved):
		var poise_after := BlockPoiseScript.get_current(boss)
		var poise_max := BlockPoiseScript.get_max(boss)
		if (
			crossed_block_quarter(poise_before, poise_after, poise_max)
			and randf() < BLOCK_RAGE_CHANCE
			and boss.has_method("try_enter_block_rage")
			and bool(boss.call("try_enter_block_rage"))
		):
			pass
		elif (
			randf() < BLOCK_COUNTER_CHANCE
			and boss.has_method("try_boss_block_counter")
			and bool(boss.call("try_boss_block_counter", resolved))
		):
			pass
		elif boss.has_method("on_boss_block_chip"):
			boss.call("on_boss_block_chip", resolved, chip_amount)
	elif boss.has_method("on_boss_block_chip"):
		boss.call("on_boss_block_chip", resolved, chip_amount)

	return {
		"outcome": Outcome.BLOCKED,
		"hit_info": resolved,
		"chip_amount": chip_amount,
	}


static func _ensure_block_chip_amount(boss: Node, hit_info: Dictionary) -> Dictionary:
	var resolved := hit_info.duplicate(true)
	if is_explosive_hit(resolved):
		resolved["chip_damage"] = EXPLOSIVE_SHIELD_CHIP
		resolved["damage"] = int(EXPLOSIVE_SHIELD_CHIP)
		return resolved
	if resolved.has("chip_damage") and float(resolved.get("chip_damage", 0.0)) > 0.0:
		return resolved
	if resolved.has("damage") and int(resolved.get("damage", 0)) > 0:
		return resolved
	var zone := BulletHitDamageScript.classify_hit_zone(boss, resolved)
	resolved["damage"] = BulletHitDamageScript.damage_for_zone(zone, resolved)
	return resolved


static func _block_chip_amount(hit_info: Dictionary) -> float:
	if hit_info.has("chip_damage"):
		return maxf(float(hit_info.get("chip_damage")), 0.0)
	return maxf(float(hit_info.get("damage", 1.0)), 0.0)


static func _estimate_raw_damage(boss: Node, hit_info: Dictionary) -> float:
	if hit_info.has("chip_damage") and float(hit_info.get("chip_damage", 0.0)) > 0.0:
		return maxf(float(hit_info.get("chip_damage")), 0.0)
	if hit_info.has("damage") and int(hit_info.get("damage", 0)) > 0:
		return float(int(hit_info.get("damage")))
	var zone := BulletHitDamageScript.classify_hit_zone(boss, hit_info)
	return float(BulletHitDamageScript.damage_for_zone(zone, hit_info))
