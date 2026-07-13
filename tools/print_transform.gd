extends SceneTree
func _initialize() -> void:
    var n := Node3D.new()
    n.rotation_degrees = Vector3(0, -90, -25)
    print(n.transform)
    quit()
