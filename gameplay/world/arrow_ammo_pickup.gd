extends "res://gameplay/world/revolver_ammo_pickup.gd"
## Walk-over arrow pickup: auto-attracts like revolver ammo but refills the
## player's bow ammo (only collectible while the bow is equipped and not full).

const ARROW_SCENE := preload("res://Assets/Weapons/Bow/arrow.tscn")


func _can_collect_now() -> bool:
	if _player == null or not _player.has_method("get_bow_ammo_space"):
		return false
	return int(_player.call("get_bow_ammo_space")) > 0


func _add_ammo(player: Node3D, amount: int) -> int:
	if player == null or not player.has_method("add_bow_ammo"):
		return 0
	return int(player.call("add_bow_ammo", amount))


func _grab_sound_weapon_id() -> GroyperWeapons.Id:
	return GroyperWeapons.Id.BOW


func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "AmmoVisual"
	add_child(_visual_root)

	# Arrow scene points tip toward -Z; lean it tip-up so the parent's spin
	# (rotate_y) shows it off like the revolver ammo drum.
	var arrow: Node3D = ARROW_SCENE.instantiate()
	arrow.transform = Transform3D(
		Basis.from_euler(Vector3(1.25, 0.0, 0.0)).scaled(Vector3(0.8, 0.8, 0.8)),
		Vector3(0.0, 0.2, 0.0)
	)
	_visual_root.add_child(arrow)

	_visual_root.position.y = 0.04
