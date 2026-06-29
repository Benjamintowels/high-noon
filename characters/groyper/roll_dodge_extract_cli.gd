extends SceneTree

func _init() -> void:
	var err := RollDodgeExtract.extract_to_res()
	quit(0 if err == OK else 1)
