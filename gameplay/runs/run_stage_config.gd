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

## When true and the zone has `run_encounter_area` markers, spawn themed packs
## on area entry. Can combine with hybrid_drip_enabled for near-player drip.
@export var use_encounter_areas: bool = false
@export var encounter_base_pack: int = 3
@export var encounter_pack_per_difficulty: float = 0.06
@export var encounter_max_pack: int = 8
@export var encounter_reinforce_min_difficulty: float = 28.0
@export var encounter_elite_min_difficulty: float = 18.0
@export var encounter_reinforce_pack_bonus: int = 2

## With encounter areas: also drip from wave_groups flagged drip_enabled.
@export var hybrid_drip_enabled: bool = false
@export var hybrid_drip_interval_mult: float = 1.75
@export var hybrid_drip_max_per_tick: int = 1
## Fixed near-player drip cadence while hybrid_drip_enabled (seconds).
@export var hybrid_drip_interval_seconds: float = 5.0
## Alive-cap ladder: base at t=0, then +per_minute each full minute (0 = flat base).
@export var max_alive_base: int = 5
@export var max_alive_per_minute: int = 5
## When true, RunDirector overwrites unit weapon/HP with RunEnemyTier recipes.
@export var use_difficulty_tiers: bool = false
## Tier recipe profile: &"default" or &"dry_gulch" (bandit unarmed→revolver only).
@export var tier_profile: StringName = &"default"
## Strip run gun-armor / bullet reflect from all tiered spawns.
@export var disable_enemy_gun_armor: bool = false
## Kill this many run enemies to open the extract portal (0 = boss-only).
@export var kill_goal: int = 0
@export var kill_goal_hud_title := "Enemies"

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
	config.set("max_difficulty", 40.0)
	config.set("difficulty_per_second", 0.2)
	config.set("difficulty_per_wave", 2.0)
	config.set("first_wave_delay", 0.5)
	config.set("wave_interval", 16.0)
	config.set("base_spawn_count", 2)
	config.set("spawn_count_per_difficulty", 0.05)
	config.set("max_alive_enemies", 15)
	config.set("run_sight_range", 40.0)
	config.set("run_hearing_range", 46.0)
	config.set("run_aggro_range", 40.0)
	config.set("base_loot_mult", 0.85)
	config.set("loot_mult_per_difficulty", 0.015)
	config.set("modifier_thresholds", PackedFloat32Array([10.0, 22.0, 34.0]))
	config.set("max_active_modifiers", 2)
	config.set("elite_interval", 45.0)
	config.set("wavegroup_upgrade_interval", 60.0)
	config.set("use_encounter_areas", true)
	config.set("encounter_base_pack", 2)
	config.set("encounter_pack_per_difficulty", 0.04)
	config.set("encounter_max_pack", 5)
	config.set("encounter_reinforce_min_difficulty", 22.0)
	config.set("encounter_elite_min_difficulty", 12.0)
	config.set("encounter_reinforce_pack_bonus", 1)
	config.set("hybrid_drip_enabled", true)
	config.set("hybrid_drip_interval_mult", 1.75)
	config.set("hybrid_drip_max_per_tick", 1)
	config.set("hybrid_drip_interval_seconds", 5.0)
	config.set("max_alive_base", 15)
	config.set("max_alive_per_minute", 0)
	config.set("use_difficulty_tiers", true)
	config.set("tier_profile", &"dry_gulch")
	config.set("disable_enemy_gun_armor", true)
	config.set("kill_goal", 50)
	config.set("kill_goal_hud_title", "Enemies")
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
	## Bandits only. Area pockets keep place names; loadout comes from tiers.
	const BANDIT := "res://characters/groyper/groyper_bandit_npc.tscn"
	var groups: Array[Resource] = []
	groups.append(
		_make_area_bandit_group(
			&"outskirts", "Dust Road Outskirts", "Dust Road Outskirts — bandits ahead"
		)
	)
	groups.append(
		_make_area_bandit_group(
			&"bank", "First National Bank", "First National Bank — stick-up in progress"
		)
	)
	groups.append(
		_make_area_bandit_group(
			&"saloon", "Saloon Alley", "Saloon Alley — bandits hold the street"
		)
	)
	groups.append(
		_make_area_bandit_group(&"graveyard", "Boot Hill", "Boot Hill — ambush waiting")
	)
	groups.append(
		_make_area_bandit_group(
			&"church", "Church Ruins", "Church Ruins — bandits in the nave"
		)
	)
	groups.append(
		_make_area_bandit_group(
			&"gallows", "Hangman's Bluff", "Hangman's Bluff — posse ahead"
		)
	)
	groups.append(
		_make_drip_group(
			&"drip_bandits",
			"Wandering Bandits",
			0.0,
			"Hostiles closing in…",
			BANDIT,
			BANDIT,
			"Shotgun Bandit",
			10.0,
			4.0
		)
	)
	return groups


static func _make_area_bandit_group(
	id: StringName,
	display_name: String,
	announce: String
) -> Resource:
	const BANDIT := "res://characters/groyper/groyper_bandit_npc.tscn"
	var group: Resource = RunWaveGroupScript.new()
	group.set("id", id)
	group.set("display_name", display_name)
	group.set("unlock_time", 0.0)
	group.set("unlock_announce", announce)
	group.set("drip_enabled", false)
	group.set("base_spawn_interval", 10.0)
	group.set("min_spawn_interval", 4.0)
	group.set("spawns_per_tick", 1)
	group.set("elite_scene", load(BANDIT))
	group.set("elite_announce", "Elite Bandit")
	group.set("elite_weapon_id", GroyperWeaponsScript.Id.REVOLVER)
	group.set("elite_health_mult", 1.0)
	group.set("elite_loot_mult", 2.0)
	group.set("elite_visual_scale", 1.25)
	group.set("base_unit_max_health", 2)
	var units: Array[Resource] = [_unit(BANDIT, 1.0, -1, false, 0.0)]
	group.set("base_units", units)
	return group


static func _make_drip_group(
	id: StringName,
	display_name: String,
	unlock_time: float,
	announce: String,
	base_scene_path: String,
	elite_scene_path: String,
	elite_announce: String,
	base_interval: float,
	min_interval: float
) -> Resource:
	var group: Resource = RunWaveGroupScript.new()
	group.set("id", id)
	group.set("display_name", display_name)
	group.set("unlock_time", unlock_time)
	group.set("unlock_announce", announce)
	group.set("drip_enabled", true)
	group.set("base_spawn_interval", base_interval)
	group.set("min_spawn_interval", min_interval)
	group.set("spawns_per_tick", 1)
	group.set("elite_scene", load(elite_scene_path))
	group.set("elite_announce", elite_announce)
	group.set("elite_weapon_id", GroyperWeaponsScript.Id.SHOTGUN)
	group.set("elite_health_mult", 1.0)
	group.set("elite_loot_mult", 2.5)
	group.set("elite_visual_scale", 1.45)
	group.set("base_unit_max_health", 2)
	var units: Array[Resource] = [_unit(base_scene_path, 1.0, -1, false, 0.0)]
	group.set("base_units", units)
	return group


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
