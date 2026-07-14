extends RefCounted
class_name MeleeBlockFX

const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const BLOCK_FX_PIXEL_SIZE := 0.024


static func play(
	defender: Node,
	attacker: Node,
	contact_position: Vector3,
	_direction: Vector3,
	modulate_override: Color = Color(0, 0, 0, 0)
) -> void:
	var fx_parent := ImpactFXScript.parent_for(defender)
	MuzzleFlashFXScript.spawn(
		fx_parent,
		contact_position,
		&"symmetrical",
		BLOCK_FX_PIXEL_SIZE,
		false,
		modulate_override
	)
	GameAudioScript.play_punch(defender, contact_position)

	if attacker != null and attacker.has_method("apply_camera_shake"):
		attacker.apply_camera_shake(0.38)
	if defender != null and defender.has_method("apply_camera_shake"):
		defender.apply_camera_shake(0.38)
