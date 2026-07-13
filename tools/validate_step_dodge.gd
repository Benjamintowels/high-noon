extends SceneTree

const RigAnimConfig := preload("res://characters/groyper/rig_anim_config.gd")
const RigAnimUtils := preload("res://characters/groyper/rig_anim_utils.gd")


func _initialize() -> void:
	var lines: PackedStringArray = []
	for pose_name: String in RigAnimConfig.AUTHORED_SIDESTEP_POSES.keys():
		var scene_path: String = RigAnimConfig.AUTHORED_SIDESTEP_POSES[pose_name]
		var source := RigAnimUtils.load_skeleton_animation(scene_path)
		if source == null:
			lines.append("%s FAILED" % pose_name)
			continue
		var prepared := RigAnimUtils.prepare_for_body_player(source)
		lines.append(
			"%s length=%.3f tracks=%d"
			% [pose_name, prepared.length, prepared.get_track_count()]
		)
	var f := FileAccess.open("c:/Users/TowelsPC/Documents/high-noon/tools/step_dodge_validate.txt", FileAccess.WRITE)
	for line in lines:
		f.store_line(line)
	f.close()
	quit()
