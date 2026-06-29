class_name GameAudio
extends RefCounted

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const SHOTGUN_SHOT := preload("res://Assets/Sounds/BigGun.wav")
const SHOTGUN_RELOAD := preload("res://Assets/Sounds/ShotGunReload.wav")
const REVOLVER_SHOTS: Array[AudioStream] = [
	preload("res://Assets/Sounds/Revolver1.mp3"),
	preload("res://Assets/Sounds/Revolver2.mp3"),
]
const MAC10_SHOT := preload("res://Assets/Sounds/GunBasic2.wav")
const AK47_SHOT := preload("res://Assets/Sounds/GunBasic.wav")
const AWP_SHOT := preload("res://Assets/Sounds/SniperShot.wav")
const WALK_FOOTSTEP := preload("res://Assets/Sounds/WalkingDirt.mp3")
const SPRINT_FOOTSTEP := preload("res://Assets/Sounds/RunningDirt.mp3")
const HORSE_WALK_FOOTSTEP := preload("res://Assets/Sounds/horsewalking.mp3")
const HORSE_RUN_FOOTSTEP := preload("res://Assets/Sounds/horserun.mp3")
const REVOLVER_SPIN := preload("res://Assets/Sounds/revolver_spin.mp3")
const REVOLVER_AIM := preload("res://Assets/Sounds/RevolverAim.mp3")
const HORSE_NEIGH_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/HorseNeigh/horse_neigh_#1-1782511463442.mp3"),
	preload("res://Assets/Sounds/HorseNeigh/horse_neigh_#2-1782511468059.mp3"),
	preload("res://Assets/Sounds/HorseNeigh/horse_neigh_#3-1782511469296.mp3"),
	preload("res://Assets/Sounds/HorseNeigh/horse_neigh_#4-1782511469297.mp3"),
]
const AGGRO_VOICE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/GroypTalk/GroypTalkMad.mp3"),
	preload("res://Assets/Sounds/GroypTalk/GroypTalkMad2.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#1-1782512966447.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#1-1782512990589.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#2-1782512962983.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#2-1782512994468.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#3-1782512959797.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#4-1782512955319.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#4-1782513000080.mp3"),
]
const SHERIFF_INTERACT_VOICE := preload(
	"res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#4-1782512955319.mp3"
)
const SHERIFF_DIALOG_LINE_2_VOICE := preload(
	"res://Assets/Sounds/GroypTalk/Gruff_cowboy_voice,__#3-1782512959797.mp3"
)
const EASY_THERE_VOICE := preload("res://Assets/Sounds/easythere.mp3")
const WOAH_VOICE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/GroypTalk/Woah/Cowboy_talk_woah_#1-1782513449187.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Woah/Cowboy_talk_woah_#2-1782513433108.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Woah/Cowboy_talk_woah_#3-1782513437512.mp3"),
]
const CHEER_VOICE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/GroypTalk/Cheer/cowboy_cheer_#1-1782751949786.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Cheer/cowboy_cheer_#2-1782751954305.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Cheer/cowboy_cheer_#2-1782751933213.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Cheer/cowboy_cheer_#3-1782751938887.mp3"),
]
const STAGE_BIRDS := preload("res://Assets/Sounds/Birds.mp3")
const BIRD_FLAP := preload("res://Assets/Sounds/BirdFlap.wav")
const LEAVES_RUSTLE := preload("res://Assets/Sounds/LeavesRustle.mp3")
const COW_MOO := preload("res://Assets/Sounds/ChibiAnimal.mp3")
const BirdFlockAlert := preload("res://characters/animals/bird_flock_alert.gd")
const GUNNER_TAKE_DAMAGE := preload("res://Assets/Sounds/GunnerTakeDamage.wav")
const BULLET_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_wood_#4-1782512116103.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_ricochet_#4-1782512040434.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#1-1782512201634.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#2-1782512217992.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#4-1782512213622.mp3"),
]

const PITCH_MIN := 0.9
const PITCH_MAX := 1.12
const VOLUME_JITTER_DB := 2.5

const SPRINT_VOLUME_DB := -6.0


static func play_weapon_shot(
	weapon_id: GroyperWeapons.Id,
	parent: Node,
	position: Vector3 = Vector3.INF
) -> void:
	if parent == null:
		return

	if weapon_id == GroyperWeapons.Id.SHOTGUN:
		_play(parent, SHOTGUN_SHOT, position, true)
		_notify_birds_of_gunfire(parent, position)
		var delay := SHOTGUN_SHOT.get_length()
		if delay <= 0.0:
			delay = 0.35
		_play_delayed(parent, SHOTGUN_RELOAD, delay, position, false)
		return

	var stream := _get_weapon_shot_stream(weapon_id)
	if stream == null:
		return
	_play(parent, stream, position, weapon_id == GroyperWeapons.Id.REVOLVER)
	_notify_birds_of_gunfire(parent, position)


static func play_revolver_eject_spin(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, REVOLVER_SPIN, position, true)


static func play_revolver_aim(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, REVOLVER_AIM, position, false)


static func play_horse_neigh(parent: Node, position: Vector3 = Vector3.INF) -> void:
	if HORSE_NEIGH_SOUNDS.is_empty():
		return
	var stream: AudioStream = HORSE_NEIGH_SOUNDS[randi() % HORSE_NEIGH_SOUNDS.size()]
	_play(parent, stream, position, true)


static func pick_aggro_voice() -> AudioStream:
	if AGGRO_VOICE_SOUNDS.is_empty():
		return null
	return AGGRO_VOICE_SOUNDS[randi() % AGGRO_VOICE_SOUNDS.size()]


static func pick_woah_voice() -> AudioStream:
	if WOAH_VOICE_SOUNDS.is_empty():
		return null
	return WOAH_VOICE_SOUNDS[randi() % WOAH_VOICE_SOUNDS.size()]


static func pick_cheer_voice() -> AudioStream:
	if CHEER_VOICE_SOUNDS.is_empty():
		return null
	return CHEER_VOICE_SOUNDS[randi() % CHEER_VOICE_SOUNDS.size()]


static func pick_gropyptalk_voice() -> AudioStream:
	var pool: Array[AudioStream] = []
	pool.append_array(AGGRO_VOICE_SOUNDS)
	pool.append_array(WOAH_VOICE_SOUNDS)
	pool.append_array(CHEER_VOICE_SOUNDS)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


static func play_npc_voice(
	parent: Node,
	stream: AudioStream,
	position: Vector3 = Vector3.INF,
	apply_variation: bool = false
) -> void:
	_play(parent, stream, position, apply_variation)


static func play_death_sound(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, GUNNER_TAKE_DAMAGE, position, true)


static func play_bullet_hit(parent: Node, position: Vector3 = Vector3.INF) -> void:
	if BULLET_HIT_SOUNDS.is_empty():
		return
	var stream: AudioStream = BULLET_HIT_SOUNDS[randi() % BULLET_HIT_SOUNDS.size()]
	_play(parent, stream, position, true)


static func play_stage_birds(parent: Node) -> void:
	if parent == null or STAGE_BIRDS == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = STAGE_BIRDS
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func play_bird_flap(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, BIRD_FLAP, position, true, -2.0)


static func play_bird_death(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, LEAVES_RUSTLE, position, true)


static func play_cow_moo(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, COW_MOO, position, true, -1.0)


static func notify_birds_of_explosion(parent: Node, position: Vector3) -> void:
	BirdFlockAlert.scare_from_explosion(parent, position)


static func _notify_birds_of_gunfire(parent: Node, position: Vector3) -> void:
	BirdFlockAlert.scare_from_gun(parent, position)


static func _get_weapon_shot_stream(weapon_id: GroyperWeapons.Id) -> AudioStream:
	match weapon_id:
		GroyperWeapons.Id.REVOLVER:
			return REVOLVER_SHOTS[randi() % REVOLVER_SHOTS.size()]
		GroyperWeapons.Id.MAC10:
			return MAC10_SHOT
		GroyperWeapons.Id.AWP:
			return AWP_SHOT
		GroyperWeapons.Id.AK47:
			return AK47_SHOT
		_:
			return null


static func _play_delayed(
	parent: Node,
	stream: AudioStream,
	delay: float,
	position: Vector3,
	apply_variation: bool
) -> void:
	if parent == null or stream == null:
		return
	var tree := parent.get_tree()
	if tree == null:
		return
	var timer := tree.create_timer(maxf(delay, 0.0))
	timer.timeout.connect(
		func() -> void:
			if is_instance_valid(parent):
				_play(parent, stream, position, apply_variation)
	)


static func _play(
	parent: Node,
	stream: AudioStream,
	position: Vector3,
	apply_variation: bool,
	volume_offset_db: float = 0.0
) -> void:
	var player := _spawn_player(parent, stream, position, apply_variation, volume_offset_db)
	if player == null:
		return
	player.finished.connect(player.queue_free)
	player.play()


static func _spawn_player(
	parent: Node,
	stream: AudioStream,
	position: Vector3,
	apply_variation: bool,
	volume_offset_db: float = 0.0
) -> AudioStreamPlayer3D:
	if parent == null or stream == null:
		return null

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.max_distance = 80.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.unit_size = 4.0
	player.volume_db = volume_offset_db

	if apply_variation:
		player.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX)
		player.volume_db += randf_range(-VOLUME_JITTER_DB * 0.5, VOLUME_JITTER_DB * 0.5)

	parent.add_child(player)
	if position != Vector3.INF:
		player.global_position = position
	elif parent is Node3D:
		player.global_position = (parent as Node3D).global_position

	return player
