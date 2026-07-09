extends RefCounted
class_name FactionIds

const NEUTRAL := &"neutral"
const BANDITS := &"bandits"
const BECKER_BOYS := &"becker_boys"
## Legacy alias — townspeople and sheriff belong to The Becker Boys.
const TOWNSPEOPLE := BECKER_BOYS
## Ranch hands from Top Ranch. Neutral to everyone until the hotel brawl
## turns them against the player (stays hostile until a future sidequest).
const TOP_RANCH := &"top_ranch"
const ENGINES := &"engines"
const CRUSADERS := &"crusaders"
const REDO := &"redo"
const RUINS := &"ruins"
const TC := &"tc"
const PLAYER := &"player"


static func get_display_name(faction_id: StringName) -> String:
	match faction_id:
		BECKER_BOYS:
			return "The Becker Boys"
		TOP_RANCH:
			return "Top Ranch"
		ENGINES:
			return "Engines"
		BANDITS:
			return "Bandits"
		CRUSADERS:
			return "Crusaders"
		REDO:
			return "Redo"
		RUINS:
			return "Ruins"
		TC:
			return "TC"
		PLAYER:
			return "Player"
		NEUTRAL:
			return "Neutral"
		_:
			return String(faction_id)


static func rallies_town_on_injury(faction_id: StringName) -> bool:
	return faction_id == BECKER_BOYS
