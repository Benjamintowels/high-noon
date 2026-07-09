class_name GameAudio
extends RefCounted

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const SHOTGUN_SHOT := preload("res://Assets/Sounds/BigGun.wav")
const SHOTGUN_RELOAD := preload("res://Assets/Sounds/ShotGunReload.wav")
const BASIC_RELOAD := preload("res://Assets/Sounds/BasicReload.wav")
const SNIPER_RELOAD := preload("res://Assets/Sounds/SniperReload.wav")
const SHOP_SPEND := preload("res://Assets/Sounds/Spend.mp3")
const DRAMA_START := preload("res://Assets/Sounds/DramaStart.mp3")
const TOWN_BELL := preload("res://Assets/Sounds/TownBell.mp3")
const PICKUP_MONEY_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/PickUpMoney/Sparkling_magical_ch_#1-1783436608600.mp3"),
	preload("res://Assets/Sounds/PickUpMoney/Sparkling_magical_ch_#2-1783436603235.mp3"),
	preload("res://Assets/Sounds/PickUpMoney/Sparkling_magical_ch_#3-1783436606062.mp3"),
	preload("res://Assets/Sounds/PickUpMoney/Sparkling_magical_ch_#4-1783436611242.mp3"),
]
const REVOLVER_SHOTS: Array[AudioStream] = [
	preload("res://Assets/Sounds/Revolver1.mp3"),
	preload("res://Assets/Sounds/Revolver2.mp3"),
]
const MAC10_SHOT := preload("res://Assets/Sounds/GunBasic2.wav")
const AK47_SHOT := preload("res://Assets/Sounds/GunBasic.wav")
const AWP_SHOT := preload("res://Assets/Sounds/SniperShot.wav")
const WALK_FOOTSTEP := preload("res://Assets/Sounds/WalkingDirt.mp3")
const SPRINT_FOOTSTEP := preload("res://Assets/Sounds/RunningDirt.mp3")
const GRASS_FOOTSTEP := preload("res://Assets/Sounds/FootstepsGrass.mp3")
const WOOD_FOOTSTEP := preload("res://Assets/Sounds/WalkingWood.mp3")
const FOOTSTEP_SPRINT_PITCH := 2.0
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
const PROSPECTOR_VOICE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/GroypTalk/Prospector/Prospector_speaking__#1-1783438146559.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Prospector/Prospector_speaking__#2-1783438146560.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Prospector/Prospector_speaking__#3-1783438152722.mp3"),
	preload("res://Assets/Sounds/GroypTalk/Prospector/Prospector_speaking__#4-1783438152723.mp3"),
]
const BALDWIN_TALK_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/BaldwinTalk/Majestic,_resonant_v_#1-1783016136008.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Majestic,_resonant_v_#1-1783016159754.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Majestic,_resonant_v_#2-1783016138208.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Regal,_booming_voice_#1-1783016225269.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Regal,_booming_voice_#2-1783016219783.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Regal,_booming_voice_#2-1783016244740.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Regal,_booming_voice_#3-1783016229275.mp3"),
	preload("res://Assets/Sounds/BaldwinTalk/Regal,_booming_voice_#4-1783016254598.mp3"),
]
const STAGE_BIRDS := preload("res://Assets/Sounds/Birds.mp3")
const BIRD_FLAP := preload("res://Assets/Sounds/BirdFlap.wav")
const LEAVES_RUSTLE := preload("res://Assets/Sounds/LeavesRustle.mp3")
const COW_MOO := preload("res://Assets/Sounds/ChibiAnimal.mp3")
const PYO_YAP := preload("res://Assets/Sounds/Small_dog_yapping_ex_#4-1783425645295.mp3")
const OPEN_DOOR := preload("res://Assets/Sounds/OpenDoor.mp3")
const CLOSE_DOOR := preload("res://Assets/Sounds/CloseDoor.mp3")
const HAMMER_CHINK := preload("res://Assets/Sounds/Chink.mp3")
const EQUIP_HAT := preload("res://Assets/Sounds/equipHat.mp3")
const BirdFlockAlert := preload("res://characters/animals/bird_flock_alert.gd")
const GUNNER_TAKE_DAMAGE := preload("res://Assets/Sounds/GunnerTakeDamage.wav")
const BULLET_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_wood_#4-1782512116103.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_ricochet_#4-1782512040434.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#1-1782512201634.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#2-1782512217992.mp3"),
	preload("res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#4-1782512213622.mp3"),
]
const PUNCH_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/Punch/punch_flesh_#1-1783437745928.mp3"),
	preload("res://Assets/Sounds/Punch/punch_heavy_#1-1783437867015.mp3"),
	preload("res://Assets/Sounds/Punch/punch_heavy_#3-1783437934300.mp3"),
]
const OIL_DRUM_HIT := preload(
	"res://Assets/Sounds/BulletHitSounds/bullet_hit_body_#1-1782512201634.mp3"
)
const EXPLOSION := preload("res://Assets/Sounds/Explosion.mp3")
const METEOR_START := preload("res://Assets/Sounds/MeteorStart.mp3")
const METEOR_CRASH := preload("res://Assets/Sounds/MeteorCrash.mp3")
const FLAME_PULSE := preload("res://Assets/Sounds/FlamePulse.mp3")
const WHOOSH2 := preload("res://Assets/Sounds/Whoosh2.mp3")
const BOW_RELEASE := preload("res://Assets/Sounds/WhooshCut.mp3")
const BOW_DRAWBACK_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/Drawback/draw_back_bow_and_ar_#1-1782768171628.mp3"),
	preload("res://Assets/Sounds/Drawback/draw_back_bow_and_ar_#2-1782768176428.mp3"),
	preload("res://Assets/Sounds/Drawback/draw_back_bow_and_ar_#4-1782768181672.mp3"),
]
const ARROW_WOOD_IMPACT := preload("res://Assets/Sounds/WoodenCrateBreak.wav")
const ARROW_BODY_IMPACT := preload("res://Assets/Sounds/KnifeImpact.mp3")
const KNIFE_SLICE := preload("res://Assets/Sounds/KnifeImpact.mp3")
const KNIFE_THROW_WHOOSH := preload("res://Assets/Sounds/ThrowKnifeWhoosh.mp3")
const KNIFE_THUD := preload("res://Assets/Sounds/Thud.mp3")
const ROPE_TWIRL := preload("res://Assets/Sounds/RopeTwirl.mp3")
const ROPE_THROW := preload("res://Assets/Sounds/RopeThrow.mp3")
const ROPE_PULL_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Sounds/Rope/Thick_rope_being_pul_#1-1783443367319.mp3"),
	preload("res://Assets/Sounds/Rope/Thick_rope_being_pul_#2-1783443382463.mp3"),
	preload("res://Assets/Sounds/Rope/Thick_rope_being_pul_#3-1783443373952.mp3"),
	preload("res://Assets/Sounds/Rope/Thick_rope_being_pul_#4-1783443378512.mp3"),
]
const OWL_HOOTS: Array[AudioStream] = [
	preload("res://Assets/Sounds/owlhoot1.mp3"),
	preload("res://Assets/Sounds/owlhoot2.mp3"),
]
const PUNCH_THROW_WHOOSHES: Array[AudioStream] = [
	preload("res://Assets/Sounds/PunchThrow1.mp3"),
	preload("res://Assets/Sounds/PunchThrow2.mp3"),
	preload("res://Assets/Sounds/PunchThrow3.mp3"),
]
const SWORD_SWING_WHOOSH := preload("res://Assets/Sounds/SwingLarge.mp3")

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


static func play_shop_purchase(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, SHOP_SPEND, position, false)
	play_loot_pickup(parent, position)


static func play_loot_pickup(parent: Node, position: Vector3 = Vector3.INF) -> void:
	if PICKUP_MONEY_SOUNDS.is_empty():
		return
	var money_stream: AudioStream = PICKUP_MONEY_SOUNDS[randi() % PICKUP_MONEY_SOUNDS.size()]
	_play(parent, money_stream, position, true)


static func play_weapon_reload_grab(
	parent: Node,
	weapon_id: GroyperWeapons.Id,
	position: Vector3 = Vector3.INF
) -> void:
	if not _is_firearm(weapon_id):
		return

	match weapon_id:
		GroyperWeapons.Id.REVOLVER:
			play_revolver_eject_spin(parent, position)
		GroyperWeapons.Id.SHOTGUN:
			_play(parent, SHOTGUN_RELOAD, position, false)
		GroyperWeapons.Id.AWP:
			_play(parent, SNIPER_RELOAD, position, false)
		_:
			_play(parent, BASIC_RELOAD, position, false)


static func play_revolver_aim(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, REVOLVER_AIM, position, false)


static func play_hat_equip(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, EQUIP_HAT, position, false)


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


static func pick_rope_pull_sound() -> AudioStream:
	if ROPE_PULL_SOUNDS.is_empty():
		return null
	return ROPE_PULL_SOUNDS[randi() % ROPE_PULL_SOUNDS.size()]


static func pick_gropyptalk_voice() -> AudioStream:
	var pool: Array[AudioStream] = []
	pool.append_array(AGGRO_VOICE_SOUNDS)
	pool.append_array(WOAH_VOICE_SOUNDS)
	pool.append_array(CHEER_VOICE_SOUNDS)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


static func pick_prospector_talk_voice() -> AudioStream:
	if PROSPECTOR_VOICE_SOUNDS.is_empty():
		return null
	return PROSPECTOR_VOICE_SOUNDS[randi() % PROSPECTOR_VOICE_SOUNDS.size()]


static func pick_baldwin_talk_voice() -> AudioStream:
	if BALDWIN_TALK_SOUNDS.is_empty():
		return null
	return BALDWIN_TALK_SOUNDS[randi() % BALDWIN_TALK_SOUNDS.size()]


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


static func play_punch(parent: Node, position: Vector3 = Vector3.INF) -> void:
	if PUNCH_SOUNDS.is_empty():
		return
	var stream: AudioStream = PUNCH_SOUNDS[randi() % PUNCH_SOUNDS.size()]
	_play(parent, stream, position, true, 1.5)


static func play_oil_drum_hit(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, OIL_DRUM_HIT, position, true, 1.5)


static func play_explosion(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, EXPLOSION, position, true, 2.0)


static func play_comet_flyby(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, METEOR_START, position, true, -5.0)
	_play_delayed(parent, FLAME_PULSE, 0.25, position, true)
	_play_delayed(parent, WHOOSH2, 0.55, position, true)


static func play_distant_comet_crash(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, METEOR_CRASH, position, true, -8.0)
	_play_delayed(parent, EXPLOSION, 0.2, position, true, -10.0)


static func play_bow_release(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, BOW_RELEASE, position, true)


static func start_bow_drawback(parent: Node, position: Vector3 = Vector3.INF) -> AudioStreamPlayer3D:
	if parent == null or BOW_DRAWBACK_SOUNDS.is_empty():
		return null
	var stream: AudioStream = BOW_DRAWBACK_SOUNDS[randi() % BOW_DRAWBACK_SOUNDS.size()]
	var player := _spawn_player(parent, stream, position, true)
	if player == null:
		return null
	player.play()
	return player


static func stop_bow_drawback(player) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player is AudioStreamPlayer3D:
		return
	var audio_player := player as AudioStreamPlayer3D
	audio_player.stop()
	audio_player.queue_free()


static func play_arrow_wood_impact(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, ARROW_WOOD_IMPACT, position, true)


static func play_arrow_body_impact(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, ARROW_BODY_IMPACT, position, true)


static func play_knife_slice(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, KNIFE_SLICE, position, true, 1.2)


static func play_knife_throw_whoosh(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, KNIFE_THROW_WHOOSH, position, true)


static func play_knife_thud(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, KNIFE_THUD, position, true, 1.4)


static func play_rope_throw(parent: Node, position: Vector3 = Vector3.INF, volume_offset_db: float = -2.0) -> void:
	_play(parent, ROPE_THROW, position, true, volume_offset_db)


static func play_rope_one_shot(
	parent: Node,
	stream: AudioStream,
	position: Vector3 = Vector3.INF,
	volume_offset_db: float = 0.0
) -> void:
	_play(parent, stream, position, true, volume_offset_db)


static func play_stage_birds(parent: Node) -> void:
	if parent == null or STAGE_BIRDS == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = STAGE_BIRDS
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func play_raid_drama_start(parent: Node) -> void:
	if parent == null or DRAMA_START == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = DRAMA_START
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func play_town_bell(parent: Node) -> void:
	if parent == null or TOWN_BELL == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = TOWN_BELL
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func play_bird_flap(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, BIRD_FLAP, position, true, -2.0)


static func play_bird_death(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, LEAVES_RUSTLE, position, true)


static func play_cow_moo(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, COW_MOO, position, true, -1.0)


static func play_owl_hoot(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, OWL_HOOTS[randi() % OWL_HOOTS.size()], position, true, -4.0)


static func play_punch_throw(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, PUNCH_THROW_WHOOSHES[randi() % PUNCH_THROW_WHOOSHES.size()], position, true)


static func play_sword_swing(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, SWORD_SWING_WHOOSH, position, true)


static func play_pyo_yap(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, PYO_YAP, position, true, -1.0)


static func play_door_open(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, OPEN_DOOR, position, false)


static func play_door_close(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, CLOSE_DOOR, position, false)


static func play_hammer_chink(parent: Node, position: Vector3 = Vector3.INF) -> void:
	_play(parent, HAMMER_CHINK, position, false)


static func notify_birds_of_explosion(parent: Node, position: Vector3) -> void:
	BirdFlockAlert.scare_from_explosion(parent, position)


static func _notify_birds_of_gunfire(parent: Node, position: Vector3) -> void:
	BirdFlockAlert.scare_from_gun(parent, position)


static func _is_firearm(weapon_id: GroyperWeapons.Id) -> bool:
	var mode := String(GroyperWeapons.get_fire_mode(weapon_id))
	return mode == "bullet" or mode == "rpg"


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
	apply_variation: bool,
	volume_offset_db: float = 0.0
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
				_play(parent, stream, position, apply_variation, volume_offset_db)
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
