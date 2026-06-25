extends RefCounted
class_name FxFramesLoader

const ANIM_NAME := &"default"
const FILTER_2D := CanvasItem.TEXTURE_FILTER_NEAREST
const FILTER_3D := BaseMaterial3D.TEXTURE_FILTER_NEAREST


static func from_png_dir(
	dir_path: String,
	fps: float = 24.0,
	loop: bool = false
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(ANIM_NAME)
	frames.set_animation_speed(ANIM_NAME, fps)
	frames.set_animation_loop(ANIM_NAME, loop)

	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("FxFramesLoader: cannot open %s" % dir_path)
		return frames

	var png_files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			png_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	png_files.sort()

	for png in png_files:
		var texture := load("%s/%s" % [dir_path, png]) as Texture2D
		if texture != null:
			frames.add_frame(ANIM_NAME, texture)

	return frames
