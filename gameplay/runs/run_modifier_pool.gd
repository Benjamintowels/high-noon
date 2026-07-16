extends Resource
class_name RunModifierPool

@export var modifiers: Array[Resource] = []


func pick_for_difficulty(difficulty: float, exclude_ids: Array[StringName] = []) -> Resource:
	var eligible: Array[Resource] = []
	var total_weight := 0.0
	for modifier in modifiers:
		if modifier == null or modifier.get("id") == &"":
			continue
		if difficulty < float(modifier.get("min_difficulty")):
			continue
		if exclude_ids.has(modifier.get("id") as StringName):
			continue
		eligible.append(modifier)
		total_weight += maxf(float(modifier.get("weight")), 0.0)

	if eligible.is_empty() or total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	var cursor := 0.0
	for modifier in eligible:
		cursor += maxf(float(modifier.get("weight")), 0.0)
		if roll <= cursor:
			return modifier
	return eligible[eligible.size() - 1]
