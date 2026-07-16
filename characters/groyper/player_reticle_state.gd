extends RefCounted
## Shared reticle / scope-aim state for the Groyper player forks
## (groyper_overworld_player.gd + groyper_player.gd).
## Pure state + math: no node access, no Input reads, no viewport queries.
## The players own the Camera3D / Control nodes and tuning values; they pass
## values in per call and apply the returned offsets themselves.
##
## Feel constants that differ between modes (mouse accel, drag, max speed,
## smooth, kick defaults) stay in each player and arrive as parameters.
## RECOIL_RECOVERY is identical in both forks, so it lives here.

const RECOIL_RECOVERY := 9.0

## Reticle screen-space state (pixels, relative to screen center).
var reticle_offset := Vector2.ZERO
var reticle_offset_target := Vector2.ZERO
var reticle_velocity := Vector2.ZERO
var reticle_recoil := Vector2.ZERO
var reticle_limit_px: float = 180.0

## Scope aim state (radians).
var scope_yaw: float = 0.0
var scope_pitch: float = 0.0
var scope_recoil_yaw: float = 0.0
var scope_recoil_pitch: float = 0.0
var scope_blend: float = 0.0

## Run-and-gun bloom: crosshair spread half-angle in degrees. Grows with
## movement and shots, recovers toward the resting target at the gun's
## handling rate (degrees/second).
var bloom_deg: float = 0.0
## How fast bloom expands toward a larger target (movement/ADS changes).
const BLOOM_GROW_SMOOTH := 14.0


func update_limit(viewport_size: Vector2, max_screen_fraction: float) -> void:
	reticle_limit_px = minf(viewport_size.x, viewport_size.y) * max_screen_fraction


func reset_reticle() -> void:
	reticle_offset = Vector2.ZERO
	reticle_offset_target = Vector2.ZERO
	reticle_velocity = Vector2.ZERO


func clamp_offset(offset: Vector2) -> Vector2:
	if offset.length() <= reticle_limit_px:
		return offset
	return offset.normalized() * reticle_limit_px


func add_mouse_motion(relative: Vector2, mouse_accel: float) -> void:
	reticle_velocity += relative * mouse_accel


## Per-frame decay of shot recoil (reticle kick + scope kick).
func decay_recoil(delta: float) -> void:
	var step := 1.0 - exp(-RECOIL_RECOVERY * delta)
	reticle_recoil = reticle_recoil.lerp(Vector2.ZERO, step)
	scope_recoil_yaw = lerpf(scope_recoil_yaw, 0.0, step)
	scope_recoil_pitch = lerpf(scope_recoil_pitch, 0.0, step)


## Kills outward velocity when the offset target hits the reticle boundary.
func apply_boundary_velocity() -> void:
	var clamped := clamp_offset(reticle_offset_target)
	if clamped.is_equal_approx(reticle_offset_target):
		return
	var push := reticle_offset_target - clamped
	if push.length_squared() < 0.001:
		return
	var boundary_normal := push.normalized()
	var outward := reticle_velocity.dot(boundary_normal)
	if outward > 0.0:
		reticle_velocity -= boundary_normal * outward
	reticle_offset_target = clamped


## Scope-aim active: reticle collapses back to screen center.
func update_reticle_scoped(delta: float, smooth: float) -> Vector2:
	reticle_velocity = Vector2.ZERO
	reticle_offset_target = Vector2.ZERO
	var step := 1.0 - exp(-smooth * delta)
	reticle_offset = reticle_offset.lerp(Vector2.ZERO, step)
	return reticle_offset


## Normal free-reticle update. Returns the new screen offset to display.
func update_reticle(delta: float, drag: float, max_speed_px: float, smooth: float) -> Vector2:
	reticle_velocity *= exp(-drag * delta)
	var speed := reticle_velocity.length()
	if speed > max_speed_px:
		reticle_velocity = reticle_velocity * (max_speed_px / speed)

	reticle_offset_target += reticle_velocity * delta
	apply_boundary_velocity()

	var step := 1.0 - exp(-smooth * delta)
	var target := clamp_offset(reticle_offset_target + reticle_recoil)
	reticle_offset = reticle_offset.lerp(target, step)
	return reticle_offset


func apply_scope_look(
	relative: Vector2, sensitivity: float, yaw_max_rad: float, pitch_max_rad: float
) -> void:
	scope_yaw = clampf(scope_yaw - relative.x * sensitivity, -yaw_max_rad, yaw_max_rad)
	scope_pitch = clampf(scope_pitch - relative.y * sensitivity, -pitch_max_rad, pitch_max_rad)


func seed_scope_from_reticle(yaw_max_deg: float, pitch_max_deg: float) -> void:
	if reticle_limit_px <= 0.0:
		reset_reticle()
		return
	scope_yaw = deg_to_rad(reticle_offset.x / reticle_limit_px * yaw_max_deg)
	scope_pitch = deg_to_rad(-reticle_offset.y / reticle_limit_px * pitch_max_deg)
	reset_reticle()


func reset_scope() -> void:
	scope_yaw = 0.0
	scope_pitch = 0.0
	scope_recoil_yaw = 0.0
	scope_recoil_pitch = 0.0


## Returns the new blend so the caller can push it to its scope overlay.
func update_scope_blend(delta: float, target: float, smooth: float) -> float:
	var step := 1.0 - exp(-smooth * delta)
	scope_blend = lerpf(scope_blend, target, step)
	return scope_blend


## Shot kick while scope aim is active (kick in reticle px, converted to rad).
func apply_scope_shot_recoil(kick: float, randomness: float) -> void:
	var kick_rad := deg_to_rad(kick * 0.035)
	if randomness >= 0.95:
		var angle := randf() * TAU
		var magnitude := kick_rad * randf_range(0.8, 1.45)
		scope_recoil_yaw += cos(angle) * magnitude
		scope_recoil_pitch += sin(angle) * magnitude
	else:
		scope_recoil_pitch += kick_rad
		scope_recoil_yaw += deg_to_rad(randf_range(-kick * randomness, kick * randomness) * 0.035)


## Shot kick on the free reticle (screen-space px). Decays via decay_recoil().
func apply_reticle_shot_recoil(kick: float, randomness: float) -> void:
	if randomness >= 0.95:
		var angle := randf() * TAU
		var magnitude := kick * randf_range(0.8, 1.45)
		reticle_recoil += Vector2(cos(angle), sin(angle)) * magnitude
	else:
		reticle_recoil.y += kick
		reticle_recoil.x += randf_range(-kick * randomness, kick * randomness)


## Per-frame bloom sim. The resting target is base + move penalty (scaled by
## how fast the player is moving), all multiplied by the ADS scale. Expansion
## is snappy; recovery from shot bloom shrinks at the gun's handling rate.
func update_bloom(
	delta: float,
	base_deg: float,
	move_deg: float,
	move_fraction: float,
	ads_scale: float,
	handling_deg_per_sec: float,
	max_deg: float
) -> float:
	var target := (base_deg + move_deg * clampf(move_fraction, 0.0, 1.0)) * ads_scale
	target = minf(target, max_deg)
	if bloom_deg < target:
		var grow_step := 1.0 - exp(-BLOOM_GROW_SMOOTH * delta)
		bloom_deg = lerpf(bloom_deg, target, grow_step)
	else:
		bloom_deg = maxf(bloom_deg - handling_deg_per_sec * delta, target)
	return bloom_deg


## Instant bloom growth from firing a shot.
func add_shot_bloom(shot_deg: float, max_deg: float) -> void:
	bloom_deg = minf(bloom_deg + shot_deg, max_deg)


func reset_bloom(base_deg: float = 0.0) -> void:
	bloom_deg = base_deg


## Converts the bloom half-angle to a screen radius in pixels for the given
## camera vertical FOV and viewport height (Godot cameras are fov-vertical).
static func bloom_deg_to_px(bloom: float, camera_fov_deg: float, viewport_height: float) -> float:
	var half_fov := deg_to_rad(maxf(camera_fov_deg, 1.0)) * 0.5
	return tan(deg_to_rad(bloom)) / tan(half_fov) * viewport_height * 0.5
