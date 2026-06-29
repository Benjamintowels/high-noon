extends Node3D

const GRAZE_WORK_REQUIRED := 2.8
const REGROW_TIME := 50.0

var consumed := false

@onready var _visual: Node3D = $Visual

var _graze_progress := 0.0
var _regrow_timer := 0.0


func _ready() -> void:
	add_to_group("tall_grass")


func _process(delta: float) -> void:
	if not consumed:
		return
	_regrow_timer -= delta
	if _regrow_timer <= 0.0:
		_regrow()


func add_graze_work(delta: float) -> bool:
	if consumed:
		return true

	_graze_progress += delta
	if _visual != null:
		var eaten := clampf(_graze_progress / GRAZE_WORK_REQUIRED, 0.0, 1.0)
		var scale_factor := lerpf(1.0, 0.12, eaten)
		_visual.scale = Vector3(scale_factor, scale_factor, scale_factor)

	if _graze_progress >= GRAZE_WORK_REQUIRED:
		_consume()
		return true
	return false


func _consume() -> void:
	consumed = true
	_graze_progress = 0.0
	_regrow_timer = REGROW_TIME
	if _visual != null:
		_visual.visible = false


func _regrow() -> void:
	consumed = false
	if _visual != null:
		_visual.visible = true
		_visual.scale = Vector3.ONE
