@tool
extends Node3D

const RUINS_GR_SNAP := preload("res://gameplay/world/ruins_gr_snap.gd")


@export_group("Layout Snap")
## Toggle on in the editor to snap, then save the scene. Does not run at play time.
@export var snap_stairs_and_floors: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		RUINS_GR_SNAP.apply_to_layout(self)
		snap_stairs_and_floors = false
