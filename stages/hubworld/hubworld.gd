extends Node3D

## Roguelike hub town. The player returns here after every run (or death), talks
## to vendors, and walks out one of the four run gates. Outdoor dress mirrors
## stage1 town props (buildings/farms/corrals/foliage); keep combat-scale
## content in the run zones, not here.

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const GROYPER_TOWN_NPC_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
const HUB_WEAPON_CHEST_SCENE := preload("res://gameplay/world/hub_weapon_chest.tscn")
const TownNpcSpawnScript := preload("res://gameplay/world/town_npc_spawn.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const STAGE1_VISUAL_SETUP := preload("res://stages/stage1/stage1_visual_setup.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay

var _player: Node3D


func _ready() -> void:
	# Cover first — heavy setup below must not flash the default clear color.
	_fade_overlay.modulate.a = 1.0

	FxCatalogScript.warm_all()
	add_to_group("hubworld_stage")
	# Booting straight into the hub (editor F6 / testing) still counts as a
	# roguelike session so death routing works.
	if not RunState.roguelike_active:
		RunState.begin_roguelike_session(RoguelikeSave.has_save())
	# Keep hub wallet aligned with extracted bank after runs.
	if RunMetaProgress.banked_gram > 0 or RunMetaProgress.banked_soul_shards > 0:
		RunMetaProgress.apply_bank_to_inventory()
	ShopSession.reset_for_outdoor_spawn()
	DayNightCycle.bind_outdoor_scene($Sun)

	_ensure_terrain_floor()
	STAGE1_VISUAL_SETUP.apply_materials(self)
	_setup_town_collision()
	_refresh_run_gate_locks()
	_wire_shop_doors()
	_wire_blacksmith_doors()
	_spawn_town_npcs()
	_spawn_weapon_chest()

	var death_return := RunState.consume_pending_death_return()
	var return_zone_id := RunState.consume_pending_return_zone()
	_spawn_player(death_return, return_zone_id)

	# Persist hub stats / bank / stash / zone unlocks every time we arrive.
	RoguelikeSave.save_session()

	# Terrain3D collision / floor snap need a physics tick before reveal.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()

	await _reveal_after_load()

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func _reveal_after_load() -> void:
	var death_fade := RunState.consume_death_fade_pending()
	if death_fade:
		# DeathOverlayManager (layer 120) owns the reveal; drop our covers under it.
		_fade_overlay.modulate.a = 0.0
		DeathOverlayManager.fade_in_after_respawn()
		if RunState.is_covering():
			RunState.clear_cover()
		return

	if RunState.is_covering():
		_fade_overlay.modulate.a = 0.0
		await RunState.fade_from_black()
		return

	# Editor F6 / direct boot — stage overlay only.
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _exit_tree() -> void:
	DayNightCycle.unbind_outdoor_scene($Sun)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


## Until real terrain regions are sculpted in the editor, import a flat region
## at runtime so the town has a walkable floor. Once the data directory has
## saved regions this is a no-op — editor work simply replaces it.
func _ensure_terrain_floor() -> void:
	var terrain := get_node_or_null("Terrain/Terrain3D")
	if terrain == null:
		return
	var data: Variant = terrain.get("data")
	if data == null:
		return
	if int(data.call("get_region_count")) > 0:
		return
	var img := Image.create_empty(512, 512, false, Image.FORMAT_RF)
	data.call("import_images", [img, null, null], Vector3(-256.0, 0.0, -256.0), 0.0, 1.0)
	print(
		"Hubworld: no saved terrain regions — imported flat floor (%d regions)."
		% int(data.call("get_region_count"))
	)


## Trimesh collision + wood impact surfaces for the buildings. The hub is a
## handful of props, so the synchronous whole-node pass stage1 outgrew is fine
## here.
func _setup_town_collision() -> void:
	var town := get_node_or_null("Town")
	if town != null:
		WOOD_BULLET_COVER.apply_to(town)


## Show a closed barrier on locked hub gates. Triggers stay monitoring so they
## can toast "Clear The Dry Gulch first" when the player walks into them.
func _refresh_run_gate_locks() -> void:
	for node in get_tree().get_nodes_in_group("run_gate"):
		if not is_instance_valid(node):
			continue
		if int(node.get("destination")) != 0:
			continue
		var zone_id := str(node.get("zone_id"))
		var unlocked := RunState.is_zone_unlocked(zone_id)
		_set_gate_closed_barrier(node as Node3D, not unlocked)


func _set_gate_closed_barrier(gate: Node3D, closed: bool) -> void:
	if gate == null:
		return
	var barrier := gate.get_node_or_null("ClosedBarrier") as Node3D
	if closed and barrier == null:
		barrier = _make_closed_barrier()
		gate.add_child(barrier)
	if barrier != null:
		barrier.visible = closed


func _make_closed_barrier() -> Node3D:
	var root := Node3D.new()
	root.name = "ClosedBarrier"
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(10.0, 5.0, 1.2)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.16, 0.12, 1.0)
	mat.roughness = 0.95
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, 2.2, 0.0)
	root.add_child(mesh_inst)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(10.0, 5.0, 1.2)
	shape.shape = box_shape
	shape.position = Vector3(0.0, 2.2, 0.0)
	body.add_child(shape)
	root.add_child(body)
	return root


func _spawn_player(death_return: bool, return_zone_id: String) -> void:
	var spawn_transform := _resolve_spawn_transform(death_return, return_zone_id)
	_player = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_transform = spawn_transform
	if _player.has_method("sync_overworld_spawn_orientation"):
		_player.sync_overworld_spawn_orientation()
	if _player.has_method("set_transition_locked"):
		_player.set_transition_locked(true)
	call_deferred("_finalize_player_spawn")


func _finalize_player_spawn() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()
	_sync_player_equipped_to_inventory()


## After extract the player may only own a non-starting weapon; equip something
## they actually carry instead of the default revolver.
func _sync_player_equipped_to_inventory() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("equip_weapon"):
		return
	var equipped := int(_player.get("_equipped_weapon"))
	if PlayerInventory.owns_weapon_type(equipped):
		return
	var owned := PlayerInventory.get_extractable_weapons()
	if owned.is_empty():
		_player.equip_weapon(GroyperWeapons.Id.UNARMED, false)
		return
	_player.equip_weapon(owned[0], false)


func _resolve_spawn_transform(death_return: bool, return_zone_id: String) -> Transform3D:
	# Death always recovers at the central spawn; run completion returns
	# through the gate the run started from.
	if not death_return and return_zone_id != "":
		var gate_spawn := _find_gate_return_spawn(return_zone_id)
		if gate_spawn != null:
			return gate_spawn.global_transform
	var spawn := get_node_or_null("HubSpawn") as Marker3D
	if spawn != null:
		return spawn.global_transform
	return Transform3D(Basis.from_euler(Vector3(0.0, PI, 0.0)), Vector3(0.0, 1.0, 0.0))


func _find_gate_return_spawn(zone_id: String) -> Marker3D:
	for node in get_tree().get_nodes_in_group("run_gate"):
		if not is_instance_valid(node):
			continue
		if str(node.get("zone_id")) != zone_id:
			continue
		var marker := node.get_node_or_null("ReturnSpawn") as Marker3D
		if marker != null:
			return marker
	return null


func _spawn_town_npcs() -> void:
	var host := get_node_or_null("TownActors")
	if host == null:
		return
	var markers := get_node_or_null("Town/NpcSpawns")
	if markers == null:
		return
	for marker in markers.get_children():
		if not marker is Marker3D:
			continue
		var spawn := TownNpcSpawnScript.new()
		spawn.npc_scene = GROYPER_TOWN_NPC_SCENE
		host.add_child(spawn)
		spawn.global_transform = (marker as Marker3D).global_transform
		spawn.spawn_npc()


func _spawn_weapon_chest() -> void:
	if get_node_or_null("HubWeaponChest") != null:
		return
	var chest: Node3D = HUB_WEAPON_CHEST_SCENE.instantiate()
	chest.name = "HubWeaponChest"
	add_child(chest)
	var marker := get_node_or_null("WeaponChestSpawn") as Marker3D
	if marker != null:
		chest.global_transform = marker.global_transform
	else:
		# In front of the blacksmith, near the town square.
		chest.global_transform = Transform3D(Basis.IDENTITY, Vector3(-6.0, 0.1, 6.0))


func _wire_shop_doors() -> void:
	var entrance_marker := get_node_or_null("Town/Build_Shop/ShopEntranceMarker") as Marker3D
	var entrance := get_node_or_null("Town/Build_Shop/ShopEntranceMarker/ShopEntrance")
	var interior_slot := get_node_or_null("ShopInteriors/ShopInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Hubworld: shop door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Hubworld: shop interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
		exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _wire_blacksmith_doors() -> void:
	var entrance_marker := get_node_or_null(
		"Town/Build_Blacksmith/BlacksmithEntranceMarker"
	) as Marker3D
	var entrance := get_node_or_null(
		"Town/Build_Blacksmith/BlacksmithEntranceMarker/BlacksmithEntrance"
	)
	var interior_slot := get_node_or_null("ShopInteriors/BlacksmithInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Hubworld: blacksmith door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Hubworld: blacksmith interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	entrance.set("interior_music", ShopSession.SMITH_MUSIC)
	entrance.set("interior_music_volume_db", ShopSession.SMITH_MUSIC_VOLUME_DB)
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
		exit_door.set("destination", exit_door.get_path_to(entrance_marker))
