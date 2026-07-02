extends CharacterBody3D

@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var anim: AnimationPlayer


func _ready() -> void:
	anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null and anim.has_animation("Idle"):
		anim.play("Idle")
		anim.seek(0.0, true)


func attack() -> void:
	if anim == null:
		return
	anim.play("Attack")
	audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyAttack.mp3")
	audio.play()


func die() -> void:
	if anim == null:
		return
	anim.play("Death")
	audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyDeath.mp3")
	audio.play()


func run() -> void:
	if anim == null:
		return
	anim.play("Run")
	audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyBase.mp3")
	audio.play()


func hit() -> void:
	if anim == null:
		return
	anim.play("Hit")


func idle() -> void:
	if anim == null:
		return
	anim.play("Idle")


func scream() -> void:
	if anim == null:
		return
	anim.play("Scream")
	audio.stream = load("res://Assets/World/RuinsGR/Sounds/SkelyAttack.mp3")
	audio.play()
