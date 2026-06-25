extends RigidBody3D

const LIFETIME := 3.5


func _ready() -> void:
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)
