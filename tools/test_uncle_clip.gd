extends SceneTree

const SCENE := UncleToadAnimConfig.MERGED_SCENE
const CLIP := UncleToadAnimConfig.MESHY_WALK

func _initialize() -> void:
	var anim := RigAnimUtils.load_skeleton_animation(SCENE, CLIP)
	print("walk anim: ", anim != null, " len=", anim.length if anim else 0)
	quit(0)
