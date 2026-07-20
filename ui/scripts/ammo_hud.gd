class_name AmmoHud
extends CanvasLayer

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")
const ReserveAmmoDisplayScript := preload("res://ui/scripts/reserve_ammo_display.gd")

@export var weapon_icon_size := Vector2(52.0, 52.0)

@onready var _ammo_panel: HBoxContainer = $MarginContainer/AmmoColumn/AmmoPanel
@onready var _gem_stamina_bar: ProgressBar = $MarginContainer/AmmoColumn/GemStaminaBar
@onready var _weapon_icon: TextureRect = $MarginContainer/AmmoColumn/AmmoPanel/WeaponIcon
@onready var _cylinder_display: CylinderAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/CylinderDisplay
@onready var _magazine_display: MagazineAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/MagazineDisplay
@onready var _slug_tube_display: SlugTubeAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/SlugTubeDisplay
@onready var _single_rocket_display: SingleRocketAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/SingleRocketDisplay
@onready var _sniper_magazine_display: SniperMagazineAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/SniperMagazineDisplay
@onready var _banana_clip_display: BananaClipAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/BananaClipDisplay
@onready var _quiver_display: QuiverAmmoDisplay = $MarginContainer/AmmoColumn/AmmoPanel/QuiverDisplay

var _reserve_display: ReserveAmmoDisplay
var _weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.REVOLVER
var _active_display_mode: GroyperWeapons.AmmoDisplayMode = GroyperWeapons.AmmoDisplayMode.CYLINDER
var _gem_fill_style: StyleBoxFlat
var _gem_bg_style: StyleBoxFlat


func _ready() -> void:
	_setup_gem_stamina_bar_styles()
	_ensure_reserve_display()
	configure_for_weapon(GroyperWeapons.DEFAULT_WEAPON)
	sync_reserve_ammo(PlayerInventory.get_revolver_ammo())


func _setup_gem_stamina_bar_styles() -> void:
	_gem_bg_style = StyleBoxFlat.new()
	_gem_bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.75)
	_gem_bg_style.set_corner_radius_all(2)
	_gem_bg_style.content_margin_left = 1.0
	_gem_bg_style.content_margin_right = 1.0
	_gem_bg_style.content_margin_top = 1.0
	_gem_bg_style.content_margin_bottom = 1.0

	_gem_fill_style = StyleBoxFlat.new()
	_gem_fill_style.bg_color = Color(1.0, 0.92, 0.22, 1.0)
	_gem_fill_style.set_corner_radius_all(2)

	_gem_stamina_bar.add_theme_stylebox_override("background", _gem_bg_style)
	_gem_stamina_bar.add_theme_stylebox_override("fill", _gem_fill_style)


func _ensure_reserve_display() -> void:
	if _reserve_display != null:
		return
	_reserve_display = ReserveAmmoDisplayScript.new() as ReserveAmmoDisplay
	_reserve_display.name = "ReserveAmmoDisplay"
	_reserve_display.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reserve_display.size_flags_vertical = Control.SIZE_SHRINK_END
	_ammo_panel.add_child(_reserve_display)
	_ammo_panel.move_child(_reserve_display, _cylinder_display.get_index() + 1)


func configure_for_weapon(weapon_id: GroyperWeapons.Id) -> void:
	_weapon_id = weapon_id
	_active_display_mode = GroyperWeapons.get_ammo_display_mode(weapon_id)
	var hide_ammo := _active_display_mode == GroyperWeapons.AmmoDisplayMode.NONE
	_cylinder_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.CYLINDER
	_magazine_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.MAGAZINE
	_slug_tube_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.SLUG_TUBE
	_single_rocket_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.SINGLE_ROCKET
	_sniper_magazine_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.SNIPER_MAGAZINE
	_banana_clip_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.BANANA_CLIP
	_quiver_display.visible = not hide_ammo and _active_display_mode == GroyperWeapons.AmmoDisplayMode.QUIVER

	_ensure_reserve_display()
	_reserve_display.visible = _active_display_mode == GroyperWeapons.AmmoDisplayMode.CYLINDER

	set_equipped_weapon(GroyperWeapons.get_icon(weapon_id))
	sync_rounds(GroyperWeapons.get_max_ammo(weapon_id))
	sync_reserve_ammo(PlayerInventory.get_revolver_ammo())


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
		GroyperWeapons.AmmoDisplayMode.QUIVER:
			_quiver_display.sync_rounds(clamped, animate_shot, reset_display)
		_:
			_cylinder_display.sync_rounds(clamped, animate_shot, reset_display)

	if clamped <= 0:
		_weapon_icon.modulate = Color(0.55, 0.55, 0.55, 0.85)
	else:
		_weapon_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)


func eject_all_casings() -> void:
	match _active_display_mode:
		GroyperWeapons.AmmoDisplayMode.MAGAZINE:
			_magazine_display.eject_all_casings()
		GroyperWeapons.AmmoDisplayMode.SLUG_TUBE:
			_slug_tube_display.eject_all_casings()
		GroyperWeapons.AmmoDisplayMode.SINGLE_ROCKET:
			_single_rocket_display.eject_all_casings()
		GroyperWeapons.AmmoDisplayMode.SNIPER_MAGAZINE:
			_sniper_magazine_display.eject_all_casings()
		GroyperWeapons.AmmoDisplayMode.BANANA_CLIP:
			_banana_clip_display.eject_all_casings()
		_:
			_cylinder_display.eject_all_casings()


func animate_reload_round(round_count: int) -> void:
	match _active_display_mode:
		GroyperWeapons.AmmoDisplayMode.SLUG_TUBE:
			_slug_tube_display.animate_load_round(round_count)
		_:
			_cylinder_display.animate_load_round(round_count)

	_update_weapon_icon_modulate(round_count)


func animate_reload_magazine(round_count: int) -> void:
	match _active_display_mode:
		GroyperWeapons.AmmoDisplayMode.MAGAZINE:
			_magazine_display.animate_reload_magazine(round_count)
		GroyperWeapons.AmmoDisplayMode.SINGLE_ROCKET:
			_single_rocket_display.animate_reload_magazine(round_count)
		GroyperWeapons.AmmoDisplayMode.SNIPER_MAGAZINE:
			_sniper_magazine_display.animate_reload_magazine(round_count)
		GroyperWeapons.AmmoDisplayMode.BANANA_CLIP:
			_banana_clip_display.animate_reload_magazine(round_count)

	_update_weapon_icon_modulate(round_count)


func sync_reserve_ammo(count: int) -> void:
	_ensure_reserve_display()
	_reserve_display.sync_count(count)


## Short colored bar for the equipped weapon's embedded gem stamina.
func sync_gem_stamina(bar_visible: bool, ratio: float, color: Color) -> void:
	if _gem_stamina_bar == null:
		return
	_gem_stamina_bar.visible = bar_visible
	if not bar_visible:
		return
	_gem_stamina_bar.value = clampf(ratio, 0.0, 1.0)
	if _gem_fill_style != null:
		_gem_fill_style.bg_color = color


func _update_weapon_icon_modulate(round_count: int) -> void:
	if round_count <= 0:
		_weapon_icon.modulate = Color(0.55, 0.55, 0.55, 0.85)
	else:
		_weapon_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
