extends Node

const POPUP_SCENE := preload("res://ui/scenes/reward_popup.tscn")

var _layer: CanvasLayer
var _popup: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 110
	add_child(_layer)


func show_gram_reward(amount: int) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = POPUP_SCENE.instantiate()
	_layer.add_child(_popup)
	_popup.call("play", "+%d Gram" % amount)
