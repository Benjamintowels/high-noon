class_name CylinderAmmoDisplay
extends Control

const CHAMBER_BULLET_SCENE := preload("res://ui/scenes/chamber_bullet.tscn")

const MAX_ROUNDS := 6
const SPIN_STEP_DEG := 360.0 / float(MAX_ROUNDS)
const SPIN_DURATION := 0.24
const LOAD_POP_SCALE := 2.2
const LOAD_POP_DURATION := 0.1
const EJECT_STAGGER := 0.04
const EJECT_FLY_DURATION := 0.2
const WHEEL_CENTER := Vector2(62.0, 62.0)

@export var bullet_slot_size := Vector2(18.0, 18.0)
@export var chamber_radius := 34.0

@onready var _chamber_marker: Control = $ChamberMarker
@onready var _chamber_pivot: Control = $ChamberPivot

var _rounds := MAX_ROUNDS
var _chambers_fired := 0
var _chamber_slots: Array[Control] = []
var _spin_tween: Tween
var _load_pop_tween: Tween


func _ready() -> void:
	_position_chamber_marker()
	_build_chambers()
	sync_rounds(MAX_ROUNDS)


func sync_rounds(count: int, animate_shot: bool = false, reset_cylinder: bool = false) -> void:
	var previous := _rounds
	_rounds = clampi(count, 0, MAX_ROUNDS)
	if reset_cylinder:
		_chambers_fired = 0
	elif animate_shot and _rounds < previous:
		_chambers_fired = mini(_chambers_fired + 1, MAX_ROUNDS)

	_update_chamber_states()

	if animate_shot and _rounds < previous:
		_advance_chamber_wheel()
	else:
		_chamber_pivot.rotation_degrees = _chambers_fired * SPIN_STEP_DEG


func _position_chamber_marker() -> void:
	var pivot := WHEEL_CENTER
	var angle := -PI * 0.5
	var chamber_offset := Vector2(cos(angle), sin(angle)) * chamber_radius
	_chamber_marker.custom_minimum_size = bullet_slot_size
	_chamber_marker.size = bullet_slot_size
	_chamber_marker.position = pivot + chamber_offset - bullet_slot_size * 0.5
	_chamber_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_chambers() -> void:
	_chamber_slots.clear()
	for child in _chamber_pivot.get_children():
		if child.name == "HexagonFrame":
			continue
		child.queue_free()

	var pivot := WHEEL_CENTER
	_chamber_pivot.pivot_offset = pivot

	for i in MAX_ROUNDS:
		var slot: Control = CHAMBER_BULLET_SCENE.instantiate()
		slot.custom_minimum_size = bullet_slot_size
		slot.size = bullet_slot_size
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var angle := (TAU * float(i) / float(MAX_ROUNDS)) - PI * 0.5
		var chamber_offset := Vector2(cos(angle), sin(angle)) * chamber_radius
		slot.position = pivot + chamber_offset - bullet_slot_size * 0.5
		_chamber_pivot.add_child(slot)
		_chamber_slots.append(slot)


func _update_chamber_states() -> void:
	for i in _chamber_slots.size():
		var slot := _chamber_slots[i]
		slot.visible = true
		if slot.has_method("set_loaded"):
			slot.set_loaded(_is_chamber_loaded(i))


func _is_chamber_loaded(index: int) -> bool:
	if _rounds <= 0:
		return false

	var first_loaded := _chambers_fired
	var last_loaded := (_chambers_fired + _rounds - 1) % MAX_ROUNDS
	if first_loaded <= last_loaded:
		return index >= first_loaded and index <= last_loaded
	return index >= first_loaded or index <= last_loaded


func _advance_chamber_wheel() -> void:
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()

	var target_rotation := _chambers_fired * SPIN_STEP_DEG

	_spin_tween = create_tween()
	_spin_tween.tween_property(
		_chamber_pivot,
		"rotation_degrees",
		target_rotation,
		SPIN_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func eject_all_casings() -> void:
	_rounds = 0
	_chambers_fired = 0
	_update_chamber_states()
	_chamber_pivot.rotation_degrees = 0.0

	for i in _chamber_slots.size():
		var slot := _chamber_slots[i]
		if slot.has_method("set_loaded"):
			slot.set_loaded(false)
		_animate_casing_eject(slot, i)


func animate_load_round(round_count: int) -> void:
	var previous := _rounds
	_rounds = clampi(round_count, 0, MAX_ROUNDS)
	_update_chamber_states()
	_chamber_pivot.rotation_degrees = _chambers_fired * SPIN_STEP_DEG

	if _rounds <= previous:
		return

	var chamber_index := (_chambers_fired + _rounds - 1) % MAX_ROUNDS
	if chamber_index < 0 or chamber_index >= _chamber_slots.size():
		return
	_pop_chamber_slot(_chamber_slots[chamber_index])


func _pop_chamber_slot(slot: Control) -> void:
	if _load_pop_tween != null and _load_pop_tween.is_valid():
		_load_pop_tween.kill()

	slot.scale = Vector2.ONE * LOAD_POP_SCALE
	slot.pivot_offset = slot.size * 0.5

	_load_pop_tween = create_tween()
	_load_pop_tween.tween_property(
		slot,
		"scale",
		Vector2.ONE,
		LOAD_POP_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_casing_eject(slot: Control, index: int) -> void:
	var delay := float(index) * EJECT_STAGGER
	if delay <= 0.0:
		_spawn_flying_casing(slot, index)
		return

	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if is_instance_valid(self) and is_instance_valid(slot):
				_spawn_flying_casing(slot, index)
	)


func _spawn_flying_casing(slot: Control, index: int) -> void:
	var flying: Control = CHAMBER_BULLET_SCENE.instantiate()
	flying.custom_minimum_size = bullet_slot_size
	flying.size = bullet_slot_size
	flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying.pivot_offset = bullet_slot_size * 0.5
	if flying.has_method("set_loaded"):
		flying.set_loaded(false)
	add_child(flying)
	flying.position = _chamber_pivot.position + slot.position
	flying.scale = slot.scale

	var start := flying.position
	var angle := (TAU * float(index) / float(MAX_ROUNDS)) - PI * 0.5
	var end := start + Vector2(cos(angle), sin(angle)) * 28.0 + Vector2(0.0, -16.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		flying,
		"position",
		end,
		EJECT_FLY_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		flying,
		"scale",
		Vector2.ONE * 0.35,
		EJECT_FLY_DURATION
	)
	tween.tween_property(
		flying,
		"modulate:a",
		0.0,
		EJECT_FLY_DURATION * 0.85
	).set_delay(EJECT_FLY_DURATION * 0.15)
	tween.chain().tween_callback(flying.queue_free)
