extends RefCounted
class_name NpcCoverTactics

## Helpers for firearm NPCs seeking CoverPiece props between them and a target.

const OCCUPANT_META := &"npc_cover_occupant"
const DEFAULT_SEARCH_RANGE := 18.0
const BETWEEN_LATERAL_MAX := 2.75
const BETWEEN_ALONG_MIN := 1.0
const FLANK_SAME_SIDE_DOT := 0.2
const PEEK_AIM_HEIGHT := 1.45
const PEEK_EDGE_OFFSET := 0.4


static func find_best_cover(
	npc: Node3D,
	player: Node3D,
	tree: SceneTree,
	max_range: float = DEFAULT_SEARCH_RANGE
) -> CoverPiece:
	if npc == null or player == null or tree == null:
		return null

	var npc_pos := npc.global_position
	var player_pos := player.global_position
	var to_player := player_pos - npc_pos
	to_player.y = 0.0
	var span := to_player.length()
	if span < 2.5:
		return null
	var forward := to_player / span
	var max_range_sq := max_range * max_range

	var best: CoverPiece
	var best_score := -INF
	for node in tree.get_nodes_in_group("cover_piece"):
		if not node is CoverPiece:
			continue
		var cover := node as CoverPiece
		if not is_instance_valid(cover):
			continue
		if is_claimed_by_other(cover, npc):
			continue

		var anchor := cover.get_cover_anchor()
		var to_anchor := anchor - npc_pos
		to_anchor.y = 0.0
		if to_anchor.length_squared() > max_range_sq:
			continue

		var along := to_anchor.dot(forward)
		if along < BETWEEN_ALONG_MIN or along > span - 0.75:
			continue
		var lateral := (to_anchor - forward * along).length()
		var lateral_limit := maxf(
			BETWEEN_LATERAL_MAX,
			maxf(cover.cover_half_extents.x, cover.cover_half_extents.z) + 1.25
		)
		if lateral > lateral_limit:
			continue

		var spot := get_cover_hold_spot(cover, player)
		var hold_pos: Vector3 = spot.get("position", Vector3.ZERO)
		var to_hold := hold_pos - npc_pos
		to_hold.y = 0.0
		# Prefer nearer free spots that sit cleanly on the NPC→player line.
		var score := (span - along) * 1.5 - lateral * 2.0 - to_hold.length() * 0.35
		if score > best_score:
			best_score = score
			best = cover
	return best


static func get_cover_hold_spot(cover: CoverPiece, player: Node3D) -> Dictionary:
	if cover == null or player == null:
		return {
			"position": Vector3.ZERO,
			"facing_yaw": 0.0,
			"outward": Vector3.FORWARD,
		}
	# Far side from the player = NPC behind the box with the crate between them.
	return cover.get_crouch_spot(player, true)


static func is_flanked(cover: CoverPiece, npc: Node3D, player: Node3D) -> bool:
	if cover == null or npc == null or player == null:
		return true
	var anchor := cover.get_cover_anchor()
	var to_npc := npc.global_position - anchor
	to_npc.y = 0.0
	var to_player := player.global_position - anchor
	to_player.y = 0.0
	if to_npc.length_squared() < 0.04 or to_player.length_squared() < 0.04:
		return true
	# Same half-space around the box → player has crossed to the NPC's side.
	return to_npc.normalized().dot(to_player.normalized()) > FLANK_SAME_SIDE_DOT


static func get_peek_aim_origin(hold_position: Vector3, outward: Vector3) -> Vector3:
	var edge := outward
	edge.y = 0.0
	if edge.length_squared() < 0.0001:
		edge = Vector3.FORWARD
	else:
		edge = edge.normalized()
	# Step slightly toward the threat side of the lip so chest rays clear the box.
	return hold_position + Vector3(0.0, PEEK_AIM_HEIGHT, 0.0) - edge * PEEK_EDGE_OFFSET


static func is_claimed_by_other(cover: CoverPiece, npc: Node3D) -> bool:
	if cover == null or not cover.has_meta(OCCUPANT_META):
		return false
	var occupant: Variant = cover.get_meta(OCCUPANT_META)
	if occupant == null or not is_instance_valid(occupant):
		cover.remove_meta(OCCUPANT_META)
		return false
	return occupant != npc


static func claim(cover: CoverPiece, npc: Node3D) -> bool:
	if cover == null or npc == null:
		return false
	if is_claimed_by_other(cover, npc):
		return false
	cover.set_meta(OCCUPANT_META, npc)
	return true


static func release(cover: CoverPiece, npc: Node3D) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	if not cover.has_meta(OCCUPANT_META):
		return
	var occupant: Variant = cover.get_meta(OCCUPANT_META)
	if occupant == npc or occupant == null or not is_instance_valid(occupant):
		cover.remove_meta(OCCUPANT_META)
