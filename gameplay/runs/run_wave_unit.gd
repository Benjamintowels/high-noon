extends Resource
class_name RunWaveUnit

## One weighted base-enemy variant inside a RunWaveGroup.

@export var enemy_scene: PackedScene
@export var weight: float = 1.0
## Run-elapsed seconds before this variant joins the group's spawn pool.
@export var unlock_time: float = 0.0
## GroyperWeapons.Id, or -1 to keep the scene default.
@export var weapon_id: int = -1
@export var melee_only: bool = false
## Bandit throws one dynamite stick on aggro, flees, then fights unarmed.
@export var dynamite_thrower: bool = false
@export var health_mult: float = 1.0
@export var visual_scale: float = 1.0
