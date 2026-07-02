extends RefCounted
class_name NpcCombatNavigation

const TownNavSetupScript := preload("res://gameplay/navigation/town_nav_setup.gd")

const RETARGET_INTERVAL := 0.35
const STUCK_SPEED_THRESHOLD := 0.45
const STUCK_TIME := 0.55
const PATH_ENDPOINT_EPSILON := 0.35
const RECOVERY_ARRIVE_DISTANCE := 1.35
const FLANK_DISTANCES := [5.0, 8.0, 12.0]
const RELOCATE_AFTER_STUCK_COUNT := 3

var _owner: CharacterBody3D
var _agent: NavigationAgent3D
var _agent_ready := false
var _retarget_timer := 0.0
var _stuck_timer := 0.0
var _stuck_count := 0
var _flank_sign := 1.0
var _pending_roll := false
var _pending_relocate := false
var _recovery_active := false
var _recovery_final := Vector3.ZERO
var _current_target := Vector3.ZERO
var _has_target := false


func setup(owner: CharacterBody3D) -> void:
	_owner = owner
	_agent = NavigationAgent3D.new()
	_agent.name = "CombatNavigationAgent"
	_agent.path_desired_distance = 0.55
	_agent.target_desired_distance = 1.15
	_agent.path_max_distance = 2.5
	_agent.radius = 0.35
	_agent.height = 1.6
	_agent.max_speed = 8.0
	_agent.avoidance_enabled = false
	owner.add_child(_agent)
	owner.call_deferred("_finalize_combat_nav_agent")


func mark_agent_ready() -> void:
	_agent_ready = true


func is_available() -> bool:
	if (
		_agent == null
		or not _agent_ready
		or _owner == null
		or not is_instance_valid(_owner)
		or not TownNavSetupScript.is_navigation_ready(_owner.get_tree())
	):
		return false

	var map_rid := _agent.get_navigation_map()
	var closest := NavigationServer3D.map_get_closest_point(map_rid, _owner.global_position)
	return _owner.global_position.distance_squared_to(closest) <= 2.25


func is_recovery_active() -> bool:
	return _recovery_active


func get_stuck_count() -> int:
	return _stuck_count


func consume_pending_relocate() -> bool:
	if not _pending_relocate:
		return false
	_pending_relocate = false
	return true


func set_target(world_pos: Vector3) -> void:
	_current_target = world_pos
	_has_target = true
	_retarget_timer = 0.0
	_push_target_to_agent()


func set_target_if_needed(world_pos: Vector3, threshold: float = 1.25) -> void:
	if _recovery_active:
		return
	if not _has_target or _current_target.distance_squared_to(world_pos) >= threshold * threshold:
		set_target(world_pos)


func clear_target() -> void:
	_has_target = false
	_recovery_active = false
	_recovery_final = Vector3.ZERO
	_stuck_count = 0
	_pending_roll = false
	_pending_relocate = false


func snap_position(world_pos: Vector3) -> Vector3:
	if not is_available():
		return world_pos
	var map_rid := _agent.get_navigation_map()
	return NavigationServer3D.map_get_closest_point(map_rid, world_pos)


func get_move_direction(delta: float) -> Vector3:
	if not is_available() or not _has_target:
		return Vector3.ZERO

	_tick_recovery()

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = RETARGET_INTERVAL
		_push_target_to_agent()

	var corner_dir := _get_path_corner_direction()
	if corner_dir.length_squared() > 0.0001:
		return corner_dir

	if _agent.is_navigation_finished():
		var to_target := _current_target - _owner.global_position
		to_target.y = 0.0
		if to_target.length_squared() <= PATH_ENDPOINT_EPSILON * PATH_ENDPOINT_EPSILON:
			return Vector3.ZERO
		return to_target.normalized()

	var next_pos := _agent.get_next_path_position()
	var to_next := next_pos - _owner.global_position
	to_next.y = 0.0
	if to_next.length_squared() < 0.0001:
		var to_target := _current_target - _owner.global_position
		to_target.y = 0.0
		if to_target.length_squared() < 0.0001:
			return Vector3.ZERO
		return to_target.normalized()
	return to_next.normalized()


func update_stuck(delta: float, horizontal_speed: float) -> void:
	if horizontal_speed > STUCK_SPEED_THRESHOLD:
		if _stuck_timer > 0.35:
			_stuck_count = 0
		_stuck_timer = 0.0
		_pending_roll = false
		return

	_stuck_timer += delta
	if _stuck_timer >= STUCK_TIME:
		_handle_stuck_event()


func consume_stuck_roll_request() -> bool:
	if not _pending_roll:
		return false
	_pending_roll = false
	_stuck_timer = 0.0
	return true


func handle_stuck_for_final_target(final_target: Vector3) -> void:
	_handle_stuck_event(final_target)


func force_wide_flank_recovery(final_target: Vector3) -> void:
	if _owner == null or not is_available():
		_pending_roll = true
		return
	_stuck_count = 0
	_stuck_timer = 0.0
	_pending_relocate = false
	var route_point := _pick_flank_point(final_target)
	if route_point == Vector3.ZERO:
		route_point = _pick_path_corner(final_target)
	if route_point != Vector3.ZERO:
		_begin_unstuck_route(route_point, final_target)
	else:
		_pending_roll = true


func get_roll_target_ahead(move_dir: Vector3, distance: float = 3.5) -> Vector3:
	if _owner == null:
		return Vector3.ZERO
	if move_dir.length_squared() < 0.0001:
		return _current_target
	return _owner.global_position + move_dir.normalized() * distance


func get_safe_roll_direction(preferred_dir: Vector3) -> Vector3:
	var candidates: Array[Vector3] = []
	if preferred_dir.length_squared() > 0.0001:
		candidates.append(preferred_dir.normalized())

	if _has_target:
		var to_target := _current_target - _owner.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			var forward := to_target.normalized()
			var lateral := forward.cross(Vector3.UP)
			candidates.append(lateral)
			candidates.append(-lateral)
			candidates.append(-forward)

	for dir: Vector3 in candidates:
		if _is_direction_clear(dir, 2.75):
			return dir
	return Vector3.ZERO


func _handle_stuck_event(final_target: Vector3 = Vector3.ZERO) -> void:
	if _owner == null or not is_available():
		_pending_roll = true
		return

	_stuck_count += 1
	_stuck_timer = 0.0
	_pending_roll = false
	_retarget_timer = 0.0
	_agent.path_max_distance = 4.5 if _stuck_count >= 2 else 2.5

	if final_target.length_squared() < 0.0001:
		final_target = _current_target

	var route_point := _pick_path_corner(final_target)
	if route_point == Vector3.ZERO:
		route_point = _pick_flank_point(final_target)

	if route_point != Vector3.ZERO:
		_begin_unstuck_route(route_point, final_target)
		return

	if _stuck_count >= RELOCATE_AFTER_STUCK_COUNT:
		_pending_relocate = true
		return

	_pending_roll = true


func _begin_unstuck_route(route_point: Vector3, final_point: Vector3) -> void:
	_recovery_active = true
	_recovery_final = final_point
	_current_target = route_point
	_has_target = true
	_push_target_to_agent()


func _tick_recovery() -> void:
	if not _recovery_active:
		return

	var to_route := _current_target - _owner.global_position
	to_route.y = 0.0
	if (
		to_route.length_squared() <= RECOVERY_ARRIVE_DISTANCE * RECOVERY_ARRIVE_DISTANCE
		or _agent.is_navigation_finished()
	):
		_recovery_active = false
		if _recovery_final.length_squared() > 0.0001:
			set_target(_recovery_final)
		_recovery_final = Vector3.ZERO


func _get_path_corner_direction() -> Vector3:
	if _owner == null or not _has_target or not is_available():
		return Vector3.ZERO

	var map_rid := _agent.get_navigation_map()
	var path := NavigationServer3D.map_get_path(
		map_rid,
		_owner.global_position,
		_current_target,
		true
	)
	if path.size() < 2:
		return Vector3.ZERO

	for i in range(1, path.size()):
		var corner := path[i]
		var to_corner := corner - _owner.global_position
		to_corner.y = 0.0
		if to_corner.length_squared() >= 2.0:
			return to_corner.normalized()
	return Vector3.ZERO


func _pick_path_corner(final_target: Vector3) -> Vector3:
	if _owner == null or not is_available():
		return Vector3.ZERO

	var map_rid := _agent.get_navigation_map()
	var path := NavigationServer3D.map_get_path(
		map_rid,
		_owner.global_position,
		final_target,
		true
	)
	if path.size() < 2:
		return Vector3.ZERO

	for i in range(1, path.size()):
		var corner := path[i]
		var to_corner := corner - _owner.global_position
		to_corner.y = 0.0
		if to_corner.length_squared() >= 2.25:
			return snap_position(corner)
	return snap_position(path[path.size() - 1])


func _pick_flank_point(final_target: Vector3) -> Vector3:
	if _owner == null or not is_available():
		return Vector3.ZERO

	var to_target := final_target - _owner.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Vector3.ZERO

	var forward := to_target.normalized()
	var lateral := forward.cross(Vector3.UP) * _flank_sign
	_flank_sign *= -1.0

	var map_rid := _agent.get_navigation_map()
	for flank_distance: float in FLANK_DISTANCES:
		var candidate := _owner.global_position + lateral * flank_distance
		var flank_point := NavigationServer3D.map_get_closest_point(map_rid, candidate)
		if flank_point.distance_squared_to(_owner.global_position) >= 2.25:
			return flank_point
	return Vector3.ZERO


func _is_direction_clear(direction: Vector3, distance: float) -> bool:
	if _owner == null or direction.length_squared() < 0.0001:
		return false

	var space_state := _owner.get_world_3d().direct_space_state
	if space_state == null:
		return true

	var origin := _owner.global_position + Vector3(0.0, 0.55, 0.0)
	var target := origin + direction.normalized() * distance
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [_owner.get_rid()]
	query.collide_with_areas = false
	query.collision_mask = 1
	var hit := space_state.intersect_ray(query)
	return hit.is_empty()


func _push_target_to_agent() -> void:
	if _agent == null or _owner == null or not _has_target:
		return
	_agent.target_position = _current_target
