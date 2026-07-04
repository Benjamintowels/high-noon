extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const BALDWIN_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/baldwin/baldwin_overworld_player.tscn"
)
const TC_BOSS_SCENE := preload("res://characters/tc/tc_boss.tscn")
const BossHealthBarScript := preload("res://gameplay/ui/boss_health_bar.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const BIRDS_AMBIENCE := preload("res://Assets/World/RuinsGR/Sounds/BirdsAmbience.mp3")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _ambience_player: AudioStreamPlayer = $AmbiencePlayer

var _player: Node3D
var _boss: Node3D


func _ready() -> void:
	add_to_group("caves_boss_room")
	_setup_ambience()
	_fade_overlay.modulate.a = 1.0

	if AdventureSave.has_save_data():
		_spawn_player_from_save()
	else:
		_spawn_fresh_player()

	call_deferred("_link_baldwin_companion", _player)
	call_deferred("_spawn_boss")

	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func _spawn_player_from_save() -> void:
	_player = _spawn_overworld_player()
	AdventureSave.apply_to_player(_player)


func _spawn_fresh_player() -> void:
	_player = _spawn_overworld_player()


func _spawn_overworld_player() -> Node3D:
	var spawn: Marker3D = $OverworldSpawn
	var player_scene: PackedScene = GROYPER_OVERWORLD_PLAYER_SCENE
	if GameState.selected_character_id == "baldwin":
		player_scene = BALDWIN_OVERWORLD_PLAYER_SCENE

	var player: Node3D = player_scene.instantiate()
	add_child(player)
	player.global_transform = spawn.global_transform
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	call_deferred("_finalize_player_spawn", player)
	return player


func _finalize_player_spawn(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	PlayerInventory.set_has_sword_shield(true)
	if player.has_method("refresh_melee_equipment"):
		player.refresh_melee_equipment()
	if player.has_method("equip_weapon"):
		player.equip_weapon(GroyperWeaponsScript.Id.SWORD_SHIELD)
	if player.has_method("snap_to_floor"):
		player.snap_to_floor()


func _link_baldwin_companion(player: Node3D) -> void:
	if player == null or not CompanionManager.is_recruited(CompanionManager.COMPANION_BALDWIN):
		return
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node is BaldwinNpc:
			(node as BaldwinNpc).call_deferred("_begin_companion_mode", player)


func _setup_ambience() -> void:
	_ambience_player.stream = BIRDS_AMBIENCE
	_ambience_player.volume_db = -20.0
	_ambience_player.autoplay = true


func _spawn_boss() -> void:
	var spawn: Marker3D = get_node_or_null("BossSpawn") as Marker3D
	if spawn == null:
		push_error("CavesBossRoom: missing BossSpawn marker.")
		return

	_boss = TC_BOSS_SCENE.instantiate() as Node3D
	add_child(_boss)
	_boss.global_transform = spawn.global_transform
	if _boss.has_method("snap_to_floor"):
		_boss.snap_to_floor()
	BossHealthBarScript.attach_to(_boss, "TC")
