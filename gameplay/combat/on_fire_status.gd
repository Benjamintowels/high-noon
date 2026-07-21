extends Node3D

## Persistent on-fire status: chip DoT, AoE spread, performative fire VFX.

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const OnFirePanicScript := preload("res://gameplay/combat/on_fire_panic.gd")
const TerrainGrassFireScript := preload("res://gameplay/world/terrain_grass_fire.gd")

const NODE_NAME := &"OnFireStatus"
const ON_FIRE_GROUP := &"on_fire"
const DEFAULT_DURATION := 10.0
const CHIP_DAMAGE := 0.2
const CHIP_INTERVAL := 1.0
const SPREAD_RADIUS := 1.8
const SPREAD_RADIUS_SQ := SPREAD_RADIUS * SPREAD_RADIUS
const SPREAD_INTERVAL := 0.25
const FIRE_TINT := Color(1.0, 0.55, 0.18, 1.0)
const IGNITE_TINT := Color(1.0, 0.72, 0.28, 0.95)
const BODY_PIXEL_SIZE := 0.026
const IGNITE_PIXEL_SIZE := 0.034
const HEAD_HEIGHT_FALLBACK := 1.78
const PROP_HEIGHT_FALLBACK := 0.7

var _source: Node
var _time_left := DEFAULT_DURATION
var _chip_timer := 0.0
var _spread_timer := 0.0
var _loop_sprite: AnimatedSprite3D
var _light: OmniLight3D


static func is_on_fire(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return host.get_node_or_null(NodePath(String(NODE_NAME))) != null


static func ignite(host: Node, source: Node = null, duration: float = DEFAULT_DURATION) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not _is_burnable_host(host):
		return
	var existing := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if existing != null and existing.has_method("refresh"):
		existing.call("refresh", duration, source)
		return
	var script: Script = load("res://gameplay/combat/on_fire_status.gd") as Script
	var status: Node3D = script.new() as Node3D
	if status == null:
		return
	status.name = String(NODE_NAME)
	host.add_child(status)
	if status.has_method("setup"):
		status.call("setup", source, duration)


static func _is_burnable_host(host: Node) -> bool:
	if host.has_method("apply_fire_damage"):
		return true
	if host.has_method("receive_bullet_hit"):
		return true
	return false


func setup(source: Node, duration: float) -> void:
	_source = source
	_time_left = maxf(duration, 0.1)
	_chip_timer = 0.0
	_spread_timer = 0.0
	add_to_group(ON_FIRE_GROUP)
	_position_on_host()
	_spawn_ignition_burst()
	_spawn_loop_visuals()
	# First tick shortly after ignite so the DoT is felt immediately.
	_chip_timer = CHIP_INTERVAL * 0.15


func refresh(duration: float, source: Node = null) -> void:
	_time_left = maxf(_time_left, duration)
	if source != null:
		_source = source


func _exit_tree() -> void:
	OnFirePanicScript.clear(get_parent())


func _process(delta: float) -> void:
	if not is_instance_valid(get_parent()):
		queue_free()
		return

	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return

	_chip_timer += delta
	if _chip_timer >= CHIP_INTERVAL:
		_chip_timer -= CHIP_INTERVAL
		_apply_chip()

	_spread_timer += delta
	if _spread_timer >= SPREAD_INTERVAL:
		_spread_timer = 0.0
		_try_spread()


func _position_on_host() -> void:
	position = Vector3(0.0, _resolve_vfx_height(), 0.0)


func _resolve_vfx_height() -> float:
	var host := get_parent()
	if host == null:
		return HEAD_HEIGHT_FALLBACK
	# Props / crates: keep the flame near the top of the object.
	if not (host is CharacterBody3D):
		return PROP_HEIGHT_FALLBACK
	var host_3d := host as Node3D
	if host.has_method("get_threat_aim_point"):
		var aim: Vector3 = host.call("get_threat_aim_point")
		var head_y := aim.y - host_3d.global_position.y
		if head_y > 1.2:
			return head_y
	if host.has_method("get_head_hit_sphere"):
		var sphere: Dictionary = host.call("get_head_hit_sphere")
		var center: Variant = sphere.get("center", null)
		if center is Vector3:
			var head_y := (center as Vector3).y - host_3d.global_position.y
			if head_y > 1.2:
				return head_y
	return HEAD_HEIGHT_FALLBACK


func _spawn_ignition_burst() -> void:
	var parent := ImpactFXScript.parent_for(self)
	if parent == null:
		return
	var frames := FxCatalogScript.epic_explosion_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = IGNITE_PIXEL_SIZE
	sprite.modulate = IGNITE_TINT
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)


func _spawn_loop_visuals() -> void:
	var frames := FxCatalogScript.status_sparkling_loop_frames()
	if frames != null and frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) > 0:
		_loop_sprite = AnimatedSprite3D.new()
		_loop_sprite.sprite_frames = frames
		_loop_sprite.animation = FxFramesLoaderScript.ANIM_NAME
		_loop_sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
		_loop_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_loop_sprite.pixel_size = BODY_PIXEL_SIZE
		_loop_sprite.modulate = FIRE_TINT
		add_child(_loop_sprite)
		_loop_sprite.play()

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.45, 0.12, 1.0)
	_light.light_energy = 1.8
	_light.omni_range = 2.2
	_light.shadow_enabled = false
	add_child(_light)


func _apply_chip() -> void:
	var host := get_parent()
	if host == null or not is_instance_valid(host):
		return
	if host.has_method("is_defeated") and host.is_defeated():
		queue_free()
		return
	if host.has_method("apply_fire_damage"):
		host.apply_fire_damage(CHIP_DAMAGE)
		return
	if host.has_method("receive_bullet_hit"):
		host.receive_bullet_hit({
			"position": global_position,
			"direction": Vector3.UP,
			"shooter": _source,
			"damage": 0,
			"chip_damage": CHIP_DAMAGE,
			"fire_burn": true,
			"skip_knockback": true,
			"melee": false,
			"force_knockback": false,
		})


func _try_spread() -> void:
	var host := get_parent()
	if host == null or not (host is Node3D):
		return
	var tree := get_tree()
	if tree == null:
		return
	var origin := (host as Node3D).global_position
	_try_spread_to_terrain_grass(tree, origin)
	for candidate in _gather_spread_candidates(tree):
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate == host:
			continue
		if not _is_spread_eligible(host, candidate):
			continue
		if not (candidate is Node3D):
			continue
		if (candidate as Node3D).global_position.distance_squared_to(origin) > SPREAD_RADIUS_SQ:
			continue
		ignite(candidate, _source, DEFAULT_DURATION)


func _try_spread_to_terrain_grass(tree: SceneTree, origin: Vector3) -> void:
	var grass_fire := TerrainGrassFireScript.ensure_for_tree(tree)
	if grass_fire != null and grass_fire.has_method("try_ignite_near"):
		grass_fire.call("try_ignite_near", origin, _source)


func _gather_spread_candidates(tree: SceneTree) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for group_name: StringName in [
		&"duel_target",
		&"cave_enemy",
		&"armory_test_target",
		&"punchable_prop",
		&"breakable_prop",
	]:
		for node in tree.get_nodes_in_group(group_name):
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			result.append(node)
	return result


func _is_spread_eligible(from_host: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if is_on_fire(target):
		return false
	if target.is_in_group("overworld_player") or target.is_in_group("player"):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if target.has_method("apply_fire_damage"):
		return true
	if not target.has_method("receive_bullet_hit"):
		return false
	var shooter := _source if _source != null else from_host
	if FactionAffinityScript.are_allies(shooter, target):
		return false
	return true
