extends RefCounted
class_name FactionAffinity

enum Relation { HOSTILE, NEUTRAL, FRIENDLY }


static func get_relation(from_faction: StringName, to_faction: StringName) -> Relation:
	if from_faction == to_faction:
		return Relation.FRIENDLY

	match from_faction:
		FactionIds.BANDITS:
			match to_faction:
				FactionIds.BECKER_BOYS, FactionIds.PLAYER:
					return Relation.HOSTILE
				FactionIds.BANDITS:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.BECKER_BOYS:
			match to_faction:
				FactionIds.BANDITS, FactionIds.ENGINES:
					return Relation.HOSTILE
				FactionIds.BECKER_BOYS:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.ENGINES:
			match to_faction:
				FactionIds.PLAYER, FactionIds.BECKER_BOYS, FactionIds.BANDITS:
					return Relation.HOSTILE
				FactionIds.ENGINES:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.PLAYER:
			match to_faction:
				FactionIds.BANDITS, FactionIds.ENGINES, FactionIds.REDO:
					return Relation.HOSTILE
				FactionIds.PLAYER, FactionIds.CRUSADERS:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.CRUSADERS:
			match to_faction:
				FactionIds.BANDITS, FactionIds.ENGINES, FactionIds.REDO:
					return Relation.HOSTILE
				FactionIds.CRUSADERS, FactionIds.PLAYER:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.REDO:
			match to_faction:
				FactionIds.PLAYER, FactionIds.CRUSADERS:
					return Relation.HOSTILE
				FactionIds.REDO:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		_:
			return Relation.NEUTRAL


static func is_hostile(from_faction: StringName, to_faction: StringName) -> bool:
	return get_relation(from_faction, to_faction) == Relation.HOSTILE


## Bandits fight everyone who is not a bandit (townsfolk + player).
static func faction_wars_with_outsiders(faction_id: StringName) -> bool:
	return faction_id == FactionIds.BANDITS


static func is_outsider_war_target(from_faction: StringName, to_faction: StringName) -> bool:
	if from_faction == FactionIds.BANDITS:
		return to_faction == FactionIds.BECKER_BOYS or to_faction == FactionIds.PLAYER
	return false


static func is_enemy_faction(from_faction: StringName, to_faction: StringName) -> bool:
	if is_outsider_war_target(from_faction, to_faction):
		return true
	return is_hostile(from_faction, to_faction)


static func is_friendly(from_faction: StringName, to_faction: StringName) -> bool:
	return get_relation(from_faction, to_faction) == Relation.FRIENDLY


static func are_allies(a: Node, b: Node) -> bool:
	if a == null or b == null:
		return false
	return is_friendly(resolve_faction_id(a), resolve_faction_id(b))


static func are_hostile(a: Node, b: Node) -> bool:
	if a == null or b == null:
		return false
	return is_hostile(resolve_faction_id(a), resolve_faction_id(b))


static func resolve_faction_id(node: Node) -> StringName:
	if node == null or not is_instance_valid(node):
		return FactionIds.NEUTRAL
	if node.has_method("get_faction_id"):
		return node.call("get_faction_id")
	if node.is_in_group("bandit"):
		return FactionIds.BANDITS
	if node.is_in_group("engines_npc"):
		return FactionIds.ENGINES
	if (
		node.is_in_group("town_groyper")
		or node.is_in_group("town_fast")
		or node.is_in_group("town_sheriff")
	):
		return FactionIds.BECKER_BOYS
	if node.is_in_group("overworld_player"):
		return FactionIds.PLAYER
	if node.is_in_group("crusader_npc"):
		return FactionIds.CRUSADERS
	if node.is_in_group("redo_npc") or node.is_in_group("pavel_npc"):
		return FactionIds.REDO
	return FactionIds.NEUTRAL
