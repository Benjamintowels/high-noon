extends Node3D

const HAMMERS_SCENE := preload("res://Assets/Weapons/Hammers/source/Hammers.fbx")


func _ready() -> void:
	var hammers: Node3D = HAMMERS_SCENE.instantiate()
	add_child(hammers)
	for hidden_name in ["BallPeenHammer", "ClawHammer"]:
		var node := hammers.get_node_or_null(hidden_name) as Node3D
		if node != null:
			node.visible = false
	var club := hammers.get_node_or_null("ClubHammer") as Node3D
	if club == null:
		push_warning("HammerMesh: ClubHammer node missing from Hammers.fbx.")
