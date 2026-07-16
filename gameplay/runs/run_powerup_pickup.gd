extends Area3D

## Stub timed buff pickup for roguelike runs. Wire real player stat hooks later.

@export var display_name := "Powerup"
@export var duration := 20.0
@export var stat_key := &"move_speed"
@export var stat_bonus := 0.15

var _collected := false
var _player_in_range: Node3D


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	if _collected:
		return ""
	return "Take %s" % display_name


func interact(player: Node3D) -> void:
	if _collected or player == null:
		return
	_collected = true
	monitoring = false
	if player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	_apply_stub_buff(player)
	queue_free()


func _apply_stub_buff(player: Node3D) -> void:
	# Placeholder: stash on player meta so future systems can read active buffs.
	var buffs: Array = []
	if player.has_meta("run_powerups"):
		buffs = player.get_meta("run_powerups")
	buffs.append({
		"stat_key": stat_key,
		"stat_bonus": stat_bonus,
		"expires_at_msec": Time.get_ticks_msec() + int(duration * 1000.0),
		"display_name": display_name,
	})
	player.set_meta("run_powerups", buffs)
	if player.has_method("get_raid_hud"):
		var hud: Node = player.get_raid_hud()
		if hud != null and hud.has_method("show_zone_title"):
			hud.show_zone_title(display_name, 1.6)


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
