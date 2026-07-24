extends CanvasLayer

const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const NewHudAtlas := preload("res://ui/scripts/new_hud_atlas.gd")
const PlayerStamina := preload("res://gameplay/combat/player_stamina.gd")

const HEART_COUNT := 5
const HP_PER_HEART := 2
const HEART_DISPLAY_SIZE := Vector2(36, 36)

@onready var _hearts_row: HBoxContainer = $MarginContainer/HudColumn/HeartsRow
@onready var _stamina_bar: ProgressBar = $MarginContainer/HudColumn/StaminaBar

var _heart_rects: Array[TextureRect] = []
var _tex_empty: AtlasTexture
var _tex_half: AtlasTexture
var _tex_full: AtlasTexture


func _ready() -> void:
	_ensure_textures()
	_ensure_heart_rects()
	set_health(BulletHitDamage.PLAYER_MAX_HEALTH, BulletHitDamage.PLAYER_MAX_HEALTH)
	set_stamina(PlayerStamina.MAX_STAMINA, PlayerStamina.MAX_STAMINA)


func set_health(current: int, max_health: int = BulletHitDamage.PLAYER_MAX_HEALTH) -> void:
	_ensure_textures()
	_ensure_heart_rects()
	if _heart_rects.size() < HEART_COUNT:
		return
	var remaining := clampi(current, 0, maxi(max_health, 0))
	for i in HEART_COUNT:
		var heart_hp := mini(remaining, HP_PER_HEART)
		remaining -= heart_hp
		var rect := _heart_rects[i]
		if heart_hp >= HP_PER_HEART:
			rect.texture = _tex_full
			rect.flip_h = false
		elif heart_hp == 1:
			# Sheet half is right-filled; flip so the left half remains (drain R→L).
			rect.texture = _tex_half
			rect.flip_h = true
		else:
			rect.texture = _tex_empty
			rect.flip_h = false


func set_stamina(current: float, max_stamina: float = PlayerStamina.MAX_STAMINA) -> void:
	if _stamina_bar == null:
		_stamina_bar = get_node_or_null("MarginContainer/HudColumn/StaminaBar") as ProgressBar
	if _stamina_bar == null:
		return
	var max_val := maxf(max_stamina, 0.001)
	_stamina_bar.max_value = max_val
	_stamina_bar.value = clampf(current, 0.0, max_val)


func _ensure_textures() -> void:
	if _tex_empty != null:
		return
	_tex_empty = NewHudAtlas.heart_empty()
	_tex_half = NewHudAtlas.heart_half()
	_tex_full = NewHudAtlas.heart_full()


func _ensure_heart_rects() -> void:
	if not _heart_rects.is_empty():
		return
	if _hearts_row == null:
		_hearts_row = get_node_or_null("MarginContainer/HudColumn/HeartsRow") as HBoxContainer
	if _hearts_row == null:
		return
	for child in _hearts_row.get_children():
		if child is TextureRect:
			_heart_rects.append(child as TextureRect)
	while _heart_rects.size() < HEART_COUNT:
		var rect := TextureRect.new()
		rect.name = "Heart%d" % (_heart_rects.size() + 1)
		rect.custom_minimum_size = HEART_DISPLAY_SIZE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hearts_row.add_child(rect)
		_heart_rects.append(rect)
