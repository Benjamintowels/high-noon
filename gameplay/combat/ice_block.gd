extends CharacterBody3D

## Kickable ice shell over a frozen NPC. Player punch/shot/melee slides it;
## explodes on contact with something (or after 3s).

const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")
const IceFXScript := preload("res://gameplay/fx/ice_fx.gd")
const IceGemCombatScript := preload("res://gameplay/combat/ice_gem_combat.gd")

const MAX_DURATION := 3.0
const FRICTION := 0.85
const GRAVITY := 22.0
const SHOVE_GAIN := 10.0
const MIN_SHOVE_SPEED := 1.2
const PUNCH_SPEED := 10.5
const SHOT_SPEED := 11.5
const MELEE_SPEED := 10.5
const CONTACT_EXPLODE_SPEED := 1.5
const CONTACT_RADIUS := 0.55
const BOX_SIZE := Vector3(1.15, 2.05, 1.15)
const FLOOR_NORMAL_Y := 0.65

var _host: CharacterBody3D
var _source: Node
var _status: Node
var _time_left := MAX_DURATION
var _shattering := false
var _launched := false
var _saved_host_layer := 0
var _saved_host_mask := 0
var _host_collision_saved := false


func _ready() -> void:
	_ensure_ice_material()


func setup(host: CharacterBody3D, source: Node, status: Node, duration: float = MAX_DURATION) -> void:
	_host = host
	_source = source
	_status = status
	_time_left = maxf(duration, 0.5)
	add_to_group(&"punchable_prop")
	add_to_group(&"ice_block")
	collision_layer = TownNpcShoveScript.PUSHABLE_COLLISION_LAYER
	collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	floor_stop_on_slope = true
	_ensure_ice_material()
	if host != null and is_instance_valid(host):
		global_position = host.global_position
		_disable_host_collision(host)


func _ensure_ice_material() -> void:
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst == null:
		return
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.55, 0.88, 1.0, 0.38)
	mat.roughness = 0.15
	mat.metallic = 0.05
	mesh_inst.material_override = mat


func refresh(duration: float, source: Node = null) -> void:
	_time_left = maxf(_time_left, duration)
	if source != null:
		_source = source


func get_prop_center() -> Vector3:
	return global_position + Vector3(0.0, BOX_SIZE.y * 0.5, 0.0)


func get_prop_contact_radius() -> float:
	return CONTACT_RADIUS


func receive_punch(hit_info: Dictionary) -> void:
	_apply_attack_launch(hit_info, PUNCH_SPEED)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	# Shots and melee that route through bullet-hit all slide the block.
	if bool(hit_info.get("ice_shatter_hit", false)) or bool(hit_info.get("ice_thaw_kill", false)):
		return
	var speed := MELEE_SPEED if bool(hit_info.get("melee", false)) else SHOT_SPEED
	_apply_attack_launch(hit_info, speed)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func _apply_attack_launch(hit_info: Dictionary, launch_speed: float) -> void:
	if _shattering:
		return
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	else:
		direction = direction.normalized()
	_launched = true
	velocity.x = direction.x * launch_speed
	velocity.z = direction.z * launch_speed
	velocity.y = maxf(velocity.y, 1.35)
	var shooter: Node = hit_info.get("shooter")
	if shooter != null:
		_source = shooter


func is_shattering() -> bool:
	return _shattering


func release_without_shatter() -> void:
	if _shattering:
		return
	_shattering = true
	_restore_host_collision()
	queue_free()


func _physics_process(delta: float) -> void:
	if _shattering:
		return
	if _host == null or not is_instance_valid(_host):
		release_without_shatter()
		return
	if (
		_host.has_method("is_defeated")
		and _host.is_defeated()
		and not IceGemCombatScript.has_pending_death(_host)
	):
		release_without_shatter()
		return

	_time_left -= delta
	if _time_left <= 0.0:
		_explode(false)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = lerpf(velocity.x, 0.0, FRICTION * delta)
	velocity.z = lerpf(velocity.z, 0.0, FRICTION * delta)
	if not _launched:
		_apply_character_shoves(delta)

	move_and_slide()
	_sync_host()
	_try_explode_on_contact()


func _apply_character_shoves(delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var best_dir := Vector3.ZERO
	var best_speed := 0.0
	for group_name in TownNpcShoveScript.PUSHER_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node) or not (node is CharacterBody3D):
				continue
			if node == _host:
				continue
			var mover := node as CharacterBody3D
			var offset := global_position - mover.global_position
			offset.y = 0.0
			var dist := offset.length()
			var touch := CONTACT_RADIUS + 0.36 + 0.14
			if dist > touch or dist < 0.001:
				continue
			var intent := Vector3(mover.velocity.x, 0.0, mover.velocity.z)
			if mover.has_method("get_push_intent"):
				intent = mover.call("get_push_intent")
				intent.y = 0.0
			if intent.length_squared() < 0.04:
				continue
			var push_dir := offset.normalized()
			var alignment := intent.normalized().dot(push_dir)
			if alignment < 0.2:
				continue
			var speed := intent.length() * maxf(alignment, 0.35)
			if speed > best_speed:
				best_speed = speed
				best_dir = push_dir
	if best_speed > 0.0 and best_dir.length_squared() > 0.0001:
		_launched = true
		var push := maxf(best_speed * SHOVE_GAIN, MIN_SHOVE_SPEED) * delta
		velocity.x += best_dir.x * push
		velocity.z += best_dir.z * push


func _sync_host() -> void:
	if _host == null or not is_instance_valid(_host):
		return
	_host.global_position = global_position
	_host.velocity = Vector3.ZERO


func _try_explode_on_contact() -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var count := get_slide_collision_count()
	for i in count:
		var col := get_slide_collision(i)
		if col == null:
			continue
		var collider := col.get_collider() as Node
		var victim := _resolve_combatant(collider)
		if victim != null and victim != _host:
			if victim.is_in_group("overworld_player") or victim.is_in_group("player"):
				continue
			if victim.has_method("is_defeated") and victim.is_defeated():
				continue
			if not victim.has_method("receive_bullet_hit"):
				continue
			# Hit another combatant while sliding (or after any launch).
			if _launched or speed >= CONTACT_EXPLODE_SPEED:
				_impact_victim(victim)
				_explode(true)
				return
			continue

		# Launched into a wall / prop (not the floor) → explode.
		if _launched and speed >= CONTACT_EXPLODE_SPEED:
			var normal := col.get_normal()
			if normal.y < FLOOR_NORMAL_Y:
				_explode(true)
				return


func _impact_victim(victim: Node) -> void:
	var dir := (victim as Node3D).global_position - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3(velocity.x, 0.0, velocity.z)
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	else:
		dir = dir.normalized()
	victim.receive_bullet_hit({
		"position": (victim as Node3D).global_position + Vector3(0.0, 1.0, 0.0),
		"direction": dir,
		"shooter": _source if _source != null else _host,
		"damage": 1,
		"melee": false,
		"force_knockback": true,
		"ice_shatter_hit": true,
	})


func _explode(from_contact: bool) -> void:
	if _shattering:
		return
	_shattering = true
	_restore_host_collision()
	var host := _host
	IceFXScript.spawn_ice_explode(self if host == null else host)
	var pending := IceGemCombatScript.has_pending_death(host)
	if pending:
		IceGemCombatScript.force_pending_death(host, _source)
	elif from_contact and host != null and is_instance_valid(host) and host.has_method("receive_bullet_hit"):
		host.receive_bullet_hit({
			"position": host.global_position + Vector3(0.0, 1.0, 0.0),
			"direction": Vector3.UP,
			"shooter": _source,
			"damage": 1,
			"skip_knockback": true,
			"ice_shatter_hit": true,
			"melee": false,
			"force_knockback": false,
		})
	elif not from_contact and host != null and is_instance_valid(host):
		# Timed melt with no pending death — just thaw.
		pass
	if _status != null and is_instance_valid(_status):
		_status.queue_free()
	queue_free()


func _disable_host_collision(host: CharacterBody3D) -> void:
	if _host_collision_saved:
		return
	_saved_host_layer = host.collision_layer
	_saved_host_mask = host.collision_mask
	host.collision_layer = 0
	host.collision_mask = 0
	_host_collision_saved = true


func _restore_host_collision() -> void:
	if not _host_collision_saved:
		return
	if _host != null and is_instance_valid(_host):
		_host.collision_layer = _saved_host_layer
		_host.collision_mask = _saved_host_mask
	_host_collision_saved = false


func _resolve_combatant(from_node: Node) -> Node:
	var node := from_node
	while node != null:
		if node is CharacterBody3D and node.has_method("receive_bullet_hit"):
			if node.is_in_group(&"ice_block"):
				node = node.get_parent()
				continue
			return node
		node = node.get_parent()
	return null


func _exit_tree() -> void:
	_restore_host_collision()
