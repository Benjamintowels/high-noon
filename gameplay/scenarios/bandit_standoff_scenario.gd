extends Node3D
class_name BanditStandoffScenario

const BANDIT_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const TOWNSFOLK_SCENE := preload("res://characters/groyper/groyper_townsfolk_npc.tscn")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const BANDIT_COUNT := 9
const TOWNSFOLK_COUNT := 8
const ROW_SPACING := 2.4
const BANDIT_ROW_Z := 11.0
const TOWNSFOLK_ROW_Z := -3.0
## Just behind the townsfolk row on their side of the street.
const PLAYER_SPAWN_Z := -5.5


func setup(_stage: Node3D, town: Node3D) -> Marker3D:
	var bandit_spawns := _build_row_markers("BanditSpawns", BANDIT_COUNT, BANDIT_ROW_Z)
	var townsfolk_spawns := _build_row_markers("TownsfolkSpawns", TOWNSFOLK_COUNT, TOWNSFOLK_ROW_Z)
	var player_spawn := Marker3D.new()
	player_spawn.name = "PlayerSpawn"
	player_spawn.position = Vector3(0.0, 0.0, PLAYER_SPAWN_Z)
	player_spawn.rotation.y = PI
	add_child(player_spawn)

	var bandits := _spawn_faction_row(
		BANDIT_SCENE,
		bandit_spawns,
		town,
		FactionIdsScript.BANDITS,
		(BANDIT_COUNT - 1) / 2
	)
	var townsfolk := _spawn_faction_row(
		TOWNSFOLK_SCENE,
		townsfolk_spawns,
		town,
		FactionIdsScript.TOWNSPEOPLE,
		(TOWNSFOLK_COUNT - 1) / 2
	)
	_pair_stare_targets(bandits, townsfolk)
	return player_spawn


func _build_row_markers(root_name: String, count: int, row_z: float) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	add_child(root)

	var total_width := float(count - 1) * ROW_SPACING
	var start_x := -total_width * 0.5

	for i in count:
		var marker := Marker3D.new()
		marker.name = "Spawn%02d" % (i + 1)
		marker.position = Vector3(start_x + float(i) * ROW_SPACING, 0.0, row_z)
		root.add_child(marker)

	return root


func _spawn_faction_row(
	scene: PackedScene,
	spawns_root: Node3D,
	town: Node3D,
	faction_id: StringName,
	shotgun_member_index: int = -1
) -> Array[GroyperTownNpc]:
	var members: Array[GroyperTownNpc] = []
	var spawn_index := 0

	for child in spawns_root.get_children():
		if not child is Marker3D:
			continue
		var marker := child as Marker3D
		var npc: GroyperTownNpc = scene.instantiate()
		if spawn_index == shotgun_member_index:
			npc.equipped_weapon_id = GroyperWeaponsScript.Id.SHOTGUN
		town.add_child(npc)
		npc.global_position = marker.global_position
		# Facing is driven by Model.rotation via facing_yaw_for_direction — do not
		# bake yaw into the CharacterBody3D root or Meshy rigs face backward.
		members.append(npc)
		spawn_index += 1

	for member in members:
		member.configure_faction_standoff(faction_id, null)

	return members


func _pair_stare_targets(bandits: Array[GroyperTownNpc], townsfolk: Array[GroyperTownNpc]) -> void:
	for i in bandits.size():
		var bandit := bandits[i]
		var target_index := mini(i, townsfolk.size() - 1)
		if townsfolk.is_empty():
			continue
		bandit.set_faction_aggro_level(1, townsfolk[target_index])

	for i in townsfolk.size():
		var townsfolk_npc := townsfolk[i]
		var target_index := mini(i, bandits.size() - 1)
		if bandits.is_empty():
			continue
		townsfolk_npc.set_faction_aggro_level(1, bandits[target_index])
