extends Node3D

## Attached to the stylized melee weapon grip scenes. Applies the weapon's PBR
## textures to its meshes whenever the grip is instantiated (hand, holster, or
## ground pickup).

@export var weapon_id: int = -1


func _ready() -> void:
	if weapon_id >= 0:
		MeleeWeaponVisuals.apply(self, weapon_id)
