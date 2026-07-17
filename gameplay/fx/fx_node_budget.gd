extends RefCounted

## Ring-buffer helpers for FX node budgets.
## Godot's queue_free() does NOT drop get_child_count() until end of frame —
## eviction must remove_child() + free() immediately, or recycle in place.


static func ensure_container(parent: Node, container_name: StringName) -> Node3D:
	if parent == null:
		return null
	var existing := parent.get_node_or_null(NodePath(String(container_name))) as Node3D
	if existing != null:
		return existing
	var container := Node3D.new()
	container.name = String(container_name)
	parent.add_child(container)
	return container


## Immediately frees the oldest child. Safe inside spawn loops (unlike queue_free).
static func free_oldest(parent: Node) -> void:
	if parent == null or parent.get_child_count() <= 0:
		return
	var oldest := parent.get_child(0)
	parent.remove_child(oldest)
	oldest.free()


## Free oldest children until count < max_count. No-op if already under budget.
static func ensure_child_budget(parent: Node, max_count: int) -> void:
	if parent == null or max_count <= 0:
		return
	while parent.get_child_count() >= max_count:
		free_oldest(parent)


## Make room for `needed` new children by freeing oldest immediately.
static func ensure_room(parent: Node, max_count: int, needed: int = 1) -> void:
	if parent == null or max_count <= 0:
		return
	var room_needed := maxi(needed, 1)
	while parent.get_child_count() + room_needed > max_count:
		if parent.get_child_count() <= 0:
			break
		free_oldest(parent)


## Under budget: factory creates a new child (caller must add_child, or factory adds).
## At budget: returns the oldest child moved to the end (LRU recycle) — do not free it.
## `factory` is called only when creating; signature () -> Node, and this helper adds it.
static func acquire_or_recycle(parent: Node, max_count: int, factory: Callable) -> Node:
	if parent == null or max_count <= 0:
		return null
	if parent.get_child_count() >= max_count:
		var oldest := parent.get_child(0)
		parent.remove_child(oldest)
		parent.add_child(oldest)
		return oldest
	if not factory.is_valid():
		return null
	var node: Node = factory.call()
	if node == null:
		return null
	parent.add_child(node)
	return node


## True when parent is already at/over budget (useful for skip-when-full FX).
static func is_at_budget(parent: Node, max_count: int) -> bool:
	if parent == null or max_count <= 0:
		return true
	return parent.get_child_count() >= max_count
