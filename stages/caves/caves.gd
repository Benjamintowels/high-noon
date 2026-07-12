extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const BALDWIN_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/baldwin/baldwin_overworld_player.tscn"
)
const RUINS_LOOT_CHEST_SCENE := preload("res://gameplay/world/ruins_loot_chest.tscn")
const TERRAIN_COLLISION := preload("res://gameplay/world/terrain_collision.gd")
const FLOOR_TILE_COLLISION := preload("res://gameplay/world/floor_tile_collision.gd")
const BIRDS_AMBIENCE := preload("res://Assets/World/RuinsGR/Sounds/BirdsAmbience.mp3")
const TownNavSetup := preload("res://gameplay/navigation/town_nav_setup.gd")
const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _ruins_root: Node3D = $RuinsLayout
@onready var _ambience_player: AudioStreamPlayer = $AmbiencePlayer

var _player: Node3D
var _baldwin_melee_test := false


func _ready() -> void:
	# Pay all FX sprite-frame PNG loads during stage load instead of on the
	# first shot/hit of a fight.
	FxCatalogScript.warm_all()
	add_to_group("caves_stage")
	_sync_exit_portal_from_marker()
	_setup_ruins_collision()
	_setup_caves_navigation()
	_setup_ambience()
	_fade_overlay.modulate.a = 1.0
	PlayerDeathLoot.restore_loot_bag_for_stage(self)

	if GameState.start_in_caves_test:
		_baldwin_melee_test = true
		_spawn_fresh_player()
		_grant_caves_test_loadout()
		GameState.start_in_caves_test = false
	elif BonfireTravelManager.has_pending_travel():
		var travel := BonfireTravelManager.consume_pending_travel()
		_player = _spawn_overworld_player_at_transform(
			BonfireTravelManager.get_travel_spawn_transform(self, travel)
		)
		AdventureSave.apply_to_player(_player)
		if _player.has_method("sync_overworld_spawn_orientation"):
			_player.sync_overworld_spawn_orientation()
		call_deferred("_finalize_player_spawn", _player)
		call_deferred("_link_baldwin_companion", _player)
	elif AdventureSave.consume_pending_bonfire_respawn():
		_player = _spawn_overworld_player_at_transform(AdventureSave.get_bonfire_spawn_transform(self))
		AdventureSave.apply_to_player(_player)
		if _player.has_method("sync_overworld_spawn_orientation"):
			_player.sync_overworld_spawn_orientation()
		if _player.has_method("apply_post_bonfire_respawn"):
			_player.call_deferred("apply_post_bonfire_respawn")
	elif AdventureSave.should_restore_on_caves_load():
		_player = _spawn_player_at_return_save()
		AdventureSave.consume_pending_caves_restore()
	elif AdventureSave.has_save_data():
		_spawn_player_from_save()
	else:
		_spawn_fresh_player()

	call_deferred("_setup_cave_enemies")
	call_deferred("_finalize_layout_spawns")

	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if AdventureSave.consume_bonfire_respawn_fade_pending():
		DeathOverlayManager.fade_in_after_respawn()

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func _sync_exit_portal_from_marker() -> void:
	var marker := get_node_or_null("ExitToTown") as Marker3D
	var portal := get_node_or_null("ExitToTown/ExitPortal") as Node3D
	if portal == null:
		portal = get_node_or_null("ExitPortal") as Node3D
	if marker == null or portal == null or portal.get_parent() == marker:
		return
	portal.global_transform = marker.global_transform


func _spawn_player_from_save() -> void:
	_player = _spawn_overworld_player()
	AdventureSave.apply_to_player(_player)


func _spawn_player_at_return_save() -> Node3D:
	var player := _spawn_overworld_player_at_transform(AdventureSave.get_return_spawn_transform())
	AdventureSave.apply_to_player(player)
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	call_deferred("_finalize_player_spawn", player)
	call_deferred("_link_baldwin_companion", player)
	return player


func _spawn_overworld_player_at_transform(spawn_transform: Transform3D) -> Node3D:
	var player_scene: PackedScene = (
		BALDWIN_OVERWORLD_PLAYER_SCENE
		if _baldwin_melee_test
		else GROYPER_OVERWORLD_PLAYER_SCENE
	)
	var player: Node3D = player_scene.instantiate()
	add_child(player)
	player.global_transform = spawn_transform
	return player


func _spawn_fresh_player() -> void:
	_player = _spawn_overworld_player()


func _spawn_overworld_player() -> Node3D:
	var spawn: Marker3D = $OverworldSpawn
	var player_scene: PackedScene = (
		BALDWIN_OVERWORLD_PLAYER_SCENE
		if _baldwin_melee_test
		else GROYPER_OVERWORLD_PLAYER_SCENE
	)
	var player: Node3D = player_scene.instantiate()
	add_child(player)
	player.global_transform = spawn.global_transform
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	call_deferred("_finalize_player_spawn", player)
	call_deferred("_link_baldwin_companion", player)
	return player


func _grant_caves_test_loadout() -> void:
	PlayerInventory.set_has_ruins_key(true)


func _link_baldwin_companion(player: Node3D) -> void:
	if player == null or not CompanionManager.is_recruited(CompanionManager.COMPANION_BALDWIN):
		return
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node is BaldwinNpc:
			(node as BaldwinNpc).call_deferred("_begin_companion_mode", player)


func _setup_caves_navigation() -> void:
	var nav_setup := TownNavSetup.new()
	nav_setup.name = "CavesNavigation"
	add_child(nav_setup)
	nav_setup.configure_and_bake(_ruins_root, Vector3.ZERO, Vector3(48.0, 10.0, 48.0))
	nav_setup.add_ruins_stair_nav_links(_ruins_root)


func _finalize_player_spawn(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("snap_to_floor"):
		player.snap_to_floor()


func _setup_ambience() -> void:
	_ambience_player.stream = BIRDS_AMBIENCE
	_ambience_player.volume_db = -16.0
	_ambience_player.autoplay = true


func _setup_ruins_collision() -> void:
	var floor_root := _ruins_root.get_node_or_null("Floor") as Node3D
	if floor_root != null:
		FLOOR_TILE_COLLISION.apply_to(floor_root)

	for node_name in ["Structures", "Obstacles"]:
		var collision_root := _ruins_root.get_node_or_null(node_name) as Node3D
		if collision_root != null:
			TERRAIN_COLLISION.apply_to(collision_root)

	# Catch editor-placed pieces still parented to the layout root.
	for child in _ruins_root.get_children():
		if not child is Node3D:
			continue
		if child.name in ["Floor", "Structures", "Obstacles"]:
			continue
		TERRAIN_COLLISION.apply_to(child)


func _setup_cave_enemies() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("spawn_enemy"):
			node.spawn_enemy()


func _finalize_layout_spawns() -> void:
	# Floor collision is built in _ready; wait for physics before snapping NPCs.
	await get_tree().physics_frame

	var gameplay := get_node_or_null("Gameplay") as Node3D
	if gameplay != null:
		_place_paired_npc_spawns(gameplay, "RedoSpawn", "RedoNpc")
		_place_paired_npc_spawns(gameplay, "PavelSpawn", "PavelNpc")
		_place_paired_npc_spawns(gameplay, "UndeadSpawn", "UndeadNpc")

	var baldwin := get_node_or_null("Gameplay/BaldwinNpc") as Node3D
	if baldwin != null and baldwin.has_method("snap_to_floor"):
		baldwin.snap_to_floor()

	_setup_ruins_loot_chest()
	_setup_enemy_health_bars()


func _setup_ruins_loot_chest() -> void:
	if PlayerInventory.has_sword_shield:
		return

	# Testing: key is granted so the chest can always be opened for now.
	PlayerInventory.set_has_ruins_key(true)

	var old_chest := _ruins_root.get_node_or_null("Structures/chest_90") as Node3D
	if old_chest == null:
		return

	var chest_transform := old_chest.global_transform
	var parent := old_chest.get_parent()
	old_chest.queue_free()

	var loot_chest: Node3D = RUINS_LOOT_CHEST_SCENE.instantiate()
	parent.add_child(loot_chest)
	loot_chest.global_transform = chest_transform


func _setup_enemy_health_bars() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy"):
		if node is Node3D:
			FloatingEnemyHealthBarScript.attach_to(node as Node3D)


func _place_paired_npc_spawns(parent: Node, spawn_prefix: String, npc_prefix: String) -> void:
	for child in parent.get_children():
		if not child is Marker3D:
			continue
		if not _spawn_marker_matches_prefix(child.name, spawn_prefix):
			continue
		var suffix := _spawn_marker_suffix(child.name, spawn_prefix)
		var npc_name := npc_prefix if suffix.is_empty() else npc_prefix + suffix
		var npc := parent.get_node_or_null(npc_name) as Node3D
		if npc != null:
			_place_npc_at_spawn(npc, child as Marker3D)


func _spawn_marker_matches_prefix(node_name: String, prefix: String) -> bool:
	if node_name == prefix:
		return true
	if not node_name.begins_with(prefix):
		return false
	var suffix := node_name.substr(prefix.length())
	return not suffix.is_empty() and suffix.is_valid_int()


func _spawn_marker_suffix(node_name: String, prefix: String) -> String:
	if node_name == prefix:
		return ""
	return node_name.substr(prefix.length())


func _place_npc_at_spawn(npc: Node3D, spawn: Marker3D) -> void:
	if npc == null or spawn == null:
		return
	npc.global_transform = spawn.global_transform
	if npc.has_method("refresh_patrol_anchor"):
		npc.refresh_patrol_anchor()
	elif npc.has_method("snap_to_floor"):
		npc.snap_to_floor()
