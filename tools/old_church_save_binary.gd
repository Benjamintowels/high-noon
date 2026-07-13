extends SceneTree

const SOURCE_PATH := "res://gameplay/world/old_church.scn"
const OUT_PATH := "res://gameplay/world/old_church.scn"


func _init() -> void:
	var packed := load(SOURCE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % SOURCE_PATH)
		quit(1)
		return

	var err := ResourceSaver.save(packed, OUT_PATH)
	if err != OK:
		push_error("Failed to save %s (%s)" % [OUT_PATH, error_string(err)])
		quit(1)
		return

	print("Saved binary scene to ", OUT_PATH)
	quit()
