extends RefCounted
class_name FactionAffinity

enum Relation { HOSTILE, NEUTRAL, FRIENDLY }


static func get_relation(from_faction: StringName, to_faction: StringName) -> Relation:
	if from_faction == to_faction:
		return Relation.FRIENDLY

	match from_faction:
		FactionIds.BANDITS:
			match to_faction:
				FactionIds.TOWNSPEOPLE, FactionIds.PLAYER:
					return Relation.HOSTILE
				FactionIds.BANDITS:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.TOWNSPEOPLE:
			match to_faction:
				FactionIds.BANDITS:
					return Relation.HOSTILE
				FactionIds.TOWNSPEOPLE, FactionIds.PLAYER:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		FactionIds.PLAYER:
			match to_faction:
				FactionIds.BANDITS:
					return Relation.HOSTILE
				FactionIds.TOWNSPEOPLE, FactionIds.PLAYER:
					return Relation.FRIENDLY
				_:
					return Relation.NEUTRAL
		_:
			return Relation.NEUTRAL


static func is_hostile(from_faction: StringName, to_faction: StringName) -> bool:
	return get_relation(from_faction, to_faction) == Relation.HOSTILE


static func is_friendly(from_faction: StringName, to_faction: StringName) -> bool:
	return get_relation(from_faction, to_faction) == Relation.FRIENDLY


static func resolve_faction_id(node: Node) -> StringName:
	if node == null or not is_instance_valid(node):
		return FactionIds.NEUTRAL
	if node.has_method("get_faction_id"):
		return node.call("get_faction_id")
	if node.is_in_group("bandit"):
		return FactionIds.BANDITS
	if node.is_in_group("town_groyper"):
		return FactionIds.TOWNSPEOPLE
	if node.is_in_group("overworld_player"):
		return FactionIds.PLAYER
	return FactionIds.NEUTRAL
