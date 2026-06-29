extends RefCounted
class_name BirdFrames

const IDLE_LEFT_RIGHT := preload("res://Assets/Animals/Birds/BirdLeftRight.png")
const IDLE_UP := preload("res://Assets/Animals/Birds/BirdUp.png")
const IDLE_DOWN := preload("res://Assets/Animals/Birds/BirdDown.png")

const FLIGHT_LEFT_RIGHT := preload("res://Assets/Animals/Birds/BirdFlightLeftRight.png")
const FLIGHT_UP := preload("res://Assets/Animals/Birds/BirdFlightUp.png")
const FLIGHT_DOWN := preload("res://Assets/Animals/Birds/BirdFlightDown.png")

const IDLE_ANIM := &"idle"
const FLAP_ANIM := &"flap"
const FLAP_FPS := 36.0

static var _idle_frames: Dictionary = {}
static var _flight_frames: Dictionary = {}


static func idle_frames(facing: BirdFacing.Facing) -> SpriteFrames:
	if not _idle_frames.has(facing):
		_idle_frames[facing] = _make_idle_frames(facing)
	return _idle_frames[facing]


static func flight_frames(facing: BirdFacing.Facing) -> SpriteFrames:
	if not _flight_frames.has(facing):
		_flight_frames[facing] = _make_flight_frames(facing)
	return _flight_frames[facing]


static func _make_idle_frames(facing: BirdFacing.Facing) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(IDLE_ANIM)
	frames.set_animation_speed(IDLE_ANIM, 1.0)
	frames.set_animation_loop(IDLE_ANIM, true)

	var texture: Texture2D = IDLE_LEFT_RIGHT
	match facing:
		BirdFacing.Facing.FRONT:
			texture = IDLE_DOWN
		BirdFacing.Facing.BACK:
			texture = IDLE_UP
		_:
			texture = IDLE_LEFT_RIGHT

	frames.add_frame(IDLE_ANIM, texture)
	return frames


static func _make_flight_frames(facing: BirdFacing.Facing) -> SpriteFrames:
	var texture: Texture2D = FLIGHT_LEFT_RIGHT
	match facing:
		BirdFacing.Facing.FRONT:
			texture = FLIGHT_DOWN
		BirdFacing.Facing.BACK:
			texture = FLIGHT_UP
		_:
			texture = FLIGHT_LEFT_RIGHT

	return _from_alpha_strip(texture, FLAP_ANIM, FLAP_FPS, true)


static func _from_alpha_strip(
	texture: Texture2D,
	animation_name: StringName,
	fps: float,
	loop: bool
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	if texture == null:
		push_error("BirdFrames: missing texture for %s" % String(animation_name))
		return frames

	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("BirdFrames: failed to read image for %s" % texture.resource_path)
		return frames

	for frame_rect: Rect2i in _detect_frame_rects(image):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = frame_rect
		frames.add_frame(animation_name, atlas)

	if frames.get_frame_count(animation_name) == 0:
		frames.add_frame(animation_name, texture)

	return frames


static func _detect_frame_rects(image: Image) -> Array[Rect2i]:
	var width := image.get_width()
	var height := image.get_height()
	var rects: Array[Rect2i] = []
	var in_frame := false
	var start_x := 0

	for x in width:
		var column_has_alpha := false
		for y in height:
			if image.get_pixel(x, y).a > 0.01:
				column_has_alpha = true
				break

		if column_has_alpha and not in_frame:
			start_x = x
			in_frame = true
		elif not column_has_alpha and in_frame:
			var frame_width := x - start_x
			if frame_width > 8:
				rects.append(Rect2i(start_x, 0, frame_width, height))
			in_frame = false

	if in_frame:
		var frame_width := width - start_x
		if frame_width > 8:
			rects.append(Rect2i(start_x, 0, frame_width, height))

	return rects
