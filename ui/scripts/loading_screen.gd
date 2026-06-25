extends Control

const FADE_DURATION := 0.65
const MIN_LOAD_DISPLAY := 0.85

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var progress_bar: ProgressBar = $Layout/ProgressBar
@onready var status_label: Label = $Layout/StatusLabel

var _stage_path: String = GameState.pending_stage_path
var _load_started_at: float = 0.0
var _transition_started: bool = false
var _load_progress: Array = []


func _ready() -> void:
	_load_started_at = Time.get_ticks_msec() / 1000.0
	fade_overlay.modulate.a = 1.0

	var reveal := create_tween()
	reveal.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	ResourceLoader.load_threaded_request(_stage_path)


func _process(_delta: float) -> void:
	if _transition_started:
		return

	var status := ResourceLoader.load_threaded_get_status(_stage_path, _load_progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not _load_progress.is_empty():
				progress_bar.value = _load_progress[0] * 100.0
			status_label.text = "Loading the frontier..."
		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = 100.0
			status_label.text = "Saddling up..."
			_transition_started = true
			_finish_loading.call_deferred()
		ResourceLoader.THREAD_LOAD_FAILED:
			status_label.text = "Failed to load stage."
			push_error("Failed to load stage: %s" % _stage_path)


func _finish_loading() -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0 - _load_started_at
	if elapsed < MIN_LOAD_DISPLAY:
		await get_tree().create_timer(MIN_LOAD_DISPLAY - elapsed).timeout

	var packed: PackedScene = ResourceLoader.load_threaded_get(_stage_path)
	if packed == null:
		status_label.text = "Failed to load stage."
		return

	var fade := create_tween()
	fade.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished

	get_tree().change_scene_to_packed(packed)
