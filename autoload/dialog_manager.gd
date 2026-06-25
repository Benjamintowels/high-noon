extends Node

const DIALOG_BOX_SCENE := preload("res://ui/scenes/dialog_box.tscn")

var _layer: CanvasLayer
var _dialog_box: DialogBox


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	_dialog_box = DIALOG_BOX_SCENE.instantiate() as DialogBox
	_layer.add_child(_dialog_box)
	_dialog_box.hide_immediate()


func show_dialog(
	speaker_name: String,
	text: String,
	on_dismiss: Callable = Callable()
) -> void:
	_dialog_box.show_line(speaker_name, text, on_dismiss)


func show_dialog_sequence(
	lines: PackedStringArray,
	on_dismiss: Callable = Callable(),
	speaker_name: String = ""
) -> void:
	_dialog_box.show_sequence(speaker_name, lines, on_dismiss)


func hide_dialog() -> void:
	_dialog_box.hide_line()


func is_showing() -> bool:
	return _dialog_box != null and _dialog_box.is_showing()
