extends RefCounted
class_name FxCatalog

const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const CROWN_DIR := "res://Assets/FX/PNG/Symbols/symbol_crown_001/symbol_crown_001_large_yellow"
const ALERT_DIR := "res://Assets/FX/PNG/Symbols/symbol_alert_001/symbol_alert_001_large_red"
const MUZZLE_DIR := "res://Assets/FX/PNG/Explosions/symmetrical_explosion_001/symmetrical_explosion_001_small_orange"
const EPIC_EXPLOSION_DIR := "res://Assets/FX/PNG/Explosions/epic_explosion_001/epic_explosion_001_small_orange"

static var _crown_frames: SpriteFrames
static var _alert_frames: SpriteFrames
static var _muzzle_frames: SpriteFrames
static var _epic_explosion_frames: SpriteFrames


static func crown_frames() -> SpriteFrames:
	if _crown_frames == null:
		_crown_frames = FxFramesLoaderScript.from_png_dir(CROWN_DIR, 24.0)
	return _crown_frames


static func alert_frames() -> SpriteFrames:
	if _alert_frames == null:
		_alert_frames = FxFramesLoaderScript.from_png_dir(ALERT_DIR, 24.0)
	return _alert_frames


static func muzzle_frames() -> SpriteFrames:
	if _muzzle_frames == null:
		_muzzle_frames = FxFramesLoaderScript.from_png_dir(MUZZLE_DIR, 30.0)
	return _muzzle_frames


static func epic_explosion_frames() -> SpriteFrames:
	if _epic_explosion_frames == null:
		_epic_explosion_frames = FxFramesLoaderScript.from_png_dir(EPIC_EXPLOSION_DIR, 28.0)
	return _epic_explosion_frames
