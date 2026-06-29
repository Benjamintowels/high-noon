extends Control

const FADE_IN_DURATION := 0.35
const HOLD_DURATION := 1.1
const FADE_OUT_DURATION := 0.45

@onready var _label: Label = $Label

var _tween: Tween


func play(text: String) -> void:
	_label.text = text
	modulate.a = 0.0
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(queue_free)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
