extends Node

## Amortizes expensive one-shot setup work (trimesh cover generation, prop
## decoration, ...) across frames with a per-frame millisecond budget, so big
## stages stop paying everything in one _ready hitch. Enqueue callables in
## dependency order; `drained` fires once after the last one runs.

signal drained

## Millisecond budget per frame. The queue always runs at least one job per
## frame so it can never stall on a single slow item.
@export var frame_budget_ms: float = 4.0

var _queue: Array[Callable] = []
var _drained_emitted := false


func enqueue(job: Callable) -> void:
	_queue.append(job)
	_drained_emitted = false
	set_process(true)


func enqueue_all(jobs: Array[Callable]) -> void:
	for job in jobs:
		_queue.append(job)
	if not _queue.is_empty():
		_drained_emitted = false
		set_process(true)


func is_drained() -> bool:
	return _queue.is_empty()


func _ready() -> void:
	set_process(not _queue.is_empty())


func _process(_delta: float) -> void:
	var deadline := Time.get_ticks_usec() + int(frame_budget_ms * 1000.0)
	while not _queue.is_empty():
		var job: Callable = _queue.pop_front()
		if job.is_valid():
			job.call()
		if Time.get_ticks_usec() >= deadline:
			break

	if _queue.is_empty():
		set_process(false)
		if not _drained_emitted:
			_drained_emitted = true
			drained.emit()
