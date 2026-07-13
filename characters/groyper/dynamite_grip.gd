extends Node3D

## Applies the Dynamite albedo texture to the imported Meshy mesh.

const ALBEDO_PATH := "res://Assets/Weapons/Dynamite/textures/Dynamite.png"


func _ready() -> void:
	_apply_texture()


func _apply_texture() -> void:
	if not ResourceLoader.exists(ALBEDO_PATH):
		return
	var albedo := load(ALBEDO_PATH) as Texture2D
	if albedo == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.roughness = 0.72
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		mesh_inst.material_override = mat
