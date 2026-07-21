extends RefCounted

## Named run-enemy difficulty recipes. Same scenes; loadout/HP/armor/speed differ.

const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

enum Tier {
	EASY,
	MEDIUM,
	HARDER,
	ARMORED,
	MINIBOSS,
}

const PROFILE_DEFAULT := &"default"
const PROFILE_DRY_GULCH := &"dry_gulch"

const DRY_GULCH_UNARMED_SECONDS := 60.0
const DRY_GULCH_REVOLVER_SECONDS := 150.0
const DRY_GULCH_SHOTGUN_SECONDS := 240.0


static func pick_tier(difficulty: float) -> int:
	return pick_tier_for_profile(PROFILE_DEFAULT, difficulty, 0.0)


static func pick_tier_for_profile(
	profile: StringName,
	difficulty: float,
	run_elapsed: float
) -> int:
	if profile == PROFILE_DRY_GULCH:
		return pick_dry_gulch_tier(run_elapsed)
	return _pick_default_tier(difficulty)


static func pick_dry_gulch_tier(run_elapsed: float) -> int:
	## Regulars stay unarmed; tier only scales toughness / elite gun choice.
	## Elites: shotgun early, Winchester once this returns ARMORED.
	if run_elapsed < DRY_GULCH_UNARMED_SECONDS:
		return Tier.EASY
	if run_elapsed < DRY_GULCH_REVOLVER_SECONDS:
		return Tier.MEDIUM
	if run_elapsed < DRY_GULCH_SHOTGUN_SECONDS:
		return Tier.HARDER
	return Tier.ARMORED


static func pick_miniboss_tier() -> int:
	return Tier.MINIBOSS


static func build_spawn_opts(tier: int) -> Dictionary:
	return build_spawn_opts_for_profile(PROFILE_DEFAULT, tier, false)


static func build_spawn_opts_for_profile(
	profile: StringName,
	tier: int,
	elite_miniboss: bool = false
) -> Dictionary:
	if profile == PROFILE_DRY_GULCH:
		return _build_dry_gulch_opts(tier, elite_miniboss)
	return _build_default_opts(tier)


static func merge_opts(base: Dictionary, tier_opts: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	for key in tier_opts:
		merged[key] = tier_opts[key]
	return merged


static func _build_dry_gulch_opts(tier: int, elite_miniboss: bool) -> Dictionary:
	## Dry Gulch: regulars always unarmed melee. Only elites carry guns
	## (shotgun → Winchester) and those are the only weapon drops in runs.
	if elite_miniboss or tier == Tier.MINIBOSS:
		var elite_weapon := GroyperWeaponsScript.Id.SHOTGUN
		if tier == Tier.ARMORED:
			elite_weapon = GroyperWeaponsScript.Id.WINCHESTER
		return {
			"weapon_id": elite_weapon,
			"melee_only": false,
			"max_health": _roll_inclusive(6, 8),
			"health_mult": 1.0,
			"loot_mult": 2.5,
			"elite": true,
			"visual_scale": 1.45,
			"speed_mult": 1.15,
			"block_health": 0.0,
			"auto_reflect": false,
		}
	var max_health := _roll_inclusive(2, 3)
	var loot_mult := 1.0
	if tier == Tier.ARMORED:
		max_health = _roll_inclusive(3, 4)
		loot_mult = 1.25
	elif tier == Tier.HARDER:
		max_health = _roll_inclusive(3, 4)
		loot_mult = 1.15
	elif tier == Tier.MEDIUM:
		max_health = _roll_inclusive(2, 3)
	# TEMP: arm drip/budget regulars with revolvers so cover AI can be playtested.
	# Revert to UNARMED + melee_only true before shipping.
	return {
		"weapon_id": GroyperWeaponsScript.Id.REVOLVER,
		"melee_only": false,
		"max_health": max_health,
		"health_mult": 1.0,
		"loot_mult": loot_mult,
		"elite": false,
		"visual_scale": 1.0,
		"speed_mult": 1.0,
		"block_health": 0.0,
		"auto_reflect": false,
	}


static func build_dry_gulch_elite_opts(run_elapsed: float = 0.0) -> Dictionary:
	## Encounter / drip elites: shotgun, then Winchester late-run.
	var elite_tier: int = Tier.MINIBOSS
	if pick_dry_gulch_tier(run_elapsed) == Tier.ARMORED:
		elite_tier = Tier.ARMORED
	return _build_dry_gulch_opts(elite_tier, true)


static func _build_default_opts(tier: int) -> Dictionary:
	match tier:
		Tier.EASY:
			return {
				"weapon_id": GroyperWeaponsScript.Id.UNARMED,
				"melee_only": true,
				"max_health": _roll_inclusive(2, 3),
				"health_mult": 1.0,
				"loot_mult": 1.0,
				"elite": false,
				"visual_scale": 1.0,
				"speed_mult": 1.0,
				"block_health": 0.0,
				"auto_reflect": false,
			}
		Tier.MEDIUM:
			return {
				"weapon_id": GroyperWeaponsScript.Id.REVOLVER,
				"melee_only": false,
				"max_health": _roll_inclusive(2, 3),
				"health_mult": 1.0,
				"loot_mult": 1.0,
				"elite": false,
				"visual_scale": 1.0,
				"speed_mult": 1.0,
				"block_health": 0.0,
				"auto_reflect": false,
			}
		Tier.HARDER:
			return {
				"weapon_id": GroyperWeaponsScript.Id.SHOTGUN,
				"melee_only": false,
				"max_health": _roll_inclusive(3, 4),
				"health_mult": 1.0,
				"loot_mult": 1.15,
				"elite": false,
				"visual_scale": 1.0,
				"speed_mult": 1.0,
				"block_health": 0.0,
				"auto_reflect": false,
			}
		Tier.ARMORED:
			var armored_weapon := (
				GroyperWeaponsScript.Id.SWORD_SHIELD
				if randf() < 0.55
				else GroyperWeaponsScript.Id.SWORD_1H
			)
			return {
				"weapon_id": armored_weapon,
				"melee_only": true,
				"max_health": _roll_inclusive(8, 10),
				"health_mult": 1.0,
				"loot_mult": 1.5,
				"elite": false,
				"visual_scale": 1.0,
				"speed_mult": 1.0,
				"block_health": 10.0,
				"auto_reflect": true,
			}
		Tier.MINIBOSS:
			var mini_weapon := (
				GroyperWeaponsScript.Id.SHOTGUN
				if randf() < 0.5
				else GroyperWeaponsScript.Id.SWORD_2H
			)
			return {
				"weapon_id": mini_weapon,
				"melee_only": mini_weapon == GroyperWeaponsScript.Id.SWORD_2H,
				"max_health": _roll_inclusive(20, 25),
				"health_mult": 1.0,
				"loot_mult": 3.0,
				"elite": true,
				"visual_scale": 2.0,
				"speed_mult": 1.2,
				"block_health": 15.0,
				"auto_reflect": true,
			}
		_:
			return _build_default_opts(Tier.EASY)


static func _pick_default_tier(difficulty: float) -> int:
	var weights := _weights_for_difficulty(difficulty)
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return Tier.EASY
	var roll := randf() * total
	var cursor := 0.0
	for i in weights.size():
		cursor += weights[i]
		if roll <= cursor:
			return i
	return Tier.EASY


static func _weights_for_difficulty(difficulty: float) -> PackedFloat32Array:
	# EASY, MEDIUM, HARDER, ARMORED, MINIBOSS
	if difficulty < 12.0:
		return PackedFloat32Array([1.0, 0.15, 0.0, 0.0, 0.0])
	if difficulty < 25.0:
		return PackedFloat32Array([0.55, 0.45, 0.05, 0.0, 0.0])
	if difficulty < 40.0:
		return PackedFloat32Array([0.15, 0.45, 0.35, 0.05, 0.0])
	if difficulty < 55.0:
		return PackedFloat32Array([0.05, 0.2, 0.4, 0.3, 0.05])
	return PackedFloat32Array([0.0, 0.1, 0.25, 0.5, 0.15])


static func _roll_inclusive(lo: int, hi: int) -> int:
	if hi <= lo:
		return lo
	return randi_range(lo, hi)
