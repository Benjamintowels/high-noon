class_name DuelPaces
extends RefCounted

const PACE_STEPS := [30, 24, 18, 12]
const MIN_SEPARATION := 2.0
## Replay uses the low side camera at or below this lane separation.
const CLASSIC_REPLAY_MAX_SEPARATION := 12.0

const ENEMY_MIN_DRAW_DELAY := 0.0
const ENEMY_MAX_DRAW_DELAY := 0.2
const ENEMY_MIN_FIRE_DELAY := 0.3
const ENEMY_MAX_FIRE_DELAY := 2.0
## Chance the enemy aims slightly off-body at the opening distance (30 paces).
const START_AIM_MISS_CHANCE := 0.30
## Chance at toe-to-toe range — always centered.
const END_AIM_MISS_CHANCE := 0.0


static func max_match_rounds() -> int:
	return GameState.ROUNDS_TO_WIN * 2 - 1


static func separation_for_round(round_number: int) -> float:
	var index := round_number - 1
	if index < PACE_STEPS.size():
		return float(PACE_STEPS[index])

	var paces_past_schedule := round_number - PACE_STEPS.size()
	return maxf(float(PACE_STEPS[-1]) - float(paces_past_schedule), MIN_SEPARATION)


static func pace_progress(round_number: int) -> float:
	var start_sep := float(PACE_STEPS[0])
	var sep := separation_for_round(round_number)
	return pace_progress_from_separation(sep)


static func pace_progress_from_separation(separation: float) -> float:
	var start_sep := float(PACE_STEPS[0])
	if start_sep <= MIN_SEPARATION:
		return 1.0
	return clampf(1.0 - (separation - MIN_SEPARATION) / (start_sep - MIN_SEPARATION), 0.0, 1.0)


static func pace_label_for_round(round_number: int) -> String:
	return "%d Paces" % int(roundf(separation_for_round(round_number)))


static func uses_classic_replay_camera(separation: float) -> bool:
	return separation <= CLASSIC_REPLAY_MAX_SEPARATION + 0.01


static func duel_positions_for_round(
	round_number: int,
	player_spawn: Node3D,
	enemy_spawn: Node3D
) -> Dictionary:
	var midpoint_z := (player_spawn.global_position.z + enemy_spawn.global_position.z) * 0.5
	var half_gap := separation_for_round(round_number) * 0.5

	return {
		"player": Vector3(
			player_spawn.global_position.x,
			player_spawn.global_position.y,
			midpoint_z - half_gap
		),
		"enemy": Vector3(
			enemy_spawn.global_position.x,
			enemy_spawn.global_position.y,
			midpoint_z + half_gap
		),
	}


static func enemy_fire_delays_for_round(_round_number: int) -> Vector2:
	return Vector2(ENEMY_MIN_FIRE_DELAY, ENEMY_MAX_FIRE_DELAY)


static func enemy_draw_delays_for_round(_round_number: int) -> Vector2:
	return Vector2(ENEMY_MIN_DRAW_DELAY, ENEMY_MAX_DRAW_DELAY)


static func enemy_aim_miss_chance_for_round(round_number: int) -> float:
	var t := pace_progress(round_number)
	return lerpf(START_AIM_MISS_CHANCE, END_AIM_MISS_CHANCE, t)
