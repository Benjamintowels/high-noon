extends RefCounted
class_name CombatKnockback

## Knockback pushes a body backward without turning it to face the push direction,
## unless a caller explicitly opts into a different facing rule.
const DEFAULT_HOLD := 0.14


static func preserve_velocity(body: Node, duration: float = DEFAULT_HOLD) -> void:
	if body != null and body.has_method("hold_knockback_velocity"):
		body.hold_knockback_velocity(duration)


static func should_preserve_velocity(body: Node) -> bool:
	if body != null and body.has_method("should_preserve_knockback_velocity"):
		return body.should_preserve_knockback_velocity()
	return false
