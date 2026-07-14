extends Node
class_name CanyonGateTransition
## Multi-gate zone-transition cinematic (hotel ↔ canyon ↔ church ↔ town).
## Letterbox + look-at camera + white zone title, then StageZoneCuller swaps
## heavy stage roots so only the active region draws and simulates. Each gate
## declares the zone/title/look-marker on both of its sides.

const StageZoneCuller := preload("res://gameplay/world/stage_zone_culler.gd")

const TITLE_CANYONS := "The Canyons"
const TITLE_HOTEL := "The Hotel"
const TITLE_CHURCH := "The Old Church"
const TITLE_TOWN := "The Town"
const TITLE_HOLD_SECONDS := 2.0
const TITLE_FADE_IN := 0.25
const TITLE_FADE_OUT := 0.55
const CAMERA_BLEND_IN_SECONDS := 0.45
const CAMERA_RETURN_SECONDS := 0.9
const LETTERBOX_OUT_SECONDS := 0.55
const MOVE_DIR_MIN_SPEED := 0.35
const DEFAULT_WALK_SPEED := 3.6

const FALLBACK_INNER_LOOK_LOCAL := Vector3(-22.0, 4.0, 0.0)
const FALLBACK_OUTER_LOOK_LOCAL := Vector3(28.0, 4.0, 0.0)

enum Zone {
	OVERWORLD,
	CANYON,
	CHURCH,
}

class GateBinding:
	var trigger: Area3D
	var inner_look: Marker3D
	var outer_look: Marker3D
	var inner_zone: int = Zone.CANYON
	var outer_zone: int = Zone.OVERWORLD
	var inner_title: String = TITLE_CANYONS
	var outer_title: String = TITLE_HOTEL
	var armed := true
	var player_inside := false


var _player: Node3D
var _stage: Node3D
var _gates: Array[GateBinding] = []
var _zone: int = Zone.OVERWORLD
var _active := false
var _overworld_roots: Array[Node3D] = []
var _canyon_root: Node3D
var _church_root: Node3D
var _church_culler: DistanceZoneCuller


func setup(player: Node3D, stage: Node3D) -> void:
	if player == null or stage == null:
		return
	_player = player
	_stage = stage
	_resolve_zone_roots()
	_apply_zone_state(_zone)


func bind_church_culler(culler: DistanceZoneCuller) -> void:
	_church_culler = culler


func add_gate(
	trigger: Area3D,
	inner_zone: int,
	inner_title: String,
	inner_look_name: String,
	outer_zone: int,
	outer_title: String,
	outer_look_name: String
) -> void:
	if trigger == null:
		return
	var gate := GateBinding.new()
	gate.trigger = trigger
	gate.inner_zone = inner_zone
	gate.inner_title = inner_title
	gate.outer_zone = outer_zone
	gate.outer_title = outer_title
	_configure_trigger(trigger)
	_resolve_gate_look_markers(gate, inner_look_name, outer_look_name)
	trigger.body_entered.connect(_on_body_entered.bind(gate))
	trigger.body_exited.connect(_on_body_exited.bind(gate))
	_gates.append(gate)


func is_in_canyon() -> bool:
	return _zone == Zone.CANYON


func get_zone() -> int:
	return _zone


## Restore zone culling after spawn/load without playing the cinematic.
func sync_from_player_position() -> void:
	if _player == null:
		return
	_zone = _detect_zone(_player.global_position)
	_apply_zone_state(_zone)


## Fast-travel / checkpoint arrival — map known bonfire ids to zones so we do
## not depend on walking through a gate Area3D.
func sync_from_travel_id(travel_id: String) -> void:
	var id := travel_id.strip_edges().to_lower()
	match id:
		"canyon":
			force_set_zone(Zone.CANYON)
		"church":
			force_set_zone(Zone.CHURCH)
		"town", "hotel":
			force_set_zone(Zone.OVERWORLD)
		_:
			sync_from_player_position()


func force_set_zone(zone: int) -> void:
	_zone = zone
	_apply_zone_state(_zone)


func _resolve_zone_roots() -> void:
	_overworld_roots.clear()
	for path in ["Town", "Environment", "CavePuzzle", "Terrain/DistantMesas"]:
		var node := _stage.get_node_or_null(path) as Node3D
		if node != null:
			_overworld_roots.append(node)

	_canyon_root = _stage.get_node_or_null("Canyon") as Node3D
	if _canyon_root == null:
		_canyon_root = Node3D.new()
		_canyon_root.name = "Canyon"
		_stage.add_child(_canyon_root)

	_church_root = _stage.get_node_or_null("Church") as Node3D


func _configure_trigger(trigger: Area3D) -> void:
	trigger.monitoring = true
	trigger.monitorable = false
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	var collision := trigger.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = false


func _resolve_gate_look_markers(
	gate: GateBinding,
	inner_look_name: String,
	outer_look_name: String
) -> void:
	gate.inner_look = gate.trigger.get_node_or_null(inner_look_name) as Marker3D
	gate.outer_look = gate.trigger.get_node_or_null(outer_look_name) as Marker3D
	if gate.inner_look == null:
		gate.inner_look = Marker3D.new()
		gate.inner_look.name = inner_look_name
		gate.trigger.add_child(gate.inner_look)
		gate.inner_look.position = FALLBACK_INNER_LOOK_LOCAL
	if gate.outer_look == null:
		gate.outer_look = Marker3D.new()
		gate.outer_look.name = outer_look_name
		gate.trigger.add_child(gate.outer_look)
		gate.outer_look.position = FALLBACK_OUTER_LOOK_LOCAL


func _on_body_entered(body: Node3D, gate: GateBinding) -> void:
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player = body
	gate.player_inside = true
	if _active or not gate.armed:
		return
	_begin_sequence(gate, _resolve_entering_inner(body, gate))


func _on_body_exited(body: Node3D, gate: GateBinding) -> void:
	if body == null or body != _player:
		return
	gate.player_inside = false
	if _active:
		return
	gate.armed = true


func _resolve_entering_inner(player: Node3D, gate: GateBinding) -> bool:
	var into := _into_inner_direction(gate)
	var move := Vector3.ZERO
	if player is CharacterBody3D:
		move = (player as CharacterBody3D).velocity
	move.y = 0.0
	if move.length() >= MOVE_DIR_MIN_SPEED and into.length_squared() > 0.0001:
		return move.dot(into) > 0.0
	return _zone != gate.inner_zone


func _into_inner_direction(gate: GateBinding) -> Vector3:
	if gate.inner_look == null or gate.outer_look == null:
		return Vector3.LEFT
	var into := gate.inner_look.global_position - gate.outer_look.global_position
	into.y = 0.0
	if into.length_squared() < 0.0001:
		return Vector3.LEFT
	return into.normalized()


func _begin_sequence(gate: GateBinding, entering_inner: bool) -> void:
	if _active:
		return
	_active = true
	gate.armed = false

	var dest_zone: int = gate.inner_zone if entering_inner else gate.outer_zone
	var look_target := gate.inner_look if entering_inner else gate.outer_look
	var title := gate.inner_title if entering_inner else gate.outer_title
	var into := _into_inner_direction(gate)
	var walk_dir := into if entering_inner else -into
	var walk_speed := DEFAULT_WALK_SPEED
	if _player is CharacterBody3D:
		var horizontal := Vector3(
			(_player as CharacterBody3D).velocity.x,
			0.0,
			(_player as CharacterBody3D).velocity.z
		)
		if horizontal.length() > MOVE_DIR_MIN_SPEED:
			walk_speed = horizontal.length()

	if _player != null and _player.has_method("begin_cinematic_walk"):
		_player.begin_cinematic_walk(walk_dir, walk_speed)
	elif _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(true)

	if _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(look_target)

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	await get_tree().create_timer(CAMERA_BLEND_IN_SECONDS).timeout

	var zone_changed := dest_zone != _zone
	_zone = dest_zone
	_apply_zone_state(_zone)
	if zone_changed:
		# Sky-shift across the title hold + camera return while the player
		# is looking at the destination vista.
		var sky_duration := (
			TITLE_FADE_IN
			+ TITLE_HOLD_SECONDS
			+ TITLE_FADE_OUT
			+ maxf(CAMERA_RETURN_SECONDS, LETTERBOX_OUT_SECONDS)
		)
		DayNightCycle.advance_phase_tweened(sky_duration)

	if hud != null and hud.has_method("show_zone_title"):
		hud.show_zone_title(title, TITLE_HOLD_SECONDS)
	await get_tree().create_timer(TITLE_FADE_IN + TITLE_HOLD_SECONDS + TITLE_FADE_OUT).timeout

	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()

	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()

	await get_tree().create_timer(maxf(CAMERA_RETURN_SECONDS, LETTERBOX_OUT_SECONDS)).timeout
	_finish_sequence(gate)


func _finish_sequence(gate: GateBinding) -> void:
	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()
	if _player != null and _player.has_method("end_cinematic_walk"):
		_player.end_cinematic_walk()
	elif _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)
	_active = false
	if gate != null and not gate.player_inside:
		gate.armed = true


func _apply_zone_state(zone: int) -> void:
	var in_overworld := zone == Zone.OVERWORLD
	var in_canyon := zone == Zone.CANYON
	var in_church := zone == Zone.CHURCH

	for root in _overworld_roots:
		if root == null or not is_instance_valid(root):
			continue
		StageZoneCuller.set_zone_active(root, in_overworld)

	if _canyon_root != null and is_instance_valid(_canyon_root):
		StageZoneCuller.set_zone_active(_canyon_root, in_canyon)

	# Dynamic actors live under stage/CanyonBandits and stage/TownActors. Only
	# toggle visibility/process — do NOT run StageZoneCuller on them (it
	# force-toggles CollisionShape3Ds on the NPCs and leaves them frozen/broken
	# across zone toggles).
	if _stage != null:
		var bandits_host := _stage.get_node_or_null("CanyonBandits") as Node3D
		if bandits_host != null:
			bandits_host.visible = in_canyon
			bandits_host.process_mode = (
				Node.PROCESS_MODE_PAUSABLE if in_canyon else Node.PROCESS_MODE_DISABLED
			)
		var town_actors := _stage.get_node_or_null("TownActors") as Node3D
		if town_actors != null:
			town_actors.visible = in_overworld
			town_actors.process_mode = (
				Node.PROCESS_MODE_PAUSABLE if in_overworld else Node.PROCESS_MODE_DISABLED
			)

	# NewGameHotel + canyon gates stay outside culled roots so Area3Ds keep
	# working. Church is owned by DistanceZoneCuller in overworld mode. The
	# town ↔ church gate lives UNDER the Church root, which is safe: the culler
	# re-enables the whole root (trigger included) whenever the player is close
	# enough to reach that gate.
	if _church_culler != null:
		if in_overworld:
			_church_culler.set_suspended(false)
		else:
			_church_culler.set_suspended(true)
			_church_culler.force_set_active(in_church)
	elif _church_root != null and is_instance_valid(_church_root):
		StageZoneCuller.set_zone_active(_church_root, in_church)

	if in_canyon:
		# Wait a frame so StageZoneCuller collision restores before floor-snaps.
		call_deferred("_arm_canyon_bandits")


func _arm_canyon_bandits() -> void:
	if _stage != null and _stage.has_method("ensure_canyon_bandits_spawned"):
		_stage.ensure_canyon_bandits_spawned(_player)
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("canyon_bandit_spawn"):
		if node.has_method("ensure_spawned"):
			node.ensure_spawned(_player)
		elif node.has_method("arm_hostility_if_alive"):
			node.arm_hostility_if_alive(_player)


## The gate whose look markers are nearest to the player decides the zone:
## whichever of its two sides is closer wins. Far-away gates would otherwise
## vote with stale half-space guesses (e.g. the canyon reads as the church
## side of the town ↔ church gate).
func _detect_zone(world_pos: Vector3) -> int:
	var best_zone: int = Zone.OVERWORLD
	var best_dist_sq := INF
	for gate in _gates:
		if gate.inner_look == null or gate.outer_look == null:
			continue
		var to_inner := gate.inner_look.global_position.distance_squared_to(world_pos)
		var to_outer := gate.outer_look.global_position.distance_squared_to(world_pos)
		var nearest := minf(to_inner, to_outer)
		if nearest < best_dist_sq:
			best_dist_sq = nearest
			best_zone = gate.inner_zone if to_inner < to_outer else gate.outer_zone
	return best_zone


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null
