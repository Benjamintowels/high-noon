extends SceneTree

const OUT_PATH := OS.get_cache_dir().path_join("high_noon_fps_capture.png")


func _initialize() -> void:
	var player: Node3D = load("res://characters/groyper/groyper_player.tscn").instantiate()
	var world := Node3D.new()
	world.add_child(player)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 40, 0)
	sun.light_energy = 1.4
	world.add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.position.y = -0.01
	world.add_child(ground)

	var window := Window.new()
	window.size = Vector2i(1152, 648)
	window.add_child(world)
	root.add_child(window)
	window.show()

	await create_timer(2.0).timeout
	var image := window.get_viewport().get_texture().get_image()
	var saved := OUT_PATH
	image.save_png(saved)
	print("CAPTURE_SAVED:", saved)
	quit()
