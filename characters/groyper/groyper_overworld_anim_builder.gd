extends RefCounted
## Run-once AnimationTree / animation-library construction for the overworld
## player, extracted from groyper_overworld_player.gd. Every function is a
## static helper taking the player instance as `p`; runtime state stays on
## the player.

const VaultExtractScript := preload("res://characters/groyper/vault_extract.gd")
const LassoSwingExtractScript := preload("res://characters/groyper/lasso_swing_extract.gd")
const ClimbFallExtractScript := preload("res://characters/groyper/climb_fall_extract.gd")
const LadderClimbExtractScript := preload("res://characters/groyper/ladder_climb_extract.gd")
const PunchPoseExtractScript := preload("res://characters/groyper/punch_pose_extract.gd")
const FlyingKickExtractScript := preload("res://characters/groyper/flying_kick_extract.gd")
const UnarmedBlockPoseExtractScript := preload(
	"res://characters/groyper/unarmed_block_pose_extract.gd"
)
const BaldwinAnimUtilsScript := preload("res://characters/baldwin/baldwin_anim_utils.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const LOCOMOTION_IDLE_NODE := &"LocomotionIdle"
const ROLL_ANIM_NODE := &"RollAnim"
const VAULT_ANIM_NODE := &"VaultAnim"
const CROUCH_COVER_ANIM_NODE := &"CrouchCoverAnim"
const COVER_PEEK_AIM_ANIM_NODE := &"CoverPeekAimAnim"
const SADDLE_BLEND := &"SaddleBlend"
const SADDLE_ANIM_NODE := &"SaddleAnim"
const PUNCH_ANIM_NODE := &"PunchAnim"


static func _setup_locomotion_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	if p._animation_tree.active:
		p._animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(p, library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(p, library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(p, library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)
	_add_reversed_walk_clip(p, library)

	if p._animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		p._animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	p._animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)


static func _add_locomotion_clip(
	p,
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


static func _add_reversed_walk_clip(p, library: AnimationLibrary) -> void:
	var walk := library.get_animation(RigAnimConfig.LOCOMOTION_WALK)
	if walk == null:
		push_error("GroyperOverworldPlayer: missing walk clip for walk_reverse.")
		return

	var reversed := RigAnimUtils.make_reversed_animation(walk)
	reversed.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(RigAnimConfig.LOCOMOTION_WALK_REVERSE, reversed)


static func _setup_melee_library(p) -> void:
	if p._animation_player == null:
		return

	var library := AnimationLibrary.new()
	_add_melee_clip(p, library, p.GroyperMeleeAnimConfig.CLIP_COMBAT_IDLE, p.GroyperMeleeAnimConfig.COMBAT_IDLE_SCENE, Animation.LOOP_LINEAR)
	_add_melee_clip(p, library, p.GroyperMeleeAnimConfig.CLIP_SWORD_SLASH, p.GroyperMeleeAnimConfig.SWORD_SLASH_SCENE, Animation.LOOP_NONE)
	var slash := library.get_animation(p.GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
	if slash != null:
		var slash_reverse := RigAnimUtils.make_reversed_animation(slash)
		slash_reverse.loop_mode = Animation.LOOP_NONE
		library.add_animation(p.GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE, slash_reverse)
	p._attack_reverse_anim_name = p.GroyperMeleeAnimConfig.clip_path(
		p.GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE
	)
	_add_melee_clip(p,
		library,
		p.GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK,
		p.GroyperMeleeAnimConfig.SPIN_ATTACK_SCENE,
		Animation.LOOP_NONE
	)
	var spin := library.get_animation(p.GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK)
	if spin != null:
		var spin_reverse := RigAnimUtils.make_reversed_animation(spin)
		spin_reverse.loop_mode = Animation.LOOP_NONE
		library.add_animation(p.GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE, spin_reverse)
	p._spin_attack_anim_name = p.GroyperMeleeAnimConfig.clip_path(
		p.GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK
	)
	p._spin_attack_reverse_anim_name = p.GroyperMeleeAnimConfig.clip_path(
		p.GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE
	)
	_add_melee_clip(p, library, p.GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD, p.GroyperMeleeAnimConfig.BLOCK_HOLD_SCENE, Animation.LOOP_LINEAR)
	_add_melee_clip(p, library, p.GroyperMeleeAnimConfig.CLIP_BLOCK_CLASH, p.GroyperMeleeAnimConfig.BLOCK_CLASH_SCENE, Animation.LOOP_NONE)
	_add_melee_clip(p, library, p.GroyperMeleeAnimConfig.CLIP_BLOCK_BREAK, p.GroyperMeleeAnimConfig.BLOCK_BREAK_SCENE, Animation.LOOP_NONE)
	_add_melee_clip(p,
		library,
		p.GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD,
		p.GroyperMeleeAnimConfig.BLOCK_WALK_BACKWARD_SCENE,
		Animation.LOOP_LINEAR
	)

	if p._animation_player.has_animation_library(p.GroyperMeleeAnimConfig.LIBRARY):
		p._animation_player.remove_animation_library(p.GroyperMeleeAnimConfig.LIBRARY)
	p._animation_player.add_animation_library(p.GroyperMeleeAnimConfig.LIBRARY, library)

	var block_walk_back := library.get_animation(p.GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD)
	if block_walk_back != null:
		var block_walk_forward := RigAnimUtils.make_reversed_animation(block_walk_back)
		block_walk_forward.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(p.GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_FORWARD, block_walk_forward)

	p._block_walk_backward_path = p.GroyperMeleeAnimConfig.clip_path(
		p.GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD
	)
	p._block_walk_forward_path = p.GroyperMeleeAnimConfig.clip_path(
		p.GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_FORWARD
	)


static func _add_melee_clip(
	p,
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load melee clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


static func _setup_weapon_throw_library(p) -> void:
	if p._animation_player == null:
		return
	var library := AnimationLibrary.new()
	var raw := RigAnimUtils.load_skeleton_animation(p.WeaponThrowConfigScript.PITCH_SCENE)
	if raw == null:
		push_warning(
			"GroyperOverworldPlayer: missing baseball pitch clip at %s."
			% p.WeaponThrowConfigScript.PITCH_SCENE
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	p.WeaponThrowConfigScript.apply_hips_yaw(
		animation,
		p.WeaponThrowConfigScript.PITCH_YAW_CORRECTION_DEG
	)
	animation.loop_mode = Animation.LOOP_NONE
	library.add_animation(p.WeaponThrowConfigScript.CLIP_PITCH, animation)

	if p._animation_player.has_animation_library(p.WeaponThrowConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.WeaponThrowConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.WeaponThrowConfigScript.LIBRARY_NAME, library)


static func _setup_roll_dodge_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := RollDodgeExtract.load_authored_library()
	if source == null:
		push_error("GroyperOverworldPlayer: missing roll_dodge.tres â€” run RollDodgeExtract.")
		return

	if p._animation_player.has_animation_library(RollDodgeConfig.LIBRARY_NAME):
		p._animation_player.remove_animation_library(RollDodgeConfig.LIBRARY_NAME)
	p._animation_player.add_animation_library(RollDodgeConfig.LIBRARY_NAME, source.duplicate(true))


static func _setup_punch_pose_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := PunchPoseExtractScript.load_authored_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing punch_pose.tres â€” "
			+ "author in groyper_body.tscn or run PunchPoseExtract."
		)
		return

	if p._animation_player.has_animation_library(p.PunchPoseConfig.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.PunchPoseConfig.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.PunchPoseConfig.LIBRARY_NAME, source.duplicate(true))


static func _setup_flying_kick_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := FlyingKickExtractScript.load_authored_library()
	if source == null:
		push_warning(
			"GroyperOverworldPlayer: missing flying_kick.tres — run FlyingKickExtract."
		)
		return

	if p._animation_player.has_animation_library(p.FlyingKickConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.FlyingKickConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(
		p.FlyingKickConfigScript.LIBRARY_NAME,
		source.duplicate(true)
	)


static func _setup_unarmed_block_pose_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := UnarmedBlockPoseExtractScript.load_authored_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing unarmed_block_pose.tres — "
			+ "author in groyper_body.tscn or run UnarmedBlockPoseExtract."
		)
		return

	if p._animation_player.has_animation_library(p.UnarmedBlockPoseConfig.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.UnarmedBlockPoseConfig.LIBRARY_NAME)
	p._animation_player.add_animation_library(
		p.UnarmedBlockPoseConfig.LIBRARY_NAME,
		source.duplicate(true)
	)


static func _setup_vault_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := VaultExtractScript.load_authored_library()
	if source == null:
		push_error("GroyperOverworldPlayer: missing vault.tres â€” run VaultExtract.")
		return

	if p._animation_player.has_animation_library(p.VaultConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.VaultConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.VaultConfigScript.LIBRARY_NAME, source.duplicate(true))


static func _setup_lasso_swing_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := LassoSwingExtractScript.load_authored_library()
	if source == null:
		push_warning(
			"GroyperOverworldPlayer: missing lasso_swing.tres â€” run LassoSwingExtract."
		)
		return

	if p._animation_player.has_animation_library(p.LassoSwingConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.LassoSwingConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.LassoSwingConfigScript.LIBRARY_NAME, source.duplicate(true))


static func _setup_climb_fall_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := ClimbFallExtractScript.load_authored_library()
	if source == null:
		push_warning(
			"GroyperOverworldPlayer: missing climb_fall.tres — run ClimbFallExtract."
		)
		return

	if p._animation_player.has_animation_library(p.ClimbFallConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.ClimbFallConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.ClimbFallConfigScript.LIBRARY_NAME, source.duplicate(true))


static func _setup_ladder_climb_library(p) -> void:
	if p._animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := LadderClimbExtractScript.load_authored_library()
	if source == null:
		push_warning(
			"GroyperOverworldPlayer: missing ladder_climb.tres — run LadderClimbExtract."
		)
		return

	if p._animation_player.has_animation_library(p.LadderClimbConfigScript.LIBRARY_NAME):
		p._animation_player.remove_animation_library(p.LadderClimbConfigScript.LIBRARY_NAME)
	p._animation_player.add_animation_library(p.LadderClimbConfigScript.LIBRARY_NAME, source.duplicate(true))


static func _setup_animation_tree(p) -> void:
	if p._animation_player == null:
		return

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)
	var walk_reverse_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK_REVERSE]
	)

	if (
		not p._animation_player.has_animation(idle_path)
		or not p._animation_player.has_animation(walk_path)
		or not p._animation_player.has_animation(run_path)
		or not p._animation_player.has_animation(walk_reverse_path)
	):
		push_error("GroyperOverworldPlayer: locomotion clips missing on AnimationPlayer.")
		return

	var walk_roll_path := StringName(
		"%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]
	)
	if not p._animation_player.has_animation(walk_roll_path):
		push_error("GroyperOverworldPlayer: roll dodge clips missing on AnimationPlayer.")
		return

	var walk_vault_path := StringName(
		"%s/%s" % [p.VaultConfigScript.LIBRARY_NAME, p.VaultConfigScript.WALK_VAULT]
	)
	if not p._animation_player.has_animation(walk_vault_path):
		push_error("GroyperOverworldPlayer: vault clips missing on AnimationPlayer.")
		return

	var crouch_cover_path := CoverPoseConfig.get_crouch_cover_path()
	if not p._animation_player.has_animation(crouch_cover_path):
		push_error("GroyperOverworldPlayer: cover pose clips missing on AnimationPlayer.")
		return

	var cover_peek_aim_path := CoverPoseConfig.get_cover_peek_aim_path()
	if not p._animation_player.has_animation(cover_peek_aim_path):
		push_error("GroyperOverworldPlayer: cover_peek_aim missing on AnimationPlayer.")
		return

	var saddle_path = p.SaddlePoseConfig.get_animation_path()
	if not p._animation_player.has_animation(saddle_path):
		push_warning(
			"GroyperOverworldPlayer: missing %s â€” author in groyper_body.tscn."
			% saddle_path
		)

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	p._idle_anim_node = idle_node
	p._peaceful_idle_path = idle_path
	p._combat_idle_path = p.GroyperMeleeAnimConfig.clip_path(p.GroyperMeleeAnimConfig.CLIP_COMBAT_IDLE)

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	p._walk_anim_node = walk_node

	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var walk_reverse_node := AnimationNodeAnimation.new()
	walk_reverse_node.animation = walk_reverse_path
	p._walk_reverse_anim_node = walk_reverse_node

	var walk_blend_space := AnimationNodeBlendSpace1D.new()
	walk_blend_space.add_blend_point(walk_reverse_node, p.WALK_DIR_BACK_BLEND)
	walk_blend_space.add_blend_point(walk_node, p.WALK_DIR_WALK_BLEND)
	walk_blend_space.add_blend_point(run_node, p.WALK_DIR_RUN_BLEND)
	walk_blend_space.min_space = p.WALK_DIR_BACK_BLEND
	walk_blend_space.max_space = p.WALK_DIR_RUN_BLEND
	walk_blend_space.sync = true
	walk_blend_space.snap = 0.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true

	var move_locomotion_node: StringName = p.WALK_LOCOMOTION_BLEND
	var block_walk_blend_space: AnimationNodeBlendSpace1D = null
	var block_walk_layer_blend: AnimationNodeBlend2 = null
	p._melee_block_walk_nodes_ready = false
	if (
		p._animation_player.has_animation(p._block_walk_backward_path)
		and p._animation_player.has_animation(p._block_walk_forward_path)
	):
		p._melee_block_walk_nodes_ready = true

		var block_walk_reverse_node := AnimationNodeAnimation.new()
		block_walk_reverse_node.animation = p._block_walk_backward_path

		var block_walk_forward_node := AnimationNodeAnimation.new()
		block_walk_forward_node.animation = p._block_walk_forward_path

		block_walk_blend_space = AnimationNodeBlendSpace1D.new()
		block_walk_blend_space.add_blend_point(block_walk_reverse_node, p.WALK_DIR_BACK_BLEND)
		block_walk_blend_space.add_blend_point(block_walk_forward_node, p.WALK_DIR_WALK_BLEND)
		block_walk_blend_space.min_space = p.WALK_DIR_BACK_BLEND
		block_walk_blend_space.max_space = p.WALK_DIR_WALK_BLEND
		block_walk_blend_space.sync = true
		block_walk_blend_space.snap = 0.0

		block_walk_layer_blend = AnimationNodeBlend2.new()
		block_walk_layer_blend.sync = true
		move_locomotion_node = p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND

	var idle_locomotion_node: StringName = LOCOMOTION_IDLE_NODE
	var combat_idle_anim_node: AnimationNodeAnimation = null
	var combat_idle_layer_blend: AnimationNodeBlend2 = null
	p._melee_combat_idle_nodes_ready = false
	if p._animation_player.has_animation(p._combat_idle_path):
		p._melee_combat_idle_nodes_ready = true

		combat_idle_anim_node = AnimationNodeAnimation.new()
		combat_idle_anim_node.animation = p._combat_idle_path
		var combat_idle_res = p._animation_player.get_animation(p._combat_idle_path)
		if combat_idle_res != null:
			combat_idle_res.loop_mode = Animation.LOOP_LINEAR

		combat_idle_layer_blend = AnimationNodeBlend2.new()
		combat_idle_layer_blend.sync = true
		idle_locomotion_node = p.GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND

	p._roll_anim_node = AnimationNodeAnimation.new()
	p._roll_anim_node.animation = walk_roll_path

	var roll_one_shot := AnimationNodeOneShot.new()
	roll_one_shot.fadein_time = p.ROLL_ANIM_FADEIN
	roll_one_shot.fadeout_time = p.ROLL_ANIM_FADEOUT
	roll_one_shot.sync = true

	var punch_path = p.PunchPoseConfig.get_animation_path()
	var punch_has_clip := false
	if p._animation_player.has_animation(punch_path):
		p._punch_anim_node = AnimationNodeAnimation.new()
		p._punch_anim_node.animation = punch_path
		punch_has_clip = true
	else:
		push_warning("GroyperOverworldPlayer: missing punch pose â€” author in groyper_body.tscn.")

	var punch_time_seek := AnimationNodeTimeSeek.new()
	p._punch_blend_node = AnimationNodeBlend2.new()
	p._punch_blend_node.sync = false
	if punch_has_clip:
		p.UnarmedBlockPoseConfig.configure_block_blend_filter(p._punch_blend_node)

	p._vault_anim_node = AnimationNodeAnimation.new()
	p._vault_anim_node.animation = walk_vault_path

	var vault_time_seek := AnimationNodeTimeSeek.new()
	var vault_time_scale := AnimationNodeTimeScale.new()

	p._vault_blend_node = AnimationNodeBlend2.new()
	p._vault_blend_node.sync = false

	var lasso_swing_has_clips = (
		p._animation_player.has_animation(p.LassoSwingConfigScript.get_swing_path())
		and p._animation_player.has_animation(p.LassoSwingConfigScript.get_fall_path())
		and p._animation_player.has_animation(p.LassoSwingConfigScript.get_land_path())
	)
	p._lasso_swing_nodes_ready = lasso_swing_has_clips
	if not lasso_swing_has_clips:
		push_warning(
			"GroyperOverworldPlayer: missing lasso swing clips â€” run LassoSwingExtract."
		)

	var climb_fall_has_clips = (
		p._animation_player.has_animation(p.ClimbFallConfigScript.get_fall_entry_path())
		and p._animation_player.has_animation(p.ClimbFallConfigScript.get_fall_loop_path())
		and p._animation_player.has_animation(p.ClimbFallConfigScript.get_fall_land_path())
	)
	p._climb_fall_nodes_ready = climb_fall_has_clips
	if not climb_fall_has_clips:
		push_warning(
			"GroyperOverworldPlayer: missing climb fall clips — run ClimbFallExtract."
		)

	var ladder_climb_has_clips = (
		p._animation_player.has_animation(p.LadderClimbConfigScript.get_climb_loop_path())
		and p._animation_player.has_animation(p.LadderClimbConfigScript.get_climb_finish_path())
	)
	p._ladder_climb_nodes_ready = ladder_climb_has_clips
	if not ladder_climb_has_clips:
		push_warning(
			"GroyperOverworldPlayer: missing ladder climb clips — run LadderClimbExtract."
		)

	var crouch_cover_anim := AnimationNodeAnimation.new()
	crouch_cover_anim.animation = crouch_cover_path

	p._cover_pose_blend_node = AnimationNodeBlend2.new()
	p._cover_pose_blend_node.sync = false
	CoverPoseConfig.configure_cover_pose_blend(p._cover_pose_blend_node)

	var cover_peek_aim_anim := AnimationNodeAnimation.new()
	cover_peek_aim_anim.animation = cover_peek_aim_path

	p._cover_peek_blend_node = AnimationNodeBlend2.new()
	p._cover_peek_blend_node.sync = false
	CoverPoseConfig.configure_cover_peek_blend(p._cover_peek_blend_node)

	var saddle_anim := AnimationNodeAnimation.new()
	saddle_anim.animation = saddle_path

	p._saddle_blend_node = AnimationNodeBlend2.new()
	p._saddle_blend_node.sync = false
	p.SaddlePoseConfig.configure_saddle_blend_filter(p._saddle_blend_node)

	var bonfire_has_clips = (
		p._animation_player.has_animation(p.BonfirePoseConfig.get_stand_up3_path())
		and p._animation_player.has_animation(p.BonfirePoseConfig.get_stand_up3_reverse_path())
		and p._animation_player.has_animation(p.BonfirePoseConfig.get_sit_cross_path())
	)
	if not bonfire_has_clips:
		push_warning(
			"GroyperOverworldPlayer: missing bonfire pose clips â€” check Stand Up3 / Sit Cross Legged imports."
		)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_IDLE_NODE, idle_node)
	if combat_idle_anim_node != null and combat_idle_layer_blend != null:
		blend_tree.add_node(p.GroyperMeleeAnimConfig.COMBAT_IDLE_ANIM, combat_idle_anim_node)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND, combat_idle_layer_blend)
		blend_tree.connect_node(p.GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND, 0, LOCOMOTION_IDLE_NODE)
		blend_tree.connect_node(
			p.GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND,
			1,
			p.GroyperMeleeAnimConfig.COMBAT_IDLE_ANIM
		)
	blend_tree.add_node(p.WALK_LOCOMOTION_BLEND, walk_blend_space)
	if block_walk_blend_space != null and block_walk_layer_blend != null:
		blend_tree.add_node(p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_SPACE, block_walk_blend_space)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND, block_walk_layer_blend)
		blend_tree.connect_node(
			p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			0,
			p.WALK_LOCOMOTION_BLEND
		)
		blend_tree.connect_node(
			p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			1,
			p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_SPACE
		)
	blend_tree.add_node(p.LOCOMOTION_BLEND, move_blend)
	blend_tree.connect_node(p.LOCOMOTION_BLEND, 0, idle_locomotion_node)
	blend_tree.connect_node(p.LOCOMOTION_BLEND, 1, move_locomotion_node)
	blend_tree.add_node(ROLL_ANIM_NODE, p._roll_anim_node)
	blend_tree.add_node(p.ROLL_ONE_SHOT, roll_one_shot)
	if punch_has_clip:
		blend_tree.add_node(PUNCH_ANIM_NODE, p._punch_anim_node)
		blend_tree.add_node(p.PunchPoseConfig.TIME_SEEK_NODE, punch_time_seek)
		blend_tree.add_node(p.PunchPoseConfig.BLEND_NODE, p._punch_blend_node)
	blend_tree.add_node(VAULT_ANIM_NODE, p._vault_anim_node)
	blend_tree.add_node(p.VAULT_TIME_SEEK, vault_time_seek)
	blend_tree.add_node(p.VAULT_TIME_SCALE, vault_time_scale)
	blend_tree.add_node(p.VAULT_BLEND, p._vault_blend_node)
	if climb_fall_has_clips:
		var fall_entry_anim := AnimationNodeAnimation.new()
		fall_entry_anim.animation = p.ClimbFallConfigScript.get_fall_entry_path()
		var fall_entry_seek := AnimationNodeTimeSeek.new()

		var fall_loop_anim := AnimationNodeAnimation.new()
		fall_loop_anim.animation = p.ClimbFallConfigScript.get_fall_loop_path()
		var fall_loop_seek := AnimationNodeTimeSeek.new()

		var fall_land_anim := AnimationNodeAnimation.new()
		fall_land_anim.animation = p.ClimbFallConfigScript.get_fall_land_path()
		var fall_land_seek := AnimationNodeTimeSeek.new()

		p._climb_fall_blend_node = AnimationNodeBlend2.new()
		p._climb_fall_blend_node.sync = false
		p._climb_fall_pose_blend_node = AnimationNodeBlend2.new()
		p._climb_fall_pose_blend_node.sync = false
		p._climb_fall_land_blend_node = AnimationNodeBlend2.new()
		p._climb_fall_land_blend_node.sync = false

		blend_tree.add_node(p.ClimbFallConfigScript.FALL_ENTRY_ANIM_NODE, fall_entry_anim)
		blend_tree.add_node(p.ClimbFallConfigScript.FALL_ENTRY_TIME_SEEK, fall_entry_seek)
		blend_tree.add_node(p.ClimbFallConfigScript.FALL_LOOP_ANIM_NODE, fall_loop_anim)
		blend_tree.add_node(p.ClimbFallConfigScript.FALL_LOOP_TIME_SEEK, fall_loop_seek)
		blend_tree.add_node(p.ClimbFallConfigScript.FALL_LAND_ANIM_NODE, fall_land_anim)
		blend_tree.add_node(p.ClimbFallConfigScript.FALL_LAND_TIME_SEEK, fall_land_seek)
		blend_tree.add_node(p.ClimbFallConfigScript.POSE_BLEND_NODE, p._climb_fall_pose_blend_node)
		blend_tree.add_node(p.ClimbFallConfigScript.LAND_BLEND_NODE, p._climb_fall_land_blend_node)
		blend_tree.add_node(p.ClimbFallConfigScript.BLEND_NODE, p._climb_fall_blend_node)
	if ladder_climb_has_clips:
		var ladder_climb_anim := AnimationNodeAnimation.new()
		ladder_climb_anim.animation = p.LadderClimbConfigScript.get_climb_loop_path()
		var ladder_climb_seek := AnimationNodeTimeSeek.new()
		var ladder_climb_scale := AnimationNodeTimeScale.new()

		var ladder_finish_anim := AnimationNodeAnimation.new()
		ladder_finish_anim.animation = p.LadderClimbConfigScript.get_climb_finish_path()
		var ladder_finish_seek := AnimationNodeTimeSeek.new()
		var ladder_finish_scale := AnimationNodeTimeScale.new()

		p._ladder_blend_node = AnimationNodeBlend2.new()
		p._ladder_blend_node.sync = false
		p._ladder_finish_blend_node = AnimationNodeBlend2.new()
		p._ladder_finish_blend_node.sync = false

		blend_tree.add_node(p.LadderClimbConfigScript.CLIMB_ANIM_NODE, ladder_climb_anim)
		blend_tree.add_node(p.LadderClimbConfigScript.CLIMB_TIME_SCALE, ladder_climb_scale)
		blend_tree.add_node(p.LadderClimbConfigScript.CLIMB_TIME_SEEK, ladder_climb_seek)
		blend_tree.add_node(p.LadderClimbConfigScript.FINISH_ANIM_NODE, ladder_finish_anim)
		blend_tree.add_node(p.LadderClimbConfigScript.FINISH_TIME_SCALE, ladder_finish_scale)
		blend_tree.add_node(p.LadderClimbConfigScript.FINISH_TIME_SEEK, ladder_finish_seek)
		blend_tree.add_node(p.LadderClimbConfigScript.FINISH_BLEND_NODE, p._ladder_finish_blend_node)
		blend_tree.add_node(p.LadderClimbConfigScript.BLEND_NODE, p._ladder_blend_node)
	if lasso_swing_has_clips:
		var swing_anim := AnimationNodeAnimation.new()
		swing_anim.animation = p.LassoSwingConfigScript.get_swing_path()
		var swing_seek := AnimationNodeTimeSeek.new()
		var swing_scale := AnimationNodeTimeScale.new()

		var fall_anim := AnimationNodeAnimation.new()
		fall_anim.animation = p.LassoSwingConfigScript.get_fall_path()
		var fall_seek := AnimationNodeTimeSeek.new()

		var land_anim := AnimationNodeAnimation.new()
		land_anim.animation = p.LassoSwingConfigScript.get_land_path()
		var land_seek := AnimationNodeTimeSeek.new()
		var land_scale := AnimationNodeTimeScale.new()

		p._lasso_swing_blend_node = AnimationNodeBlend2.new()
		p._lasso_swing_blend_node.sync = false
		p._lasso_swing_pose_blend_node = AnimationNodeBlend2.new()
		p._lasso_swing_pose_blend_node.sync = false
		p._lasso_swing_land_blend_node = AnimationNodeBlend2.new()
		p._lasso_swing_land_blend_node.sync = false

		blend_tree.add_node(p.LassoSwingConfigScript.SWING_ANIM_NODE, swing_anim)
		blend_tree.add_node(p.LassoSwingConfigScript.SWING_TIME_SCALE, swing_scale)
		blend_tree.add_node(p.LassoSwingConfigScript.SWING_TIME_SEEK, swing_seek)
		blend_tree.add_node(p.LassoSwingConfigScript.FALL_ANIM_NODE, fall_anim)
		blend_tree.add_node(p.LassoSwingConfigScript.FALL_TIME_SEEK, fall_seek)
		blend_tree.add_node(p.LassoSwingConfigScript.LAND_ANIM_NODE, land_anim)
		blend_tree.add_node(p.LassoSwingConfigScript.LAND_TIME_SCALE, land_scale)
		blend_tree.add_node(p.LassoSwingConfigScript.LAND_TIME_SEEK, land_seek)
		blend_tree.add_node(p.LassoSwingConfigScript.POSE_BLEND_NODE, p._lasso_swing_pose_blend_node)
		blend_tree.add_node(p.LassoSwingConfigScript.LAND_BLEND_NODE, p._lasso_swing_land_blend_node)
		blend_tree.add_node(p.LassoSwingConfigScript.BLEND_NODE, p._lasso_swing_blend_node)
	blend_tree.add_node(CROUCH_COVER_ANIM_NODE, crouch_cover_anim)
	blend_tree.add_node(p.COVER_POSE_BLEND, p._cover_pose_blend_node)
	blend_tree.add_node(COVER_PEEK_AIM_ANIM_NODE, cover_peek_aim_anim)
	blend_tree.add_node(p.COVER_PEEK_BLEND, p._cover_peek_blend_node)
	blend_tree.add_node(SADDLE_ANIM_NODE, saddle_anim)
	blend_tree.add_node(SADDLE_BLEND, p._saddle_blend_node)
	if bonfire_has_clips:
		p._bonfire_stand_anim_node = AnimationNodeAnimation.new()
		p._bonfire_stand_anim_node.animation = p.BonfirePoseConfig.get_stand_up3_reverse_path()

		var bonfire_stand_seek := AnimationNodeTimeSeek.new()

		var sit_cross_anim := AnimationNodeAnimation.new()
		sit_cross_anim.animation = p.BonfirePoseConfig.get_sit_cross_path()
		p._bonfire_sit_anim_node = sit_cross_anim

		p._bonfire_pose_blend_node = AnimationNodeBlend2.new()
		p._bonfire_pose_blend_node.sync = false

		p._bonfire_blend_node = AnimationNodeBlend2.new()
		p._bonfire_blend_node.sync = false

		blend_tree.add_node(p.BonfirePoseConfig.STAND_ANIM_NODE, p._bonfire_stand_anim_node)
		blend_tree.add_node(p.BonfirePoseConfig.STAND_TIME_SEEK, bonfire_stand_seek)
		blend_tree.add_node(p.BonfirePoseConfig.SIT_ANIM_NODE, sit_cross_anim)
		blend_tree.add_node(p.BonfirePoseConfig.BONFIRE_POSE_BLEND, p._bonfire_pose_blend_node)
		blend_tree.add_node(p.BonfirePoseConfig.BONFIRE_BLEND, p._bonfire_blend_node)
	blend_tree.connect_node(p.ROLL_ONE_SHOT, 0, p.LOCOMOTION_BLEND)
	blend_tree.connect_node(p.ROLL_ONE_SHOT, 1, ROLL_ANIM_NODE)
	# PunchBlend is wired AFTER melee combat overlays (block hold / clash /
	# break). Those Sword_Parry layers used to sit above the punch and steal
	# the swing whenever a blocked contact left any leftover blend/one-shot.
	if punch_has_clip:
		blend_tree.connect_node(p.PunchPoseConfig.TIME_SEEK_NODE, 0, PUNCH_ANIM_NODE)
	blend_tree.connect_node(p.VAULT_BLEND, 0, p.ROLL_ONE_SHOT)
	blend_tree.connect_node(p.VAULT_TIME_SEEK, 0, p.VAULT_TIME_SCALE)
	blend_tree.connect_node(p.VAULT_TIME_SCALE, 0, VAULT_ANIM_NODE)
	blend_tree.connect_node(p.VAULT_BLEND, 1, p.VAULT_TIME_SEEK)
	var locomotion_overlay_input: StringName = p.VAULT_BLEND
	var flying_kick_path = p.FlyingKickConfigScript.get_animation_path()
	p._flying_kick_nodes_ready = p._animation_player.has_animation(flying_kick_path)
	if p._flying_kick_nodes_ready:
		var flying_kick_anim := AnimationNodeAnimation.new()
		flying_kick_anim.animation = flying_kick_path
		var flying_kick_seek := AnimationNodeTimeSeek.new()
		var flying_kick_scale := AnimationNodeTimeScale.new()
		p._flying_kick_blend_node = AnimationNodeBlend2.new()
		p._flying_kick_blend_node.sync = false
		blend_tree.add_node(p.FlyingKickConfigScript.ANIM_NODE, flying_kick_anim)
		blend_tree.add_node(p.FlyingKickConfigScript.TIME_SCALE_NODE, flying_kick_scale)
		blend_tree.add_node(p.FlyingKickConfigScript.TIME_SEEK_NODE, flying_kick_seek)
		blend_tree.add_node(p.FlyingKickConfigScript.BLEND_NODE, p._flying_kick_blend_node)
		blend_tree.connect_node(
			p.FlyingKickConfigScript.TIME_SCALE_NODE,
			0,
			p.FlyingKickConfigScript.ANIM_NODE
		)
		blend_tree.connect_node(
			p.FlyingKickConfigScript.TIME_SEEK_NODE,
			0,
			p.FlyingKickConfigScript.TIME_SCALE_NODE
		)
		blend_tree.connect_node(
			p.FlyingKickConfigScript.BLEND_NODE,
			0,
			locomotion_overlay_input
		)
		blend_tree.connect_node(
			p.FlyingKickConfigScript.BLEND_NODE,
			1,
			p.FlyingKickConfigScript.TIME_SEEK_NODE
		)
		locomotion_overlay_input = p.FlyingKickConfigScript.BLEND_NODE
	else:
		push_warning(
			"GroyperOverworldPlayer: missing flying kick clip — run FlyingKickExtract."
		)
	var weapon_throw_path = p.WeaponThrowConfigScript.get_animation_path()
	p._weapon_throw_nodes_ready = p._animation_player.has_animation(weapon_throw_path)
	if p._weapon_throw_nodes_ready:
		var throw_anim := AnimationNodeAnimation.new()
		throw_anim.animation = weapon_throw_path
		var throw_seek := AnimationNodeTimeSeek.new()
		var throw_scale := AnimationNodeTimeScale.new()
		var throw_blend := AnimationNodeBlend2.new()
		throw_blend.sync = false
		blend_tree.add_node(p.WeaponThrowConfigScript.ANIM_NODE, throw_anim)
		blend_tree.add_node(p.WeaponThrowConfigScript.TIME_SCALE_NODE, throw_scale)
		blend_tree.add_node(p.WeaponThrowConfigScript.TIME_SEEK_NODE, throw_seek)
		blend_tree.add_node(p.WeaponThrowConfigScript.BLEND_NODE, throw_blend)
		blend_tree.connect_node(
			p.WeaponThrowConfigScript.TIME_SCALE_NODE,
			0,
			p.WeaponThrowConfigScript.ANIM_NODE
		)
		blend_tree.connect_node(
			p.WeaponThrowConfigScript.TIME_SEEK_NODE,
			0,
			p.WeaponThrowConfigScript.TIME_SCALE_NODE
		)
		blend_tree.connect_node(
			p.WeaponThrowConfigScript.BLEND_NODE,
			0,
			locomotion_overlay_input
		)
		blend_tree.connect_node(
			p.WeaponThrowConfigScript.BLEND_NODE,
			1,
			p.WeaponThrowConfigScript.TIME_SEEK_NODE
		)
		locomotion_overlay_input = p.WeaponThrowConfigScript.BLEND_NODE
	if climb_fall_has_clips:
		blend_tree.connect_node(
			p.ClimbFallConfigScript.FALL_ENTRY_TIME_SEEK,
			0,
			p.ClimbFallConfigScript.FALL_ENTRY_ANIM_NODE
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.FALL_LOOP_TIME_SEEK,
			0,
			p.ClimbFallConfigScript.FALL_LOOP_ANIM_NODE
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.FALL_LAND_TIME_SEEK,
			0,
			p.ClimbFallConfigScript.FALL_LAND_ANIM_NODE
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.POSE_BLEND_NODE,
			0,
			p.ClimbFallConfigScript.FALL_ENTRY_TIME_SEEK
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.POSE_BLEND_NODE,
			1,
			p.ClimbFallConfigScript.FALL_LOOP_TIME_SEEK
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.LAND_BLEND_NODE,
			0,
			p.ClimbFallConfigScript.POSE_BLEND_NODE
		)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.LAND_BLEND_NODE,
			1,
			p.ClimbFallConfigScript.FALL_LAND_TIME_SEEK
		)
		blend_tree.connect_node(p.ClimbFallConfigScript.BLEND_NODE, 0, locomotion_overlay_input)
		blend_tree.connect_node(
			p.ClimbFallConfigScript.BLEND_NODE,
			1,
			p.ClimbFallConfigScript.LAND_BLEND_NODE
		)
		locomotion_overlay_input = p.ClimbFallConfigScript.BLEND_NODE
	if ladder_climb_has_clips:
		blend_tree.connect_node(
			p.LadderClimbConfigScript.CLIMB_TIME_SEEK,
			0,
			p.LadderClimbConfigScript.CLIMB_TIME_SCALE
		)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.CLIMB_TIME_SCALE,
			0,
			p.LadderClimbConfigScript.CLIMB_ANIM_NODE
		)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.FINISH_TIME_SEEK,
			0,
			p.LadderClimbConfigScript.FINISH_TIME_SCALE
		)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.FINISH_TIME_SCALE,
			0,
			p.LadderClimbConfigScript.FINISH_ANIM_NODE
		)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.FINISH_BLEND_NODE,
			0,
			p.LadderClimbConfigScript.CLIMB_TIME_SEEK
		)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.FINISH_BLEND_NODE,
			1,
			p.LadderClimbConfigScript.FINISH_TIME_SEEK
		)
		blend_tree.connect_node(p.LadderClimbConfigScript.BLEND_NODE, 0, locomotion_overlay_input)
		blend_tree.connect_node(
			p.LadderClimbConfigScript.BLEND_NODE,
			1,
			p.LadderClimbConfigScript.FINISH_BLEND_NODE
		)
		locomotion_overlay_input = p.LadderClimbConfigScript.BLEND_NODE
	if lasso_swing_has_clips:
		blend_tree.connect_node(p.LassoSwingConfigScript.SWING_TIME_SEEK, 0, p.LassoSwingConfigScript.SWING_TIME_SCALE)
		blend_tree.connect_node(p.LassoSwingConfigScript.SWING_TIME_SCALE, 0, p.LassoSwingConfigScript.SWING_ANIM_NODE)
		blend_tree.connect_node(p.LassoSwingConfigScript.FALL_TIME_SEEK, 0, p.LassoSwingConfigScript.FALL_ANIM_NODE)
		blend_tree.connect_node(p.LassoSwingConfigScript.LAND_TIME_SEEK, 0, p.LassoSwingConfigScript.LAND_TIME_SCALE)
		blend_tree.connect_node(p.LassoSwingConfigScript.LAND_TIME_SCALE, 0, p.LassoSwingConfigScript.LAND_ANIM_NODE)
		blend_tree.connect_node(
			p.LassoSwingConfigScript.POSE_BLEND_NODE,
			0,
			p.LassoSwingConfigScript.SWING_TIME_SEEK
		)
		blend_tree.connect_node(
			p.LassoSwingConfigScript.POSE_BLEND_NODE,
			1,
			p.LassoSwingConfigScript.FALL_TIME_SEEK
		)
		blend_tree.connect_node(
			p.LassoSwingConfigScript.LAND_BLEND_NODE,
			0,
			p.LassoSwingConfigScript.POSE_BLEND_NODE
		)
		blend_tree.connect_node(
			p.LassoSwingConfigScript.LAND_BLEND_NODE,
			1,
			p.LassoSwingConfigScript.LAND_TIME_SEEK
		)
		blend_tree.connect_node(p.LassoSwingConfigScript.BLEND_NODE, 0, locomotion_overlay_input)
		blend_tree.connect_node(
			p.LassoSwingConfigScript.BLEND_NODE,
			1,
			p.LassoSwingConfigScript.LAND_BLEND_NODE
		)
		locomotion_overlay_input = p.LassoSwingConfigScript.BLEND_NODE
	blend_tree.connect_node(p.COVER_POSE_BLEND, 0, locomotion_overlay_input)
	blend_tree.connect_node(p.COVER_POSE_BLEND, 1, CROUCH_COVER_ANIM_NODE)
	blend_tree.connect_node(p.COVER_PEEK_BLEND, 0, p.COVER_POSE_BLEND)
	blend_tree.connect_node(p.COVER_PEEK_BLEND, 1, COVER_PEEK_AIM_ANIM_NODE)
	blend_tree.connect_node(SADDLE_BLEND, 0, p.COVER_PEEK_BLEND)
	blend_tree.connect_node(SADDLE_BLEND, 1, SADDLE_ANIM_NODE)
	if bonfire_has_clips:
		blend_tree.connect_node(p.BonfirePoseConfig.STAND_TIME_SEEK, 0, p.BonfirePoseConfig.STAND_ANIM_NODE)
		blend_tree.connect_node(p.BonfirePoseConfig.BONFIRE_POSE_BLEND, 0, p.BonfirePoseConfig.STAND_TIME_SEEK)
		blend_tree.connect_node(p.BonfirePoseConfig.BONFIRE_POSE_BLEND, 1, p.BonfirePoseConfig.SIT_ANIM_NODE)
		blend_tree.connect_node(p.BonfirePoseConfig.BONFIRE_BLEND, 0, SADDLE_BLEND)
		blend_tree.connect_node(p.BonfirePoseConfig.BONFIRE_BLEND, 1, p.BonfirePoseConfig.BONFIRE_POSE_BLEND)
		var melee_output := _attach_melee_combat_nodes(
			p, blend_tree, p.BonfirePoseConfig.BONFIRE_BLEND
		)
		var punch_output := _attach_punch_overlay_nodes(p, blend_tree, melee_output, punch_has_clip)
		var final_output := _attach_hit_reaction_nodes(p, blend_tree, punch_output)
		blend_tree.connect_node(&"output", 0, final_output)
	else:
		var melee_output := _attach_melee_combat_nodes(p, blend_tree, SADDLE_BLEND)
		var punch_output := _attach_punch_overlay_nodes(p, blend_tree, melee_output, punch_has_clip)
		var final_output := _attach_hit_reaction_nodes(p, blend_tree, punch_output)
		blend_tree.connect_node(&"output", 0, final_output)

	p._animation_tree.tree_root = blend_tree
	p._animation_tree.anim_player = p._animation_tree.get_path_to(p._animation_player)
	p._animation_tree.process_priority = -100
	p._animation_tree.active = true
	p._apply_locomotion_tree_blends()
	if p._melee_combat_nodes_ready:
		p._animation_tree.set(
			"parameters/%s/blend_amount" % p.GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND,
			0.0
		)
	if p._melee_block_walk_nodes_ready:
		p._animation_tree.set(
			"parameters/%s/blend_amount" % p.GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			0.0
		)
	if p._melee_combat_idle_nodes_ready:
		p._animation_tree.set(
			"parameters/%s/blend_amount" % p.GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND,
			0.0
		)
	if p._two_hand_locomotion_nodes_ready:
		p._two_hand_locomotion_blend = 0.0
		p._two_hand_locomotion_pos = 0.0
		p._animation_tree.set("parameters/%s/blend_amount" % p.TWO_HAND_LOCOMOTION_BLEND, 0.0)
		p._animation_tree.set("parameters/%s/blend_position" % p.TWO_HAND_LOCOMOTION_SPACE, 0.0)
	_init_vault_animation_tree_state(p)
	p._init_lasso_swing_animation_tree_state()
	p._init_climb_fall_animation_tree_state()
	p._init_ladder_climb_animation_tree_state()
	p._init_punch_animation_tree_state()
	p._init_flying_kick_animation_tree_state()
	p._init_bonfire_animation_tree_state()
	_init_hit_reaction_animation_tree_state(p)


static func _init_vault_animation_tree_state(p) -> void:
	p._vault_blend = 0.0
	p._vault_for_mount = false
	p._vault_for_dismount = false
	p._mount_vault_yaw_from = 0.0
	p._mount_vault_yaw_to = 0.0
	p._dismount_vault_landing = Vector3.ZERO
	if p._animation_tree == null:
		return
	p._animation_tree.set("parameters/%s/blend_amount" % p.VAULT_BLEND, 0.0)
	p._animation_tree.set("parameters/%s/seek_request" % p.VAULT_TIME_SEEK, -1.0)
	p._set_vault_playback_speed(1.0)


static func _attach_two_hand_locomotion_nodes(
	p,
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName
) -> StringName:
	p._two_hand_locomotion_nodes_ready = false
	var idle_path = p.TwoHandedConfigScript.clip_path(p.TwoHandedConfigScript.CLIP_IDLE)
	var walk_path = p.TwoHandedConfigScript.clip_path(p.TwoHandedConfigScript.CLIP_WALK)
	var sprint_path = p.TwoHandedConfigScript.clip_path(p.TwoHandedConfigScript.CLIP_SPRINT)
	if not (
		p._animation_player.has_animation(idle_path)
		and p._animation_player.has_animation(walk_path)
		and p._animation_player.has_animation(sprint_path)
	):
		push_warning(
			"GroyperOverworldPlayer: missing two_handed locomotion clips — run TwoHandedExtract."
		)
		return input_node

	for clip_path: StringName in [idle_path, walk_path, sprint_path]:
		var res = p._animation_player.get_animation(clip_path)
		if res != null:
			res.loop_mode = Animation.LOOP_LINEAR

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var sprint_node := AnimationNodeAnimation.new()
	sprint_node.animation = sprint_path

	var walk_speed = p.WALK_SPEED * p.TWO_HAND_MOVE_SPEED_MULT
	var run_speed = p.RUN_SPEED * p.TWO_HAND_MOVE_SPEED_MULT
	var space := AnimationNodeBlendSpace1D.new()
	space.add_blend_point(idle_node, 0.0)
	space.add_blend_point(walk_node, walk_speed)
	space.add_blend_point(sprint_node, run_speed)
	space.min_space = 0.0
	space.max_space = run_speed
	space.sync = true
	space.snap = 0.0

	var layer := AnimationNodeBlend2.new()
	layer.sync = true

	blend_tree.add_node(p.TWO_HAND_LOCOMOTION_SPACE, space)
	blend_tree.add_node(p.TWO_HAND_LOCOMOTION_BLEND, layer)
	blend_tree.connect_node(p.TWO_HAND_LOCOMOTION_BLEND, 0, input_node)
	blend_tree.connect_node(p.TWO_HAND_LOCOMOTION_BLEND, 1, p.TWO_HAND_LOCOMOTION_SPACE)
	p._two_hand_locomotion_nodes_ready = true
	return p.TWO_HAND_LOCOMOTION_BLEND


## Punch / unarmed-block share PunchBlend. Place it above melee combat overlays
## so Sword_Parry block-hold/clash/break cannot bury an active punch.
static func _attach_punch_overlay_nodes(
	p,
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName,
	punch_has_clip: bool
) -> StringName:
	if not punch_has_clip or p._punch_blend_node == null:
		return input_node
	blend_tree.connect_node(p.PunchPoseConfig.BLEND_NODE, 0, input_node)
	blend_tree.connect_node(p.PunchPoseConfig.BLEND_NODE, 1, p.PunchPoseConfig.TIME_SEEK_NODE)
	# Runtime proof for headless tests / debug: punch must feed from a melee
	# overlay node (hold/attack/clash/break), not from locomotion.
	p.set_meta(&"punch_blend_input0", String(input_node))
	return p.PunchPoseConfig.BLEND_NODE


static func _attach_melee_combat_nodes(p, blend_tree: AnimationNodeBlendTree, input_node: StringName) -> StringName:
	var block_hold_path = p.GroyperMeleeAnimConfig.clip_path(p.GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)
	var attack_path = p.GroyperMeleeAnimConfig.clip_path(p.GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
	var clash_path = p.GroyperMeleeAnimConfig.clip_path(p.GroyperMeleeAnimConfig.CLIP_BLOCK_CLASH)
	var break_path = p.GroyperMeleeAnimConfig.clip_path(p.GroyperMeleeAnimConfig.CLIP_BLOCK_BREAK)

	if not p._animation_player.has_animation(block_hold_path) or not p._animation_player.has_animation(attack_path):
		p._melee_combat_nodes_ready = false
		return input_node

	p._melee_combat_nodes_ready = true
	p._attack_anim_name = attack_path

	# Two-handed weapons swap the whole locomotion for a dedicated idle/walk/sprint
	# set that blends over the base tree; attacks/block still layer on top.
	var combat_input := _attach_two_hand_locomotion_nodes(p, blend_tree, input_node)

	var block_hold_node := AnimationNodeAnimation.new()
	block_hold_node.animation = block_hold_path
	p._melee_block_hold_anim_node = block_hold_node
	var block_hold_blend := AnimationNodeBlend2.new()
	BaldwinAnimUtilsScript.configure_block_hold_blend(block_hold_blend)

	var attack_node := AnimationNodeAnimation.new()
	attack_node.animation = attack_path
	p._melee_attack_anim_node = attack_node
	var attack_time_seek := AnimationNodeTimeSeek.new()
	var attack_time_scale := AnimationNodeTimeScale.new()
	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	blend_tree.add_node(p.GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, block_hold_blend)
	blend_tree.add_node(p.GroyperMeleeAnimConfig.SHIELD_BLOCK_HOLD_ANIM, block_hold_node)
	blend_tree.add_node(p.GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(p.GroyperMeleeAnimConfig.ATTACK_ANIM, attack_node)
	blend_tree.add_node(p.GroyperMeleeAnimConfig.ATTACK_TIME_SEEK, attack_time_seek)
	blend_tree.add_node(p.GroyperMeleeAnimConfig.ATTACK_TIME_SCALE, attack_time_scale)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, 0, combat_input)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, 1, p.GroyperMeleeAnimConfig.SHIELD_BLOCK_HOLD_ANIM)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, 0, p.GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, 1, p.GroyperMeleeAnimConfig.ATTACK_TIME_SEEK)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.ATTACK_TIME_SEEK, 0, p.GroyperMeleeAnimConfig.ATTACK_TIME_SCALE)
	blend_tree.connect_node(p.GroyperMeleeAnimConfig.ATTACK_TIME_SCALE, 0, p.GroyperMeleeAnimConfig.ATTACK_ANIM)
	p._set_melee_attack_playback_speed(1.0)

	var output_node: StringName = p.GroyperMeleeAnimConfig.ATTACK_ONE_SHOT

	if p._animation_player.has_animation(clash_path):
		p._shield_block_clash_path = clash_path
		var clash_node := AnimationNodeAnimation.new()
		clash_node.animation = clash_path
		p._melee_block_clash_anim_node = clash_node
		var clash_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			clash_shot,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEIN,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEOUT,
			true
		)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT, clash_shot)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.SHIELD_BLOCK_CLASH_ANIM, clash_node)
		blend_tree.connect_node(p.GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(
			p.GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT,
			1,
			p.GroyperMeleeAnimConfig.SHIELD_BLOCK_CLASH_ANIM
		)
		output_node = p.GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT

	if p._animation_player.has_animation(break_path):
		p._shield_block_break_path = break_path
		var break_node := AnimationNodeAnimation.new()
		break_node.animation = break_path
		var break_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			break_shot,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEIN,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEOUT,
			true
		)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT, break_shot)
		blend_tree.add_node(p.GroyperMeleeAnimConfig.SHIELD_BLOCK_BREAK_ANIM, break_node)
		blend_tree.connect_node(p.GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(
			p.GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT,
			1,
			p.GroyperMeleeAnimConfig.SHIELD_BLOCK_BREAK_ANIM
		)
		output_node = p.GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT

	return output_node


static func _attach_hit_reaction_nodes(
	p,
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName
) -> StringName:
	var fall_path = p.GroyperHitReactionConfig.get_falling_down_path()
	var stand_path = p.BonfirePoseConfig.get_stand_up3_path()
	if (
		not p._animation_player.has_animation(fall_path)
		or not p._animation_player.has_animation(stand_path)
	):
		p._hit_reaction_nodes_ready = false
		return input_node

	p._hit_reaction_nodes_ready = true

	var fall_anim := AnimationNodeAnimation.new()
	fall_anim.animation = fall_path
	p._hit_reaction_fall_anim_node = fall_anim

	var fall_seek := AnimationNodeTimeSeek.new()

	var stand_anim := AnimationNodeAnimation.new()
	stand_anim.animation = stand_path
	p._hit_reaction_stand_anim_node = stand_anim

	var stand_seek := AnimationNodeTimeSeek.new()
	var stand_scale := AnimationNodeTimeScale.new()

	var pose_blend := AnimationNodeBlend2.new()
	pose_blend.sync = false
	p._hit_reaction_pose_blend_node = pose_blend

	var reaction_blend := AnimationNodeBlend2.new()
	reaction_blend.sync = false
	p._hit_reaction_blend_node = reaction_blend

	blend_tree.add_node(p.GroyperHitReactionConfig.FALL_ANIM_NODE, fall_anim)
	blend_tree.add_node(p.GroyperHitReactionConfig.FALL_TIME_SEEK, fall_seek)
	blend_tree.add_node(p.GroyperHitReactionConfig.STAND_ANIM_NODE, stand_anim)
	blend_tree.add_node(p.GroyperHitReactionConfig.STAND_TIME_SEEK, stand_seek)
	blend_tree.add_node(p.GroyperHitReactionConfig.STAND_TIME_SCALE, stand_scale)
	blend_tree.add_node(p.GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, pose_blend)
	blend_tree.add_node(p.GroyperHitReactionConfig.HIT_REACTION_BLEND, reaction_blend)

	blend_tree.connect_node(p.GroyperHitReactionConfig.FALL_TIME_SEEK, 0, p.GroyperHitReactionConfig.FALL_ANIM_NODE)
	blend_tree.connect_node(p.GroyperHitReactionConfig.STAND_TIME_SEEK, 0, p.GroyperHitReactionConfig.STAND_TIME_SCALE)
	blend_tree.connect_node(p.GroyperHitReactionConfig.STAND_TIME_SCALE, 0, p.GroyperHitReactionConfig.STAND_ANIM_NODE)
	blend_tree.connect_node(p.GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, 0, p.GroyperHitReactionConfig.FALL_TIME_SEEK)
	blend_tree.connect_node(p.GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, 1, p.GroyperHitReactionConfig.STAND_TIME_SEEK)
	blend_tree.connect_node(p.GroyperHitReactionConfig.HIT_REACTION_BLEND, 0, input_node)
	blend_tree.connect_node(p.GroyperHitReactionConfig.HIT_REACTION_BLEND, 1, p.GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND)

	var output_node: StringName = p.GroyperHitReactionConfig.HIT_REACTION_BLEND
	p._face_punch_nodes_ready = p.GroyperFacePunchReactionScript.ensure_library(p._animation_player)
	if p._face_punch_nodes_ready:
		output_node = p.GroyperFacePunchReactionScript.attach_nodes(
			blend_tree,
			output_node,
			p._animation_player
		)
	return output_node


static func _init_hit_reaction_animation_tree_state(p) -> void:
	p._hit_reaction_active = false
	p._hit_reaction_phase = p.GroyperHitReactionConfig.Phase.NONE
	p._hit_reaction_blend = 0.0
	p._hit_reaction_pose_blend = 0.0
	p._hit_reaction_fall_timer = 0.0
	p._hit_reaction_stand_timer = 0.0
	p._hit_reaction_impulse_timer = 0.0
	p._hit_reaction_control_unlocked = false
	p._hit_reaction_model_sink = 0.0
	p._hit_reaction_applied_body_sink = 0.0
	if p._animation_tree == null:
		return
	p.GroyperHitReactionConfig.set_reaction_blend(p._animation_tree, 0.0)
	p.GroyperHitReactionConfig.set_pose_blend(p._animation_tree, 0.0)
	p.GroyperHitReactionConfig.set_fall_seek(p._animation_tree, -1.0)
	p.GroyperHitReactionConfig.set_stand_seek(p._animation_tree, -1.0)
	p.GroyperHitReactionConfig.set_stand_playback_speed(p._animation_tree, 1.0)
	if p._face_punch_nodes_ready:
		p.GroyperFacePunchReactionScript.init_tree_state(p._animation_tree)
