extends Area3D

## Blue/white oval return portal. Proximity + E (or walk into the core) extracts.

const FADE_SECONDS := 1.0
const BLACK_HOLD_SECONDS := 0.15
const RING_SPIN_SPEED := 0.85
const PULSE_SPEED := 2.4
## Horizontal range for E / HUD registration (physics Area is a backup only).
const INTERACT_RADIUS := 4.5
## Walk into the glowing core to extract without pressing E.
const WALK_EXTRACT_RADIUS := 1.35

@export var interact_hint := "Return to town"
@export var portal_enabled := false
@export var walk_through_extracts := true

var _player_in_range: Node3D
var _transitioning := false
var _visual_root: Node3D
var _inner_mesh: MeshInstance3D
var _outer_mesh: MeshInstance3D
var _particles: GPUParticles3D
var _inner_mat: StandardMaterial3D
var _outer_mat: StandardMaterial3D
var _hint_label: Label3D
var _pulse_t := 0.0


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	# Broad mask — CharacterBody layers vary; proximity is the real gate.
	collision_mask = 0x7FFFFFFF
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visuals()
	_build_collision()
	visible = portal_enabled
	set_process(true)
	set_process_unhandled_input(true)
	_update_hint_label()


func set_portal_enabled(enabled: bool) -> void:
	portal_enabled = enabled
	visible = enabled
	_update_hint_label()
	if not enabled:
		_clear_player_in_range()
		return
	# Immediate proximity sync — don't wait on Area body_entered.
	_update_player_proximity()


func set_gate_enabled(enabled: bool) -> void:
	set_portal_enabled(enabled)


func get_interact_hint() -> String:
	if not portal_enabled or _transitioning:
		return ""
	return interact_hint


func allows_combat_interact() -> bool:
	return true


func interact(player: Node3D) -> void:
	_try_start_return(player)


func _process(delta: float) -> void:
	if portal_enabled and not _transitioning:
		_update_player_proximity()
	if not portal_enabled or _visual_root == null:
		return
	_pulse_t += delta
	if _outer_mesh != null:
		_outer_mesh.rotate_z(delta * RING_SPIN_SPEED)
	if _inner_mesh != null:
		_inner_mesh.rotate_z(-delta * RING_SPIN_SPEED * 1.35)
	var pulse := 0.55 + 0.45 * (0.5 + 0.5 * sin(_pulse_t * PULSE_SPEED))
	if _inner_mat != null:
		_inner_mat.emission_energy_multiplier = 1.2 + pulse * 2.4
		_inner_mat.albedo_color.a = 0.35 + pulse * 0.35
	if _outer_mat != null:
		_outer_mat.emission_energy_multiplier = 0.9 + pulse * 1.6


func _unhandled_input(event: InputEvent) -> void:
	if not portal_enabled or _transitioning:
		return
	if _player_in_range == null or not is_instance_valid(_player_in_range):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_try_start_return(_player_in_range)
		get_viewport().set_input_as_handled()


func _update_player_proximity() -> void:
	var player := _find_player()
	if player == null:
		_clear_player_in_range()
		return

	var offset := player.global_position - global_position
	offset.y = 0.0
	var dist := offset.length()
	if dist > INTERACT_RADIUS:
		_clear_player_in_range()
		return

	if _player_in_range != player:
		_clear_player_in_range()
		_player_in_range = player
		if player.has_method("register_interactable"):
			player.register_interactable(self)

	if walk_through_extracts and dist <= WALK_EXTRACT_RADIUS:
		_try_start_return(player)


func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("overworld_player"):
		if node is Node3D and is_instance_valid(node):
			return node as Node3D
	return null


func _try_start_return(player: Node3D) -> void:
	if not portal_enabled or _transitioning or player == null:
		return
	if not is_instance_valid(player):
		return
	_transitioning = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_hint_label()
	_clear_player_in_range()
	_begin_return(player)


func _begin_return(player: Node3D) -> void:
	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)
	if player.has_method("set_cinematic_invulnerable"):
		player.set_cinematic_invulnerable(true)
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(false)

	var hud: Node = null
	if player.has_method("get_raid_hud"):
		hud = player.get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()
	if hud != null and hud.has_method("show_zone_title"):
		hud.show_zone_title("Returning to town", FADE_SECONDS + 0.4)

	var fade_overlay := _get_fade_overlay()
	if fade_overlay != null and is_instance_valid(fade_overlay):
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_SECONDS)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	if is_inside_tree():
		await get_tree().create_timer(BLACK_HOLD_SECONDS).timeout

	# Autoload owns the extract — survives this node / stage teardown.
	await RunState.return_to_hub(true)


func _clear_player_in_range() -> void:
	if _player_in_range != null and is_instance_valid(_player_in_range):
		if _player_in_range.has_method("unregister_interactable"):
			_player_in_range.unregister_interactable(self)
	_player_in_range = null


func _update_hint_label() -> void:
	if _hint_label == null:
		return
	_hint_label.visible = portal_enabled and not _transitioning
	_hint_label.text = "[E] %s" % interact_hint


func _build_collision() -> void:
	var existing := get_node_or_null("CollisionShape3D")
	if existing != null:
		existing.free()
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACT_RADIUS
	shape.shape = sphere
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)


func _build_visuals() -> void:
	if get_node_or_null("PortalVisual") != null:
		_visual_root = get_node_or_null("PortalVisual") as Node3D
		_hint_label = _visual_root.get_node_or_null("HintLabel") as Label3D
		return

	_visual_root = Node3D.new()
	_visual_root.name = "PortalVisual"
	add_child(_visual_root)
	_visual_root.position = Vector3(0.0, 1.55, 0.0)

	_outer_mat = _make_portal_material(Color(0.55, 0.82, 1.0, 0.55), Color(0.35, 0.7, 1.0), 1.4)
	_inner_mat = _make_portal_material(Color(0.95, 0.98, 1.0, 0.65), Color(0.85, 0.95, 1.0), 2.2)

	_outer_mesh = _make_torus(1.15, 1.45, _outer_mat)
	_visual_root.add_child(_outer_mesh)

	_inner_mesh = _make_torus(0.55, 0.95, _inner_mat)
	_visual_root.add_child(_inner_mesh)

	var disc := MeshInstance3D.new()
	var disc_mesh := SphereMesh.new()
	disc_mesh.radius = 0.82
	disc_mesh.height = 0.12
	disc_mesh.radial_segments = 24
	disc_mesh.rings = 8
	disc.mesh = disc_mesh
	disc.material_override = _make_portal_material(
		Color(0.35, 0.65, 1.0, 0.42), Color(0.5, 0.85, 1.0), 3.0
	)
	_visual_root.add_child(disc)

	_particles = GPUParticles3D.new()
	_particles.amount = 48
	_particles.lifetime = 1.6
	_particles.preprocess = 0.5
	_particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 1.05
	mat.emission_ring_inner_radius = 0.7
	mat.emission_ring_height = 0.05
	mat.emission_ring_axis = Vector3(0.0, 0.0, 1.0)
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 18.0
	mat.initial_velocity_min = 0.35
	mat.initial_velocity_max = 1.1
	mat.gravity = Vector3(0.0, 0.4, 0.0)
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = Color(0.75, 0.9, 1.0, 0.9)
	_particles.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.06
	draw.height = 0.12
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.albedo_color = Color(0.9, 0.97, 1.0, 0.85)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.6, 0.85, 1.0)
	draw_mat.emission_energy_multiplier = 2.0
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	_particles.draw_pass_1 = draw
	_visual_root.add_child(_particles)

	_hint_label = Label3D.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = "[E] %s" % interact_hint
	_hint_label.font_size = 48
	_hint_label.modulate = Color(0.85, 0.95, 1.0, 0.95)
	_hint_label.outline_modulate = Color(0.05, 0.15, 0.35, 0.9)
	_hint_label.outline_size = 12
	_hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint_label.no_depth_test = true
	_hint_label.position = Vector3(0.0, 1.35, 0.0)
	_visual_root.add_child(_hint_label)
	_update_hint_label()


func _make_torus(inner_r: float, outer_r: float, material: Material) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner_r
	torus.outer_radius = outer_r
	torus.rings = 36
	torus.ring_segments = 18
	mesh_i.mesh = torus
	mesh_i.material_override = material
	mesh_i.rotation.x = PI * 0.5
	return mesh_i


func _make_portal_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.rim_enabled = true
	material.rim = 0.7
	return material


func _get_fade_overlay() -> ColorRect:
	var stage := get_tree().current_scene if get_tree() != null else null
	if stage != null and stage.has_method("get_duel_fade_overlay"):
		return stage.get_duel_fade_overlay()
	return null


func _on_body_entered(body: Node3D) -> void:
	# Backup path — proximity poll is primary.
	if not portal_enabled or _transitioning:
		return
	if body != null and body.is_in_group("overworld_player"):
		_update_player_proximity()


func _on_body_exited(_body: Node3D) -> void:
	pass
