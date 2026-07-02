extends RefCounted
class_name CombatAnimTransitions

const ATTACK_FADEIN := 0.14
const ATTACK_FADEOUT := 0.18
const PARRY_CLASH_FADEIN := 0.12
const PARRY_CLASH_FADEOUT := 0.20
const ROLL_FADEIN := 0.10
const ROLL_FADEOUT := 0.14
const BLOCK_ENTER_FADEIN := 0.12
const BLOCK_ENTER_FADEOUT := 0.18
const BLOCK_BREAK_FADEIN := 0.10
const BLOCK_BREAK_FADEOUT := 0.18
const BLOCK_HOLD_BLEND_IN := 0.20
const BLOCK_HOLD_BLEND_OUT := 0.16
const CLASH_BLOCK_BLEND_OUT := 0.10


static func configure_one_shot(
	one_shot: AnimationNodeOneShot,
	fadein: float,
	fadeout: float,
	break_loop_at_end: bool = false
) -> void:
	one_shot.fadein_time = fadein
	one_shot.fadeout_time = fadeout
	one_shot.sync = false
	one_shot.break_loop_at_end = break_loop_at_end


static func tween_tree_float(
	host: Node,
	tree: AnimationTree,
	param_path: String,
	target: float,
	duration: float
) -> Tween:
	if host == null or not is_instance_valid(host):
		return null
	if tree == null or not tree.active:
		return null

	var full_path := "parameters/%s" % param_path
	var current := float(tree.get(full_path))
	if is_equal_approx(current, target):
		tree.set(full_path, target)
		return null

	var tween := host.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(value: float) -> void:
			if is_instance_valid(tree) and tree.active:
				tree.set(full_path, value),
		current,
		target,
		duration
	)
	return tween
