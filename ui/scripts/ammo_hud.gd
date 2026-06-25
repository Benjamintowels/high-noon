class_name AmmoHud
extends CanvasLayer

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

@export var weapon_icon_size := Vector2(52.0, 52.0)

@onready var _weapon_icon: TextureRect = $MarginContainer/AmmoPanel/WeaponIcon
@onready var _cylinder_display: CylinderAmmoDisplay = $MarginContainer/AmmoPanel/CylinderDisplay
@onready var _magazine_display: MagazineAmmoDisplay = $MarginContainer/AmmoPanel/MagazineDisplay
@onready var _slug_tube_display: SlugTubeAmmoDisplay = $MarginContainer/AmmoPanel/SlugTubeDisplay
@onready var _single_rocket_display: SingleRocketAmmoDisplay = $MarginContainer/AmmoPanel/SingleRocketDisplay
@onready var _sniper_magazine_display: SniperMagazineAmmoDisplay = $MarginContainer/AmmoPanel/SniperMagazineDisplay
@onready var _banana_clip_display: BananaClipAmmoDisplay = $MarginContainer/AmmoPanel/BananaClipDisplay

var _weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.REVOLVER
var _active_display_mode: GroyperWeapons.AmmoDisplayMode = GroyperWeapons.AmmoDisplayMode.CYLINDER


func _ready() -> void:
	configure_for_weapon(GroyperWeapons.DEFAULT_WEAPON)


func configure_for_weapon(weapon_id: GroyperWeapons.Id) -> void:
	_weapon_id = weapon_id
	_active_display_mode = GroyperWeapons.get_ammo_display_mode(weapon_id)
	_cylinder_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.CYLINDER
	_magazine_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.MAGAZINE
	_slug_tube_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.SLUG_TUBE
	_single_rocket_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.SINGLE_ROCKET
	_sniper_magazine_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.SNIPER_MAGAZINE
	_banana_clip_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.BANANA_CLIP

	set_equipped_weapon(GroyperWeapons.get_icon(weapon_id))
	sync_rounds(GroyperWeapons.get_max_ammo(weapon_id))


func set_equipped_weapon(texture: Texture2D) -> void:
	_weapon_icon.texture = texture
	_weapon_icon.visible = texture != null


func sync_rounds(count: int, animate_shot: bool = false, reset_display: bool = false) -> void:
	var max_ammo := GroyperWeapons.get_max_ammo(_weapon_id)
	var clamped := clampi(count, 0, max_ammo)

	match _active_display_mode:
		GroyperWeapons.AmmoDisplayMode.MAGAZINE:
			_magazine_display.sync_rounds(clamped, animate_shot, reset_display)
		GroyperWeapons.AmmoDisplayMode.SLUG_TUBE:
			_slug_tube_display.sync_rounds(clamped, animate_shot, reset_display)
		GroyperWeapons.AmmoDisplayMode.SINGLE_ROCKET:
			_single_rocket_display.sync_rounds(clamped, animate_shot, reset_display)
		GroyperWeapons.AmmoDisplayMode.SNIPER_MAGAZINE:
			_sniper_magazine_display.sync_rounds(clamped, animate_shot, reset_display)
		GroyperWeapons.AmmoDisplayMode.BANANA_CLIP:
			_banana_clip_display.sync_rounds(clamped, animate_shot, reset_display)
		_:
			_cylinder_display.sync_rounds(clamped, animate_shot, reset_display)

	if clamped <= 0:
		_weapon_icon.modulate = Color(0.55, 0.55, 0.55, 0.85)
	else:
		_weapon_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
