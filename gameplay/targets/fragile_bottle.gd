extends "res://gameplay/world/tabletop_prop.gd"

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const KNOCK_SOUND_SPEED := 0.55
const KNOCK_SOUND_COOLDOWN := 0.18

var _broken := false
var _knock_sound_cooldown := 0.0


func _ready() -> void:
	super._ready()
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_knock_body_entered)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_knock_sound_cooldown = maxf(_knock_sound_cooldown - delta, 0.0)


func _on_knock_body_entered(body: Node) -> void:
	if _broken or freeze or body == self:
		return
	if linear_velocity.length() < KNOCK_SOUND_SPEED and angular_velocity.length() < 0.8:
		return
	if _knock_sound_cooldown > 0.0:
		return
	_knock_sound_cooldown = KNOCK_SOUND_COOLDOWN
	GameAudioScript.play_glass_bottle_knock(self, global_position)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _broken:
		return
	_broken = true

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

	ImpactFXScript.spawn_glass_shatter(self, hit_position, normal, direction)
	queue_free()
