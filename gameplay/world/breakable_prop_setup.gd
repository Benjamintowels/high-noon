extends RefCounted

## Scans a stage root for named obstacle props and installs BreakableProp so
## dynamite blasts can clear paths. Also upgrades rock collision to box shapes.

const BreakablePropScript := preload("res://gameplay/world/breakable_prop.gd")

const ROCK_PREFIXES := ["large_rock", "small_rock", "LargeRock", "SmallRock"]
const WOOD_PREFIXES := [
	"fence_planks",
	"Barrel_",
	"Barrel",
	"wood_barrel",
	"box",
	"Box",
	"crate",
	"Crate",
	"table",
	"Table",
	"chair",
	"Chair",
]
const TREE_PREFIXES := ["Tree", "extra_tree", "ExtraTree"]


static func apply_to(root: Node) -> void:
	if root == null:
		return
	_scan(root)


static func _scan(node: Node) -> void:
	if node is Node3D:
		var kind := _kind_for_name(String(node.name))
		if kind >= 0 and _should_install(node as Node3D):
			BreakablePropScript.install_on(node as Node3D, kind)
	for child in node.get_children():
		_scan(child)


static func _should_install(node: Node3D) -> bool:
	if node.has_meta("breakable_prop_installed"):
		return false
	# Already scripted destructibles / physics props — blast path hits them via groups.
	if node.has_method("break_apart") or node.has_method("break_from_explosion"):
		return false
	if node.is_in_group("punchable_prop") or node.is_in_group("sit_chair") or node.is_in_group("oil_drum"):
		return false
	if node is RigidBody3D:
		return false
	# Nested mesh/collision children named Tree/Box/etc. — only decorate the instance root.
	if node.get_parent() != null and _kind_for_name(String(node.get_parent().name)) >= 0:
		return false
	return true


static func _kind_for_name(node_name: String) -> int:
	for prefix in ROCK_PREFIXES:
		if node_name.begins_with(prefix):
			return BreakablePropScript.PropKind.ROCK
	for prefix in TREE_PREFIXES:
		if node_name.begins_with(prefix):
			return BreakablePropScript.PropKind.TREE
	for prefix in WOOD_PREFIXES:
		if node_name.begins_with(prefix):
			return BreakablePropScript.PropKind.WOOD
	return -1
