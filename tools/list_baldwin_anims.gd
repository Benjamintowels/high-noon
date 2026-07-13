extends SceneTree

const SCENE := (
	"res://Assets/CharacterModels/Baldwin/Meshy_AI_King_Croaker_biped/"
	+ "Meshy_AI_King_Croaker_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)


func _initialize() -> void:
	var scene: PackedScene = load(SCENE)
	if scene == null:
		push_error("Failed to load scene")
		quit(1)
		return
	var instance := scene.instantiate()
	var player := RigAnimUtils.find_animation_player(instance)
	if player == null:
		push_error("No AnimationPlayer")
		quit(1)
		return
	for name in RigAnimUtils.collect_animation_names(player):
		print(name)
	instance.free()
	quit(0)
