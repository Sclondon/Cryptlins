class_name Shelf
extends Control
## Everything the keeper has, as the things themselves, floating in a row along the bottom of
## the screen with the room showing between them. The row slides sideways under a finger. Den
## reads the touches and asks this which item is where. It is its own little 3D scene with
## nothing behind it, drawn small and blown up like the room.

const GAP := 0.4
const TALL := 1.15
# Screen units to one pixel of the shelf's picture
const COARSE := 2.0

var view: SubViewport
var camera: Camera3D
var overlay: Control
var row: Node3D
var ids: Array[String] = []
var spots: Array[float] = []
var holders: Array[Node3D] = []
# By item id: "heart" or "cross" for what is known of the cryptlin's tastes, how many are left of
# things that get used up, and which are out in the tank just now
var marks := {}
var counts := {}
var out := {}
var scroll := 0.0
var speed := 0.0
var held := false
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	view.size = Vector2i(64, 32)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.85)
	env.ambient_light_energy = 0.45
	camera = Camera3D.new()
	camera.environment = env
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = TALL
	camera.near = 0.1
	camera.far = 20.0
	view.add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.25
	view.add_child(sun)
	sun.look_at_from_position(Vector3(-2, 4, 5), Vector3.ZERO)
	row = Node3D.new()
	view.add_child(row)

	var post := ShaderMaterial.new()
	post.shader = load("res://shaders/ps1_float.gdshader")
	var picture := TextureRect.new()
	picture.texture = view.get_texture()
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.material = post
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_paint)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit)
	_fit()


# Puts these items on the shelf, in this order, with a gap wherever the group changes
func stock(items: Array[String]) -> void:
	if items == ids:
		return
	for h in holders:
		h.queue_free()
	holders.clear()
	spots.clear()
	ids = items.duplicate()
	var x := 0.0
	var group := ""
	for id in ids:
		var g: String = Items.find(id)["group"]
		if group != "":
			x += 1.0 + (GAP if g != group else 0.0)
		group = g
		var holder := Items.model(id)
		var stand := Node3D.new()
		stand.position.x = x
		stand.add_child(holder)
		row.add_child(stand)
		holders.append(stand)
		spots.append(x)
	_limit()


func _fit() -> void:
	if view == null:
		return
	view.size = Vector2i(maxi(int(size.x / COARSE), 8), maxi(int(size.y / COARSE), 8))
	_limit()


# Screen units to one unit of the shelf's own space
func _unit() -> float:
	return maxf(size.y, 1.0) / TALL


func _span() -> float:
	return size.x / _unit()


func _limit() -> void:
	if spots.is_empty():
		return
	var low := spots[0] - 0.7
	var high := spots[spots.size() - 1] + 0.7 - _span()
	if high < low:
		# Everything fits: keep it in the middle
		low = (low + high) * 0.5
		high = low
	if scroll < low or scroll > high:
		speed = 0.0
	scroll = clampf(scroll, low, high)


func can_scroll(way: float) -> bool:
	if spots.is_empty():
		return false
	if way < 0.0:
		return scroll > spots[0] - 0.65
	return scroll < spots[spots.size() - 1] + 0.65 - _span()


# The item under a point on the screen, or "" for none
func item_at(at: Vector2) -> String:
	var x := scroll + (at.x - global_position.x) / _unit()
	for i in spots.size():
		if absf(spots[i] - x) < 0.5:
			return ids[i]
	return ""


func has_point(at: Vector2) -> bool:
	return visible and get_global_rect().has_point(at)


func grab() -> void:
	held = true
	speed = 0.0


# Slid along by a finger that moved this far across the screen
func drag(by: float, delta: float) -> void:
	var moved := -by / _unit()
	scroll += moved
	if delta > 0.0:
		speed = lerpf(speed, moved / delta, 0.5)
	_limit()


func let_go() -> void:
	held = false


# Slides along until this item is in view (for the tests, and for showing off something new)
func show_item(id: String) -> void:
	var i := ids.find(id)
	if i >= 0:
		scroll = spots[i] - _span() * 0.5
		speed = 0.0
		_limit()


func _process(delta: float) -> void:
	t += delta
	if not held and absf(speed) > 0.01:
		scroll += speed * delta
		speed = move_toward(speed, 0.0, delta * (3.0 + absf(speed) * 2.0))
		_limit()
	camera.position = Vector3(scroll + _span() * 0.5, 1.25, 3.0)
	camera.rotation = Vector3(-0.3, 0, 0)
	# Each thing turns a little and bobs where it hangs, to show its shape
	for i in holders.size():
		holders[i].rotation.y = 0.35 + sin(t * 0.9 + i * 1.7) * 0.4
		holders[i].position.y = 0.06 + sin(t * 1.3 + i * 2.3) * 0.03
	overlay.queue_redraw()


# What is drawn sharp over the picture: the marks, and a hint of more either side
func _paint() -> void:
	var w := overlay.size.x
	var h := overlay.size.y
	var font := get_theme_default_font()
	var unit := _unit()
	for i in ids.size():
		var x := (spots[i] - scroll) * unit
		if x < -unit or x > w + unit:
			continue
		var id := ids[i]
		if out.get(id, false):
			overlay.draw_circle(Vector2(x, h - 9.0), 4.0, Icons.AMBER)
		if marks.has(id):
			Icons.paint(overlay, marks[id], Vector2(x + unit * 0.3, h * 0.2), h * 0.085)
		if counts.has(id):
			overlay.draw_string_outline(font, Vector2(x + unit * 0.14, h - 8.0), "x%d" % counts[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0, 0, 0, 0.8))
			overlay.draw_string(font, Vector2(x + unit * 0.14, h - 8.0), "x%d" % counts[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Icons.BONE)
	for way: float in [-1.0, 1.0]:
		if can_scroll(way):
			var c := Vector2(14.0 if way < 0.0 else w - 14.0, h * 0.5)
			overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(7 * way, 0), c + Vector2(-5 * way, -10), c + Vector2(-5 * way, 10)]), Color(Icons.AMBER, 0.55))


# Where on the screen an item stands (the middle of it), sliding the shelf along first if it is out of view
func point_of(id: String) -> Vector2:
	var i := ids.find(id)
	if i < 0:
		return Vector2(-1, -1)
	var x := (spots[i] - scroll) * _unit()
	if x < _unit() * 0.5 or x > size.x - _unit() * 0.5:
		show_item(id)
		x = (spots[i] - scroll) * _unit()
	return global_position + Vector2(x, size.y * 0.5)
