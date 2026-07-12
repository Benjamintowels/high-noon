extends RefCounted
class_name HammerSpinStrike

## Contact resolution for the war hammer's sprint spin attack. The player keeps
## a continuous hitbox live from early in the swing to the end and feeds each
## newly-touched enemy through resolve_contact():
## - clean hits launch bodies flying backwards as projectiles that bowl over
##   whatever they clip (the same flight the flying kick / grab throw uses)
## - a melee-blocking defender clashes (mutual stun + shove) and the caller
##   interrupts the rest of the swing.

const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const UnarmedParryThrowScript := preload("res://gameplay/combat/unarmed_parry_throw.gd")
const FlyingKickFXScript := preload("res://gameplay/fx/flying_kick_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

enum ContactResult { MISSED, LAUNCHED, CLASHED }

const CONTACT_DAMAGE := 1
## Fraction of the spin animation after which the hitbox goes live (stays live
## through the end of the clip).
const STRIKE_START_FRACTION := 0.12
const STUN_DURATION := 0.9
const CAMERA_SHAKE := 0.45


static func resolve_contact(attacker: Node3D, target: Node) -> ContactResult:
	if attacker == null or target == null or not is_instance_valid(target):
		return ContactResult.MISSED
	if not (target is Node3D):
		return ContactResult.MISSED

	# The spin flings everything radially away from the attacker.
	var fly_dir := (target as Node3D).global_position - attacker.global_position
	fly_dir.y = 0.0
	if fly_dir.length_squared() < 0.0001:
		fly_dir = -attacker.global_transform.basis.z
		fly_dir.y = 0.0
	if fly_dir.length_squared() < 0.0001:
		fly_dir = Vector3.FORWARD
	fly_dir = fly_dir.normalized()

	var contact: Vector3 = MeleeSwordSlashScript._get_target_anchor(target as Node3D)
	var fx_parent: Node = attacker.get_parent()

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	# Ragdoll-capable victims that aren't guarding fly on the grab-throw arc
	# (its landing deals the 1 base damage) and bowl over anything they clip.
	var melee_guarding: bool = target.has_method("is_blocking") and target.is_blocking()
	if not melee_guarding and _is_toss_eligible(attacker, target):
		var controller := UnarmedParryThrowScript.new()
		controller.name = "UnarmedParryThrow"
		fx_parent.add_child(controller)
		controller.begin_shove(attacker, target as CharacterBody3D, fly_dir)
		_play_contact_feedback(attacker, fx_parent, contact, fly_dir)
		return ContactResult.LAUNCHED

	if not target.has_method("receive_bullet_hit"):
		return ContactResult.MISSED

	var hit_info := {
		"position": contact,
		"direction": fly_dir,
		"shooter": attacker,
		"damage": CONTACT_DAMAGE,
		"knockback_speed": MeleeSwordSlashScript.HEAVY_KNOCKBACK_SPEED,
		"knockback_up": MeleeSwordSlashScript.HEAVY_KNOCKBACK_UP,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"sword_hit": true,
		"heavy_hit": true,
		# Only read by the defeat ragdoll when the strike kills: the corpse
		# launches on this ballistic arc instead of dropping at the spot.
		"mounted_dismount": true,
		"mounted_launch_velocity": (
			fly_dir * UnarmedParryThrowScript.TOSS_FORWARD_SPEED
			+ Vector3.UP * UnarmedParryThrowScript.TOSS_UP_SPEED
		),
	}
	target.receive_bullet_hit(hit_info)

	if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
		# The defender blocked: MeleeClash.resolve already stunned and shoved
		# both parties apart. The caller aborts the rest of the swing.
		return ContactResult.CLASHED

	if target.has_method("apply_melee_stun"):
		target.apply_melee_stun(STUN_DURATION)

	if (
		target is CharacterBody3D
		and target.has_method("is_defeated")
		and target.is_defeated()
	):
		# The launched corpse is a weapon too: bowl over anything it clips.
		var corpse_watch := UnarmedParryThrowScript.new()
		corpse_watch.name = "UnarmedParryThrow"
		fx_parent.add_child(corpse_watch)
		corpse_watch.begin_corpse_flight(attacker, target as CharacterBody3D, fly_dir)

	_play_contact_feedback(attacker, fx_parent, contact, fly_dir)
	return ContactResult.LAUNCHED


static func _play_contact_feedback(
	attacker: Node3D,
	fx_parent: Node,
	contact: Vector3,
	direction: Vector3
) -> void:
	FlyingKickFXScript.spawn_impact(fx_parent, contact, direction)
	GameAudioScript.play_punch(attacker, contact)
	if attacker.has_method("apply_camera_shake"):
		attacker.apply_camera_shake(CAMERA_SHAKE)


static func _is_toss_eligible(attacker: Node3D, target: Node) -> bool:
	if target == null or not is_instance_valid(target) or target == attacker:
		return false
	if not (target is CharacterBody3D):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if not target.has_method("begin_lasso_capture") or not target.has_method("get_lasso_ragdoll"):
		return false
	if target.has_method("is_lassoable") and not target.is_lassoable():
		return false
	if target.has_method("is_hostage_captured") and target.is_hostage_captured():
		return false
	return true
