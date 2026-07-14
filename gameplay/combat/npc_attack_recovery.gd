extends RefCounted
## Forced idle after an NPC finishes an attack or combo.
## Gives the player a readable opening before the next AI decision.
##
## Tune globally via `base_seconds` / `difficulty_mult`, or per-NPC with an
## `@export var post_attack_recovery_seconds` passed into `get_seconds()`.
## Harder difficulty → smaller `difficulty_mult` → shorter opening.

const DEFAULT_SECONDS := 2.0

static var base_seconds: float = DEFAULT_SECONDS
## 1.0 = normal. Lower = harder (shorter chill). Higher = easier.
static var difficulty_mult: float = 1.0


static func get_seconds(override_seconds: float = -1.0) -> float:
	var base := base_seconds if override_seconds < 0.0 else override_seconds
	return maxf(0.0, base * difficulty_mult)


static func set_difficulty_mult(mult: float) -> void:
	difficulty_mult = maxf(0.0, mult)
