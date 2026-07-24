extends RefCounted

## Atlas slices from Assets/UI/NewHudAssets for player health hearts and
## elemental gem stamina bars.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")

const HEARTS_SHEET := preload("res://Assets/UI/NewHudAssets/00.png")
const BARS_SHEET := preload("res://Assets/UI/NewHudAssets/06.png")
## Cyan solid gem polygon used as the hue-shift source for elemental icons.
const GEM_ICON_SHEET := preload("res://Assets/UI/NewHudAssets/01.png")
const GEM_ICON_BASE_REGION := Rect2(183, 57, 34, 30)

const HEART_SIZE := Vector2i(12, 12)
const HEART_EMPTY_REGION := Rect2(82, 114, 12, 12)
const HEART_HALF_REGION := Rect2(98, 114, 12, 12)
const HEART_FULL_REGION := Rect2(114, 114, 12, 12)

const BAR_ORIGIN := Vector2i(5, 22)
const BAR_CELL := Vector2i(39, 5)
const BAR_COL_STRIDE := 48
const BAR_ROW_STRIDE := 16
const BAR_FRAME_COUNT := 5

const ROW_BLUE := 0
const ROW_GREEN := 1
const ROW_SLATE_PURPLE := 2
const ROW_ORANGE := 3
const ROW_MAGENTA := 4
const ROW_PINK_RED := 5

const GEM_BAR_ROWS := {
	ElementalGems.ICE: ROW_BLUE,
	ElementalGems.LIGHTNING: ROW_SLATE_PURPLE,
	ElementalGems.FIRE: ROW_ORANGE,
}


static func heart_empty() -> AtlasTexture:
	return _atlas(HEARTS_SHEET, HEART_EMPTY_REGION)


static func heart_half() -> AtlasTexture:
	return _atlas(HEARTS_SHEET, HEART_HALF_REGION)


static func heart_full() -> AtlasTexture:
	return _atlas(HEARTS_SHEET, HEART_FULL_REGION)


static func gem_bar_row(gem_id: StringName) -> int:
	return int(GEM_BAR_ROWS.get(gem_id, ROW_BLUE))


static func gem_bar_frame_index(ratio: float, cooling: bool = false) -> int:
	if cooling:
		return BAR_FRAME_COUNT - 1
	var clamped := clampf(ratio, 0.0, 1.0)
	return clampi(int(round((1.0 - clamped) * float(BAR_FRAME_COUNT - 1))), 0, BAR_FRAME_COUNT - 1)


static func gem_bar(gem_id: StringName, ratio: float, cooling: bool = false) -> AtlasTexture:
	return gem_bar_at_row(gem_bar_row(gem_id), gem_bar_frame_index(ratio, cooling))


static func gem_bar_at_row(color_row: int, frame: int) -> AtlasTexture:
	var row := clampi(color_row, 0, ROW_PINK_RED)
	var fr := clampi(frame, 0, BAR_FRAME_COUNT - 1)
	var region := Rect2(
		BAR_ORIGIN.x + fr * BAR_COL_STRIDE,
		BAR_ORIGIN.y + row * BAR_ROW_STRIDE,
		BAR_CELL.x,
		BAR_CELL.y
	)
	return _atlas(BARS_SHEET, region)


static func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = region
	tex.filter_clip = true
	return tex
