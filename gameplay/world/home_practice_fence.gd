extends Node3D
class_name HomePracticeFence

const PracticeTargetFactoryScript := preload("res://gameplay/target/practice_target_factory.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const DECORATIVE_PROP_NAMES: Array[StringName] = [&"TinCan", &"GlassBottle", &"TargetBoard"]
const PLAYER_SPEAKER := "Groyper"
const NO_GUN_LINE := "You need a gun"

const TARGET_SPECS: Array[Dictionary] = [
	{"style": "can", "offset": Vector3(-0.55, 1.22, 0.04)},
	{"style": "bottle", "offset": Vector3(0.15, 1.26, 0.02)},
	{
		"style": "board",
		"transform": Transform3D(
			Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)),
			Vector3(0.82, 1.05, 0.06)
		),
	},
]

var _manager: SoloPracticeManager
var _interact_area: Area3D
var _player_in_range: Node3D
var _scorables: Array[TargetScorable] = []


func setup(manager: SoloPracticeManager) -> void:
	_manager = manager
	_setup_interact_area()
	restore_decorative_targets()


func get_interact_hint() -> String:
	if _manager != null and _manager.is_active():
		return ""
	return "Practice the pistol"


func interact(player: Node3D) -> void:
	if player == null or _manager == null or _manager.is_active():
		return
	if not PlayerInventory.owns_weapon_type(GroyperWeaponsScript.Id.REVOLVER):
		_show_no_gun_dialog(player)
		return
	_manager.request_start(self, player)


func _show_no_gun_dialog(player: Node3D) -> void:
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)
	DialogManager.show_dialog(
		PLAYER_SPEAKER,
		NO_GUN_LINE,
		func() -> void:
			_end_no_gun_dialog(player)
	)


func _end_no_gun_dialog(player: Node3D) -> void:
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func reset_scorable_targets() -> Array[TargetScorable]:
	_clear_scorables()
	_hide_decorative_targets()

	for spec in TARGET_SPECS:
		var prop: TargetScorable = PracticeTargetFactoryScript.create_scorable(spec["style"])
		add_child(prop)
		if spec.has("transform"):
			prop.transform = spec["transform"]
		else:
			prop.position = spec["offset"]
		if prop.has_signal("scored") and _manager != null:
			prop.scored.connect(_manager.on_target_scored)
		_scorables.append(prop)

	return _scorables


func restore_decorative_targets() -> void:
	_clear_scorables()
	for child in get_children():
		if child.name in DECORATIVE_PROP_NAMES:
			child.visible = true
			if child is RigidBody3D:
				(child as RigidBody3D).freeze = true


func _hide_decorative_targets() -> void:
	for child in get_children():
		if child.name in DECORATIVE_PROP_NAMES:
			child.visible = false


func _clear_scorables() -> void:
	for scorable in _scorables:
		if is_instance_valid(scorable):
			scorable.queue_free()
	_scorables.clear()


func _setup_interact_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.monitorable = false
	add_child(_interact_area)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 2.5, 3.5)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.1, 1.8)
	_interact_area.add_child(shape_node)

	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
