extends SceneTree

const CANDIDATES := [
	Vector3(0, -90, -30),
	Vector3(5, -90, -30),
	Vector3(-5, -90, -30),
	Vector3(0, -90, -25),
	Vector3(8, -90, -35),
]


func _initialize() -> void:
	var player: Node3D = load("res://characters/groyper/groyper_player.tscn").instantiate()
	root.add_child(player)
	await create_timer(0.8).timeout

	var cam: Camera3D = player.get_node("FpsRig/Yaw/Pitch/FpsCamera")
	var vm: Node3D = player.get_node("FpsRig/Yaw/Pitch/FpsCamera/ViewModel/FpsRevolverViewModel")
	var muzzle: Node3D = vm.get_node("RevolverGrip/Revolver/Muzzle")
	var forward := -cam.global_transform.basis.z

	for euler in CANDIDATES:
		vm.rotation_degrees = euler
		await create_timer(0.05).timeout
		var barrel := muzzle.global_transform.basis.x.normalized()
		print("euler=%s x_dot=%.4f barrel=%s" % [euler, barrel.dot(forward), barrel.snapped(Vector3(0.01, 0.01, 0.01))])

	quit()
