extends Area3D

## Debug interactable: spawn combat targets and trigger common test helpers.

const TOWN_NPC_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
const BANDIT_NPC_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

const TARGET_GROUP := &"armory_test_target"

var _player_in_range: Node3D
var _menu: CanvasLayer
var _action_list: VBoxContainer
var _busy := false
var _target_spawn: Marker3D
var _decal_wall: Node3D
var _spawned_targets: Array[Node] = []


func configure(target_spawn: Marker3D, decal_wall: Node3D) -> void:
	_target_spawn = target_spawn
	_decal_wall = decal_wall


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_ensure_visuals()
	_ensure_menu()


func get_interact_hint() -> String:
	if _busy:
		return ""
	return "Use Terminal"


func interact(player: Node3D) -> void:
	if _busy or player == null:
		return
	_player_in_range = player
	_busy = true
	_open_menu()


func _ensure_visuals() -> void:
	if get_node_or_null("MeshInstance3D") == null:
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 1.6, 0.55)
		mesh_instance.mesh = box
		mesh_instance.position = Vector3(0.0, 0.8, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.2, 0.24, 1.0)
		mat.metallic = 0.55
		mat.roughness = 0.35
		mesh_instance.material_override = mat
		add_child(mesh_instance)
	if get_node_or_null("CollisionShape3D") == null:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.4, 1.8, 1.0)
		shape_node.shape = shape
		shape_node.position = Vector3(0.0, 0.9, 0.0)
		add_child(shape_node)
	if get_node_or_null("Label3D") == null:
		var label := Label3D.new()
		label.name = "Label3D"
		label.text = "TERMINAL"
		label.font_size = 48
		label.outline_size = 8
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, 2.05, 0.0)
		label.modulate = Color(0.55, 0.95, 0.7, 1.0)
		add_child(label)


func _ensure_menu() -> void:
	_menu = get_node_or_null("TerminalMenu") as CanvasLayer
	if _menu != null:
		_action_list = _menu.get_node_or_null("Root/Center/Panel/Margin/VBox/Actions") as VBoxContainer
		if _action_list == null:
			_action_list = _menu.get_node_or_null("Root/Panel/Margin/VBox/Actions") as VBoxContainer
		return

	_menu = CanvasLayer.new()
	_menu.name = "TerminalMenu"
	_menu.layer = 120
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu.hide()
	add_child(_menu)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu.add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_gui_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(320, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Armory Terminal"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_close_menu)
	header.add_child(close_btn)

	_action_list = VBoxContainer.new()
	_action_list.name = "Actions"
	_action_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_action_list)

	_rebuild_actions()


func _rebuild_actions() -> void:
	for child in _action_list.get_children():
		child.queue_free()

	var actions: Array[Dictionary] = [
		{"label": "Spawn Townsperson", "callable": _spawn_townsperson},
		{"label": "Spawn Bandit", "callable": _spawn_bandit},
		{"label": "Despawn Targets", "callable": _despawn_targets},
		{"label": "Refill Ammo", "callable": _refill_ammo},
		{"label": "Heal Player", "callable": _heal_player},
		{"label": "Clear Bullet Holes", "callable": _clear_bullet_holes},
	]
	for action in actions:
		var button := Button.new()
		button.text = str(action["label"])
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_action_pressed.bind(action["callable"] as Callable))
		_action_list.add_child(button)


func _open_menu() -> void:
	_menu.show()
	set_process_input(true)
	DebugUiGate.begin(_menu)


func _close_menu() -> void:
	if not _busy:
		return
	_busy = false
	set_process_input(false)
	if _menu != null:
		_menu.hide()
		DebugUiGate.end(_menu)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if not _busy:
		return
	if event.is_action_pressed("ui_cancel") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	):
		_close_menu()
		get_viewport().set_input_as_handled()


func _on_action_pressed(action: Callable) -> void:
	if action.is_valid():
		action.call()
	_close_menu()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_menu()


func _spawn_point() -> Transform3D:
	if _target_spawn != null:
		return _target_spawn.global_transform
	var xform := global_transform
	xform.origin += -global_transform.basis.z * 4.0
	return xform


func _spawn_npc(scene: PackedScene) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null or scene == null:
		return
	var npc: Node3D = scene.instantiate() as Node3D
	if npc == null:
		return
	parent.add_child(npc)
	npc.global_transform = _spawn_point()
	npc.add_to_group(TARGET_GROUP)
	_spawned_targets.append(npc)
	if npc.has_method("snap_to_floor"):
		npc.call_deferred("snap_to_floor")


func _spawn_townsperson() -> void:
	_spawn_npc(TOWN_NPC_SCENE)


func _spawn_bandit() -> void:
	_spawn_npc(BANDIT_NPC_SCENE)


func _despawn_targets() -> void:
	for target in _spawned_targets:
		if is_instance_valid(target):
			target.queue_free()
	_spawned_targets.clear()
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(TARGET_GROUP):
		if is_instance_valid(node):
			node.queue_free()


func _refill_ammo() -> void:
	var player := _player_in_range
	if player == null:
		return
	if player.has_method("rest_at_bonfire"):
		player.rest_at_bonfire()
		return
	if player.has_method("equip_weapon"):
		var weapon_id: Variant = player.get("_equipped_weapon")
		if weapon_id != null:
			player.set("_ammo", GroyperWeapons.get_max_ammo(int(weapon_id)))
			var hud: Variant = player.get("_ammo_hud")
			if hud != null and hud.has_method("sync_rounds"):
				hud.sync_rounds(player.get("_ammo"))


func _heal_player() -> void:
	var player := _player_in_range
	if player == null:
		return
	if player.has_method("heal") and player.has_method("get_max_health"):
		player.heal(int(player.get_max_health()))
	elif player.has_method("rest_at_bonfire"):
		player.rest_at_bonfire()


func _clear_bullet_holes() -> void:
	var wall := _decal_wall
	if wall == null:
		wall = get_tree().current_scene.get_node_or_null("DecalWall") as Node3D
	if wall == null:
		return
	var holes := wall.get_node_or_null("BulletHoles")
	if holes == null:
		return
	for child in holes.get_children():
		child.queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
		_player_in_range = null
