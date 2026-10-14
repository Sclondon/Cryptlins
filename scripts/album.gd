class_name Album
extends Node
## The photographs at the back of the handbook: one of each kind of cryptlin, in sepia. They are
## taken once, the first time the handbook is opened: one of the kind is stood by itself in a
## little scene of its own in front of a camera, a kind to a frame of the game, and what the
## camera sees is kept as a flat picture. Nothing is left running afterwards.

# A picture has been taken, and is in `prints`
signal taken(kind: int)

# How many pixels across a picture is taken at
const ACROSS := 192
# Which of each kind sits for it, how far it is turned from facing the camera, and how much
# room is left round it
const SEED := 7
const TURNED := 0.55
const MARGIN := 1.14
const TONE: Shader = preload("res://shaders/sepia.gdshader")
const RING := Color(0.34, 0.12, 0.1)
const MOUNT := Color(0.17, 0.14, 0.2, 0.1)

var world: Den
# The picture of each kind, or null for one not taken yet
var prints: Array[Texture2D] = []
var begun := false


func _init(den: Den) -> void:
	world = den
	prints.resize(Cryptlin.KINDS.size())


# Takes them all, those of the kinds in `first` before the rest. It does so only the once, and
# not at all where there is no screen to draw on.
func take(first: Array[int]) -> void:
	if begun or DisplayServer.get_name() == "headless":
		return
	begun = true
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	view.size = Vector2i(ACROSS, ACROSS)
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(view)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 0.6
	var camera := Camera3D.new()
	camera.environment = env
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.add_child(camera)
	camera.rotation = Vector3(-0.14, 0, 0)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.3
	view.add_child(sun)
	sun.look_at_from_position(Vector3(-2, 4, 5), Vector3.ZERO)
	var order: Array[int] = []
	for kind: int in first:
		if not kind in order:
			order.append(kind)
	for kind in prints.size():
		if not kind in order:
			order.append(kind)
	for kind in order:
		var sitter := _sit(view, kind)
		_frame(camera, sitter)
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var shot := view.get_texture().get_image()
		view.remove_child(sitter)
		sitter.queue_free()
		if shot != null and not shot.is_empty():
			prints[kind] = ImageTexture.create_from_image(shot)
			taken.emit(kind)
	view.queue_free()


# One of a kind, grown, stood still in front of the camera and looking into it. It is not left
# to its own devices for a moment: it has no room to be in.
func _sit(view: SubViewport, kind: int) -> Cryptlin:
	var sitter := Cryptlin.new()
	sitter.world = world
	sitter.kind = kind
	sitter.look_seed = SEED
	view.add_child(sitter)
	sitter.set_process(false)
	sitter.position = Vector3.ZERO
	sitter.yaw = TURNED
	sitter.rotation.y = TURNED
	sitter.emote.visible = false
	sitter.gaze = Vector3(0, 0.6, 5.0)
	# (and it is not to blink as the picture is taken)
	sitter.blink = 99.0
	for i in 40:
		sitter._animate(0.05)
	return sitter


# Moves the camera to take in the whole of whoever is sitting, and no more
func _frame(camera: Camera3D, sitter: Node3D) -> void:
	var across := camera.global_basis.x
	var up := camera.global_basis.y
	var low := Vector2(INF, INF)
	var high := -low
	for part: MeshInstance3D in sitter.find_children("*", "MeshInstance3D", true, false):
		if part.mesh == null or not part.is_visible_in_tree():
			continue
		var box := part.mesh.get_aabb()
		for i in 8:
			var corner := part.global_transform * box.get_endpoint(i)
			var at := Vector2(across.dot(corner), up.dot(corner))
			low = low.min(at)
			high = high.max(at)
	if low.x > high.x:
		return
	var mid := (low + high) * 0.5
	camera.size = maxf(high.x - low.x, high.y - low.y) * MARGIN
	camera.global_position = across * mid.x + up * mid.y + camera.global_basis.z * 6.0


# One of the photographs as it is stuck in the handbook, which answers to a tap: with a dark
# ring round it if it is of a kind the keeper has, and faded and with none if not.
class Print:
	extends Button

	const EDGE := 4.0

	var album: Album
	var kind := -1
	var mine := false
	var faint := false
	var picture: TextureRect
	var tone: ShaderMaterial

	func _init(from: Album) -> void:
		album = from
		focus_mode = Control.FOCUS_NONE
		for style_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		picture = TextureRect.new()
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(EDGE))
		tone = ShaderMaterial.new()
		tone.shader = Album.TONE
		picture.material = tone
		picture.visible = false
		add_child(picture)
		album.taken.connect(_taken)

	# Which kind it is of, whether the keeper has one, and whether it is faded (as it is, in the
	# album, if he has none)
	func show_kind(which: int, owned: bool, pale := not owned) -> void:
		kind = which
		mine = owned
		picture.texture = album.prints[kind]
		picture.visible = picture.texture != null
		faint = pale
		tone.set_shader_parameter("faded", 1.0 if faint else 0.0)
		queue_redraw()

	func _taken(which: int) -> void:
		if which == kind:
			show_kind(kind, mine, faint)

	func _draw() -> void:
		var whole := Rect2(Vector2.ZERO, size)
		if mine:
			draw_rect(whole, Album.RING)
		# (the mount, which is all there is to see until its picture has been taken)
		draw_rect(whole.grow(-EDGE), Album.MOUNT if not mine else Color(0.87, 0.82, 0.68))
