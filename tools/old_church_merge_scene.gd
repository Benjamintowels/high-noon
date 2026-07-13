extends SceneTree

const GLB_PATH := "res://Assets/World/OldChurch.glb"
const VISUAL_OUT_PATH := "res://gameplay/world/old_church_visual.scn"
const WRAPPER_OUT_PATH := "res://gameplay/world/old_church.tscn"
const SCRIPT_PATH := "res://gameplay/world/old_church.gd"


func _init() -> void:
	var packed := load(GLB_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % GLB_PATH)
		quit(1)
		return

	var source_root := packed.instantiate()
	var visual_root := Node3D.new()
	visual_root.name = "OldChurchVisual"

	for child in source_root.get_children():
		var duplicate := child.duplicate() as Node
		visual_root.add_child(duplicate)
		duplicate.owner = visual_root
		_set_owners_recursive(duplicate, visual_root)

	source_root.free()

	var visual_packed := PackedScene.new()
	if visual_packed.pack(visual_root) != OK:
		push_error("Failed to pack visual scene")
		quit(1)
		return

	if ResourceSaver.save(visual_packed, VISUAL_OUT_PATH) != OK:
		push_error("Failed to save %s" % VISUAL_OUT_PATH)
		quit(1)
		return

	_save_wrapper_scene()
	print("Rebuilt %s and %s from GLB" % [VISUAL_OUT_PATH, WRAPPER_OUT_PATH])
	quit()


func _save_wrapper_scene() -> void:
	var file := FileAccess.open(WRAPPER_OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s" % WRAPPER_OUT_PATH)
		quit(1)
		return

	file.store_string("""[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="%s" id="1_script"]
[ext_resource type="PackedScene" path="%s" id="2_visual"]

[node name="OldChurch" type="Node3D"]
script = ExtResource("1_script")

[node name="Visual" parent="." instance=ExtResource("2_visual")]

[node name="Entrance" type="Marker3D" parent="."]

[node name="Props" type="Node3D" parent="."]

[node name="Lights" type="Node3D" parent="."]

[editable path="Visual"]
""" % [SCRIPT_PATH, VISUAL_OUT_PATH])
	file.close()


func _set_owners_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owners_recursive(child, owner)
