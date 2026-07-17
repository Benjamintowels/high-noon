extends RefCounted

## Shared open-count for debug menus (armory chest / terminal).
## Player input and Esc→inventory skip while any debug UI is open.

const GROUP_NAME := &"debug_ui_blocking"

static var _open_count := 0


static func begin(host: Node) -> void:
	_open_count += 1
	if host != null and is_instance_valid(host) and not host.is_in_group(GROUP_NAME):
		host.add_to_group(GROUP_NAME)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


static func end(host: Node) -> void:
	_open_count = maxi(_open_count - 1, 0)
	if host != null and is_instance_valid(host) and host.is_in_group(GROUP_NAME):
		host.remove_from_group(GROUP_NAME)
	if _open_count <= 0:
		_open_count = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


static func is_blocking() -> bool:
	return _open_count > 0


static func is_blocking_in_tree(tree: SceneTree) -> bool:
	if _open_count > 0:
		return true
	if tree == null:
		return false
	return not tree.get_nodes_in_group(GROUP_NAME).is_empty()
