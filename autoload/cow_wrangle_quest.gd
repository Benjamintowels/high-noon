extends Node

signal quest_accepted
signal wrangle_count_changed(wrangled: int, total: int)
signal quest_completed

const REQUIRED_COWS := 2

var active := false
var accepted := false
var completed := false
var wrangled_count := 0


func reset_quest() -> void:
	active = false
	accepted = false
	completed = false
	wrangled_count = 0


func begin_quest() -> void:
	active = true
	accepted = true
	wrangled_count = 0
	completed = false
	quest_accepted.emit()
	wrangle_count_changed.emit(wrangled_count, REQUIRED_COWS)


func register_wrangled_cow() -> void:
	if not accepted or completed:
		return
	wrangled_count = mini(wrangled_count + 1, REQUIRED_COWS)
	wrangle_count_changed.emit(wrangled_count, REQUIRED_COWS)
	if wrangled_count >= REQUIRED_COWS:
		completed = true
		quest_completed.emit()


func is_ready_for_reward() -> bool:
	return accepted and completed and wrangled_count >= REQUIRED_COWS


func mark_reward_claimed() -> void:
	completed = true
