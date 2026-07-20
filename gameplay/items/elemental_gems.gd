extends RefCounted

## Catalog of elemental gems that can sit free in inventory or embed into a
## weapon gem slot. Combat effects are future work — ids/colors drive UI + VFX.

const LIGHTNING := &"lightning"
const FIRE := &"fire"
const ICE := &"ice"

const GEMS: Dictionary = {
	LIGHTNING: {
		"name": "Lightning Gem",
		"color": Color(1.0, 0.92, 0.22, 1.0),
		"active": true,
	},
	FIRE: {
		"name": "Fire Gem",
		"color": Color(1.0, 0.42, 0.12, 1.0),
		"active": true,
	},
	ICE: {
		"name": "Ice Gem",
		"color": Color(0.45, 0.85, 1.0, 1.0),
		"active": true,
	},
}


static func is_valid(gem_id: StringName) -> bool:
	return GEMS.has(gem_id)


static func is_active(gem_id: StringName) -> bool:
	if not is_valid(gem_id):
		return false
	return bool((GEMS[gem_id] as Dictionary).get("active", false))


static func get_display_name(gem_id: StringName) -> String:
	if not is_valid(gem_id):
		return "Gem"
	return str((GEMS[gem_id] as Dictionary).get("name", "Gem"))


static func get_color(gem_id: StringName) -> Color:
	if not is_valid(gem_id):
		return Color(0.8, 0.8, 0.8, 1.0)
	return (GEMS[gem_id] as Dictionary).get("color", Color(0.8, 0.8, 0.8, 1.0)) as Color


## Gem ids marked active (armory summon list, etc.).
static func get_active_gem_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for gem_id: StringName in GEMS.keys():
		if is_active(gem_id):
			result.append(gem_id)
	return result
