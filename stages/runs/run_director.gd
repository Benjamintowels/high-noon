extends Node

## Owns a roguelike run stage: difficulty meter, modifiers, wave spawns,
## boss tower / portal flow. Parent should be a run zone root.

const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const RunStageConfigScript := preload("res://gameplay/runs/run_stage_config.gd")
const RunLootDirectorScript := preload("res://gameplay/runs/run_loot_director.gd")
const RunLootChestScript := preload("res://gameplay/runs/run_loot_chest.gd")
const RunEnemyTuningScript := preload("res://gameplay/runs/run_enemy_tuning.gd")
const RunEnemyTierScript := preload("res://gameplay/runs/run_enemy_tier.gd")
const RunCorpseCleanupScript := preload("res://gameplay/runs/run_corpse_cleanup.gd")
const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")
const RunReturnPortalScript := preload("res://gameplay/runs/run_return_portal.gd")
const GemEnemyStatusScript := preload("res://gameplay/runs/gem_enemy_status.gd")
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const RunEncounterSpawnSpecScript := preload("res://gameplay/runs/run_encounter_spawn_spec.gd")
const BrawlAuraFXScript := preload("res://gameplay/fx/brawl_aura_fx.gd")
const HitchProfiler := preload("res://gameplay/debug/run_hitch_profiler.gd")
const NpcAnimCache := preload("res://characters/groyper/groyper_npc_anim_cache.gd")

const GEM_ENEMY_PITY_MAX := 50
const GEM_ENEMY_FALLBACK_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")

## One full bandit AnimationTree build per frame is already a spike — never
## instantiate more than this from the spawn queue in a single _process.
const SPAWNS_PER_FRAME := 1
## First encounter area's hybrid drip: this many unarmed, then revolvers.
const DRY_GULCH_FIRST_AREA_UNARMED_DRIP := 5
const ENCOUNTER_MINI_ELITE_HEALTH_MULT := 2.0
const RUN_BRAWL_AURA_META := &"run_brawl_aura"

enum Phase { WAVES, BOSS_SUMMONED, BOSS_DEAD, PORTAL_OPEN }
enum EncounterState { PENDING, ACTIVE, CLEARED, REINFORCED }

## Defeated enemies ragdoll then fade/sink out (RunCorpseCleanup). Cap still
## exists so long portal farms can't pile skinned meshes forever.
const MAX_CORPSES := 28
const ENCOUNTER_JITTER_RADIUS := 3.5

signal difficulty_changed(difficulty: float)
signal modifier_added(modifier: Resource)
signal phase_changed(phase: int)

@export var stage_config: Resource
@export var auto_start := true

var difficulty: float = 0.0
var phase: int = Phase.WAVES
var active_modifiers: Array = []

var _config: Resource
var _player: Node3D
var _enemy_host: Node
var _alive_enemies: Array[Node3D] = []
var _corpses: Array[Node3D] = []
var _wave_index := 0
var _wave_timer := 0.0
var _modifier_threshold_index := 0
var _boss: Node3D
var _boss_tower: Node3D
var _return_portal: Node
var _started := false

## Timed wavegroup schedule (legacy drip / hybrid drip path).
var _run_elapsed := 0.0
var _use_wave_groups := false
var _use_timed_drip := false
var _wave_groups: Array = []
## Indices into _wave_groups that may drip near the player.
var _drip_group_indices: Array[int] = []
var _unlocked_group_indices: Array[int] = []
var _group_spawn_timers: PackedFloat32Array = PackedFloat32Array()
var _group_spawn_intervals: PackedFloat32Array = PackedFloat32Array()
var _schedule_milestone := 0
var _elite_rotate_index := 0
var _all_groups_unlocked := false
## Single hybrid drip clock (one enemy every hybrid_drip_interval_seconds).
var _hybrid_drip_timer := 0.0
## Per-area drip budgets (RunEncounterAreas child order). Empty = uncapped.
## FIFO queue entries: { area_id, remaining }. Anchors cached at grant time.
const DRIP_LATERAL_JITTER := 2.0
var _drip_budgets: PackedInt32Array = PackedInt32Array()
var _drip_budget_queue: Array[Dictionary] = []
## area_id → Vector3 spawn anchor (inside GateWall at trigger time).
var _drip_spawn_anchors: Dictionary = {}
## Encounter areas in RunEncounterAreas child order (budget index order).
var _encounter_area_order: Array[StringName] = []

## Area-triggered encounter packs (Dry Gulch).
var _use_encounter_areas := false
var _encounter_areas: Array[Node3D] = []
## area_id → { state, enemies: Array[Node3D], was_inside: bool }
var _encounter_runtime: Dictionary = {}

var _active_gem_enemy: Node3D
var _gem_enemy_pending := false
var _kill_goal_portal_opened := false
var _kill_hud_ready := false
## Cached Terrain3D for heightmap snaps (raycasts miss / hit props outdoors).
var _terrain3d: Terrain3D
## Pending `{scene, pos, opts, on_spawned}` — drained SPAWNS_PER_FRAME / frame.
var _spawn_queue: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("run_director")
	_ensure_config()
	set_process(false)


func begin_run(player: Node3D) -> void:
	if _started:
		return
	_started = true
	_ensure_config()
	_player = player
	_enemy_host = _find_enemy_host()
	_return_portal = _find_return_portal()
	if _return_portal != null:
		if _return_portal.has_method("set_portal_enabled"):
			_return_portal.set_portal_enabled(false)
		elif _return_portal.has_method("set_gate_enabled"):
			_return_portal.set_gate_enabled(false)
		if _return_portal is Node3D:
			(_return_portal as Node3D).visible = false
	var legacy_visual := get_parent().get_node_or_null("ReturnPortalVisual") as Node3D
	if legacy_visual != null:
		legacy_visual.visible = false
	_place_boss_tower()
	_init_wave_group_schedule()
	_init_encounter_areas()
	_init_hybrid_drip_budgets()
	var hitch_t := HitchProfiler.begin()
	_preload_wave_scenes()
	HitchProfiler.end(HitchProfiler.LABEL_DIRECTOR_PRELOAD, hitch_t)
	# Pay FBX→AnimationLibrary build under the fade so first bandit is ~1ms.
	hitch_t = HitchProfiler.begin()
	NpcAnimCache.warm()
	HitchProfiler.end(HitchProfiler.LABEL_DIRECTOR_ANIM_WARM, hitch_t)
	if _use_timed_drip:
		_unlock_due_wave_groups(true)
		# Encounter areas own first contact; skip the opener drip pack.
		if not _use_encounter_areas:
			_spawn_initial_wavegroup_enemies()
	elif not _use_encounter_areas:
		_spawn_preset_wave()
	await _populate_run_loot()
	if _config != null:
		_wave_timer = float(_config.get("first_wave_delay"))
	else:
		_wave_timer = 1.0
		push_error("RunDirector: begin_run without config — waves disabled.")
		return
	_kill_goal_portal_opened = false
	_kill_hud_ready = false
	call_deferred("_setup_kill_goal_hud")
	set_process(true)
	RunState.set_meta("active_run_director", self)


func _exit_tree() -> void:
	if RunState.has_meta("active_run_director") and RunState.get_meta("active_run_director") == self:
		RunState.remove_meta("active_run_director")


func on_player_kill() -> void:
	if not RunState.run_active:
		return
	_update_kill_goal_hud()
	_try_open_portal_for_kill_goal()
	on_player_kill_for_gem_enemy()


func on_player_kill_for_gem_enemy() -> void:
	if not RunState.run_active:
		return
	_prune_dead_enemies()
	if _is_gem_enemy_alive() or _gem_enemy_pending:
		return
	RunState.gem_enemy_pity += 1
	var pity := RunState.gem_enemy_pity
	var force := pity >= GEM_ENEMY_PITY_MAX
	var chance := float(pity) / float(GEM_ENEMY_PITY_MAX)
	if not force and randf() > chance:
		return
	if _spawn_gem_enemy():
		RunState.gem_enemy_pity = 0


func _tier_profile() -> StringName:
	if _config == null:
		return RunEnemyTierScript.PROFILE_DEFAULT
	var profile: Variant = _config.get("tier_profile")
	if profile == null or str(profile) == "":
		return RunEnemyTierScript.PROFILE_DEFAULT
	return profile as StringName


func _setup_kill_goal_hud() -> void:
	_kill_hud_ready = false
	if _config == null:
		return
	var goal := int(_config.get("kill_goal"))
	if goal <= 0:
		return
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null or not _player.has_method("get_raid_hud"):
		return
	var hud: Node = _player.get_raid_hud()
	if hud == null:
		return
	var title := str(_config.get("kill_goal_hud_title"))
	if title == "":
		title = "Enemies"
	if hud.has_method("show_run_kill_goal"):
		hud.call("show_run_kill_goal", goal, title)
	elif hud.has_method("show_raid_start"):
		hud.call("show_raid_start", goal)
	_kill_hud_ready = true
	_update_kill_goal_hud()


func _update_kill_goal_hud() -> void:
	if not _kill_hud_ready or _config == null:
		return
	var goal := int(_config.get("kill_goal"))
	if goal <= 0:
		return
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null or not _player.has_method("get_raid_hud"):
		return
	var hud: Node = _player.get_raid_hud()
	if hud != null and hud.has_method("update_kill_count"):
		hud.call("update_kill_count", RunState.run_kills, goal)


func _try_open_portal_for_kill_goal() -> void:
	if _kill_goal_portal_opened or _config == null:
		return
	var goal := int(_config.get("kill_goal"))
	if goal <= 0 or RunState.run_kills < goal:
		return
	if phase != Phase.WAVES and phase != Phase.PORTAL_OPEN:
		return
	_kill_goal_portal_opened = true
	_announce("Extract ready — %d down" % goal)
	if phase != Phase.PORTAL_OPEN:
		open_return_portal()


func _is_gem_enemy_alive() -> bool:
	if _active_gem_enemy != null and is_instance_valid(_active_gem_enemy):
		if _active_gem_enemy.has_method("is_defeated") and _active_gem_enemy.is_defeated():
			_active_gem_enemy = null
			return false
		if GemEnemyStatusScript.is_fading(_active_gem_enemy):
			return true
		return true
	_active_gem_enemy = null
	return false


func _spawn_gem_enemy() -> bool:
	if _gem_enemy_pending:
		return false
	if _alive_plus_queued() >= _get_max_alive_enemies():
		# Soft-cap: still allow one gem enemy above room by pruning first.
		_prune_dead_enemies()
	var scene := _pick_gem_enemy_scene()
	if scene == null:
		scene = GEM_ENEMY_FALLBACK_SCENE
	var pos: Variant = _pick_spawn_position()
	if pos == null:
		return false
	var gem_ids := ElementalGems.get_active_gem_ids()
	if gem_ids.is_empty():
		return false
	var gem_id: StringName = gem_ids[randi() % gem_ids.size()]
	_gem_enemy_pending = true
	var enqueued := _enqueue_spawn(
		scene,
		pos as Vector3,
		{
			"weapon_id": -1,
			"melee_only": true,
			"health_mult": 5.0,
			"loot_mult": 1.0,
			"elite": false,
			"visual_scale": 1.0,
			"skip_aggro": true,
			"gem_enemy": true,
			"gem_id": gem_id,
		},
		_on_gem_enemy_spawned,
		true
	)
	if not enqueued:
		_gem_enemy_pending = false
		return false
	return true


func _on_gem_enemy_spawned(enemy: Node3D) -> void:
	_gem_enemy_pending = false
	if enemy == null or not is_instance_valid(enemy):
		return
	_active_gem_enemy = enemy
	_announce("A gleaming stranger appears…")


func _pick_gem_enemy_scene() -> PackedScene:
	var group_index := -1
	if not _unlocked_group_indices.is_empty():
		group_index = _unlocked_group_indices[_unlocked_group_indices.size() - 1]
	elif not _wave_groups.is_empty():
		group_index = 0
	if group_index >= 0 and group_index < _wave_groups.size():
		var group: Resource = _wave_groups[group_index]
		if group != null and group.has_method("pick_base_unit"):
			var unit: Resource = group.pick_base_unit(_run_elapsed)
			if unit != null and unit.get("enemy_scene") is PackedScene:
				return unit.get("enemy_scene") as PackedScene
	return GEM_ENEMY_FALLBACK_SCENE


func get_loot_multiplier() -> float:
	if _config == null:
		return 1.0
	var mult := float(_config.get("base_loot_mult"))
	mult += difficulty * float(_config.get("loot_mult_per_difficulty"))
	for modifier in active_modifiers:
		if modifier != null:
			mult *= float(modifier.get("loot_mult"))
	return maxf(mult, 0.05)


func get_difficulty() -> float:
	return difficulty


func request_summon_boss(tower: Node3D, player: Node3D) -> void:
	if phase != Phase.WAVES:
		return
	if _config == null or _config.get("boss_scene") == null:
		push_warning("RunDirector: no boss_scene configured.")
		return
	_player = player if player != null else _player
	var boss_scene: PackedScene = _config.get("boss_scene")
	_boss = boss_scene.instantiate() as Node3D
	if _boss == null:
		return
	# Flag before add_child so deferred _finalize_spawn skips the sit pose.
	if "run_boss_mode" in _boss:
		_boss.set("run_boss_mode", true)
	var host := get_parent()
	# Position BEFORE add_child: the boss's _ready captures _sit_hold_position
	# from its current transform, and his sitting-phase physics tick can run
	# before the deferred fight start — placing him only after add_child let
	# that tick snap him back to the world origin (boss "never appeared").
	if host is Node3D:
		_boss.transform = (host as Node3D).global_transform.affine_inverse() * tower.global_transform
	else:
		_boss.transform = tower.global_transform
	host.add_child(_boss)
	_boss.global_transform = tower.global_transform
	if _boss.has_method("snap_to_floor"):
		_boss.snap_to_floor()
	# Defer so actor _finalize_spawn (also deferred) runs first.
	if _boss.has_method("start_as_run_boss"):
		_boss.call_deferred("start_as_run_boss", _player)
	elif _boss.has_method("_begin_boss_fight"):
		_boss.call_deferred("_begin_boss_fight", _player)
	if _boss.has_signal("run_boss_defeated"):
		_boss.connect("run_boss_defeated", _on_boss_defeated)
	# Fallback: if the outro callback is skipped, free still opens the portal.
	if not _boss.tree_exiting.is_connected(_on_boss_tree_exiting):
		_boss.tree_exiting.connect(_on_boss_tree_exiting)
	phase = Phase.BOSS_SUMMONED
	phase_changed.emit(phase)
	if tower.has_method("mark_used"):
		tower.mark_used()


func open_return_portal() -> void:
	_ensure_return_portal()
	if _return_portal == null:
		push_warning("RunDirector: ReturnPortal missing.")
		return
	# Place first, then enable — enable syncs overlaps after the move so the
	# player standing near the spawn point still gets the E prompt / walk-in.
	_place_return_portal_near_player()
	if _return_portal is Node3D:
		(_return_portal as Node3D).visible = true
	if _return_portal.has_method("set_portal_enabled"):
		_return_portal.set_portal_enabled(true)
	elif _return_portal.has_method("set_gate_enabled"):
		_return_portal.set_gate_enabled(true)
	var visual := get_parent().get_node_or_null("ReturnPortalVisual") as Node3D
	if visual != null:
		visual.visible = false
	phase = Phase.PORTAL_OPEN
	phase_changed.emit(phase)
	_announce("Portal open — return to town when ready")
	if _player != null and _player.has_method("set_cinematic_invulnerable"):
		_player.set_cinematic_invulnerable(false)


func _process(delta: float) -> void:
	if _config == null:
		_ensure_config()
	if _config == null:
		return
	_prune_dead_enemies()
	_drain_spawn_queue()
	# Difficulty + modifiers keep climbing even after the portal opens so long
	# stays get harder (and richer) before extract.
	if phase != Phase.BOSS_DEAD:
		_tick_difficulty(delta)
		_try_roll_modifiers()
	# Waves pause only during the Chief outro; portal phase keeps farming.
	if phase != Phase.WAVES and phase != Phase.PORTAL_OPEN:
		return

	_run_elapsed += delta
	if _use_encounter_areas:
		_tick_encounter_areas()
	if _use_timed_drip:
		_tick_wave_group_schedule()
		_tick_wave_group_spawns(delta)
	elif not _use_encounter_areas:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_spawn_dynamic_wave()
			_wave_timer = float(_config.get("wave_interval"))


func _tick_difficulty(delta: float) -> void:
	var gain := float(_config.get("difficulty_per_second")) * delta
	for modifier in active_modifiers:
		if modifier != null:
			gain *= float(modifier.get("difficulty_gain_mult"))
	_set_difficulty(difficulty + gain)


func _set_difficulty(value: float) -> void:
	var capped := clampf(value, 0.0, float(_config.get("max_difficulty")))
	if is_equal_approx(capped, difficulty):
		return
	difficulty = capped
	difficulty_changed.emit(difficulty)


func _try_roll_modifiers() -> void:
	var thresholds: PackedFloat32Array = _config.get("modifier_thresholds")
	var max_mods: int = int(_config.get("max_active_modifiers"))
	while (
		_modifier_threshold_index < thresholds.size()
		and difficulty >= thresholds[_modifier_threshold_index]
		and active_modifiers.size() < max_mods
	):
		_modifier_threshold_index += 1
		var pool = _config.get("modifier_pool")
		if pool == null or not pool.has_method("pick_for_difficulty"):
			continue
		var exclude: Array[StringName] = []
		for modifier in active_modifiers:
			if modifier != null:
				exclude.append(modifier.get("id") as StringName)
		var picked = pool.pick_for_difficulty(difficulty, exclude)
		if picked == null:
			continue
		active_modifiers.append(picked)
		modifier_added.emit(picked)
		var label := str(picked.get("display_name"))
		if label != "":
			_announce(label)


func _init_wave_group_schedule() -> void:
	_wave_groups.clear()
	_drip_group_indices.clear()
	_unlocked_group_indices.clear()
	_group_spawn_timers = PackedFloat32Array()
	_group_spawn_intervals = PackedFloat32Array()
	_schedule_milestone = 0
	_elite_rotate_index = 0
	_all_groups_unlocked = false
	_run_elapsed = 0.0
	_use_wave_groups = false
	_use_timed_drip = false
	if _config == null:
		return
	var groups: Variant = _config.get("wave_groups")
	if groups == null or not (groups is Array) or (groups as Array).is_empty():
		return
	for group in groups as Array:
		if group == null:
			continue
		_wave_groups.append(group)
	if _wave_groups.is_empty():
		return
	_use_wave_groups = true
	_group_spawn_timers.resize(_wave_groups.size())
	_group_spawn_intervals.resize(_wave_groups.size())
	var hybrid := bool(_config.get("hybrid_drip_enabled"))
	var interval_mult := 1.0
	if hybrid:
		interval_mult = maxf(float(_config.get("hybrid_drip_interval_mult")), 1.0)
	for i in _wave_groups.size():
		var group: Resource = _wave_groups[i]
		var interval := float(group.get("base_spawn_interval")) * interval_mult
		_group_spawn_intervals[i] = interval
		_group_spawn_timers[i] = 0.35 + randf_range(0.0, 0.4)
		if _group_is_drip_eligible(group):
			_drip_group_indices.append(i)
	_use_timed_drip = not _drip_group_indices.is_empty() and (
		hybrid or not bool(_config.get("use_encounter_areas"))
	)
	_hybrid_drip_timer = 0.5


func _group_is_drip_eligible(group: Resource) -> bool:
	if group == null:
		return false
	# Hybrid + encounters: only explicitly flagged roaming groups.
	if bool(_config.get("use_encounter_areas")) and bool(_config.get("hybrid_drip_enabled")):
		return bool(group.get("drip_enabled"))
	# Legacy drip-only stages: every wave group drips.
	if not bool(_config.get("use_encounter_areas")):
		return true
	return false


func _init_encounter_areas() -> void:
	_use_encounter_areas = false
	_encounter_areas.clear()
	_encounter_runtime.clear()
	_encounter_area_order.clear()
	if _config == null or not bool(_config.get("use_encounter_areas")):
		return
	var stage := get_parent()
	if stage == null:
		return
	var ordered_nodes: Array[Node3D] = _collect_ordered_encounter_areas(stage)
	for node in ordered_nodes:
		if node == null or not is_instance_valid(node):
			continue
		var area_id: StringName = &""
		if "area_id" in node:
			area_id = node.get("area_id") as StringName
		if area_id == &"":
			push_warning("RunDirector: encounter area %s missing area_id." % node.name)
			continue
		if _find_wave_group_by_id(area_id) == null:
			push_warning(
				"RunDirector: encounter area %s id '%s' has no matching wave_group."
				% [node.name, String(area_id)]
			)
			continue
		_encounter_areas.append(node)
		_encounter_area_order.append(area_id)
		_encounter_runtime[area_id] = {
			"state": EncounterState.PENDING,
			"enemies": [] as Array[Node3D],
			"was_inside": false,
			"node": node,
			"chest": null,
		}
	_use_encounter_areas = not _encounter_areas.is_empty()
	if bool(_config.get("use_encounter_areas")) and not _use_encounter_areas:
		push_warning(
			"RunDirector: use_encounter_areas set but no valid run_encounter_area markers found."
		)


func _collect_ordered_encounter_areas(stage: Node) -> Array[Node3D]:
	## Prefer RunEncounterAreas child order (linear Dry Gulch progression).
	var ordered: Array[Node3D] = []
	var host := stage.get_node_or_null("RunEncounterAreas")
	if host != null:
		for child in host.get_children():
			if child == null or not is_instance_valid(child):
				continue
			if not (child is Node3D):
				continue
			if not ("area_id" in child) and not child.is_in_group("run_encounter_area"):
				continue
			ordered.append(child as Node3D)
		if not ordered.is_empty():
			return ordered
	for node in get_tree().get_nodes_in_group("run_encounter_area"):
		if node == null or not is_instance_valid(node):
			continue
		if not stage.is_ancestor_of(node):
			continue
		if node is Node3D:
			ordered.append(node as Node3D)
	return ordered


func _init_hybrid_drip_budgets() -> void:
	_drip_budgets = PackedInt32Array()
	_drip_budget_queue.clear()
	_drip_spawn_anchors.clear()
	if _config == null:
		return
	var raw: Variant = _config.get("hybrid_drip_budgets")
	if raw is PackedInt32Array:
		_drip_budgets = raw as PackedInt32Array
	elif raw is Array:
		var packed := PackedInt32Array()
		for value in raw as Array:
			packed.append(int(value))
		_drip_budgets = packed


func _hybrid_drip_budget_remaining() -> int:
	## Empty budgets array = uncapped drip.
	if _drip_budgets.is_empty():
		return 999999
	var total := 0
	for entry in _drip_budget_queue:
		total += maxi(int(entry.get("remaining", 0)), 0)
	return total


func _grant_drip_budget_for_area(area_id: StringName) -> void:
	## Stack this area's budget when the player walks into its trigger.
	if _drip_budgets.is_empty():
		return
	var area_index := _encounter_area_order.find(area_id)
	if area_index < 0:
		return
	var budget_index := mini(area_index, _drip_budgets.size() - 1)
	var amount := maxi(int(_drip_budgets[budget_index]), 0)
	if amount <= 0:
		return
	_cache_drip_spawn_anchor(area_id)
	_drip_budget_queue.append({
		"area_id": area_id,
		"remaining": amount,
		"spawned": 0,
	})


func _cache_drip_spawn_anchor(area_id: StringName) -> void:
	if not _encounter_runtime.has(area_id):
		return
	var runtime: Dictionary = _encounter_runtime[area_id]
	var area: Node3D = runtime.get("node") as Node3D
	if area == null or not is_instance_valid(area):
		return
	if area.has_method("get_drip_spawn_anchor"):
		_drip_spawn_anchors[area_id] = area.call("get_drip_spawn_anchor") as Vector3
	else:
		_drip_spawn_anchors[area_id] = area.global_position


func _peek_drip_budget_area_id() -> StringName:
	while not _drip_budget_queue.is_empty():
		var entry: Dictionary = _drip_budget_queue[0]
		if int(entry.get("remaining", 0)) > 0:
			return entry.get("area_id", &"") as StringName
		_drip_budget_queue.pop_front()
	return &""


func _consume_drip_budget() -> void:
	if _drip_budgets.is_empty() or _drip_budget_queue.is_empty():
		return
	var entry: Dictionary = _drip_budget_queue[0]
	var remaining := maxi(int(entry.get("remaining", 0)) - 1, 0)
	entry["remaining"] = remaining
	entry["spawned"] = int(entry.get("spawned", 0)) + 1
	_drip_budget_queue[0] = entry
	if remaining <= 0:
		_drip_budget_queue.pop_front()


func _peek_drip_budget_spawned_count() -> int:
	if _drip_budget_queue.is_empty():
		return 0
	return int((_drip_budget_queue[0] as Dictionary).get("spawned", 0))


func _find_wave_group_by_id(area_id: StringName) -> Resource:
	for group in _wave_groups:
		if group == null:
			continue
		if group.get("id") == area_id:
			return group as Resource
	return null


func _tick_encounter_areas() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null:
		return
	_refresh_encounter_clear_states()
	for area in _encounter_areas:
		if area == null or not is_instance_valid(area):
			continue
		var area_id: StringName = area.get("area_id") as StringName
		if not _encounter_runtime.has(area_id):
			continue
		var runtime: Dictionary = _encounter_runtime[area_id]
		var inside := false
		if area.has_method("is_player_in_range"):
			inside = bool(area.call("is_player_in_range", _player))
		else:
			var delta := _player.global_position - area.global_position
			delta.y = 0.0
			var radius := 22.0
			if "trigger_radius" in area:
				radius = float(area.get("trigger_radius"))
			inside = delta.length() <= radius
		runtime["was_inside"] = inside
		if not inside:
			continue
		var state: int = int(runtime.get("state", EncounterState.PENDING))
		## One-shot: only PENDING → pack. No reinforce on re-entry.
		if state == EncounterState.PENDING:
			_trigger_encounter(area_id, false)


func _refresh_encounter_clear_states() -> void:
	for area_id in _encounter_runtime.keys():
		var runtime: Dictionary = _encounter_runtime[area_id]
		var state: int = int(runtime.get("state", EncounterState.PENDING))
		if state != EncounterState.ACTIVE and state != EncounterState.REINFORCED:
			continue
		_prune_encounter_enemy_list(runtime)
		var enemies: Array = runtime.get("enemies", [])
		if enemies.is_empty():
			var was_first_clear := state == EncounterState.ACTIVE
			runtime["state"] = EncounterState.CLEARED
			if was_first_clear:
				_unlock_encounter_chest(runtime)
				_sink_encounter_walls(runtime)
				var group := _find_wave_group_by_id(area_id as StringName)
				var label := ""
				if group != null:
					label = str(group.get("display_name"))
				if label == "":
					label = String(area_id)
				_announce("%s cleared" % label)


func _sink_encounter_walls(runtime: Dictionary) -> void:
	var area: Node3D = runtime.get("node") as Node3D
	if area == null or not is_instance_valid(area):
		return
	if area.has_method("sink_gate_walls"):
		area.call("sink_gate_walls")
		return
	for child in area.get_children():
		if child != null and child.has_method("sink_into_ground"):
			child.call("sink_into_ground")


func _prune_encounter_enemy_list(runtime: Dictionary) -> void:
	var enemies: Array = runtime.get("enemies", [])
	var kept: Array[Node3D] = []
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_defeated") and enemy.is_defeated():
			continue
		kept.append(enemy as Node3D)
	runtime["enemies"] = kept


func _trigger_encounter(area_id: StringName, reinforce: bool) -> void:
	if not _encounter_runtime.has(area_id):
		return
	var runtime: Dictionary = _encounter_runtime[area_id]
	var area: Node3D = runtime.get("node") as Node3D
	if area == null or not is_instance_valid(area):
		return
	var group := _find_wave_group_by_id(area_id)
	if group == null or not group.has_method("pick_base_unit"):
		return

	var spawn_specs := _collect_encounter_spawn_specs(area, group, reinforce)
	## Encounter packs always spawn (allow_over_cap); don't block on alive room.
	if spawn_specs.is_empty():
		return

	# Claim before queue drains so _process cannot re-enter.
	runtime["state"] = EncounterState.REINFORCED if reinforce else EncounterState.ACTIVE
	runtime["was_inside"] = true
	runtime["enemies"] = []
	## Near-player drip budget stacks when the player enters this trigger.
	if not reinforce:
		_grant_drip_budget_for_area(area_id)

	var enqueued := 0
	var on_spawned := _on_encounter_enemy_spawned.bind(area_id)
	for spec in spawn_specs:
		var scene: PackedScene = spec.get("scene") as PackedScene
		if scene == null:
			continue
		var opts: Dictionary = spec.get("opts", {}) as Dictionary
		if _enqueue_spawn(
			scene,
			spec.get("pos", Vector3.ZERO) as Vector3,
			opts,
			on_spawned,
			true
		):
			enqueued += 1
			_wave_index += 1

	var include_elite := (
		difficulty >= float(_config.get("encounter_elite_min_difficulty"))
		and group.get("elite_scene") != null
		and _alive_plus_queued() < _get_max_alive_enemies()
	)
	if include_elite:
		var elite_pos: Vector3 = (
			spawn_specs[maxi(enqueued - 1, 0) % spawn_specs.size()].get("pos", area.global_position)
			as Vector3
		)
		if _enqueue_spawn(
			group.get("elite_scene") as PackedScene,
			elite_pos,
			_build_elite_spawn_opts(group),
			on_spawned,
			true
		):
			enqueued += 1
			var elite_label := str(group.get("elite_announce"))
			if elite_label == "":
				elite_label = "Elite %s" % str(group.get("display_name"))
			_announce(elite_label)

	if enqueued <= 0:
		runtime["state"] = EncounterState.CLEARED if reinforce else EncounterState.PENDING
		return

	if not reinforce:
		_spawn_encounter_chest(area_id, area)

	var announce := ""
	if "announce_override" in area and str(area.get("announce_override")) != "":
		announce = str(area.get("announce_override"))
	elif reinforce:
		announce = "%s — reinforcements" % str(group.get("display_name"))
	else:
		announce = str(group.get("unlock_announce"))
		if announce == "":
			announce = str(group.get("display_name"))
	if announce != "":
		_announce(announce)

	_set_difficulty(difficulty + float(_config.get("difficulty_per_wave")) * 0.35)


func _on_encounter_enemy_spawned(enemy: Node3D, area_id: StringName) -> void:
	## Bound as `.bind(area_id)` — Godot appends bound args after call(enemy).
	if enemy == null or not is_instance_valid(enemy):
		return
	if not _encounter_runtime.has(area_id):
		return
	var runtime: Dictionary = _encounter_runtime[area_id]
	var enemies: Array = runtime.get("enemies", [])
	enemies.append(enemy)
	runtime["enemies"] = enemies


func _spawn_encounter_chest(area_id: StringName, area: Node3D) -> void:
	if not _encounter_runtime.has(area_id):
		return
	var runtime: Dictionary = _encounter_runtime[area_id]
	var existing: Node = runtime.get("chest") as Node
	if existing != null and is_instance_valid(existing):
		return

	var stage := get_parent() as Node3D
	if stage == null or area == null:
		return
	var loot_root := stage.get_node_or_null("RunLootSpawned") as Node3D
	if loot_root == null:
		loot_root = Node3D.new()
		loot_root.name = "RunLootSpawned"
		stage.add_child(loot_root)

	var world_pos := area.global_position + Vector3(2.5, 0.0, 2.5)
	if area.has_method("get_chest_marker"):
		var chest_marker: Marker3D = area.call("get_chest_marker") as Marker3D
		if chest_marker != null:
			world_pos = chest_marker.global_position

	var loot_director := stage.get_node_or_null("RunLootDirector")
	var chest: Area3D = null
	if loot_director != null and loot_director.has_method("spawn_encounter_chest"):
		chest = loot_director.call("spawn_encounter_chest", loot_root, world_pos) as Area3D
	else:
		chest = _spawn_encounter_chest_fallback(loot_root, world_pos)
	runtime["chest"] = chest


func _spawn_encounter_chest_fallback(parent: Node3D, world_pos: Vector3) -> Area3D:
	var chest: Area3D = RunLootChestScript.new() as Area3D
	chest.configure(0, 0, 1.0, 0, 1.0, 0.0, 0.0)
	parent.add_child(chest)
	var floor_y := world_pos.y
	var stage := get_parent() as Node3D
	if stage != null and stage.get_world_3d() != null:
		floor_y = GroyperBodyUtilsScript.sample_floor_y(stage.get_world_3d(), world_pos)
	chest.global_position = Vector3(world_pos.x, floor_y, world_pos.z)
	if chest.has_method("set_encounter_locked"):
		chest.call("set_encounter_locked", true)
	return chest


func _unlock_encounter_chest(runtime: Dictionary) -> void:
	var chest: Node = runtime.get("chest") as Node
	if chest == null or not is_instance_valid(chest):
		return
	if chest.has_method("set_encounter_locked"):
		chest.call("set_encounter_locked", false)


func _compute_encounter_pack_size(area: Node3D, reinforce: bool) -> int:
	## Designer spawn markers = one immediate enemy each.
	if area != null and area.has_method("get_spawn_markers"):
		var markers: Variant = area.call("get_spawn_markers")
		if markers is Array and not (markers as Array).is_empty():
			var marker_count := 0
			for marker in markers as Array:
				if marker is Marker3D and is_instance_valid(marker):
					marker_count += 1
			if marker_count > 0:
				return marker_count
	var pack := int(
		round(
			float(_config.get("encounter_base_pack"))
			+ difficulty * float(_config.get("encounter_pack_per_difficulty"))
				* _modifier_spawn_mult()
		)
	)
	if reinforce:
		pack += int(_config.get("encounter_reinforce_pack_bonus"))
	return clampi(pack, 1, int(_config.get("encounter_max_pack")))


func _collect_encounter_spawn_specs(
	area: Node3D,
	group: Resource,
	reinforce: bool
) -> Array[Dictionary]:
	## One dict per enemy: { scene, pos, opts }. Named markers set type+weapon;
	## legacy Spawn* / procedural packs use the wave-group unit + tier loadout.
	var specs: Array[Dictionary] = []
	var markers: Array = []
	if area != null and area.has_method("get_spawn_markers"):
		markers = area.call("get_spawn_markers")
	if markers is Array and not (markers as Array).is_empty():
		for marker in markers as Array:
			if not (marker is Marker3D) or not is_instance_valid(marker):
				continue
			var spec := _build_encounter_marker_spec(marker as Marker3D, group, reinforce)
			if not spec.is_empty():
				specs.append(spec)
		return specs

	var pack_size := _compute_encounter_pack_size(area, reinforce)
	var positions := _collect_encounter_spawn_positions(area, pack_size)
	for i in pack_size:
		var unit: Resource = group.pick_base_unit(_run_elapsed)
		if unit == null or unit.get("enemy_scene") == null:
			continue
		var opts := _build_encounter_mini_elite_opts(
			_build_unit_spawn_opts(unit, group, reinforce),
			unit.get("enemy_scene") as PackedScene
		)
		specs.append({
			"scene": unit.get("enemy_scene") as PackedScene,
			"pos": positions[i % positions.size()],
			"opts": opts,
		})
	return specs


func _build_encounter_marker_spec(
	marker: Marker3D,
	group: Resource,
	reinforce: bool
) -> Dictionary:
	var pos := _snap_to_floor(marker.global_position)
	var marker_name := String(marker.name)
	var parsed := RunEncounterSpawnSpecScript.parse_named_marker(marker_name)
	if not parsed.is_empty():
		var scene := RunEncounterSpawnSpecScript.load_enemy_scene(str(parsed.get("scene_path", "")))
		if scene == null:
			push_warning("RunDirector: unknown encounter scene for marker '%s'" % marker_name)
			return {}
		var weapon_id := int(parsed.get("weapon_id", GroyperWeaponsScript.Id.UNARMED))
		var opts := _build_named_encounter_opts(scene, weapon_id, reinforce)
		return {"scene": scene, "pos": pos, "opts": opts}

	## Legacy Spawn* — type/weapon from wave-group + tiers.
	var unit: Resource = group.pick_base_unit(_run_elapsed)
	if unit == null or unit.get("enemy_scene") == null:
		return {}
	var scene_legacy: PackedScene = unit.get("enemy_scene") as PackedScene
	return {
		"scene": scene_legacy,
		"pos": pos,
		"opts": _build_encounter_mini_elite_opts(
			_build_unit_spawn_opts(unit, group, reinforce),
			scene_legacy
		),
	}


func _build_named_encounter_opts(
	scene: PackedScene,
	weapon_id: int,
	reinforce: bool
) -> Dictionary:
	var opts := {
		"weapon_id": weapon_id,
		"melee_only": RunEncounterSpawnSpecScript.melee_only_for_weapon(weapon_id),
		"dynamite_thrower": false,
		"health_mult": 1.0,
		"loot_mult": 1.1 if reinforce else 1.0,
		"elite": false,
		"visual_scale": 1.0,
		"base_max_override": -1,
		"speed_mult": 1.0,
		"block_health": 0.0,
		"auto_reflect": false,
		"max_health": -1,
	}
	if _use_tiers():
		var profile := _tier_profile()
		var tier := RunEnemyTierScript.pick_tier_for_profile(profile, difficulty, _run_elapsed)
		opts = RunEnemyTierScript.merge_opts(
			opts,
			RunEnemyTierScript.build_spawn_opts_for_profile(profile, tier, false)
		)
		## Marker weapon wins over tier default.
		opts["weapon_id"] = weapon_id
		opts["melee_only"] = RunEncounterSpawnSpecScript.melee_only_for_weapon(weapon_id)
		opts = _adapt_tier_opts_for_melee_scene(scene, opts)
		## Keep designer weapon even if melee-scene remap tried to change guns.
		if not _scene_forces_melee_remap(scene):
			opts["weapon_id"] = weapon_id
			opts["melee_only"] = RunEncounterSpawnSpecScript.melee_only_for_weapon(weapon_id)
	opts = _strip_gun_armor_if_disabled(opts)
	return _build_encounter_mini_elite_opts(opts, scene)


func _scene_forces_melee_remap(scene: PackedScene) -> bool:
	if scene == null:
		return false
	var path := String(scene.resource_path).to_lower()
	return (
		path.contains("redo_npc")
		or path.contains("undead_npc")
		or path.contains("pavel_npc")
	)


func _build_encounter_mini_elite_opts(opts: Dictionary, _scene: PackedScene = null) -> Dictionary:
	## Pocket spawns: red brawl aura + doubled HP (mini elites, not full elites).
	var buffed := opts.duplicate(true)
	var max_health := int(buffed.get("max_health", -1))
	if max_health > 0:
		buffed["max_health"] = maxi(1, int(round(float(max_health) * ENCOUNTER_MINI_ELITE_HEALTH_MULT)))
	else:
		buffed["health_mult"] = (
			float(buffed.get("health_mult", 1.0)) * ENCOUNTER_MINI_ELITE_HEALTH_MULT
		)
	buffed["brawl_aura"] = true
	buffed["loot_mult"] = maxf(float(buffed.get("loot_mult", 1.0)), 1.25)
	return buffed


func _collect_encounter_spawn_positions(area: Node3D, count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var markers: Array = []
	if area.has_method("get_spawn_markers"):
		markers = area.call("get_spawn_markers")
	if markers is Array and not (markers as Array).is_empty():
		for marker in markers as Array:
			if marker is Marker3D and is_instance_valid(marker):
				positions.append(_snap_to_floor((marker as Marker3D).global_position))
				if positions.size() >= count:
					break
	if positions.is_empty():
		var origin := area.global_position
		for i in maxi(count, 1):
			var angle := TAU * float(i) / float(maxi(count, 1)) + randf_range(-0.35, 0.35)
			var dist := randf_range(1.2, ENCOUNTER_JITTER_RADIUS)
			var candidate := origin + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
			positions.append(_snap_to_floor(candidate))
	while positions.size() < count:
		var base: Vector3 = positions[positions.size() % positions.size()]
		var jitter := Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2))
		positions.append(_snap_to_floor(base + jitter))
	return positions


func _unlock_due_wave_groups(announce: bool = true) -> void:
	for i in _drip_group_indices:
		if i in _unlocked_group_indices:
			continue
		var group: Resource = _wave_groups[i]
		if _run_elapsed + 0.001 < float(group.get("unlock_time")):
			continue
		_unlocked_group_indices.append(i)
		_group_spawn_timers[i] = 0.2
		if announce:
			var label := str(group.get("unlock_announce"))
			if label == "":
				label = str(group.get("display_name"))
			if label != "":
				_announce(label)
	_all_groups_unlocked = (
		not _drip_group_indices.is_empty()
		and _unlocked_group_indices.size() >= _drip_group_indices.size()
	)


func _tick_wave_group_schedule() -> void:
	_unlock_due_wave_groups(true)
	var elite_interval := float(_config.get("elite_interval"))
	if elite_interval <= 0.0:
		elite_interval = 30.0
	var milestone := int(floor(_run_elapsed / elite_interval))
	while _schedule_milestone < milestone:
		_schedule_milestone += 1
		_on_schedule_milestone(_schedule_milestone)


func _on_schedule_milestone(milestone: int) -> void:
	# Progression elites at :30 of each minute (odd milestones). After the last
	# group's debut elite, spawn an elite every 30s rotating through all groups.
	# Unlock times are separate; every milestone still bumps base spawn rates.
	var was_all_unlocked := _all_groups_unlocked
	_unlock_due_wave_groups(true)
	if not was_all_unlocked and _all_groups_unlocked:
		_announce("All factions active")

	if _should_spawn_elite_this_milestone(milestone):
		_spawn_focus_elite()

	_bump_active_spawn_rates()
	_set_difficulty(difficulty + float(_config.get("difficulty_per_wave")) * 0.35)


func _last_group_debut_elite_time() -> float:
	if _wave_groups.is_empty() or _config == null:
		return INF
	var last: Resource = _wave_groups[_wave_groups.size() - 1]
	var elite_interval := float(_config.get("elite_interval"))
	if elite_interval <= 0.0:
		elite_interval = 30.0
	return float(last.get("unlock_time")) + elite_interval


func _should_rotate_elites() -> bool:
	if not _all_groups_unlocked:
		return false
	# After Pavel/last debut elite has already fired, rotate on later ticks.
	return _run_elapsed > _last_group_debut_elite_time() + 0.5


func _should_spawn_elite_this_milestone(milestone: int) -> bool:
	if _should_rotate_elites():
		return true
	return (milestone % 2) == 1


func _focus_group_index() -> int:
	if _unlocked_group_indices.is_empty():
		return 0
	if _should_rotate_elites():
		var idx := _unlocked_group_indices[_elite_rotate_index % _unlocked_group_indices.size()]
		_elite_rotate_index += 1
		return idx
	return _unlocked_group_indices[_unlocked_group_indices.size() - 1]


func _spawn_focus_elite() -> void:
	if _unlocked_group_indices.is_empty():
		return
	var group_index := _focus_group_index()
	_spawn_group_elite(group_index)


func _bump_active_spawn_rates() -> void:
	for i in _unlocked_group_indices:
		var group: Resource = _wave_groups[i]
		var factor := float(group.get("rate_bump_factor"))
		var min_interval := float(group.get("min_spawn_interval"))
		_group_spawn_intervals[i] = maxf(
			min_interval,
			_group_spawn_intervals[i] * factor
		)


func _get_max_alive_enemies() -> int:
	## Alive cap: max_alive_base + max_alive_per_minute * full minutes.
	## per_minute = 0 keeps a flat base (Dry Gulch). Hard ceiling: max_alive_enemies.
	if _config == null:
		return 5
	var base_cap := int(_config.get("max_alive_base"))
	if base_cap <= 0:
		base_cap = int(_config.get("max_alive_enemies"))
	if base_cap <= 0:
		base_cap = 5
	var per_minute := maxi(int(_config.get("max_alive_per_minute")), 0)
	var minutes := int(floor(_run_elapsed / 60.0))
	var cap := base_cap + per_minute * minutes
	var hard_max := int(_config.get("max_alive_enemies"))
	if hard_max > 0:
		cap = mini(cap, hard_max)
	return cap


func _tick_wave_group_spawns(delta: float) -> void:
	if _unlocked_group_indices.is_empty():
		return
	# Hybrid: near-player drip that ramps with run time.
	if _use_encounter_areas and bool(_config.get("hybrid_drip_enabled")):
		_hybrid_drip_timer -= delta
		if _hybrid_drip_timer > 0.0:
			return
		var minutes := _run_elapsed / 60.0
		var base_interval := maxf(float(_config.get("hybrid_drip_interval_seconds")), 1.0)
		## Tighten cadence over time (2.5s → ~1.2s by minute 5).
		var interval := maxf(1.0, base_interval / (1.0 + minutes * 0.35))
		_hybrid_drip_timer = interval
		var budget_room := _hybrid_drip_budget_remaining()
		if budget_room <= 0:
			return
		var room := _get_max_alive_enemies() - _alive_plus_queued()
		if room <= 0:
			return
		room = mini(room, budget_room)
		var per_tick := maxi(1, int(_config.get("hybrid_drip_max_per_tick")))
		## +1 spawn per tick every 2 full minutes (capped by alive room).
		## Queue drains 1/frame so enqueuing several here spreads the hitch.
		per_tick = mini(room, per_tick + int(floor(minutes / 2.0)))
		for _i in per_tick:
			if _hybrid_drip_budget_remaining() <= 0:
				break
			if _alive_plus_queued() >= _get_max_alive_enemies():
				break
			var drip_area_id := _peek_drip_budget_area_id()
			var drip_pos: Variant = null
			if drip_area_id != &"":
				drip_pos = _pick_drip_spawn_position(drip_area_id)
			var group_index: int = _unlocked_group_indices[
				randi() % _unlocked_group_indices.size()
			]
			var drip_weapon_opts := _dry_gulch_drip_weapon_opts(drip_area_id)
			if _spawn_group_base_unit(group_index, drip_pos, drip_weapon_opts):
				_consume_drip_budget()
		return

	var spawn_mult := _modifier_spawn_mult()
	for i in _unlocked_group_indices:
		_group_spawn_timers[i] -= delta
		if _group_spawn_timers[i] > 0.0:
			continue
		var group: Resource = _wave_groups[i]
		var count := maxi(1, int(round(float(group.get("spawns_per_tick")) * spawn_mult)))
		count = maxi(count, 1)
		var room := _get_max_alive_enemies() - _alive_plus_queued()
		if room <= 0:
			_group_spawn_timers[i] = _group_spawn_intervals[i]
			continue
		count = mini(count, room)
		for _n in count:
			_spawn_group_base_unit(i)
		_group_spawn_timers[i] = _group_spawn_intervals[i]


func _spawn_initial_wavegroup_enemies() -> void:
	if _unlocked_group_indices.is_empty():
		return
	var first := _unlocked_group_indices[0]
	for _i in 2:
		if _alive_plus_queued() >= _get_max_alive_enemies():
			break
		_spawn_group_base_unit(first)
	_wave_index = 1


func _spawn_group_base_unit(
	group_index: int,
	forced_pos: Variant = null,
	opts_override: Dictionary = {}
) -> bool:
	if group_index < 0 or group_index >= _wave_groups.size():
		return false
	if _alive_plus_queued() >= _get_max_alive_enemies():
		return false
	var group: Resource = _wave_groups[group_index]
	if not group.has_method("pick_base_unit"):
		return false
	var unit: Resource = group.pick_base_unit(_run_elapsed)
	if unit == null or unit.get("enemy_scene") == null:
		return false
	var pos: Variant = forced_pos
	if pos == null:
		pos = _pick_spawn_position()
	if pos == null:
		return false
	var opts := _build_unit_spawn_opts(unit, group, false)
	if not opts_override.is_empty():
		opts = RunEnemyTierScript.merge_opts(opts, opts_override)
	if _enqueue_spawn(unit.get("enemy_scene") as PackedScene, pos as Vector3, opts):
		_wave_index += 1
		return true
	return false


func _dry_gulch_drip_weapon_opts(area_id: StringName) -> Dictionary:
	## First area budget: first N unarmed, remainder revolvers. Other areas stay unarmed.
	if _tier_profile() != RunEnemyTierScript.PROFILE_DRY_GULCH:
		return {}
	var area_index := _encounter_area_order.find(area_id)
	if area_index < 0:
		return {
			"weapon_id": GroyperWeaponsScript.Id.UNARMED,
			"melee_only": true,
		}
	if area_index == 0:
		var already_spawned := _peek_drip_budget_spawned_count()
		if already_spawned < DRY_GULCH_FIRST_AREA_UNARMED_DRIP:
			return {
				"weapon_id": GroyperWeaponsScript.Id.UNARMED,
				"melee_only": true,
			}
		return {
			"weapon_id": GroyperWeaponsScript.Id.REVOLVER,
			"melee_only": false,
		}
	return {
		"weapon_id": GroyperWeaponsScript.Id.UNARMED,
		"melee_only": true,
	}


func _spawn_group_elite(group_index: int) -> void:
	if group_index < 0 or group_index >= _wave_groups.size():
		return
	if _alive_plus_queued() >= _get_max_alive_enemies():
		return
	var group: Resource = _wave_groups[group_index]
	var scene: PackedScene = group.get("elite_scene") as PackedScene
	if scene == null:
		return
	var pos: Variant = _pick_spawn_position()
	if pos == null:
		return
	var opts := _build_elite_spawn_opts(group)
	if not _enqueue_spawn(scene, pos as Vector3, opts):
		return
	var label := str(group.get("elite_announce"))
	if label == "":
		label = "Elite %s" % str(group.get("display_name"))
	_announce(label)


func _use_tiers() -> bool:
	return _config != null and bool(_config.get("use_difficulty_tiers"))


func _build_unit_spawn_opts(unit: Resource, group: Resource, reinforce: bool) -> Dictionary:
	var dynamite_thrower := bool(unit.get("dynamite_thrower"))
	var opts := {
		"weapon_id": int(unit.get("weapon_id")),
		"melee_only": bool(unit.get("melee_only")),
		"dynamite_thrower": dynamite_thrower,
		"health_mult": float(unit.get("health_mult")),
		"loot_mult": 1.0,
		"elite": false,
		"visual_scale": float(unit.get("visual_scale")),
		"base_max_override": int(group.get("base_unit_max_health")),
		"speed_mult": 1.0,
		"block_health": 0.0,
		"auto_reflect": false,
		"max_health": -1,
	}
	if reinforce:
		opts["loot_mult"] = 1.1
	if _use_tiers():
		var profile := _tier_profile()
		var tier := RunEnemyTierScript.pick_tier_for_profile(profile, difficulty, _run_elapsed)
		opts = RunEnemyTierScript.merge_opts(
			opts,
			RunEnemyTierScript.build_spawn_opts_for_profile(profile, tier, false)
		)
		opts = _adapt_tier_opts_for_melee_scene(unit.get("enemy_scene") as PackedScene, opts)
	# Dynamite throwers keep their stick loadout; tiers would otherwise force
	# revolver / plain unarmed and wipe the variant.
	if dynamite_thrower:
		opts["dynamite_thrower"] = true
		opts["weapon_id"] = GroyperWeaponsScript.Id.UNARMED
		opts["melee_only"] = true
	opts = _strip_gun_armor_if_disabled(opts)
	return opts


func _build_elite_spawn_opts(group: Resource) -> Dictionary:
	var opts := {
		"weapon_id": int(group.get("elite_weapon_id")),
		"melee_only": bool(group.get("elite_melee_only")),
		"health_mult": float(group.get("elite_health_mult")),
		"loot_mult": float(group.get("elite_loot_mult")),
		"elite": true,
		"visual_scale": float(group.get("elite_visual_scale")),
		"base_max_override": int(group.get("base_unit_max_health")),
		"speed_mult": 1.0,
		"block_health": 0.0,
		"auto_reflect": false,
		"max_health": -1,
	}
	if _use_tiers():
		var profile := _tier_profile()
		if profile == RunEnemyTierScript.PROFILE_DRY_GULCH:
			## Dry Gulch elites only: shotgun early, Winchester late-run.
			opts = RunEnemyTierScript.merge_opts(
				opts,
				RunEnemyTierScript.build_dry_gulch_elite_opts(_run_elapsed)
			)
		else:
			opts = RunEnemyTierScript.merge_opts(
				opts,
				RunEnemyTierScript.build_spawn_opts_for_profile(
					profile, RunEnemyTierScript.pick_miniboss_tier(), true
				)
			)
		opts = _adapt_tier_opts_for_melee_scene(group.get("elite_scene") as PackedScene, opts)
	opts = _strip_gun_armor_if_disabled(opts)
	return opts


func _strip_gun_armor_if_disabled(opts: Dictionary) -> Dictionary:
	if _config == null or not bool(_config.get("disable_enemy_gun_armor")):
		return opts
	var stripped := opts.duplicate(true)
	stripped["block_health"] = 0.0
	stripped["auto_reflect"] = false
	return stripped


func _adapt_tier_opts_for_melee_scene(scene: PackedScene, opts: Dictionary) -> Dictionary:
	## Melee-only casts can't use guns; remap gun loadouts to 2H + armor.
	## Sheriff has no melee FSM — keep firearms only.
	if scene == null:
		return opts
	var path := String(scene.resource_path).to_lower()
	var adapted := opts.duplicate(true)
	if path.contains("sheriff"):
		var sheriff_weapon := int(adapted.get("weapon_id", -1))
		if (
			sheriff_weapon != GroyperWeaponsScript.Id.REVOLVER
			and sheriff_weapon != GroyperWeaponsScript.Id.SHOTGUN
		):
			adapted["weapon_id"] = (
				GroyperWeaponsScript.Id.SHOTGUN
				if bool(adapted.get("elite", false))
				else GroyperWeaponsScript.Id.REVOLVER
			)
		adapted["melee_only"] = false
		return adapted
	if not (
		path.contains("redo_npc")
		or path.contains("undead_npc")
		or path.contains("pavel_npc")
	):
		return opts
	var weapon_id := int(adapted.get("weapon_id", -1))
	var is_gun := (
		weapon_id == GroyperWeaponsScript.Id.REVOLVER
		or weapon_id == GroyperWeaponsScript.Id.SHOTGUN
		or weapon_id == GroyperWeaponsScript.Id.WINCHESTER
		or weapon_id == GroyperWeaponsScript.Id.BOW
		or weapon_id == GroyperWeaponsScript.Id.AWP
		or weapon_id == GroyperWeaponsScript.Id.AK47
	)
	if is_gun:
		adapted["weapon_id"] = GroyperWeaponsScript.Id.SWORD_2H
		adapted["melee_only"] = true
		if not bool(adapted.get("elite", false)):
			adapted["max_health"] = randi_range(8, 10)
			adapted["block_health"] = 10.0
			adapted["auto_reflect"] = true
	elif weapon_id < 0:
		adapted["melee_only"] = true
	return adapted


func _alive_plus_queued() -> int:
	return _alive_enemies.size() + _spawn_queue.size()


## Queue a spawn for the next free frame(s). Returns false if the alive+queued
## cap is full (unless allow_over_cap — gem enemies).
func _enqueue_spawn(
	scene: PackedScene,
	world_pos: Vector3,
	opts: Dictionary,
	on_spawned: Callable = Callable(),
	allow_over_cap: bool = false
) -> bool:
	if scene == null:
		return false
	if not allow_over_cap and _alive_plus_queued() >= _get_max_alive_enemies():
		return false
	_spawn_queue.append({
		"scene": scene,
		"pos": world_pos,
		"opts": opts,
		"on_spawned": on_spawned,
	})
	return true


func _drain_spawn_queue() -> void:
	var budget := SPAWNS_PER_FRAME
	while budget > 0 and not _spawn_queue.is_empty():
		budget -= 1
		var entry: Dictionary = _spawn_queue.pop_front()
		var scene: PackedScene = entry.get("scene") as PackedScene
		var pos: Vector3 = entry.get("pos", Vector3.ZERO) as Vector3
		var opts: Dictionary = entry.get("opts", {}) as Dictionary
		var enemy := _spawn_configured_enemy(scene, pos, opts)
		var cb: Variant = entry.get("on_spawned")
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call(enemy)


## Touch every wave/elite/boss PackedScene during the black hold so first
## encounter/drip pays instantiate CPU only, not resource parse.
func _preload_wave_scenes() -> void:
	var seen: Dictionary = {}
	for group in _wave_groups:
		if group == null:
			continue
		_touch_packed_scene(group.get("elite_scene"), seen)
		var units: Variant = group.get("base_units")
		if units is Array:
			for unit in units:
				if unit != null:
					_touch_packed_scene(unit.get("enemy_scene"), seen)
	if _config != null:
		_touch_packed_scene(_config.get("boss_scene"), seen)
		var pool: Variant = _config.get("enemy_pool")
		if pool != null:
			var entries: Variant = pool.get("entries")
			if entries is Array:
				for entry in entries:
					if entry != null:
						_touch_packed_scene(entry.get("enemy_scene"), seen)
	_touch_packed_scene(GEM_ENEMY_FALLBACK_SCENE, seen)


func _touch_packed_scene(scene: Variant, seen: Dictionary) -> void:
	if scene == null or not (scene is PackedScene):
		return
	var packed := scene as PackedScene
	var path := packed.resource_path
	if path == "":
		return
	if seen.has(path):
		return
	seen[path] = true
	ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)


func _spawn_configured_enemy(scene: PackedScene, world_pos: Vector3, opts: Dictionary) -> Node3D:
	if _enemy_host == null:
		_enemy_host = _find_enemy_host()
	if _enemy_host == null or scene == null:
		return null

	var hitch_t := HitchProfiler.begin()
	var spawn_detail := _hitch_scene_detail(scene)

	var enemy: Node3D = scene.instantiate() as Node3D
	if enemy == null:
		HitchProfiler.end(HitchProfiler.LABEL_DIRECTOR_ENEMY_SPAWN, hitch_t, spawn_detail)
		return null

	var melee_only = opts.get("melee_only", null)
	if melee_only != null and "melee_only" in enemy:
		enemy.set("melee_only", bool(melee_only))
	var weapon_id := int(opts.get("weapon_id", -1))
	if weapon_id >= 0 and "equipped_weapon_id" in enemy:
		enemy.set("equipped_weapon_id", weapon_id)
	if bool(opts.get("dynamite_thrower", false)) and "dynamite_thrower" in enemy:
		enemy.set("dynamite_thrower", true)

	# Skip town NPC deferred floor snap — RunDirector owns snap + aggro.
	enemy.set_meta(&"canyon_raider", true)

	_enemy_host.add_child(enemy)
	enemy.global_position = world_pos
	_snap_enemy_to_floor(enemy)

	var tune_opts := opts.duplicate(true)
	tune_opts["weapon_id"] = weapon_id
	if melee_only != null:
		tune_opts["melee_only"] = melee_only
	RunEnemyTuningScript.apply_from_opts(enemy, tune_opts)

	var skip_aggro := bool(opts.get("skip_aggro", false)) or bool(opts.get("gem_enemy", false))
	if skip_aggro:
		enemy.set_meta(GemEnemyStatusScript.SKIP_AGGRO_META, true)
	if bool(opts.get("gem_enemy", false)):
		var gem_id: StringName = opts.get("gem_id", ElementalGems.LIGHTNING) as StringName
		GemEnemyStatusScript.apply(enemy, gem_id)

	if bool(opts.get("brawl_aura", false)):
		enemy.set_meta(RUN_BRAWL_AURA_META, true)

	FloatingEnemyHealthBarScript.attach_to(enemy)
	_alive_enemies.append(enemy)
	_watch_enemy(enemy)
	# Aggro runs deferred in _finalize_spawned_enemy so combat FSM / draw anim
	# stay off the instantiate hitch frame.
	call_deferred("_finalize_spawned_enemy", enemy)
	HitchProfiler.end(HitchProfiler.LABEL_DIRECTOR_ENEMY_SPAWN, hitch_t, spawn_detail)
	return enemy


func _hitch_scene_detail(scene: PackedScene) -> String:
	if scene == null:
		return ""
	var path := scene.resource_path
	if path.is_empty():
		return scene.get_class()
	return path.get_file().get_basename()


func _modifier_spawn_mult() -> float:
	var spawn_mult := 1.0
	for modifier in active_modifiers:
		if modifier != null:
			spawn_mult *= float(modifier.get("spawn_count_mult"))
	return spawn_mult


func _modifier_aggro_mult() -> float:
	var aggro_mult := 1.0
	for modifier in active_modifiers:
		if modifier != null:
			aggro_mult *= float(modifier.get("aggro_mult"))
	return aggro_mult


func _spawn_preset_wave() -> void:
	var stage := get_parent() as Node
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if not is_instance_valid(node) or not node.has_method("spawn_enemy"):
			continue
		if stage != null and not stage.is_ancestor_of(node):
			continue
		node.spawn_enemy()
		var spawned: Variant = node.get("_spawned")
		if spawned is Node3D and is_instance_valid(spawned):
			_alive_enemies.append(spawned as Node3D)
			_watch_enemy(spawned as Node3D)
			_apply_run_aggro(spawned as Node3D)
	if _alive_enemies.is_empty():
		_register_host_enemies()
		for enemy in _alive_enemies:
			_apply_run_aggro(enemy)
	_wave_index = 1


func _register_host_enemies() -> void:
	_alive_enemies.clear()
	if _enemy_host == null:
		return
	for child in _enemy_host.get_children():
		if child is Node3D and is_instance_valid(child):
			_alive_enemies.append(child as Node3D)
			_watch_enemy(child as Node3D)


func _spawn_dynamic_wave() -> void:
	if _config.get("enemy_pool") == null:
		return
	var spawn_mult := _modifier_spawn_mult()

	var count := int(
		round(
			(
				float(_config.get("base_spawn_count"))
				+ difficulty * float(_config.get("spawn_count_per_difficulty"))
			)
			* spawn_mult
		)
	)
	count = clampi(count, 1, 8)
	var room := _get_max_alive_enemies() - _alive_plus_queued()
	if room <= 0:
		return
	count = mini(count, room)

	var enqueued_any := false
	for _i in count:
		var pool = _config.get("enemy_pool")
		if pool == null or not pool.has_method("pick_for_difficulty"):
			continue
		var scene: PackedScene = pool.pick_for_difficulty(difficulty) as PackedScene
		if scene == null:
			continue
		var pos: Variant = _pick_spawn_position()
		if pos == null:
			continue
		if _enqueue_spawn(
			scene,
			pos as Vector3,
			{
				"weapon_id": -1,
				"melee_only": false,
				"health_mult": 1.0,
				"loot_mult": 1.0,
				"elite": false,
				"visual_scale": 1.0,
			}
		):
			enqueued_any = true

	if enqueued_any:
		_wave_index += 1
		_set_difficulty(difficulty + float(_config.get("difficulty_per_wave")))


func _watch_enemy(enemy: Node3D) -> void:
	if not enemy.tree_exiting.is_connected(_on_enemy_tree_exiting.bind(enemy)):
		enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))


func _on_enemy_tree_exiting(enemy: Node3D) -> void:
	_alive_enemies.erase(enemy)
	_corpses.erase(enemy)
	_forget_encounter_enemy(enemy)


func _prune_dead_enemies() -> void:
	var kept: Array[Node3D] = []
	for enemy in _alive_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		# Defeated town NPCs ragdoll and stay in the tree — without this check
		# corpses hold max_alive_enemies slots and spawning stops permanently.
		if enemy.has_method("is_defeated") and enemy.is_defeated():
			_register_corpse(enemy)
			_forget_encounter_enemy(enemy)
			continue
		kept.append(enemy)
	_alive_enemies = kept
	_enforce_corpse_cap()


func _forget_encounter_enemy(enemy: Node3D) -> void:
	if enemy == null or _encounter_runtime.is_empty():
		return
	for area_id in _encounter_runtime.keys():
		var runtime: Dictionary = _encounter_runtime[area_id]
		var enemies: Array = runtime.get("enemies", [])
		if enemies.has(enemy):
			enemies.erase(enemy)
			runtime["enemies"] = enemies


func _register_corpse(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if _corpses.has(enemy):
		return
	_corpses.append(enemy)
	RunCorpseCleanupScript.attach(enemy)


func _enforce_corpse_cap() -> void:
	var valid: Array[Node3D] = []
	for corpse in _corpses:
		if corpse != null and is_instance_valid(corpse):
			valid.append(corpse)
	_corpses = valid
	# Keep tracking until tree_exiting; just accelerate the oldest fades.
	var excess := _corpses.size() - MAX_CORPSES
	for i in range(excess):
		RunCorpseCleanupScript.force_despawn(_corpses[i])


func _finalize_spawned_enemy(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	_snap_enemy_to_floor(enemy)
	if bool(enemy.get_meta(RUN_BRAWL_AURA_META, false)):
		_apply_run_brawl_aura(enemy)
	if bool(enemy.get_meta(GemEnemyStatusScript.SKIP_AGGRO_META, false)):
		return
	_apply_run_aggro(enemy, _modifier_aggro_mult())


func _apply_run_brawl_aura(enemy: Node3D) -> void:
	## Wait a frame so actor body meshes exist for material_overlay.
	await get_tree().process_frame
	if enemy == null or not is_instance_valid(enemy):
		return
	BrawlAuraFXScript.apply(enemy)


func _snap_enemy_to_floor(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	# Prefer heightmap: physics rays often miss Terrain3D outside the camera
	# radius or land on elevated prop colliders, leaving raiders floating.
	if enemy is CharacterBody3D and _snap_enemy_to_terrain3d(enemy as CharacterBody3D):
		return
	if enemy is CharacterBody3D:
		if GroyperBodyUtilsScript.snap_character_to_floor(enemy as CharacterBody3D):
			return
	if enemy.has_method("snap_to_floor"):
		enemy.snap_to_floor()
		if enemy is CharacterBody3D and GroyperBodyUtilsScript.snap_character_to_floor(enemy as CharacterBody3D):
			return
	# Tall sample covers Terrain3D when the short capsule ray still misses.
	var world := enemy.get_world_3d()
	if world == null:
		return
	var floor_y := GroyperBodyUtilsScript.sample_floor_y(world, enemy.global_position)
	var feet := 0.0
	if enemy is CharacterBody3D:
		feet = GroyperBodyUtilsScript.get_collision_feet_offset(enemy as CharacterBody3D)
	enemy.global_position = Vector3(
		enemy.global_position.x,
		floor_y - feet + 0.05,
		enemy.global_position.z
	)


func _snap_enemy_to_terrain3d(body: CharacterBody3D) -> bool:
	var height := _sample_terrain_height(body.global_position)
	if is_nan(height):
		return false
	var feet := GroyperBodyUtilsScript.get_collision_feet_offset(body)
	body.global_position.y = height - feet
	if "velocity" in body:
		body.velocity.y = 0.0
	return true


func _sample_terrain_height(world_pos: Vector3) -> float:
	var terrain := _get_terrain3d()
	if terrain == null or terrain.data == null:
		return NAN
	var height: float = terrain.data.get_height(world_pos)
	if is_nan(height):
		return NAN
	return height


func _get_terrain3d() -> Terrain3D:
	if _terrain3d != null and is_instance_valid(_terrain3d) and _terrain3d.is_inside_tree():
		return _terrain3d
	_terrain3d = null
	var stage := get_parent()
	if stage == null:
		return null
	var direct := stage.get_node_or_null("Terrain/Terrain3D")
	if direct is Terrain3D:
		_terrain3d = direct as Terrain3D
		return _terrain3d
	return null


func _apply_run_aggro(enemy: Node3D, modifier_aggro_mult: float = 1.0) -> void:
	if enemy == null or _config == null:
		return
	var sight := float(_config.get("run_sight_range")) * modifier_aggro_mult
	var hearing := float(_config.get("run_hearing_range")) * modifier_aggro_mult
	var aggro := float(_config.get("run_aggro_range")) * modifier_aggro_mult
	if "sight_range" in enemy:
		enemy.set("sight_range", sight)
	if "hearing_range" in enemy:
		enemy.set("hearing_range", hearing)
	if "aggro_range" in enemy:
		enemy.set("aggro_range", aggro)
	if "faction_on_sight_aggro_range" in enemy:
		enemy.set("faction_on_sight_aggro_range", aggro)

	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null:
		return

	# Prefer full combat arming so town NPCs (Sheriff) don't idle after enter_combat.
	if enemy.has_method("arm_canyon_hostility"):
		enemy.arm_canyon_hostility(_player)
	elif enemy.has_method("set_faction_aggro_level"):
		enemy.set_faction_aggro_level(3, _player)
	elif enemy.has_method("force_alert_to_player"):
		enemy.force_alert_to_player()
	elif enemy.has_method("enter_combat"):
		enemy.enter_combat(_player)
	elif enemy.has_method("enter_melee_aggro"):
		enemy.enter_melee_aggro(_player)


func _pick_drip_spawn_position(area_id: StringName) -> Variant:
	## Spawn on the inside of that area's GateWall (cached at grant), with
	## lateral jitter so stacked drip doesn't pile on one point.
	var anchor: Vector3
	if _drip_spawn_anchors.has(area_id):
		anchor = _drip_spawn_anchors[area_id] as Vector3
	else:
		_cache_drip_spawn_anchor(area_id)
		if _drip_spawn_anchors.has(area_id):
			anchor = _drip_spawn_anchors[area_id] as Vector3
		else:
			return _pick_spawn_position()
	var toward := Vector3.ZERO
	if _encounter_runtime.has(area_id):
		var area: Node3D = (_encounter_runtime[area_id] as Dictionary).get("node") as Node3D
		if area != null and is_instance_valid(area):
			toward = area.global_position - anchor
			toward.y = 0.0
	if toward.length_squared() < 0.0001:
		toward = Vector3(0.0, 0.0, 1.0)
	else:
		toward = toward.normalized()
	var lateral := Vector3(-toward.z, 0.0, toward.x)
	var candidate := anchor + lateral * randf_range(-DRIP_LATERAL_JITTER, DRIP_LATERAL_JITTER)
	var separation: float = float(_config.get("spawn_min_separation"))
	if _is_too_close_to_enemies(candidate, separation):
		candidate += lateral * randf_range(1.2, 2.4) * (1.0 if randf() > 0.5 else -1.0)
	return _snap_to_floor(candidate)


func _pick_spawn_position() -> Variant:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null:
		return null

	var min_d: float = float(_config.get("spawn_min_distance"))
	var max_d: float = float(_config.get("spawn_max_distance"))
	var separation: float = float(_config.get("spawn_min_separation"))
	var origin := _player.global_position
	var world := get_viewport().world_3d if get_viewport() != null else null

	for _attempt in 24:
		var angle := randf() * TAU
		var dist := randf_range(min_d, max_d)
		var candidate := origin + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		candidate.y = origin.y
		if _is_too_close_to_enemies(candidate, separation):
			continue
		candidate = _snap_to_floor(candidate)
		# Reject void / sky hits far from the play surface.
		if absf(candidate.y - origin.y) > 18.0:
			continue
		if world != null:
			var floor_y := GroyperBodyUtilsScript.sample_floor_y(world, candidate)
			if absf(floor_y - origin.y) > 18.0:
				continue
			candidate.y = floor_y + 0.05
		return candidate
	# Last resort: ring sample at player height (still better than failing silently).
	var fallback_angle := randf() * TAU
	var fallback_dist := randf_range(min_d, max_d)
	var fallback := origin + Vector3(cos(fallback_angle) * fallback_dist, 0.0, sin(fallback_angle) * fallback_dist)
	fallback.y = origin.y
	return _snap_to_floor(fallback)


func _is_too_close_to_enemies(pos: Vector3, separation: float) -> bool:
	var sep_sq := separation * separation
	for enemy in _alive_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var delta := enemy.global_position - pos
		delta.y = 0.0
		if delta.length_squared() < sep_sq:
			return true
	return false


func _snap_to_floor(pos: Vector3) -> Vector3:
	var terrain_y := _sample_terrain_height(pos)
	if not is_nan(terrain_y):
		return Vector3(pos.x, terrain_y + 0.05, pos.z)
	var world := get_viewport().world_3d if get_viewport() != null else null
	if world == null:
		return pos
	# Tall fallback cast finds Terrain3D even when local collision isn't ready yet.
	var floor_y := GroyperBodyUtilsScript.sample_floor_y(world, pos)
	return Vector3(pos.x, floor_y + 0.05, pos.z)


func _place_boss_tower() -> void:
	var spots_root := get_parent().get_node_or_null("BossTowerSpots")
	if spots_root == null:
		return
	var spots: Array[Marker3D] = []
	for child in spots_root.get_children():
		if child is Marker3D:
			spots.append(child as Marker3D)
	if spots.is_empty():
		return
	var pick := spots[randi() % spots.size()]
	var tower_scene := load("res://gameplay/runs/boss_tower.tscn") as PackedScene
	if tower_scene == null:
		return
	_boss_tower = tower_scene.instantiate() as Node3D
	get_parent().add_child(_boss_tower)
	_boss_tower.global_transform = pick.global_transform
	if _boss_tower.has_method("bind_director"):
		_boss_tower.bind_director(self)


func _on_boss_defeated() -> void:
	RunState.note_boss_defeated()
	# Kill-goal extract may already have opened the portal — still mark the
	# boss subquest and run the outro freeze, but don't re-enter BOSS_DEAD.
	if phase == Phase.BOSS_DEAD:
		return
	if phase == Phase.PORTAL_OPEN:
		_announce("Chief defeated")
		return
	phase = Phase.BOSS_DEAD
	phase_changed.emit(phase)
	# Freeze remaining pack during the Chief outro — player is locked by dialog
	# but was still taking damage. Portal opens after the flee finishes.
	_freeze_alive_enemies_for_outro()
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player != null and _player.has_method("set_cinematic_invulnerable"):
		_player.set_cinematic_invulnerable(true)
	_announce("Chief defeated")


## Called by Chief Getcha after his run-mode flee/outro finishes.
func on_boss_outro_complete() -> void:
	if phase == Phase.PORTAL_OPEN:
		_unfreeze_alive_enemies_after_outro()
		return
	if phase != Phase.BOSS_DEAD:
		return
	# Unfreeze the pack and keep the spawn clock running — portal is optional
	# extract; staying longer farms more under rising difficulty.
	_unfreeze_alive_enemies_after_outro()
	open_return_portal()


func _on_boss_tree_exiting() -> void:
	# Fallback if the outro never callback'd (story free / early free).
	if phase == Phase.BOSS_DEAD:
		on_boss_outro_complete()
	elif phase == Phase.BOSS_SUMMONED:
		_on_boss_defeated()
		on_boss_outro_complete()


func _freeze_alive_enemies_for_outro() -> void:
	_prune_dead_enemies()
	for enemy in _alive_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("begin_coward_hold"):
			enemy.begin_coward_hold()
		if enemy is CharacterBody3D:
			(enemy as CharacterBody3D).velocity = Vector3.ZERO
		enemy.set_process(false)
		enemy.set_physics_process(false)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _unfreeze_alive_enemies_after_outro() -> void:
	var aggro_mult := _modifier_aggro_mult()
	for enemy in _alive_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.set_process(true)
		enemy.set_physics_process(true)
		_apply_run_aggro(enemy, aggro_mult)


func _ensure_return_portal() -> void:
	if _return_portal != null and is_instance_valid(_return_portal):
		return
	_return_portal = _find_return_portal()
	if _return_portal != null:
		return
	var host := get_parent()
	if host == null:
		return
	var portal: Area3D = RunReturnPortalScript.new() as Area3D
	portal.name = "ReturnPortal"
	host.add_child(portal)
	_return_portal = portal


func _place_return_portal_near_player() -> void:
	if _return_portal == null or not (_return_portal is Node3D):
		return
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	var anchor := Vector3.ZERO
	if _player != null:
		var forward := -_player.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() < 0.0001:
			forward = Vector3.FORWARD
		else:
			forward = forward.normalized()
		anchor = _player.global_position + forward * 6.0
	elif _boss_tower != null and is_instance_valid(_boss_tower):
		anchor = _boss_tower.global_position
	else:
		var spawn := get_parent().get_node_or_null("PlayerSpawn") as Marker3D
		if spawn != null:
			anchor = spawn.global_position
	var world := (_return_portal as Node3D).get_world_3d()
	if world != null:
		anchor.y = GroyperBodyUtilsScript.sample_floor_y(world, anchor)
	(_return_portal as Node3D).global_position = anchor


func _ensure_config() -> void:
	if _config != null and (_config.get("enemy_pool") != null or not _wave_groups_empty(_config)):
		return
	_config = _resolve_config()
	if _config == null:
		push_error("RunDirector: failed to resolve stage config.")
		return
	difficulty = float(_config.get("starting_difficulty"))


func _wave_groups_empty(config: Resource) -> bool:
	if config == null:
		return true
	var groups: Variant = config.get("wave_groups")
	return groups == null or not (groups is Array) or (groups as Array).is_empty()


func _resolve_config() -> Resource:
	var built: Resource = RunStageConfigScript.make_dry_gulch()
	if built == null:
		return null
	if stage_config == null:
		return built
	# Overlay numeric / identity fields from the .tres onto the factory pools.
	var keys := [
		"theme_title",
		"boss_scene",
		"starting_difficulty",
		"max_difficulty",
		"difficulty_per_second",
		"difficulty_per_wave",
		"first_wave_delay",
		"wave_interval",
		"base_spawn_count",
		"spawn_count_per_difficulty",
		"max_alive_enemies",
		"spawn_min_distance",
		"spawn_max_distance",
		"spawn_min_separation",
		"run_sight_range",
		"run_hearing_range",
		"run_aggro_range",
		"base_loot_mult",
		"loot_mult_per_difficulty",
		"modifier_thresholds",
		"max_active_modifiers",
		"elite_interval",
		"wavegroup_upgrade_interval",
		"use_encounter_areas",
		"encounter_base_pack",
		"encounter_pack_per_difficulty",
		"encounter_max_pack",
		"encounter_reinforce_min_difficulty",
		"encounter_elite_min_difficulty",
		"encounter_reinforce_pack_bonus",
		"hybrid_drip_enabled",
		"hybrid_drip_interval_mult",
		"hybrid_drip_max_per_tick",
		"hybrid_drip_interval_seconds",
		"hybrid_drip_budgets",
		"max_alive_base",
		"max_alive_per_minute",
		"use_difficulty_tiers",
		"tier_profile",
		"disable_enemy_gun_armor",
		"kill_goal",
		"kill_goal_hud_title",
		"chest_count",
		"prop_count",
		"chest_free_weight",
		"chest_gram_weight",
		"chest_shard_weight",
		"gram_chest_base_cost",
		"gram_chest_cost_mult",
		"shard_chest_base_cost",
		"shard_chest_cost_mult",
		"horsey_drop_chance",
		"prop_barrel_weight",
		"rare_seed_drop_chance",
	]
	for key in keys:
		var value: Variant = stage_config.get(key)
		if value != null:
			built.set(key, value)
	if stage_config.get("enemy_pool") != null:
		built.set("enemy_pool", stage_config.get("enemy_pool"))
	if stage_config.get("modifier_pool") != null:
		built.set("modifier_pool", stage_config.get("modifier_pool"))
	if not _wave_groups_empty(stage_config):
		built.set("wave_groups", stage_config.get("wave_groups"))
	return built


func _populate_run_loot() -> void:
	var stage := get_parent() as Node3D
	if stage == null or _config == null:
		return
	var director := RunLootDirectorScript.new()
	director.name = "RunLootDirector"
	stage.add_child(director)
	await director.populate(stage, _config, self)


func _find_enemy_host() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	var enemies := parent.get_node_or_null("Enemies")
	if enemies != null:
		return enemies
	return parent


func _find_return_portal() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("ReturnPortal")


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("overworld_player"):
		if node is Node3D and is_instance_valid(node):
			return node as Node3D
	return null


func _announce(text: String) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null or not _player.has_method("get_raid_hud"):
		return
	var hud: Node = _player.get_raid_hud()
	if hud != null and hud.has_method("show_zone_title"):
		hud.show_zone_title(text, 2.2)
