extends Node3D

## Open THIS scene (F6) to tune the FPS gun and reticle.
## In the editor: select FpsRig -> Yaw -> Pitch -> FpsCamera -> ViewModel
## and move/rotate with the 3D gizmo. Changes save on groyper_player.tscn.


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
