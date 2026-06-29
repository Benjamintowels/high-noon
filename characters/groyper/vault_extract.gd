@tool
class_name VaultExtract
extends RefCounted

const VaultConfigScript := preload("res://characters/groyper/vault_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")

## Extract Meshy parkour vault FBX clips into local authored resources.


static func extract_to_res() -> Error:
	var walk_animation := _extract_authored_clip(VaultConfigScript.WALK_VAULT_SCENE)
	if walk_animation == null:
		return ERR_CANT_CREATE

	var run_animation := _extract_authored_clip(VaultConfigScript.RUN_VAULT_SCENE)
	if run_animation == null:
		return ERR_CANT_CREATE

	var run_err := ResourceSaver.save(run_animation, VaultConfigScript.RUN_VAULT_OUT_PATH)
	if run_err != OK:
		push_error(
			"VaultExtract: failed to save %s (error %s)."
			% [VaultConfigScript.RUN_VAULT_OUT_PATH, run_err]
		)
		return run_err

	var saved_run := load(VaultConfigScript.RUN_VAULT_OUT_PATH) as Animation
	if saved_run == null:
		push_error("VaultExtract: failed to reload %s." % VaultConfigScript.RUN_VAULT_OUT_PATH)
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(VaultConfigScript.WALK_VAULT, walk_animation)
	library.add_animation(VaultConfigScript.RUN_VAULT, saved_run)

	var lib_err := ResourceSaver.save(library, VaultConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"VaultExtract: failed to save %s (error %s)."
			% [VaultConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"VaultExtract: saved walk_vault -> %s, run_vault -> %s"
		% [VaultConfigScript.OUT_PATH, VaultConfigScript.RUN_VAULT_OUT_PATH]
	)
	return OK


static func _extract_authored_clip(scene_path: String) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("VaultExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtilsScript.make_authored(animation)


static func load_authored_library() -> AnimationLibrary:
	var library := load(VaultConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error("VaultExtract: missing %s — run extract first." % VaultConfigScript.OUT_PATH)
		return null

	if not library.has_animation(VaultConfigScript.RUN_VAULT):
		var run_animation := load(VaultConfigScript.RUN_VAULT_OUT_PATH) as Animation
		if run_animation != null:
			library.add_animation(VaultConfigScript.RUN_VAULT, run_animation)

	return library
