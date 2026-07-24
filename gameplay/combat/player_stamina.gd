extends RefCounted

## Player stamina for sprint drain and melee costs. When empty, actions still
## run at reduced speed instead of being blocked.

const MAX_STAMINA := 100.0
const MELEE_COST := 10.0
const SPRINT_DRAIN_PER_SEC := 14.0
const RECHARGE_PER_SEC := 11.0
const RECHARGE_DELAY_SEC := 3.0
const STANDING_RECHARGE_MULT := 1.3
const EXHAUSTED_SPRINT_SPEED_MULT := 0.78
const EXHAUSTED_MELEE_SPEED_MULT := 0.5


static func try_spend_melee(current: float) -> Dictionary:
	var stamina := maxf(current, 0.0)
	if stamina >= MELEE_COST:
		return {"stamina": stamina - MELEE_COST, "full_speed": true}
	return {"stamina": 0.0, "full_speed": false}


## Returns { "stamina": float, "recharge_cooldown": float }.
## Sprint drain and any recent spend restart RECHARGE_DELAY_SEC before refill.
static func tick(
	current: float,
	delta: float,
	draining_sprint: bool,
	standing_still: bool,
	recharge_cooldown: float
) -> Dictionary:
	var stamina := clampf(current, 0.0, MAX_STAMINA)
	var cooldown := maxf(recharge_cooldown, 0.0)
	if delta <= 0.0:
		return {"stamina": stamina, "recharge_cooldown": cooldown}

	if draining_sprint:
		if stamina > 0.0:
			stamina = maxf(stamina - SPRINT_DRAIN_PER_SEC * delta, 0.0)
		return {"stamina": stamina, "recharge_cooldown": RECHARGE_DELAY_SEC}

	if cooldown > 0.0:
		cooldown = maxf(cooldown - delta, 0.0)
		return {"stamina": stamina, "recharge_cooldown": cooldown}

	var rate := RECHARGE_PER_SEC
	if standing_still:
		rate *= STANDING_RECHARGE_MULT
	stamina = minf(stamina + rate * delta, MAX_STAMINA)
	return {"stamina": stamina, "recharge_cooldown": 0.0}


static func sprint_speed_mult(current: float) -> float:
	if current > 0.0:
		return 1.0
	return EXHAUSTED_SPRINT_SPEED_MULT


static func melee_speed_mult(full_speed: bool) -> float:
	return 1.0 if full_speed else EXHAUSTED_MELEE_SPEED_MULT
