extends Resource
class_name RunEnemyPool

@export var entries: Array[Resource] = []


func pick_for_difficulty(difficulty: float) -> PackedScene:
	var eligible: Array[Resource] = []
	var total_weight := 0.0
	for entry in entries:
		if entry == null or entry.get("enemy_scene") == null:
			continue
		if difficulty < float(entry.get("min_difficulty")) or difficulty > float(entry.get("max_difficulty")):
			continue
		eligible.append(entry)
		total_weight += maxf(float(entry.get("weight")), 0.0)

	if eligible.is_empty():
		return _pick_fallback(difficulty)
	if total_weight <= 0.0:
		return eligible[randi() % eligible.size()].get("enemy_scene") as PackedScene

	var roll := randf() * total_weight
	var cursor := 0.0
	for entry in eligible:
		cursor += maxf(float(entry.get("weight")), 0.0)
		if roll <= cursor:
			return entry.get("enemy_scene") as PackedScene
	return eligible[eligible.size() - 1].get("enemy_scene") as PackedScene


func _pick_fallback(difficulty: float) -> PackedScene:
	var best: Resource = null
	var best_dist := INF
	for entry in entries:
		if entry == null or entry.get("enemy_scene") == null:
			continue
		var dist := 0.0
		var min_d := float(entry.get("min_difficulty"))
		var max_d := float(entry.get("max_difficulty"))
		if difficulty < min_d:
			dist = min_d - difficulty
		elif difficulty > max_d:
			dist = difficulty - max_d
		if dist < best_dist:
			best_dist = dist
			best = entry
	if best != null:
		return best.get("enemy_scene") as PackedScene
	return null
