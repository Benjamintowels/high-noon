extends Resource
class_name RunWaveGroup

## A faction wavegroup: base units unlock at unlock_time, elite follows +30s.

@export var id: StringName = &""
@export var display_name := ""
@export var unlock_time: float = 0.0
@export var unlock_announce := ""

@export var base_units: Array[Resource] = []
@export var base_spawn_interval: float = 7.5
@export var spawns_per_tick: int = 1
@export var rate_bump_factor: float = 0.90
@export var min_spawn_interval: float = 3.0

@export var elite_scene: PackedScene
@export var elite_announce := ""
## GroyperWeapons.Id, or -1 to keep the scene default.
@export var elite_weapon_id: int = -1
@export var elite_melee_only: bool = false
## Multiplier against regular wavegroup HP (not the elite scene's native max).
@export var elite_health_mult: float = 3.0
@export var elite_loot_mult: float = 3.0
@export var elite_visual_scale: float = 1.0
## Base HP of a regular unit in this group; elite HP = base_unit_max_health * elite_health_mult.
@export var base_unit_max_health: int = 2


func pick_base_unit(run_elapsed: float = INF) -> Resource:
	var eligible: Array[Resource] = []
	var total_weight := 0.0
	for unit in base_units:
		if unit == null or unit.get("enemy_scene") == null:
			continue
		var unit_unlock: Variant = unit.get("unlock_time")
		if unit_unlock != null and float(unit_unlock) > run_elapsed:
			continue
		eligible.append(unit)
		total_weight += maxf(float(unit.get("weight")), 0.0)
	if eligible.is_empty():
		return null
	if total_weight <= 0.0:
		return eligible[randi() % eligible.size()]
	var roll := randf() * total_weight
	var cursor := 0.0
	for unit in eligible:
		cursor += maxf(float(unit.get("weight")), 0.0)
		if roll <= cursor:
			return unit
	return eligible[eligible.size() - 1]
