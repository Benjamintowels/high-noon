extends Resource
class_name RunStageConfig

const RunEnemyEntryScript := preload("res://gameplay/runs/run_enemy_entry.gd")
const RunEnemyPoolScript := preload("res://gameplay/runs/run_enemy_pool.gd")
const RunModifierScript := preload("res://gameplay/runs/run_modifier.gd")
const RunModifierPoolScript := preload("res://gameplay/runs/run_modifier_pool.gd")
const RunWaveGroupScript := preload("res://gameplay/runs/run_wave_group.gd")
const RunWaveUnitScript := preload("res://gameplay/runs/run_wave_unit.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

@export var theme_title := "Run Stage"
@export var enemy_pool: Resource
@export var modifier_pool: Resource
@export var boss_scene: PackedScene
## When non-empty, RunDirector uses timed wavegroups instead of flat enemy_pool waves.
@export var wave_groups: Array[Resource] = []

@export var starting_difficulty: float = 0.0
@export var max_difficulty: float = 100.0
@export var difficulty_per_second: float = 0.35
@export var difficulty_per_wave: float = 4.0

@export var first_wave_delay: float = 1.0
@export var wave_interval: float = 18.0
@export var base_spawn_count: int = 2
@export var spawn_count_per_difficulty: float = 0.08
@export var max_alive_enemies: int = 14

@export var spawn_min_distance: float = 14.0
@export var spawn_max_distance: float = 26.0
@export var spawn_min_separation: float = 2.4

@export var run_sight_range: float = 42.0
@export var run_hearing_range: float = 48.0
@export var run_aggro_range: float = 42.0

@export var base_loot_mult: float = 1.0
@export var loot_mult_per_difficulty: float = 0.012

@export var modifier_thresholds: PackedFloat32Array = PackedFloat32Array([8.0, 20.0, 35.0, 50.0])
@export var max_active_modifiers: int = 3

## Seconds between elite spawns / rate bumps once a wavegroup is live.
@export var elite_interval: float = 30.0
## Seconds between wavegroup unlocks (bandits → engines → redos → mix).
@export var wavegroup_upgrade_interval: float = 60.0

## Run loot scatter (chests + destructible props).
@export var chest_count: int = 12
@export var prop_count: int = 36
@export var chest_free_weight: float = 0.25
@export var chest_gram_weight: float = 0.45
@export var chest_shard_weight: float = 0.30
@export var gram_chest_base_cost: int = 25
@export var gram_chest_cost_mult: float = 1.75
@export var shard_chest_base_cost: int = 3
@export var shard_chest_cost_mult: float = 1.6
@export var horsey_drop_chance: float = 0.03
@export var prop_barrel_weight: float = 0.55
@export var rare_seed_drop_chance: float = 0.015


static func make_dry_gulch() -> Resource:
	var script: Script = load("res://gameplay/runs/run_stage_config.gd") as Script
	var config: Resource = script.new() as Resource
	config.set("theme_title", "The Dry Gulch")
	config.set("boss_scene", load("res://characters/chief_getcha/chief_getcha_npc.tscn"))
	config.set("starting_difficulty", 0.0)
	config.set("max_difficulty", 80.0)
	config.set("difficulty_per_second", 0.3)
	config.set("difficulty_per_wave", 3.5)
	config.set("first_wave_delay", 0.5)
	config.set("wave_interval", 16.0)
	config.set("base_spawn_count", 2)
	config.set("spawn_count_per_difficulty", 0.07)
	config.set("max_alive_enemies", 12)
	config.set("run_sight_range", 40.0)
	config.set("run_hearing_range", 46.0)
	config.set("run_aggro_range", 40.0)
	config.set("base_loot_mult", 0.85)
	config.set("loot_mult_per_difficulty", 0.015)
	config.set("modifier_thresholds", PackedFloat32Array([6.0, 16.0, 28.0, 42.0]))
	config.set("max_active_modifiers", 3)
	config.set("elite_interval", 30.0)
	config.set("wavegroup_upgrade_interval", 60.0)
	config.set("chest_count", 12)
	config.set("prop_count", 36)
	config.set("chest_free_weight", 0.25)
	config.set("chest_gram_weight", 0.45)
	config.set("chest_shard_weight", 0.30)
	config.set("gram_chest_base_cost", 25)
	config.set("gram_chest_cost_mult", 1.75)
	config.set("shard_chest_base_cost", 3)
	config.set("shard_chest_cost_mult", 1.6)
	config.set("horsey_drop_chance", 0.03)
	config.set("prop_barrel_weight", 0.55)
	config.set("rare_seed_drop_chance", 0.015)

	config.set("wave_groups", _make_dry_gulch_wave_groups())

	# Legacy flat pool kept as fallback if wave_groups is cleared.
	var pool: Resource = RunEnemyPoolScript.new()
	var enemy_entries: Array[Resource] = []
	enemy_entries.append(_entry("res://characters/groyper/groyper_bandit_npc.tscn", 0.0, 100.0, 2.0))
	enemy_entries.append(_entry("res://characters/fast/engines_npc.tscn", 20.0, 100.0, 1.4))
	enemy_entries.append(_entry("res://characters/redo/redo_npc.tscn", 40.0, 100.0, 1.0))
	pool.set("entries", enemy_entries)
	config.set("enemy_pool", pool)

	var mods: Resource = RunModifierPoolScript.new()
	var modifier_entries: Array[Resource] = []
	modifier_entries.append(_mod(&"dense_packs", "Dense Packs", 6.0, 1.0, 1.35, 1.0, 1.0, 1.0))
	modifier_entries.append(_mod(&"lean_pockets", "Lean Pockets", 10.0, 1.0, 1.0, 0.7, 1.0, 1.0))
	modifier_entries.append(_mod(&"ferocious", "Ferocious", 16.0, 1.0, 1.0, 1.0, 1.35, 1.1))
	modifier_entries.append(_mod(&"rising_pressure", "Rising Pressure", 22.0, 0.8, 1.15, 0.9, 1.15, 1.25))
	mods.set("modifiers", modifier_entries)
	config.set("modifier_pool", mods)
	return config


static func _make_dry_gulch_wave_groups() -> Array[Resource]:
	var groups: Array[Resource] = []

	var bandits: Resource = RunWaveGroupScript.new()
	bandits.set("id", &"bandits")
	bandits.set("display_name", "Bandits")
	bandits.set("unlock_time", 0.0)
	bandits.set("unlock_announce", "Bandits inbound")
	bandits.set("base_spawn_interval", 10.0)
	bandits.set("min_spawn_interval", 4.0)
	bandits.set("spawns_per_tick", 1)
	bandits.set("elite_scene", load("res://characters/sheriff/sheriff_town_npc.tscn"))
	bandits.set("elite_announce", "Elite Sheriff")
	bandits.set("elite_weapon_id", GroyperWeaponsScript.Id.REVOLVER)
	bandits.set("elite_health_mult", 3.0)
	bandits.set("elite_loot_mult", 3.0)
	# Must be a typed Array[Resource]: set() silently rejects untyped literals
	# on typed exports, leaving base_units empty (no base spawns at all).
	# Unarmed melee bandits open the run; revolver bandits join at 30s.
	var bandit_units: Array[Resource] = [
		_unit(
			"res://characters/groyper/groyper_bandit_npc.tscn",
			1.0,
			GroyperWeaponsScript.Id.UNARMED,
			true,
			0.0
		),
		_unit(
			"res://characters/groyper/groyper_bandit_npc.tscn",
			1.0,
			GroyperWeaponsScript.Id.REVOLVER,
			false,
			30.0
		),
	]
	bandits.set("base_units", bandit_units)
	groups.append(bandits)

	var engines: Resource = RunWaveGroupScript.new()
	engines.set("id", &"engines")
	engines.set("display_name", "Engines")
	engines.set("unlock_time", 60.0)
	engines.set("unlock_announce", "Engines inbound")
	engines.set("base_spawn_interval", 10.0)
	engines.set("min_spawn_interval", 4.0)
	engines.set("spawns_per_tick", 1)
	engines.set("elite_scene", load("res://characters/fast/engines_npc.tscn"))
	engines.set("elite_announce", "Elite Engine")
	engines.set("elite_weapon_id", GroyperWeaponsScript.Id.SHOTGUN)
	engines.set("elite_health_mult", 3.0)
	engines.set("elite_loot_mult", 3.0)
	engines.set("elite_visual_scale", 2.0)
	var engine_units: Array[Resource] = [
		_unit(
			"res://characters/fast/engines_npc.tscn",
			1.2,
			GroyperWeaponsScript.Id.BOW,
			false,
			0.0
		),
		_unit(
			"res://characters/fast/engines_npc.tscn",
			1.0,
			GroyperWeaponsScript.Id.REVOLVER,
			false,
			0.0
		),
	]
	engines.set("base_units", engine_units)
	groups.append(engines)

	var redos: Resource = RunWaveGroupScript.new()
	redos.set("id", &"redos")
	redos.set("display_name", "Redos")
	redos.set("unlock_time", 120.0)
	redos.set("unlock_announce", "Redos inbound")
	redos.set("base_spawn_interval", 11.0)
	redos.set("min_spawn_interval", 4.5)
	redos.set("spawns_per_tick", 1)
	redos.set("elite_scene", load("res://characters/pavel/pavel_npc.tscn"))
	redos.set("elite_announce", "Elite Pavel")
	redos.set("elite_weapon_id", -1)
	redos.set("elite_health_mult", 3.0)
	redos.set("elite_loot_mult", 3.0)
	var redo_units: Array[Resource] = [
		_unit("res://characters/redo/redo_npc.tscn", 1.0, -1, false, 0.0),
	]
	redos.set("base_units", redo_units)
	groups.append(redos)

	return groups


static func _unit(
	path: String,
	weight: float,
	weapon_id: int,
	melee_only: bool,
	unlock_time: float = 0.0
) -> Resource:
	var unit: Resource = RunWaveUnitScript.new()
	unit.set("enemy_scene", load(path))
	unit.set("weight", weight)
	unit.set("weapon_id", weapon_id)
	unit.set("melee_only", melee_only)
	unit.set("unlock_time", unlock_time)
	return unit


static func _entry(path: String, min_d: float, max_d: float, weight: float) -> Resource:
	var entry: Resource = RunEnemyEntryScript.new()
	entry.set("enemy_scene", load(path))
	entry.set("min_difficulty", min_d)
	entry.set("max_difficulty", max_d)
	entry.set("weight", weight)
	return entry


static func _mod(
	id: StringName,
	display_name: String,
	min_d: float,
	weight: float,
	spawn_mult: float,
	loot_mult: float,
	aggro_mult: float,
	diff_mult: float
) -> Resource:
	var modifier: Resource = RunModifierScript.new()
	modifier.set("id", id)
	modifier.set("display_name", display_name)
	modifier.set("min_difficulty", min_d)
	modifier.set("weight", weight)
	modifier.set("spawn_count_mult", spawn_mult)
	modifier.set("loot_mult", loot_mult)
	modifier.set("aggro_mult", aggro_mult)
	modifier.set("difficulty_gain_mult", diff_mult)
	return modifier
