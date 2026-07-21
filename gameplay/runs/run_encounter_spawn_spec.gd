extends RefCounted

## Parses encounter-area Marker3D names into enemy scene + weapon loadouts.
## Naming: `{EnemyType}{Weapon}{optionalDigits}` — e.g. BanditRevolver1,
## RedoLightsaber, TownspersonUnarmed. Legacy `Spawn*` markers stay valid
## (Bandit + tier default weapon).

const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const RESERVED_EXACT := {
	"Trigger": true,
	"Chest": true,
	"DripSpawn": true,
}

## Longest-first enemy type tokens → PackedScene paths.
const ENEMY_SCENES := {
	"Townsperson": "res://characters/groyper/groyper_town_npc.tscn",
	"Townsfolk": "res://characters/groyper/groyper_townsfolk_npc.tscn",
	"Sheriff": "res://characters/sheriff/sheriff_town_npc.tscn",
	"Bandit": "res://characters/groyper/groyper_bandit_npc.tscn",
	"Pavel": "res://characters/pavel/pavel_npc.tscn",
	"Undead": "res://characters/undead/undead_npc.tscn",
	"Redo": "res://characters/redo/redo_npc.tscn",
}

## Friendly aliases → enum key without underscores (PascalCase).
const WEAPON_ALIASES := {
	"Unarmed": "Unarmed",
	"Revolver": "Revolver",
	"Shotgun": "Shotgun",
	"Winchester": "Winchester",
	"Lightsaber": "Lightsaber",
	"Sword2H": "Sword2H",
	"Sword1H": "Sword1H",
	"SwordShield": "SwordShield",
	"Axe2H": "Axe2H",
	"Axe1H": "Axe1H",
	"Hammer2H": "Hammer2H",
	"Hammer": "Hammer",
	"Bow": "Bow",
	"Shovel": "Shovel",
	"Torch": "Torch",
	"Dynamite": "Dynamite",
	"BaseballBat": "BaseballBat",
	"BusterSword": "BusterSword",
	"DeathAxe": "DeathAxe",
	"LifeSword": "LifeSword",
	"Polesaw": "Polesaw",
	"Mac10": "Mac10",
	"Ak47": "Ak47",
	"Ak47U": "Ak47U",
	"Awp": "Awp",
	"Rpg": "Rpg",
	"M1911": "M1911",
	"G36": "G36",
	"M4Xl": "M4Xl",
	"GrenadeLauncher": "GrenadeLauncher",
	"Lasso": "Lasso",
}


static func is_reserved_name(marker_name: String) -> bool:
	if RESERVED_EXACT.has(marker_name):
		return true
	return marker_name.begins_with("GateWall")


static func is_legacy_spawn_name(marker_name: String) -> bool:
	return marker_name.begins_with("Spawn")


static func is_spawn_marker_name(marker_name: String) -> bool:
	if marker_name.is_empty() or is_reserved_name(marker_name):
		return false
	if is_legacy_spawn_name(marker_name):
		return true
	return not parse_named_marker(marker_name).is_empty()


static func parse_named_marker(marker_name: String) -> Dictionary:
	## Returns { enemy_key, scene_path, weapon_id } or {} if unrecognized.
	var base := _strip_trailing_digits(marker_name)
	if base.is_empty():
		return {}
	var enemy_keys := ENEMY_SCENES.keys()
	enemy_keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for enemy_key in enemy_keys:
		if not base.begins_with(enemy_key):
			continue
		var weapon_token := base.substr(enemy_key.length())
		if weapon_token.is_empty():
			return {}
		var weapon_id := resolve_weapon_token(weapon_token)
		if weapon_id < 0:
			return {}
		return {
			"enemy_key": enemy_key,
			"scene_path": String(ENEMY_SCENES[enemy_key]),
			"weapon_id": weapon_id,
		}
	return {}


static func resolve_weapon_token(token: String) -> int:
	if token.is_empty():
		return -1
	var normalized := _normalize_token(token)
	for alias in WEAPON_ALIASES.keys():
		if _normalize_token(alias) == normalized:
			return _weapon_id_from_pascal(String(WEAPON_ALIASES[alias]))
	## Fallback: match any GroyperWeapons.Id key (underscores stripped).
	for key in GroyperWeaponsScript.Id.keys():
		if _normalize_token(String(key).replace("_", "")) == normalized:
			return int(GroyperWeaponsScript.Id[key])
	return -1


static func melee_only_for_weapon(weapon_id: int) -> bool:
	if weapon_id < 0:
		return true
	if weapon_id == GroyperWeaponsScript.Id.UNARMED:
		return true
	return GroyperWeaponsScript.is_melee(weapon_id as GroyperWeaponsScript.Id)


static func load_enemy_scene(scene_path: String) -> PackedScene:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return null
	return load(scene_path) as PackedScene


static func _strip_trailing_digits(marker_name: String) -> String:
	var end := marker_name.length()
	while end > 0 and String(marker_name[end - 1]).is_valid_int():
		end -= 1
	return marker_name.substr(0, end)


static func _normalize_token(token: String) -> String:
	return token.replace("_", "").to_lower()


static func _weapon_id_from_pascal(pascal: String) -> int:
	var normalized := _normalize_token(pascal)
	for key in GroyperWeaponsScript.Id.keys():
		if _normalize_token(String(key).replace("_", "")) == normalized:
			return int(GroyperWeaponsScript.Id[key])
	return -1
