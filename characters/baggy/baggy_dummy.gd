extends CharacterBody3D

## Passive armory damage-trial dummy (Home-Run-Bat style).
## Terminal toggles the minigame on. First lethal hit starts a 5s absorb window;
## knockback is banked and released as one launch when the timer ends.

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const DuelHitTestScript := preload("res://gameplay/duel/duel_hit_test.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")
const FlyingKickFXScript := preload("res://gameplay/fx/flying_kick_fx.gd")
const ExplosionCameraShakeScript := preload("res://gameplay/fx/explosion_camera_shake.gd")
const AlertSymbolFXScript := preload("res://gameplay/fx/alert_symbol_fx.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const MAX_HEALTH := 1
const ABSORB_DURATION := 5.0
const DEATH_HOLD := 1.35
const GRAVITY := 18.0
const FACING_SPEED := 10.0
## Baggy.glb mesh imports with +90° yaw. +90° (not -90°) lines his face up with
## facing_yaw_for_direction — -90° left him looking 180° away from the player.
const MESH_YAW_CORRECTION := PI * 0.5
## Live knockback during the absorb window is crushed; impulses bank here instead.
const ABSORB_LIVE_KNOCKBACK_SCALE := 0.04
const STORED_KNOCKBACK_SCALE := 1.0
const STORED_KNOCKBACK_MAX_SPEED := 42.0

const COLLISION_RADIUS := 0.38
const COLLISION_HEIGHT := 1.6
const COLLISION_CENTER_Y := 0.9
const HITBOX_RADIUS := 0.42
const HITBOX_HALF_HEIGHT := 0.95
const FLOAT_LABEL_Y := 2.35

const PLACE_1ST_DIR := (
	"res://Assets/FX/PNG/Symbols/symbol_place_1st_001/symbol_place_1st_001_large_yellow"
)
const WOW_DIR := "res://Assets/FX/PNG/Symbols/symbol_wow_text_001/symbol_wow_text_001_large_yellow"
const COIN_BURST_DIR := (
	"res://Assets/FX/PNG/Magic Bursts/directional_coin_burst_001/directional_coin_burst_001_large_yellow"
)

static var _place_1st_frames: SpriteFrames
static var _wow_frames: SpriteFrames
static var _coin_burst_frames: SpriteFrames

var _minigame_active := false
var _health := MAX_HEALTH
var _absorbing := false
var _finishing := false
var _defeated := false
var _window_total := 0
var _window_timer := 0.0
var _death_timer := 0.0
var _last_hit_dir := Vector3.FORWARD
var _spawn_origin := Vector3.ZERO
var _scoreboard: Node = null
var _stored_knockback := Vector3.ZERO

var _collision: CollisionShape3D
var _model: Node3D
var _body_hit_marker: Node3D
var _float_label: Label3D


func configure_scoreboard(scoreboard: Node) -> void:
	_scoreboard = scoreboard


func is_minigame_active() -> bool:
	return _minigame_active


func set_minigame_active(active: bool) -> void:
	if active == _minigame_active:
		return
	if active:
		_start_minigame()
	else:
		_stop_minigame()


func toggle_minigame() -> bool:
	set_minigame_active(not _minigame_active)
	return _minigame_active


func _ready() -> void:
	add_to_group("baggy_dummy")
	# Root stays identity — facing lives only on Model (avoids moonwalk).
	global_rotation = Vector3.ZERO
	_collision = get_node_or_null("CollisionShape3D") as CollisionShape3D
	_model = get_node_or_null("Model") as Node3D
	_body_hit_marker = get_node_or_null("BulletHitbox") as Node3D
	_configure_collision()
	GroyperBodyUtilsScript.configure_ground_physics(self)
	_center_model_pivot()
	if _model != null:
		_model.rotation.y = get_model_facing_yaw_for_direction(Vector3.FORWARD)
	_ensure_float_label()
	_spawn_origin = global_position
	_set_hittable(false)
	call_deferred("_finish_spawn")


func _finish_spawn() -> void:
	if not is_inside_tree():
		return
	global_rotation = Vector3.ZERO
	snap_to_floor()
	_spawn_origin = global_position
	_orient_toward_player(true)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if not _finishing:
		_orient_toward_player(false, delta)

	if _finishing:
		move_and_slide()
		_death_timer -= delta
		if _death_timer <= 0.0:
			_revive()
		return

	if _absorbing:
		# Crush any residual live knockback so he stays plantable during the window.
		velocity.x *= ABSORB_LIVE_KNOCKBACK_SCALE
		velocity.z *= ABSORB_LIVE_KNOCKBACK_SCALE
		_window_timer -= delta
		_update_float_label()
		if _window_timer <= 0.0:
			_finish_absorb_window()
			return

	move_and_slide()


func snap_to_floor() -> void:
	GroyperBodyUtilsScript.snap_character_to_floor(self)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	return GroyperBodyUtilsScript.facing_yaw_for_direction(direction) + MESH_YAW_CORRECTION


func drops_kill_loot() -> bool:
	return false


func drops_weapon_on_death() -> bool:
	return false


func is_defeated() -> bool:
	return not _minigame_active or _defeated or _finishing


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if not _minigame_active or _finishing or _defeated:
		return

	var hit_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	if hit_dir.length_squared() > 0.0001:
		_last_hit_dir = hit_dir.normalized()

	if _absorbing:
		_absorb_hit(hit_info)
		return

	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = int(result.health)
	if (
		not bool(hit_info.get("lightning_bolt_hit", false))
		and not bool(hit_info.get("fire_burn", false))
	):
		CombatHitFlashScript.flash_damage(self)
	if bool(result.killed):
		# Lethal path skips live knockback — bank the opening hit for the end launch.
		_store_knockback_from_hit(hit_info)
		_start_absorb_window(int(result.damage))


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if not _minigame_active or _finishing or _defeated:
		return false
	var capsule := get_bullet_capsule()
	return DuelHitTestScript.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func get_bullet_capsule() -> Dictionary:
	if _body_hit_marker != null:
		return {
			"center": _body_hit_marker.global_position,
			"half_height": HITBOX_HALF_HEIGHT,
			"radius": HITBOX_RADIUS,
			"axis": Vector3.UP,
			"source": "editor_marker",
		}
	return {
		"center": global_position + Vector3(0.0, COLLISION_CENTER_Y, 0.0),
		"half_height": COLLISION_HEIGHT * 0.5,
		"radius": COLLISION_RADIUS,
		"axis": Vector3.UP,
		"source": "fallback_constant",
	}


func _start_minigame() -> void:
	_minigame_active = true
	_reset_trial_state(false)
	_set_hittable(true)
	_orient_toward_player(true)
	if _float_label != null:
		_float_label.visible = true
		_float_label.modulate = Color(0.65, 0.95, 0.7, 1.0)
		_float_label.text = "READY"


func _stop_minigame() -> void:
	_minigame_active = false
	_reset_trial_state(true)
	_set_hittable(false)
	if _float_label != null:
		_float_label.visible = false


func _set_hittable(hittable: bool) -> void:
	if hittable:
		if not is_in_group("duel_target"):
			add_to_group("duel_target")
	elif is_in_group("duel_target"):
		remove_from_group("duel_target")


func _absorb_hit(hit_info: Dictionary) -> void:
	# High fake health so shared hit FX/chip resolve without killing or looting.
	var before_vel := velocity
	var result := BulletHitDamageScript.process_hit(self, hit_info, 999, 999)
	_window_total += int(result.damage)
	# Undo live knockback from process_hit; bank the impulse instead.
	velocity.x = before_vel.x * ABSORB_LIVE_KNOCKBACK_SCALE
	velocity.z = before_vel.z * ABSORB_LIVE_KNOCKBACK_SCALE
	_store_knockback_from_hit(hit_info)
	CombatHitFlashScript.flash_damage(self)
	_update_float_label()


func _store_knockback_from_hit(hit_info: Dictionary) -> void:
	var shot_dir: Vector3 = hit_info.get("direction", _last_hit_dir)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001:
		shot_dir = _last_hit_dir
		shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001:
		shot_dir = Vector3.FORWARD
	else:
		shot_dir = shot_dir.normalized()

	var knockback_speed := float(
		hit_info.get("knockback_speed", BulletHitDamageScript.BODY_KNOCKBACK_SPEED)
	)
	var knockback_up := float(
		hit_info.get("knockback_up", BulletHitDamageScript.BODY_KNOCKBACK_UP)
	)
	_stored_knockback.x += shot_dir.x * knockback_speed * STORED_KNOCKBACK_SCALE
	_stored_knockback.z += shot_dir.z * knockback_speed * STORED_KNOCKBACK_SCALE
	_stored_knockback.y = maxf(_stored_knockback.y, knockback_up * STORED_KNOCKBACK_SCALE)


func _apply_stored_knockback() -> void:
	var horizontal := Vector2(_stored_knockback.x, _stored_knockback.z)
	if horizontal.length_squared() > STORED_KNOCKBACK_MAX_SPEED * STORED_KNOCKBACK_MAX_SPEED:
		horizontal = horizontal.limit_length(STORED_KNOCKBACK_MAX_SPEED)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	velocity.y = maxf(velocity.y, _stored_knockback.y)
	if horizontal.length_squared() > 0.0001:
		_last_hit_dir = Vector3(horizontal.x, 0.0, horizontal.y).normalized()
	_stored_knockback = Vector3.ZERO


func _start_absorb_window(seed_damage: int) -> void:
	_absorbing = true
	_health = 0
	_window_total = maxi(seed_damage, 0)
	_window_timer = ABSORB_DURATION
	_ensure_float_label()
	if _float_label != null:
		_float_label.visible = true
		_float_label.modulate = Color(1.0, 0.95, 0.45, 1.0)
	_update_float_label()


func _finish_absorb_window() -> void:
	_absorbing = false
	_finishing = true
	_defeated = true
	_death_timer = DEATH_HOLD
	_set_hittable(false)
	if _collision != null:
		_collision.disabled = true

	_apply_stored_knockback()

	var impact_pos := global_position + Vector3(0.0, COLLISION_CENTER_Y, 0.0)
	FlyingKickFXScript.spawn_impact(get_parent(), impact_pos, _last_hit_dir)
	ExplosionCameraShakeScript.shake_nearby(self, impact_pos, 4.5, 1.25)

	var is_record := false
	if _scoreboard != null and _scoreboard.has_method("record_baggy_score"):
		is_record = bool(_scoreboard.record_baggy_score(_window_total))

	if is_record:
		_play_record_fx(impact_pos)

	if _float_label != null:
		_float_label.text = str(_window_total)
		_float_label.modulate = Color(1.0, 0.85, 0.25, 1.0)

	if _model != null:
		_model.visible = false


func _play_record_fx(impact_pos: Vector3) -> void:
	var parent := get_parent()
	if parent == null:
		parent = self
	var above := impact_pos + Vector3(0.0, 0.85, 0.0)
	AlertSymbolFXScript.spawn_above_frames(parent, above, _get_place_1st_frames())
	AlertSymbolFXScript.spawn_above_frames(
		parent,
		above + Vector3(0.0, 0.55, 0.0),
		_get_wow_frames()
	)
	var coin_frames := _get_coin_burst_frames()
	if coin_frames != null and coin_frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) > 0:
		AlertSymbolFXScript.spawn_above_frames(parent, impact_pos, coin_frames)


func _revive() -> void:
	_finishing = false
	_defeated = false
	_absorbing = false
	_health = MAX_HEALTH
	_window_total = 0
	_window_timer = 0.0
	_death_timer = 0.0
	_stored_knockback = Vector3.ZERO
	global_rotation = Vector3.ZERO
	global_position = _spawn_origin
	velocity = Vector3.ZERO
	if _collision != null:
		_collision.disabled = false
	if _model != null:
		_model.visible = true
	BulletHitDamageScript.clear_chip_damage(self)
	snap_to_floor()
	_orient_toward_player(true)

	if _minigame_active:
		_set_hittable(true)
		CombatHitFlashScript.flash_damage(self)
		if _float_label != null:
			_float_label.visible = true
			_float_label.modulate = Color(0.65, 0.95, 0.7, 1.0)
			_float_label.text = "READY"
	else:
		_set_hittable(false)
		if _float_label != null:
			_float_label.visible = false


func _reset_trial_state(hide_label: bool) -> void:
	_absorbing = false
	_finishing = false
	_defeated = false
	_health = MAX_HEALTH
	_window_total = 0
	_window_timer = 0.0
	_death_timer = 0.0
	_stored_knockback = Vector3.ZERO
	velocity = Vector3.ZERO
	global_rotation = Vector3.ZERO
	global_position = _spawn_origin
	if _collision != null:
		_collision.disabled = false
	if _model != null:
		_model.visible = true
	BulletHitDamageScript.clear_chip_damage(self)
	if hide_label and _float_label != null:
		_float_label.visible = false
	snap_to_floor()


func _orient_toward_player(instant: bool = false, delta: float = 0.0) -> void:
	if _model == null:
		return
	# Never rotate the CharacterBody3D root — Model-only yaw prevents moonwalk.
	global_rotation = Vector3.ZERO
	var player := _resolve_player()
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(to_player.normalized())
	if instant or delta <= 0.0:
		_model.rotation.y = target_yaw
	else:
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _center_model_pivot() -> void:
	## Editor placement offset the Model in X; yaw then orbits off-center from the body.
	if _model == null:
		return
	_model.position.x = 0.0
	_model.position.z = 0.0
	# Keep authored Y lift / uniform scale from the scene.


func _resolve_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group("overworld_player") as Node3D
	if player != null:
		return player
	return tree.get_first_node_in_group("player") as Node3D


func _configure_collision() -> void:
	if _collision == null:
		return
	var capsule := CapsuleShape3D.new()
	capsule.radius = COLLISION_RADIUS
	capsule.height = COLLISION_HEIGHT
	_collision.shape = capsule
	_collision.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, COLLISION_CENTER_Y, 0.0))


func _ensure_float_label() -> void:
	if _float_label != null and is_instance_valid(_float_label):
		return
	_float_label = get_node_or_null("DamageFloat") as Label3D
	if _float_label != null:
		return
	_float_label = Label3D.new()
	_float_label.name = "DamageFloat"
	_float_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_float_label.font_size = 64
	_float_label.outline_size = 12
	_float_label.pixel_size = 0.012
	_float_label.modulate = Color(1.0, 0.95, 0.45, 1.0)
	_float_label.position = Vector3(0.0, FLOAT_LABEL_Y, 0.0)
	_float_label.visible = false
	add_child(_float_label)


func _update_float_label() -> void:
	if _float_label == null:
		return
	var secs := ceili(maxf(_window_timer, 0.0))
	_float_label.text = "%d  (%ds)" % [_window_total, secs]
	_float_label.visible = true


static func _get_place_1st_frames() -> SpriteFrames:
	if _place_1st_frames == null:
		_place_1st_frames = FxFramesLoaderScript.from_png_dir(PLACE_1ST_DIR, 24.0)
	return _place_1st_frames


static func _get_wow_frames() -> SpriteFrames:
	if _wow_frames == null:
		_wow_frames = FxFramesLoaderScript.from_png_dir(WOW_DIR, 24.0)
	return _wow_frames


static func _get_coin_burst_frames() -> SpriteFrames:
	if _coin_burst_frames == null:
		_coin_burst_frames = FxFramesLoaderScript.from_png_dir(COIN_BURST_DIR, 26.0)
	return _coin_burst_frames
