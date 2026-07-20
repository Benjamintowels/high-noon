extends RefCounted

## Random panic-run while OnFireStatus is active. Bosses never panic.

const OnFireStatusScript := preload("res://gameplay/combat/on_fire_status.gd")
const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")

const DIR_META := &"on_fire_panic_dir"
const TIMER_META := &"on_fire_panic_timer"
const RETARGET_MIN := 0.35
const RETARGET_MAX := 0.95
const DEFAULT_SPEED := 5.5


static func should_panic(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if not (host is CharacterBody3D):
		return false
	if not OnFireStatusScript.is_on_fire(host):
		return false
	if BossGunResilienceScript.uses_boss_hud_poise(host):
		return false
	if host.has_method("is_defeated") and host.is_defeated():
		return false
	return true


## Updates stored panic heading; returns flat unit direction.
static func tick_direction(body: CharacterBody3D, delta: float) -> Vector3:
	if body == null:
		return Vector3.FORWARD
	var timer := float(body.get_meta(TIMER_META, 0.0)) - delta
	var dir := body.get_meta(DIR_META, Vector3.ZERO) as Vector3
	dir.y = 0.0
	if timer <= 0.0 or dir.length_squared() < 0.0001:
		var angle := randf() * TAU
		dir = Vector3(cos(angle), 0.0, sin(angle))
		timer = randf_range(RETARGET_MIN, RETARGET_MAX)
		body.set_meta(DIR_META, dir)
	body.set_meta(TIMER_META, timer)
	return dir.normalized()


static func clear(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.has_meta(DIR_META):
		body.remove_meta(DIR_META)
	if body.has_meta(TIMER_META):
		body.remove_meta(TIMER_META)
