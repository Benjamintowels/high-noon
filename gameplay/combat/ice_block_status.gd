extends Node

## Frozen state on an NPC: locks move/attack and owns a kickable IceBlock shell.

const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const ICE_BLOCK_SCENE := preload("res://gameplay/combat/ice_block.tscn")
const NODE_NAME := &"IceBlockStatus"
const PENDING_DEATH_META := &"ice_pending_death"
const MAX_DURATION := 3.0

var _source: Node
var _block: CharacterBody3D
var _removed_duel_target := false


static func is_frozen(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	return host.get_node_or_null(NodePath(String(NODE_NAME))) != null


## Punches/shots that still resolve on the frozen host slide the ice block instead.
static func try_redirect_hit_to_block(host: Node, hit_info: Dictionary) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if bool(hit_info.get("ice_shatter_hit", false)) or bool(hit_info.get("ice_thaw_kill", false)):
		return false
	var status := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if status == null or not status.has_method("redirect_hit"):
		return false
	return bool(status.call("redirect_hit", hit_info))


static func freeze(host: Node, source: Node = null, duration: float = MAX_DURATION) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not (host is CharacterBody3D):
		return
	if BossGunResilienceScript.uses_boss_hud_poise(host):
		return
	# Allow hosts marked for ice-deferred death; reject true corpses.
	if (
		host.has_method("is_defeated")
		and host.is_defeated()
		and not bool(host.get_meta(PENDING_DEATH_META, false))
	):
		return
	var existing := host.get_node_or_null(NodePath(String(NODE_NAME))) as Node
	if existing != null and existing.has_method("refresh"):
		existing.call("refresh", duration, source)
		return
	var chill := host.get_node_or_null("IceStatus")
	if chill != null:
		chill.queue_free()
	var script: Script = load("res://gameplay/combat/ice_block_status.gd") as Script
	var status: Node = script.new() as Node
	if status == null:
		return
	status.name = String(NODE_NAME)
	host.add_child(status)
	if status.has_method("setup"):
		status.call("setup", source, duration)


## Call from NPC physics after stun: zeros locomotion and skips AI while frozen.
static func tick_if_frozen(host: CharacterBody3D, _delta: float) -> bool:
	if host == null or not is_frozen(host):
		return false
	host.velocity = Vector3.ZERO
	return true


func setup(source: Node, duration: float) -> void:
	_source = source
	var host := get_parent() as CharacterBody3D
	if host == null:
		queue_free()
		return

	CombatHitFlashScript.flash_ice_freeze(host)
	if host.is_in_group("duel_target"):
		host.remove_from_group("duel_target")
		_removed_duel_target = true

	var parent := ImpactFXScript.parent_for(host)
	if parent == null:
		parent = host.get_parent()
	if parent == null:
		queue_free()
		return

	_block = ICE_BLOCK_SCENE.instantiate() as CharacterBody3D
	if _block == null:
		queue_free()
		return
	parent.add_child(_block)
	if _block.has_method("setup"):
		_block.call("setup", host, source, self, maxf(duration, 0.5))


func refresh(duration: float, source: Node = null) -> void:
	if source != null:
		_source = source
	if _block != null and is_instance_valid(_block) and _block.has_method("refresh"):
		_block.call("refresh", duration, source)


func redirect_hit(hit_info: Dictionary) -> bool:
	if _block == null or not is_instance_valid(_block):
		return false
	if _block.has_method("receive_bullet_hit"):
		_block.call("receive_bullet_hit", hit_info)
		return true
	return false


func _exit_tree() -> void:
	var host := get_parent()
	if (
		_removed_duel_target
		and host != null
		and is_instance_valid(host)
		and not host.is_in_group("duel_target")
	):
		host.add_to_group("duel_target")
	_removed_duel_target = false
	if _block != null and is_instance_valid(_block):
		if _block.has_method("is_shattering") and bool(_block.call("is_shattering")):
			_block = null
			return
		if _block.has_method("release_without_shatter"):
			_block.call("release_without_shatter")
	_block = null
