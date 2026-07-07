extends GroypetteCivilianNpc
class_name GroypetteNpc

const FLIRTY_COOLDOWN := 6.0

@onready var _interact_area: Area3D = $InteractArea

var _flirty_cooldown := 0.0


func _on_actor_ready() -> void:
	super._on_actor_ready()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_flirty_cooldown = maxf(_flirty_cooldown - delta, 0.0)


func interact(player: Node3D) -> void:
	if _defeated or player == null or _flirty_cooldown > 0.0:
		return
	_flirty_cooldown = FLIRTY_COOLDOWN
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.0001:
		_model.rotation.y = MeshyLocomotionUtils.facing_yaw_for_direction(to_player.normalized())
	_play_flirty_voice()


func get_interact_hint() -> String:
	return ""


func _play_flirty_voice() -> void:
	_play_voice(GroypetteAudio.pick_flirty_voice(), 0.04)


func _on_defeated() -> void:
	if _interact_area != null:
		_interact_area.monitoring = false
		_interact_area.monitorable = false


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
