extends RefCounted

## Per-weapon-type stamina for embedded elemental gems. When empty, gem effects
## go inactive for COOLDOWN_SEC, then recharge over RECHARGE_SEC.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")

const MAX_STAMINA := 1.0
const DRAIN_PER_ATTACK := 0.08
const COOLDOWN_SEC := 10.0
const RECHARGE_SEC := 6.0

enum Phase { ACTIVE, COOLING, RECHARGING }

## weapon_id (int as key) -> { "stamina": float, "cooldown": float, "phase": int }
static var _state: Dictionary = {}


static func has_embedded_gem(weapon_id: int) -> bool:
	return not PlayerInventory.get_embedded_gems(weapon_id).is_empty()


static func is_effect_active(weapon_id: int) -> bool:
	if not has_embedded_gem(weapon_id):
		return false
	var entry := _ensure(weapon_id)
	return int(entry["phase"]) == Phase.ACTIVE and float(entry["stamina"]) > 0.0


static func consume_on_attack(weapon_id: int) -> void:
	if not has_embedded_gem(weapon_id):
		return
	var entry := _ensure(weapon_id)
	if int(entry["phase"]) != Phase.ACTIVE:
		return
	var stamina := float(entry["stamina"]) - DRAIN_PER_ATTACK
	if stamina <= 0.0:
		entry["stamina"] = 0.0
		entry["phase"] = Phase.COOLING
		entry["cooldown"] = COOLDOWN_SEC
	else:
		entry["stamina"] = stamina
	_state[_key(weapon_id)] = entry


static func tick(delta: float) -> void:
	if delta <= 0.0 or _state.is_empty():
		return
	var keys: Array = _state.keys()
	for key in keys:
		var weapon_id := int(key)
		if not has_embedded_gem(weapon_id):
			_state.erase(key)
			continue
		var entry: Dictionary = _state[key]
		var phase := int(entry["phase"])
		match phase:
			Phase.COOLING:
				var cooldown := float(entry["cooldown"]) - delta
				if cooldown <= 0.0:
					entry["cooldown"] = 0.0
					entry["phase"] = Phase.RECHARGING
					entry["stamina"] = 0.0
				else:
					entry["cooldown"] = cooldown
				_state[key] = entry
			Phase.RECHARGING:
				var stamina := float(entry["stamina"]) + (MAX_STAMINA / RECHARGE_SEC) * delta
				if stamina >= MAX_STAMINA:
					entry["stamina"] = MAX_STAMINA
					entry["phase"] = Phase.ACTIVE
				else:
					entry["stamina"] = stamina
				_state[key] = entry
			_:
				pass


static func get_ratio(weapon_id: int) -> float:
	if not has_embedded_gem(weapon_id):
		return 0.0
	var entry := _ensure(weapon_id)
	return clampf(float(entry["stamina"]) / MAX_STAMINA, 0.0, 1.0)


static func get_display_color(weapon_id: int) -> Color:
	var gems := PlayerInventory.get_embedded_gems(weapon_id)
	if gems.is_empty():
		return Color(0.7, 0.7, 0.7, 1.0)
	var color := ElementalGems.get_color(gems[0])
	var entry := _ensure(weapon_id)
	if int(entry["phase"]) == Phase.COOLING:
		return Color(color.r * 0.35, color.g * 0.35, color.b * 0.35, 0.85)
	return color


static func clear_weapon(weapon_id: int) -> void:
	_state.erase(_key(weapon_id))


static func reset_all() -> void:
	_state.clear()


static func _ensure(weapon_id: int) -> Dictionary:
	var key := _key(weapon_id)
	if _state.has(key):
		return _state[key]
	var entry := {
		"stamina": MAX_STAMINA,
		"cooldown": 0.0,
		"phase": Phase.ACTIVE,
	}
	_state[key] = entry
	return entry


static func _key(weapon_id: int) -> String:
	return str(weapon_id)
