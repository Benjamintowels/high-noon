extends Area3D

## Debug interactable: spawn combat targets and trigger common test helpers.

const TOWN_NPC_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
const BANDIT_NPC_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const ENGINES_NPC_SCENE := preload("res://characters/fast/engines_npc.tscn")
const SHERIFF_NPC_SCENE := preload("res://characters/sheriff/sheriff_town_npc.tscn")
const REDO_NPC_SCENE := preload("res://characters/redo/redo_npc.tscn")
const PAVEL_NPC_SCENE := preload("res://characters/pavel/pavel_npc.tscn")
const UNDEAD_NPC_SCENE := preload("res://characters/undead/undead_npc.tscn")
const SKELETON_SCENE := preload("res://characters/enemies/skeleton_enemy.tscn")
const TC_BOSS_SCENE := preload("res://characters/tc/tc_boss.tscn")
const CHIEF_GETCHA_SCENE := preload("res://characters/chief_getcha/chief_getcha_npc.tscn")
const BAGGY_SCENE := preload("res://characters/baggy/baggy_dummy.tscn")
const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const BossHealthBarScript := preload("res://gameplay/ui/boss_health_bar.gd")
const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")
const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const ElementalGemPickupScript := preload("res://gameplay/world/elemental_gem_pickup.gd")
const RunLootPropScript := preload("res://gameplay/runs/run_loot_prop.gd")

const TARGET_GROUP := &"armory_test_target"
const TOWNSPERSON_GROUP_COUNT := 5
const TOWNSPERSON_GROUP_RADIUS := 1.45
const BURNABLE_CRATE_COUNT := 3
const BURNABLE_CRATE_RADIUS := 1.6
const ICE_BOWLING_COUNT := 4
const ICE_BOWLING_RADIUS := 1.2

var _player_in_range: Node3D
var _menu: CanvasLayer
var _action_list: VBoxContainer
var _busy := false
var _target_spawn: Marker3D
var _decal_wall: Node3D
var _baggy_spawn: Marker3D
var _spawned_targets: Array[Node] = []
var _baggy_last := 0
var _baggy_best := 0
var _score_label: Label3D
var _menu_score_label: Label


func configure(
	target_spawn: Marker3D,
	decal_wall: Node3D,
	baggy_spawn: Marker3D = null
) -> void:
	_target_spawn = target_spawn
	_decal_wall = decal_wall
	_baggy_spawn = baggy_spawn


## Returns true when `amount` sets a new session best for the Baggy damage trial.
func record_baggy_score(amount: int) -> bool:
	_baggy_last = maxi(amount, 0)
	var is_record := _baggy_last > _baggy_best
	if is_record:
		_baggy_best = _baggy_last
	_refresh_score_displays()
	return is_record


func get_baggy_last_score() -> int:
	return _baggy_last


func get_baggy_best_score() -> int:
	return _baggy_best


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
	_score_label = get_node_or_null("BaggyScoreLabel") as Label3D
	if _score_label == null:
		_score_label = Label3D.new()
		_score_label.name = "BaggyScoreLabel"
		_score_label.font_size = 36
		_score_label.outline_size = 8
		_score_label.pixel_size = 0.011
		_score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_score_label.position = Vector3(0.0, 2.45, 0.0)
		_score_label.modulate = Color(1.0, 0.9, 0.45, 1.0)
		add_child(_score_label)
	_refresh_score_displays()


func _ensure_menu() -> void:
	_menu = get_node_or_null("TerminalMenu") as CanvasLayer
	if _menu != null:
		_action_list = _find_action_list(_menu)
		_menu_score_label = _menu.get_node_or_null("Root/Center/Panel/Margin/VBox/BaggyScore") as Label
		if _menu_score_label == null:
			_menu_score_label = _menu.get_node_or_null("Root/Panel/Margin/VBox/BaggyScore") as Label
		_ensure_action_list_scrollable()
		_refresh_score_displays()
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
	panel.custom_minimum_size = Vector2(340, 520)
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

	_menu_score_label = Label.new()
	_menu_score_label.name = "BaggyScore"
	_menu_score_label.add_theme_font_size_override("font_size", 14)
	_menu_score_label.modulate = Color(1.0, 0.92, 0.55, 1.0)
	vbox.add_child(_menu_score_label)

	var scroll := ScrollContainer.new()
	scroll.name = "ActionScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(scroll)

	_action_list = VBoxContainer.new()
	_action_list.name = "Actions"
	_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_action_list)

	_rebuild_actions()
	_refresh_score_displays()


func _find_action_list(menu: CanvasLayer) -> VBoxContainer:
	var paths := [
		"Root/Center/Panel/Margin/VBox/ActionScroll/Actions",
		"Root/Center/Panel/Margin/VBox/Actions",
		"Root/Panel/Margin/VBox/ActionScroll/Actions",
		"Root/Panel/Margin/VBox/Actions",
	]
	for path in paths:
		var found := menu.get_node_or_null(path) as VBoxContainer
		if found != null:
			return found
	return null


## Hot-reload / already-built menus: wrap a bare Actions list in a ScrollContainer.
func _ensure_action_list_scrollable() -> void:
	if _action_list == null or _action_list.get_parent() is ScrollContainer:
		return
	var parent := _action_list.get_parent()
	if parent == null:
		return
	var index := _action_list.get_index()
	parent.remove_child(_action_list)

	var scroll := ScrollContainer.new()
	scroll.name = "ActionScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 360)
	parent.add_child(scroll)
	parent.move_child(scroll, index)

	_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_action_list)


func _rebuild_actions() -> void:
	for child in _action_list.get_children():
		child.queue_free()

	var baggy_active := _is_baggy_minigame_active()
	var actions: Array[Dictionary] = [
		{
			"label": "Stop Baggy Trial" if baggy_active else "Start Baggy Trial",
			"callable": _toggle_baggy_trial,
		},
		{"label": "Spawn Townsperson", "callable": _spawn_townsperson},
		{"label": "Spawn Townsperson Group (5)", "callable": _spawn_townsperson_group},
		{"label": "Spawn Ice Bowling Cluster (4)", "callable": _spawn_ice_bowling_cluster},
		{"label": "Spawn Burnable Crates (3)", "callable": _spawn_burnable_crates},
		{"label": "Spawn Bandit", "callable": _spawn_bandit},
		{"label": "Spawn Unarmed Bandit", "callable": _spawn_unarmed_bandit},
		{"label": "Spawn Engines", "callable": _spawn_engines},
		{"label": "Spawn Sheriff", "callable": _spawn_sheriff},
		{"label": "Spawn Redo", "callable": _spawn_redo},
		{"label": "Spawn Pavel", "callable": _spawn_pavel},
		{"label": "Spawn Undead", "callable": _spawn_undead},
		{"label": "Spawn Skeleton", "callable": _spawn_skeleton},
		{"label": "Spawn TC Boss", "callable": _spawn_tc_boss},
		{"label": "Spawn Chief Getcha", "callable": _spawn_chief_getcha},
		{"label": "Despawn Targets", "callable": _despawn_targets},
		{"label": "Refill Ammo", "callable": _refill_ammo},
		{"label": "Heal Player", "callable": _heal_player},
		{"label": "Clear Bullet Holes", "callable": _clear_bullet_holes},
	]
	# Elemental gem summons — only active catalog entries appear.
	for gem_id in ElementalGems.get_active_gem_ids():
		actions.append({
			"label": "Spawn %s" % ElementalGems.get_display_name(gem_id),
			"callable": _spawn_elemental_gem.bind(gem_id),
		})
	for action in actions:
		var button := Button.new()
		button.text = str(action["label"])
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_action_pressed.bind(action["callable"] as Callable))
		_action_list.add_child(button)


func _refresh_score_displays() -> void:
	var status := "ON" if _is_baggy_minigame_active() else "OFF"
	var score_text := "LAST %d  |  BEST %d" % [_baggy_last, _baggy_best]
	if _score_label != null and is_instance_valid(_score_label):
		_score_label.text = "BAGGY %s\n%s" % [status, score_text]
	if _menu_score_label != null and is_instance_valid(_menu_score_label):
		_menu_score_label.text = "Baggy Trial [%s] — %s" % [status, score_text]


func _open_menu() -> void:
	_rebuild_actions()
	_refresh_score_displays()
	_menu.show()
	set_process_input(true)
	DebugUiGate.begin(_menu)


func _resolve_baggy() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var baggy := tree.get_first_node_in_group("baggy_dummy")
	if baggy != null and is_instance_valid(baggy):
		return baggy
	return null


func _is_baggy_minigame_active() -> bool:
	return _resolve_baggy() != null


func _toggle_baggy_trial() -> void:
	var baggy := _resolve_baggy()
	if baggy != null:
		if baggy.is_in_group("baggy_dummy"):
			baggy.remove_from_group("baggy_dummy")
		baggy.queue_free()
	else:
		_spawn_baggy_trial()
	_refresh_score_displays()


func _spawn_baggy_trial() -> void:
	var parent := get_tree().current_scene if get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null or BAGGY_SCENE == null:
		return

	var baggy: Node3D = BAGGY_SCENE.instantiate() as Node3D
	if baggy == null:
		return
	parent.add_child(baggy)

	var spawn_origin := global_position - global_transform.basis.z * 4.0
	if _baggy_spawn != null:
		spawn_origin = _baggy_spawn.global_position
	elif _target_spawn != null:
		spawn_origin = _target_spawn.global_position
	# Root identity only — Baggy owns Model yaw. Marker yaw would moonwalk.
	baggy.global_position = spawn_origin
	baggy.global_rotation = Vector3.ZERO
	if baggy.has_method("configure_scoreboard"):
		baggy.configure_scoreboard(self)
	if baggy.has_method("set_minigame_active"):
		baggy.set_minigame_active(true)
	elif baggy.has_method("snap_to_floor"):
		baggy.call_deferred("snap_to_floor")


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


func _resolve_player() -> Node3D:
	if _player_in_range != null and is_instance_valid(_player_in_range):
		return _player_in_range
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node3D


## Town NPC facing writes world yaw onto Model without subtracting root yaw.
## Copying a marker's PI rotation onto the CharacterBody3D therefore moonwalks.
## `melee_only` must be applied before add_child so bandit _ready sees it.
func _spawn_npc(scene: PackedScene, aggro: bool = true, melee_only: bool = false) -> void:
	_spawn_npc_at(scene, _spawn_point().origin, aggro, melee_only)


func _spawn_npc_at(
	scene: PackedScene,
	origin: Vector3,
	aggro: bool = true,
	melee_only: bool = false
) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null or scene == null:
		return
	var npc: Node3D = scene.instantiate() as Node3D
	if npc == null:
		return
	if melee_only and "melee_only" in npc:
		npc.set("melee_only", true)
	parent.add_child(npc)
	npc.global_position = origin
	npc.global_rotation = Vector3.ZERO
	npc.add_to_group(TARGET_GROUP)
	_spawned_targets.append(npc)
	call_deferred("_finish_npc_spawn", npc, aggro)


func _finish_npc_spawn(npc: Node3D, aggro: bool) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if npc.has_method("snap_to_floor"):
		npc.snap_to_floor()
	_orient_npc_toward_player(npc)
	FloatingEnemyHealthBarScript.attach_to(npc)
	if aggro:
		_arm_npc_aggro(npc)


func _orient_npc_toward_player(npc: Node3D) -> void:
	var player := _resolve_player()
	if player == null:
		return
	var to_player := player.global_position - npc.global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return
	var direction := to_player.normalized()
	var model := npc.get_node_or_null("Model") as Node3D
	if model == null:
		return
	if npc.has_method("get_model_facing_yaw_for_direction"):
		model.rotation.y = npc.get_model_facing_yaw_for_direction(direction)
	else:
		model.rotation.y = GroyperBodyUtilsScript.facing_yaw_for_direction(direction)


func _arm_npc_aggro(npc: Node3D) -> void:
	var player := _resolve_player()
	if player == null:
		return
	# Prefer the strongest "open fire / rush now" entry each type exposes.
	if npc.has_method("arm_canyon_hostility"):
		npc.arm_canyon_hostility(player)
	elif npc.has_method("enter_melee_aggro"):
		npc.enter_melee_aggro(player)
	elif npc.has_method("set_faction_aggro_level"):
		npc.set_faction_aggro_level(3, player)
	elif npc.has_method("force_alert_to_player"):
		# Redo/Pavel find the player themselves (no args).
		npc.force_alert_to_player()


func _spawn_townsperson() -> void:
	_spawn_npc(TOWN_NPC_SCENE, true)


## Non-hostile cluster for lightning chain / AOE testing.
func _spawn_townsperson_group() -> void:
	var center := _spawn_point().origin
	for i in TOWNSPERSON_GROUP_COUNT:
		var angle := TAU * float(i) / float(TOWNSPERSON_GROUP_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * TOWNSPERSON_GROUP_RADIUS
		_spawn_npc_at(TOWN_NPC_SCENE, center + offset, false)


## Tight non-hostile ring for ice-block slide / shatter testing.
func _spawn_ice_bowling_cluster() -> void:
	var center := _spawn_point().origin
	for i in ICE_BOWLING_COUNT:
		var angle := TAU * float(i) / float(ICE_BOWLING_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * ICE_BOWLING_RADIUS
		_spawn_npc_at(TOWN_NPC_SCENE, center + offset, false)


## Crates that accumulate fire chip and break after enough burn.
func _spawn_burnable_crates() -> void:
	var parent := get_tree().current_scene if get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var center := _spawn_point().origin
	for i in BURNABLE_CRATE_COUNT:
		var angle := TAU * float(i) / float(BURNABLE_CRATE_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * BURNABLE_CRATE_RADIUS
		var prop: RigidBody3D = RunLootPropScript.new() as RigidBody3D
		if prop == null:
			continue
		if prop.has_method("setup"):
			prop.call("setup", false, 1.0)
		parent.add_child(prop)
		prop.global_position = center + offset + Vector3(0.0, 0.35, 0.0)
		prop.add_to_group(TARGET_GROUP)
		_spawned_targets.append(prop)


func _spawn_bandit() -> void:
	_spawn_npc(BANDIT_NPC_SCENE, true)


func _spawn_unarmed_bandit() -> void:
	_spawn_npc(BANDIT_NPC_SCENE, true, true)


func _spawn_engines() -> void:
	_spawn_npc(ENGINES_NPC_SCENE, true)


func _spawn_sheriff() -> void:
	_spawn_npc(SHERIFF_NPC_SCENE, true)


func _spawn_redo() -> void:
	_spawn_npc(REDO_NPC_SCENE, true)


func _spawn_pavel() -> void:
	_spawn_npc(PAVEL_NPC_SCENE, true)


func _spawn_undead() -> void:
	_spawn_npc(UNDEAD_NPC_SCENE, true)


func _spawn_skeleton() -> void:
	_spawn_npc(SKELETON_SCENE, true)


## TC auto-aggros from _finalize_spawn; attach boss HP bar like caves_boss_room.
func _spawn_tc_boss() -> void:
	var parent := get_tree().current_scene if get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null or TC_BOSS_SCENE == null:
		return
	var boss: Node3D = TC_BOSS_SCENE.instantiate() as Node3D
	if boss == null:
		return
	parent.add_child(boss)
	var spawn_xform := _spawn_point()
	boss.global_position = spawn_xform.origin
	boss.global_rotation = Vector3.ZERO
	boss.add_to_group(TARGET_GROUP)
	_spawned_targets.append(boss)
	call_deferred("_finish_tc_boss_spawn", boss)


func _finish_tc_boss_spawn(boss: Node3D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	if boss.has_method("snap_to_floor"):
		boss.snap_to_floor()
	_orient_npc_toward_player(boss)
	BossHealthBarScript.attach_to(boss, "TC")


## Instant fight via run_boss_mode — skips sit/talk and ChurchSanctifyQuest.
func _spawn_chief_getcha() -> void:
	var parent := get_tree().current_scene if get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null or CHIEF_GETCHA_SCENE == null:
		return
	var chief: Node3D = CHIEF_GETCHA_SCENE.instantiate() as Node3D
	if chief == null:
		return
	# Flag before add_child so deferred _finalize_spawn skips the sit pose.
	if "run_boss_mode" in chief:
		chief.set("run_boss_mode", true)
	var spawn_xform := _spawn_point()
	# Position before add_child: _ready can capture transform for sit hold.
	if parent is Node3D:
		chief.transform = (parent as Node3D).global_transform.affine_inverse() * Transform3D(Basis.IDENTITY, spawn_xform.origin)
	parent.add_child(chief)
	chief.global_position = spawn_xform.origin
	chief.global_rotation = Vector3.ZERO
	chief.add_to_group(TARGET_GROUP)
	_spawned_targets.append(chief)
	if chief.has_method("snap_to_floor"):
		chief.snap_to_floor()
	_orient_npc_toward_player(chief)
	# Defer so actor _finalize_spawn runs first; start_as_run_boss attaches HP bar.
	chief.call_deferred("start_as_run_boss", _resolve_player())


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
	var player := _resolve_player()
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
	var player := _resolve_player()
	if player == null:
		return
	if player.has_method("heal") and player.has_method("get_max_health"):
		player.heal(int(player.get_max_health()))
	elif player.has_method("rest_at_bonfire"):
		player.rest_at_bonfire()


func _spawn_elemental_gem(gem_id: StringName) -> void:
	if not ElementalGems.is_active(gem_id):
		return
	var parent := get_tree().current_scene if get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var from_pos := global_position + Vector3(0.0, 0.4, 0.0)
	var player := _resolve_player()
	if player != null:
		from_pos = player.global_position + Vector3(0.0, 0.9, 0.0)
	elif _target_spawn != null:
		from_pos = _target_spawn.global_position + Vector3(0.0, 0.4, 0.0)
	ElementalGemPickupScript.spawn_eject_drop(parent, from_pos, gem_id)


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
