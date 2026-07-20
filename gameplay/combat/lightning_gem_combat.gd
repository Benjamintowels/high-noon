extends RefCounted

## Lightning gem combat: attack-speed mult + budgeted on-hit chain bolts.
## Visual trail dust stays in elemental_attack_fx.gd.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const ElementalGemStamina := preload("res://gameplay/combat/elemental_gem_stamina.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const LightningStrikeFX := preload("res://gameplay/fx/lightning_strike_fx.gd")
const FxNodeBudget := preload("res://gameplay/fx/fx_node_budget.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const SPEED_MULT := 1.15
const BOLT_CHIP_DAMAGE := 0.5
const STUN_DURATION := 0.25
const ROOT_PROC_CHANCE := 1.0
const ARC_CHANCES: Array[float] = [0.30, 0.20, 0.10]
const ARC_RANGE := 5.0
const ARC_RANGE_SQ := ARC_RANGE * ARC_RANGE

const ROOT_PROC_COOLDOWN_MS := 80
const MAX_ROOT_PROCS_PER_FRAME := 6
const MAX_BOLTS_PER_FRAME := 12
const MAX_ARC_CANDIDATES := 12
const MAX_BOLT_VFX := 32

const PROC_COOLDOWN_META := &"lightning_gem_proc_msec"
const BOLT_VFX_CONTAINER := &"LightningBoltFx"
const BOLT_COLOR := Color(1.0, 0.94, 0.28, 1.0)

static var _budget_frame: int = -1
static var _root_procs_this_frame: int = 0
static var _bolts_this_frame: int = 0


static func get_speed_mult(weapon_id: int) -> float:
	if (
		PlayerInventory.weapon_has_gem(weapon_id, ElementalGems.LIGHTNING)
		and ElementalGemStamina.is_effect_active(weapon_id)
	):
		return SPEED_MULT
	return 1.0


static func try_proc_on_hit(shooter: Node, target: Node, weapon_id: int = -1) -> void:
	if shooter == null or target == null:
		return
	if not is_instance_valid(shooter) or not is_instance_valid(target):
		return
	if not shooter.is_in_group("overworld_player") and not shooter.is_in_group("player"):
		return

	var resolved_weapon := weapon_id
	if resolved_weapon < 0:
		var equipped: Variant = shooter.get("_equipped_weapon")
		if equipped != null:
			resolved_weapon = int(equipped)
	if resolved_weapon < 0:
		return
	if not PlayerInventory.weapon_has_gem(resolved_weapon, ElementalGems.LIGHTNING):
		return
	if not ElementalGemStamina.is_effect_active(resolved_weapon):
		return
	if not _is_eligible_bolt_target(shooter, target):
		return

	_reset_budgets_if_needed()
	if _root_procs_this_frame >= MAX_ROOT_PROCS_PER_FRAME:
		return
	if _bolts_this_frame >= MAX_BOLTS_PER_FRAME:
		return

	var now_ms := Time.get_ticks_msec()
	var last_ms := int(shooter.get_meta(PROC_COOLDOWN_META, -999999))
	if now_ms - last_ms < ROOT_PROC_COOLDOWN_MS:
		return
	if randf() > ROOT_PROC_CHANCE:
		# Still stamp a short cooldown so failed rolls don't spam RNG under pellet fire.
		shooter.set_meta(PROC_COOLDOWN_META, now_ms)
		return

	shooter.set_meta(PROC_COOLDOWN_META, now_ms)
	_root_procs_this_frame += 1

	var hit_ids: Dictionary = {}
	hit_ids[target.get_instance_id()] = true
	if not _apply_bolt(shooter, target):
		return

	var current: Node = target
	var tree := shooter.get_tree()
	if tree == null:
		return
	var candidates := _gather_candidate_nodes(tree)

	for chance in ARC_CHANCES:
		if _bolts_this_frame >= MAX_BOLTS_PER_FRAME:
			return
		if randf() > chance:
			return
		var next_target := _find_nearest_arc_target(current, shooter, hit_ids, candidates)
		if next_target == null:
			return
		hit_ids[next_target.get_instance_id()] = true
		if not _apply_bolt(shooter, next_target, current):
			return
		current = next_target


static func _reset_budgets_if_needed() -> void:
	var frame := Engine.get_physics_frames()
	if frame == _budget_frame:
		return
	_budget_frame = frame
	_root_procs_this_frame = 0
	_bolts_this_frame = 0


static func _apply_bolt(shooter: Node, target: Node, from_target: Node = null) -> bool:
	if _bolts_this_frame >= MAX_BOLTS_PER_FRAME:
		return false
	if not _is_eligible_bolt_target(shooter, target):
		return false
	_bolts_this_frame += 1

	var anchor := _target_anchor(target)
	var hit_info := {
		"position": anchor,
		"direction": Vector3.UP,
		"shooter": shooter,
		"damage": 0,
		"chip_damage": BOLT_CHIP_DAMAGE,
		"lightning_bolt_hit": true,
		"skip_knockback": true,
		"melee": false,
		"force_knockback": false,
	}
	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
	if target.has_method("apply_melee_stun"):
		target.apply_melee_stun(STUN_DURATION)

	CombatHitFlashScript.flash_electrify(target)
	_spawn_bolt_vfx(shooter, target, from_target, anchor)
	return true


static func _is_eligible_bolt_target(shooter: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == shooter:
		return false
	if target.is_in_group("overworld_player") or target.is_in_group("player"):
		return false
	if not target.has_method("receive_bullet_hit"):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if FactionAffinityScript.are_allies(shooter, target):
		return false
	return true


static func _gather_candidate_nodes(tree: SceneTree) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for group_name: StringName in [&"duel_target", &"cave_enemy", &"armory_test_target"]:
		for node in tree.get_nodes_in_group(group_name):
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			result.append(node)
	return result


static func _find_nearest_arc_target(
	from_target: Node,
	shooter: Node,
	hit_ids: Dictionary,
	candidates: Array
) -> Node:
	if from_target == null or not (from_target is Node3D):
		return null
	var from_pos := (from_target as Node3D).global_position
	var best: Node = null
	var best_dist_sq := ARC_RANGE_SQ
	var in_range_checked := 0
	for node in candidates:
		if node == null or not is_instance_valid(node):
			continue
		if hit_ids.has(node.get_instance_id()):
			continue
		if not _is_eligible_bolt_target(shooter, node):
			continue
		if not (node is Node3D):
			continue
		var dist_sq := (node as Node3D).global_position.distance_squared_to(from_pos)
		if dist_sq > ARC_RANGE_SQ or dist_sq < 0.0001:
			continue
		in_range_checked += 1
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = node
		if in_range_checked >= MAX_ARC_CANDIDATES:
			break
	return best


static func _target_anchor(target: Node) -> Vector3:
	if target is Node3D:
		return (target as Node3D).global_position + Vector3(0.0, 1.1, 0.0)
	return Vector3.ZERO


static func _spawn_bolt_vfx(
	shooter: Node,
	target: Node,
	from_target: Node,
	anchor: Vector3
) -> void:
	var parent := ImpactFXScript.parent_for(shooter if shooter is Node3D else target)
	if parent == null and target is Node:
		var tree := target.get_tree()
		if tree != null:
			parent = tree.current_scene
	if parent == null:
		return

	var container := FxNodeBudget.ensure_container(parent, BOLT_VFX_CONTAINER)
	if container == null:
		return
	# Strike + optional arc segment + light — make room instead of skipping.
	FxNodeBudget.ensure_room(container, MAX_BOLT_VFX, 4)

	LightningStrikeFX.spawn(container, anchor, false)

	var flash_light := OmniLight3D.new()
	flash_light.light_color = BOLT_COLOR
	flash_light.light_energy = 4.5
	flash_light.omni_range = 3.5
	flash_light.shadow_enabled = false
	container.add_child(flash_light)
	flash_light.global_position = anchor
	var light_tween := flash_light.create_tween()
	light_tween.set_ignore_time_scale(true)
	light_tween.tween_property(flash_light, "light_energy", 0.0, 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	light_tween.tween_callback(flash_light.queue_free)

	if from_target is Node3D and target is Node3D:
		_spawn_connecting_arc(container, _target_anchor(from_target), anchor)


static func _spawn_connecting_arc(container: Node3D, from_pos: Vector3, to_pos: Vector3) -> void:
	var delta := to_pos - from_pos
	var length := delta.length()
	if length < 0.15:
		return
	FxNodeBudget.ensure_room(container, MAX_BOLT_VFX, 3)

	var mid := from_pos + delta * 0.5
	LightningStrikeFX.spawn(container, mid, true)

	var arc := MeshInstance3D.new()
	var arc_box := BoxMesh.new()
	arc_box.size = Vector3(0.1, 0.1, length)
	arc.mesh = arc_box
	var arc_mat := StandardMaterial3D.new()
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.albedo_color = BOLT_COLOR
	arc_mat.emission_enabled = true
	arc_mat.emission = BOLT_COLOR
	arc_mat.emission_energy_multiplier = 5.5
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override = arc_mat
	container.add_child(arc)
	var dir := delta / length
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.95:
		up = Vector3.FORWARD
	arc.global_basis = Basis.looking_at(dir, up)
	arc.global_position = mid

	var arc_tween := arc.create_tween()
	arc_tween.set_ignore_time_scale(true)
	arc_tween.tween_property(arc_mat, "albedo_color:a", 0.0, 0.28)
	arc_tween.tween_callback(arc.queue_free)
