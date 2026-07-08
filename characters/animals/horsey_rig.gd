@tool
extends Node3D

const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const HorseAnimUtils := preload("res://characters/animals/horse_anim_utils.gd")
const HorseAnimConfig := preload("res://characters/animals/horse_anim_config.gd")


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_prepare_for_editing")


func _ready() -> void:
	HorseModelConfig.apply_rigged_textures(self)


func _prepare_for_editing() -> void:
	var player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		return
	if not player.has_animation_library(HorseAnimConfig.LIBRARY):
		HorseAnimUtils.ensure_library(player)
		return
	var library: AnimationLibrary = player.get_animation_library(HorseAnimConfig.LIBRARY)
	if HorseAnimUtils.library_needs_localization(library):
		player.remove_animation_library(HorseAnimConfig.LIBRARY)
		player.add_animation_library(
			HorseAnimConfig.LIBRARY,
			HorseAnimUtils.localize_library_for_editing(library)
		)
		library = player.get_animation_library(HorseAnimConfig.LIBRARY)
	HorseAnimUtils.ensure_idle_clip(library)
