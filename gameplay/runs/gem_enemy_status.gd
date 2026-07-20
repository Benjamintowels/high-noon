extends Node

## Roguelike Gem Enemy: pacifist approach → flee 10s after first damage → fade
## or drop an elemental gem if killed while fleeing.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const BrawlAuraFXScript := preload("res://gameplay/fx/brawl_aura_fx.gd")

const NODE_NAME := &"GemEnemyStatus"
const GROUP_NAME := &"gem_enemy"
const GEM_ID_META := &"gem_id"
const FADING_META := &"gem_enemy_fading"
const SKIP_AGGRO_META := &"gem_enemy_skip_aggro"

const FLEE_DURATION := 10.0
const FADE_DURATION := 0.65
const APPROACH_SPEED := 3.4
const FLEE_SPEED := 5.8
const AURA_ALPHA := 0.42

enum Phase { APPROACH, FLEE, FADING }

var _gem_id: StringName = ElementalGems.LIGHTNING
var _phase: int = Phase.APPROACH
var _flee_time_left := 0.0
var _fade_time_left := 0.0
var _fade_meshes: Array[MeshInstance3D] = []


static func is_gem_enemy(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return host.is_in_group(GROUP_NAME) or host.get_node_or_null(NodePath(String(NODE_NAME))) != null


static func is_fading(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return bool(host.get_meta(FADING_META, false))


static func apply(host: Node, gem_id: StringName) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not ElementalGems.is_valid(gem_id):
		var ids := ElementalGems.get_active_gem_ids()
		gem_id = ids[0] if not ids.is_empty() else ElementalGems.LIGHTNING
	if host.get_node_or_null(NodePath(String(NODE_NAME))) != null:
		return

	host.add_to_group(GROUP_NAME)
	host.set_meta(GEM_ID_META, gem_id)
	host.set_meta(SKIP_AGGRO_META, true)

	var script: Script = load("res://gameplay/runs/gem_enemy_status.gd") as Script
	var status: Node = script.new() as Node
	if status == null:
		return
	status.name = String(NODE_NAME)
	host.add_child(status)
	if status.has_method("setup"):
		status.call("setup", gem_id)


static func tick(host: CharacterBody3D, delta: float) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	var status := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if status == null or not status.has_method("tick_physics"):
		return false
	status.call("tick_physics", host, delta)
	return true


static func notify_damaged(host: Node) -> void:
	if host == null or not is_instance_valid(host):
		return
	var status := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if status != null and status.has_method("on_damaged"):
		status.call("on_damaged")


func setup(gem_id: StringName) -> void:
	_gem_id = gem_id
	_phase = Phase.APPROACH
	var color := ElementalGems.get_color(gem_id)
	color.a = AURA_ALPHA
	BrawlAuraFXScript.apply_colored(get_parent(), color)


func on_damaged() -> void:
	if _phase != Phase.APPROACH:
		return
	_phase = Phase.FLEE
	_flee_time_left = FLEE_DURATION


func tick_physics(host: CharacterBody3D, delta: float) -> void:
	if host == null or not is_instance_valid(host):
		return
	if host.has_method("is_defeated") and host.is_defeated():
		return

	match _phase:
		Phase.APPROACH:
			_apply_move(host, _dir_to_player(host), APPROACH_SPEED, delta)
		Phase.FLEE:
			_flee_time_left -= delta
			_apply_move(host, -_dir_to_player(host), FLEE_SPEED, delta)
			if _flee_time_left <= 0.0:
				_begin_fade(host)
		Phase.FADING:
			_fade_time_left -= delta
			_update_fade_visuals()
			host.velocity.x = 0.0
			host.velocity.z = 0.0
			if _fade_time_left <= 0.0:
				_finish_fade(host)


func _apply_move(host: CharacterBody3D, dir: Vector3, speed: float, delta: float) -> void:
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		host.velocity.x = 0.0
		host.velocity.z = 0.0
		return
	dir = dir.normalized()
	host.velocity.x = dir.x * speed
	host.velocity.z = dir.z * speed
	if host.has_method("_face_position"):
		host.call("_face_position", host.global_position + dir, delta)


func _dir_to_player(host: CharacterBody3D) -> Vector3:
	var player := _find_player(host)
	if player == null:
		return Vector3.FORWARD
	var offset := player.global_position - host.global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		return Vector3.FORWARD
	return offset.normalized()


func _find_player(host: Node) -> Node3D:
	var tree := host.get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("overworld_player"):
		if node is Node3D and is_instance_valid(node):
			if node.has_method("is_defeated") and node.is_defeated():
				continue
			return node as Node3D
	for node in tree.get_nodes_in_group("player"):
		if node is Node3D and is_instance_valid(node):
			return node as Node3D
	return null


func _begin_fade(host: Node) -> void:
	if _phase == Phase.FADING:
		return
	_phase = Phase.FADING
	_fade_time_left = FADE_DURATION
	host.set_meta(FADING_META, true)
	_fade_meshes.clear()
	var visual_root: Node = host.get_node_or_null("Model")
	if visual_root == null:
		visual_root = host
	for node in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh != null and not mesh.name.contains("Debug"):
			_fade_meshes.append(mesh)


func _update_fade_visuals() -> void:
	var t := clampf(_fade_time_left / FADE_DURATION, 0.0, 1.0)
	var alpha := t
	for mesh in _fade_meshes:
		if mesh == null or not is_instance_valid(mesh):
			continue
		# Transparency via override albedo alpha when possible.
		var mat := mesh.material_override as BaseMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			if mesh.get_active_material(0) is BaseMaterial3D:
				var src := mesh.get_active_material(0) as BaseMaterial3D
				mat.albedo_color = src.albedo_color
				mat.albedo_texture = src.albedo_texture
			mesh.material_override = mat
		else:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c := mat.albedo_color
		c.a = alpha
		mat.albedo_color = c


func _finish_fade(host: Node) -> void:
	BrawlAuraFXScript.remove(host)
	if host != null and is_instance_valid(host):
		host.queue_free()
