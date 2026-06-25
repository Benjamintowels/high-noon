extends RigidBody3D

const LIFETIME := 2.4


func _ready() -> void:
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)
