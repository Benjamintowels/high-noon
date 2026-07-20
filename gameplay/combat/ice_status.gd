extends Node3D

## Stackable chill: slows movement, third stack freezes non-bosses into an ice block.

const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")
const IceBlockStatusScript := preload("res://gameplay/combat/ice_block_status.gd")
const IceFXScript := preload("res://gameplay/fx/ice_fx.gd")

const NODE_NAME := &"IceStatus"
const PENDING_DEATH_META := &"ice_pending_death"
const STACK1_MULT := 0.65
const STACK2_MULT := 0.40
const STACK1_DURATION := 5.0
const STACK2_ADD_DURATION := 5.0
const MAX_CHILL_STACKS := 2
const FREEZE_STACK := 3
const CHILL_TINT := Color(0.55, 0.9, 1.15, 1.0)

var _source: Node
var _stacks := 0
var _time_left := 0.0
var _aura: AnimatedSprite3D


static func is_chilled(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return host.get_node_or_null(NodePath(String(NODE_NAME))) != null


static func get_chill_stacks(host: Node) -> int:
	if host == null or not is_instance_valid(host):
		return 0
	var status := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if status == null or not status.has_method("get_stacks"):
		return 0
	return int(status.call("get_stacks"))


static func get_move_mult(host: Node) -> float:
	if host == null or not is_instance_valid(host):
		return 1.0
	if IceBlockStatusScript.is_frozen(host):
		return 0.0
	var stacks := get_chill_stacks(host)
	match stacks:
		1:
			return STACK1_MULT
		2:
			return STACK2_MULT
		_:
			return 1.0 if stacks <= 0 else STACK2_MULT


static func apply_chill(host: Node, source: Node = null) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not host.has_method("receive_bullet_hit"):
		return
	# Pending ice death is still freezable; otherwise skip corpses.
	if (
		host.has_method("is_defeated")
		and host.is_defeated()
		and not bool(host.get_meta(PENDING_DEATH_META, false))
	):
		return
	if IceBlockStatusScript.is_frozen(host):
		return

	var existing := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if existing != null and existing.has_method("add_stack"):
		existing.call("add_stack", source)
		return

	var script: Script = load("res://gameplay/combat/ice_status.gd") as Script
	var status: Node3D = script.new() as Node3D
	if status == null:
		return
	status.name = String(NODE_NAME)
	host.add_child(status)
	if status.has_method("setup"):
		status.call("setup", source)


func setup(source: Node) -> void:
	_source = source
	_stacks = 0
	_time_left = 0.0
	position = Vector3(0.0, 1.35, 0.0)
	_aura = IceFXScript.make_loop_aura(self, CHILL_TINT)
	add_stack(source)


func get_stacks() -> int:
	return _stacks


func add_stack(source: Node = null) -> void:
	if source != null:
		_source = source

	var next := _stacks + 1
	if next >= FREEZE_STACK:
		if BossGunResilienceScript.uses_boss_hud_poise(get_parent()):
			_stacks = MAX_CHILL_STACKS
			_time_left += STACK2_ADD_DURATION
			IceFXScript.spawn_chill_burst(get_parent())
			_refresh_chill_tint()
			return
		var host := get_parent()
		# Leaving chill: clear mesh tint; freeze flash + ice block take over.
		IceFXScript.clear_chill_modulate(host)
		queue_free()
		IceBlockStatusScript.freeze(host, _source)
		return

	IceFXScript.spawn_chill_burst(get_parent())
	_stacks = next
	if _stacks == 1:
		_time_left = STACK1_DURATION
	else:
		_time_left += STACK2_ADD_DURATION
	_refresh_chill_tint()


func _refresh_chill_tint() -> void:
	IceFXScript.apply_chill_modulate(get_parent(), IceFXScript.chill_modulate_for_stacks(_stacks))


func _process(delta: float) -> void:
	if not is_instance_valid(get_parent()):
		queue_free()
		return
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _exit_tree() -> void:
	# Freeze path clears tint before queue_free; natural expire restores here.
	var host := get_parent()
	if host != null and is_instance_valid(host) and not IceBlockStatusScript.is_frozen(host):
		IceFXScript.clear_chill_modulate(host)
