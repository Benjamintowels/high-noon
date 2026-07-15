extends Node3D
class_name Bonfire

const INTERACT_APPROACH_TIME := 0.85
const LIGHT_TIME := 1.1
## Stand beside the fire — spawning on global_position drops the player on the altar.
const DEFAULT_RESPAWN_STAND_OFFSET := Vector3(0.0, 0.0, 1.85)

@export var starts_lit := false
@export var checkpoint_id := &""
@export var display_name := "Bonfire"
## Lazy InteriorZoneSlot path on the overworld stage (e.g. ShopInteriors/HomeInterior).
## When set, fast travel loads that slot and spawns at travel_spawn_marker instead of
## requiring the bonfire node to already exist in the tree.
@export var travel_interior_slot := ""
@export var travel_spawn_marker := "InteriorSpawn"
## Local-space offset from the bonfire root used for death / travel arrival.
@export var respawn_stand_offset := DEFAULT_RESPAWN_STAND_OFFSET

@onready var _interact_area: Area3D = $InteractArea

var _fire_visual: Node3D

var _lit := false
var _busy := false
var _menu_done := false
var _player_in_range: Node3D


func _ready() -> void:
	add_to_group("bonfire")
	_interact_area.monitoring = true
	_interact_area.monitorable = false
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)
	_fire_visual = get_node_or_null("AltarFire/Fire")
	_lit = starts_lit or AdventureSave.is_bonfire_lit(get_travel_id())
	_set_fire_visible(_lit)


## Stable identity for lit-state persistence and fast travel. Bonfires without
## a checkpoint_id (e.g. interior ones) fall back to a scene-scoped path id and
## are never offered as travel destinations.
func get_travel_id() -> String:
	if checkpoint_id != &"":
		return String(checkpoint_id)
	return "%s::%s" % [_stage_scene_path(), _bonfire_node_path()]


func _stage_scene_path() -> String:
	# Prefer the live overworld stage so packed interior roots don't write their
	# own scene_file_path into lit_bonfires / travel entries.
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		var path := tree.current_scene.scene_file_path
		if path != "":
			return path
	var stage := owner if owner != null else null
	return stage.scene_file_path if stage != null else ""


func _bonfire_node_path() -> String:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return str(tree.current_scene.get_path_to(self))
	if owner != null:
		return str(owner.get_path_to(self))
	return str(get_path())


func _build_travel_entry() -> Dictionary:
	var entry := {
		"id": get_travel_id(),
		"name": display_name,
		"stage_path": _stage_scene_path(),
		"bonfire_path": _bonfire_node_path(),
		"travelable": checkpoint_id != &"",
	}
	if travel_interior_slot != "":
		entry["interior_slot"] = travel_interior_slot
		entry["spawn_marker"] = travel_spawn_marker
	return entry


func get_interact_hint() -> String:
	return "Rest at Bonfire" if _lit else "Light Bonfire"


## Feet position for death respawn / outdoor fast travel — beside the fire, not in it.
func get_respawn_global_position() -> Vector3:
	return global_position + global_transform.basis * respawn_stand_offset


func interact(player: Node3D) -> void:
	if _busy or player == null:
		return
	_busy = true
	await _perform_bonfire_sequence(player)
	_busy = false


static func apply_rest_world_effects(from_node: Node) -> void:
	if from_node == null:
		return
	var tree := from_node.get_tree()
	if tree == null:
		return
	respawn_cave_enemies_in_tree(tree)
	respawn_canyon_bandits_in_tree(tree)
	respawn_town_natural_npcs_in_tree(tree)
	respawn_church_skeleton_ambush_in_tree(tree)
	respawn_church_chief_boss_in_tree(tree)


static func respawn_cave_enemies_in_tree(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("respawn_enemy"):
			node.respawn_enemy()


static func respawn_canyon_bandits_in_tree(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("canyon_bandit_spawn"):
		if node.has_method("respawn_enemy"):
			node.respawn_enemy()


static func respawn_town_natural_npcs_in_tree(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("town_npc_spawn"):
		if node.has_method("respawn_if_defeated"):
			node.respawn_if_defeated()


static func respawn_church_skeleton_ambush_in_tree(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("church_skeleton_ambush"):
		if node.has_method("reset_for_bonfire_rest"):
			node.reset_for_bonfire_rest()


static func respawn_church_chief_boss_in_tree(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("chief_getcha_boss"):
		if node.has_method("reset_for_bonfire_rest"):
			node.reset_for_bonfire_rest()


func respawn_cave_enemies() -> void:
	respawn_cave_enemies_in_tree(get_tree())


func respawn_town_natural_npcs() -> void:
	respawn_town_natural_npcs_in_tree(get_tree())


func _perform_bonfire_sequence(player: Node3D) -> void:
	if player.has_method("begin_bonfire_interaction"):
		player.begin_bonfire_interaction(self)

	await get_tree().create_timer(INTERACT_APPROACH_TIME).timeout
	if not is_inside_tree() or not is_instance_valid(player):
		return

	if not _lit:
		if player.has_method("begin_bonfire_cinematic_camera"):
			player.begin_bonfire_cinematic_camera(self)
		_lit = true
		_set_fire_visible(true)
		AdventureSave.mark_bonfire_lit(_build_travel_entry())
		await get_tree().create_timer(LIGHT_TIME).timeout
		if not is_inside_tree() or not is_instance_valid(player):
			return
	elif player.has_method("begin_bonfire_cinematic_camera"):
		player.begin_bonfire_cinematic_camera(self)

	BonfireMenuManager.show_menu(
		Callable(self, "_on_rest_selected").bind(player),
		Callable(self, "_on_menu_closed").bind(player),
		Callable(self, "_on_travel_selected").bind(player),
		get_travel_id()
	)
	_menu_done = false
	while not _menu_done:
		await get_tree().process_frame
		if not is_inside_tree():
			return


func _on_rest_selected(player: Node3D) -> void:
	if player != null and player.has_method("rest_at_bonfire"):
		player.rest_at_bonfire()
	apply_rest_world_effects(self)
	var stage := get_tree().current_scene
	AdventureSave.set_bonfire_checkpoint(self, stage)
	AdventureSave.sync_runtime_state(player, stage)
	AdventureSave.commit_death_checkpoint(player)
	_finish_bonfire_menu(player)


func _on_menu_closed(player: Node3D) -> void:
	_finish_bonfire_menu(player)


func _on_travel_selected(entry: Dictionary, player: Node3D) -> void:
	_finish_bonfire_menu(player)
	BonfireTravelManager.travel_to(entry, player)


func _finish_bonfire_menu(player: Node3D) -> void:
	BonfireMenuManager.hide_menu()
	if player != null:
		if player.has_method("begin_bonfire_cinematic_camera_exit"):
			player.begin_bonfire_cinematic_camera_exit()
		if player.has_method("end_bonfire_interaction"):
			player.end_bonfire_interaction()
	_menu_done = true


func _set_fire_visible(active: bool) -> void:
	if _fire_visual != null:
		_fire_visual.visible = active


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
