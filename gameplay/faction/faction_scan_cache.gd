extends RefCounted

## Per-physics-frame snapshots of combat-relevant actors with resolved faction
## ids. Faction AI used to rebuild `get_nodes_in_group` arrays and re-resolve
## factions for every scan on every NPC — O(N²) once many combatants are
## aggroed at once. All scans in one physics frame now share snapshots, so
## chaotic fights scale with actor count, not actor count squared.
##
## Three snapshots mirror the exact group unions the scans historically
## walked — do NOT merge them, they encode targeting rules (e.g. bandits pick
## hostiles among combatants, never civilians):
## - faction_members:  "faction_npc" only (aimed-at / ally-draw checks)
## - combatants:       faction_npc + engines_npc + bandit (nearest-hostile)
## - town_combatants:  combatants + becker_boys + town_* civilians (Engines
##                     raid targeting, faction member counts)
##
## Entries are only valid for the frame they were built in: cheap-to-change
## state (defeated, aggro level, position) must still be read live off the
## node by the caller.

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")

const COMBATANT_GROUPS: Array[StringName] = [
	&"faction_npc",
	&"engines_npc",
	&"bandit",
]

const TOWN_COMBATANT_GROUPS: Array[StringName] = [
	&"faction_npc",
	&"engines_npc",
	&"bandit",
	&"becker_boys",
	&"town_groyper",
	&"town_fast",
	&"town_sheriff",
]

static var _faction_frame := -1
static var _faction_entries: Array[Dictionary] = []
static var _combatant_frame := -1
static var _combatant_entries: Array[Dictionary] = []
static var _town_frame := -1
static var _town_entries: Array[Dictionary] = []
static var _player_frame := -1
static var _player: Node3D = null


## Array of {node: Node3D, faction: StringName} for the "faction_npc" group,
## rebuilt at most once per physics frame.
static func faction_members(tree: SceneTree) -> Array[Dictionary]:
	var frame := Engine.get_physics_frames()
	if frame == _faction_frame:
		return _faction_entries
	_faction_frame = frame
	_faction_entries = _build_entries(tree, [&"faction_npc"])
	return _faction_entries


## faction_npc + engines_npc + bandit, deduped — the union nearest-hostile
## target picks walk.
static func combatants(tree: SceneTree) -> Array[Dictionary]:
	var frame := Engine.get_physics_frames()
	if frame == _combatant_frame:
		return _combatant_entries
	_combatant_frame = frame
	_combatant_entries = _build_entries(tree, COMBATANT_GROUPS)
	return _combatant_entries


## Widest union including town civilians — Engines raid targeting and
## living-member counts.
static func town_combatants(tree: SceneTree) -> Array[Dictionary]:
	var frame := Engine.get_physics_frames()
	if frame == _town_frame:
		return _town_entries
	_town_frame = frame
	_town_entries = _build_entries(tree, TOWN_COMBATANT_GROUPS)
	return _town_entries


static func find_player(tree: SceneTree) -> Node3D:
	var frame := Engine.get_physics_frames()
	if frame == _player_frame and _player != null and is_instance_valid(_player):
		return _player
	_player_frame = frame
	_player = null
	if tree != null:
		_player = tree.get_first_node_in_group("overworld_player") as Node3D
	return _player


static func _build_entries(tree: SceneTree, groups: Array[StringName]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if tree == null:
		return entries
	var seen: Dictionary = {}
	for group_name in groups:
		for npc in tree.get_nodes_in_group(group_name):
			if not (npc is Node3D) or not is_instance_valid(npc):
				continue
			var id := npc.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			entries.append({
				"node": npc as Node3D,
				"faction": FactionAffinityScript.resolve_faction_id(npc),
			})
	return entries
