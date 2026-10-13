class_name Shelf
extends Control
## The shelf of things, which is a wheel: everything the keeper has, as the things themselves,
## riding the rim of a big wheel whose hub is below the bottom of the screen. Only the top of the
## rim shows: the middle thing highest and nearest, its neighbours lower and turned away, the
## rest sinking off the bottom corners. A finger turns it. No wheel is drawn, only the floating
## things, with the room showing between them. Den reads the touches and asks this which item is
## where. It is its own little 3D scene with nothing behind it, drawn small and blown up like
## the room.

# How far apart two neighbours ride along the rim, and how much further where the group changes
const PITCH := 0.92
const GAP := 0.4
const TALL := 1.15
# How far below the top edge the middle thing hangs, and how far the rim has dropped by the time
# it reaches the side of the screen (which makes the wheel as big as the screen is wide)
const CREST := 0.52
const SINK := 1.1
# How far out from the rim a finger still counts as on the wheel
const REACH := 0.56
# How far round from the top a thing has gone under, and is not drawn
const UNDER := 1.7
# Screen units to one pixel of the shelf's picture
const COARSE := 2.0

var view: SubViewport
var camera: Camera3D
var overlay: Control
var rim: Node3D
var ids: Array[String] = []
# How far round the rim each thing rides, counted in neighbours from the first
var spots: Array[float] = []
var stands: Array[Node3D] = []
# How far each is from its place just now, sliding round to it after the things on the wheel have
# changed, and how much of its size a thing new to the wheel has grown to (0 to 1)
var slips: Array[float] = []
var fresh: Array[float] = []
# What has left the wheel and is shrinking away where it rode: its stand, where that is on the
# rim, and how much of its size is left
var going: Array[Dictionary] = []
# By item id: "heart" or "cross" for what is known of the cryptlin's tastes, how many are left of
# things that get used up, and which are in use just now (the scanner, while it is pointed)
var marks := {}
var counts := {}
var out := {}
# Which spot is at the top of the wheel, and how fast that is changing
var turn := 0.0
var speed := 0.0
# The thing that asks to be picked up just now ("" for none): it bobs higher than the rest,
# turns right round, and glints
var beckon := ""
# The thing the wheel is turning to show, because a finger is bringing it back to put it away
# ("" for none): it comes round to the top, and bobs and turns there like one that beckons
var sought := ""
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
	camera.position = Vector3(0, 0, 4.0)
	view.add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.25
	view.add_child(sun)
	sun.look_at_from_position(Vector3(-2, 4, 5), Vector3.ZERO)
	rim = Node3D.new()
	view.add_child(rim)

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


# Puts these items on the wheel, in this order, with a gap wherever the group changes. What was
# on it and is not any more shrinks away where it rode, the rest slide round to close the gap,
# and what is new grows in at its place; the wheel stays with whatever was nearest the top.
func stock(items: Array[String]) -> void:
	if items == ids:
		return
	var first := ids.is_empty()
	var rode := {}
	var had := {}
	var grown := {}
	var anchor := ""
	for i in ids.size():
		var id := ids[i]
		rode[id] = _at(i)
		if not items.has(id):
			going.append({"stand": stands[i], "at": rode[id], "left": fresh[i]})
			continue
		had[id] = stands[i]
		grown[id] = fresh[i]
		if anchor == "" or absf(rode[id] - turn) < absf(rode[anchor] - turn):
			anchor = id
	var turned := turn
	stands.clear()
	spots.clear()
	slips.clear()
	fresh.clear()
	ids = items.duplicate()
	var at := 0.0
	var group := ""
	for id in ids:
		var g: String = Items.find(id)["group"]
		if group != "":
			at += 1.0 + (GAP if g != group else 0.0)
		group = g
		if had.has(id):
			stands.append(had[id])
			fresh.append(grown[id])
		else:
			# The stand rides the rim; the thing hangs in it by its middle, free to turn
			var stand := Node3D.new()
			var spin := Node3D.new()
			spin.add_child(Items.model(id))
			stand.add_child(spin)
			rim.add_child(stand)
			stands.append(stand)
			fresh.append(1.0 if first else 0.0)
		spots.append(at)
		slips.append(0.0)
	if anchor != "":
		turn += spots[ids.find(anchor)] - rode[anchor]
	_limit()
	for i in ids.size():
		if had.has(ids[i]):
			slips[i] = rode[ids[i]] - turned + turn - spots[i]
	for gone in going:
		gone["at"] += turn - turned
	_place()


func _fit() -> void:
	if view == null:
		return
	view.size = Vector2i(maxi(int(size.x / COARSE), 8), maxi(int(size.y / COARSE), 8))
	_limit()


# Screen units to one unit of the shelf's own space
func _unit() -> float:
	return maxf(size.y, 1.0) / TALL


# The wheel's radius: big enough that the rim leaves the screen by its bottom corners
func _radius() -> float:
	var half := size.x * 0.5 / _unit()
	return maxf((half * half + SINK * SINK) / (2.0 * SINK), 1.6)


# The angle between two neighbours on the rim
func _step() -> float:
	return PITCH / _radius()


# Where on the rim an item is just now, counted in neighbours from the first
func _at(i: int) -> float:
	return spots[i] + slips[i]


# How far round from the top an item is just now, clockwise
func _angle(i: int) -> float:
	return (_at(i) - turn) * _step()


# The hub, in this control's own space: below the bottom edge
func _hub() -> Vector2:
	return Vector2(size.x * 0.5, (CREST + _radius()) * _unit())


# Where an item is just now (the middle of it), in this control's own space
func _seat(i: int) -> Vector2:
	var a := _angle(i)
	return _hub() + Vector2(sin(a), -cos(a)) * _radius() * _unit()


# How big an item is drawn: the lower it has sunk, the further off and the smaller
func _size_at(a: float) -> float:
	return 1.14 - 0.4 * clampf(_radius() * (1.0 - cos(a)) / TALL, 0.0, 1.0)


# It stops with the first thing at the top one way, and the last the other
func _limit() -> void:
	if spots.is_empty():
		return
	var last := spots[spots.size() - 1]
	if turn < 0.0 or turn > last:
		speed = 0.0
	turn = clampf(turn, 0.0, last)


# The item nearest to somewhere on the rim: by where its place is, or by where it is `drawn` just now
func _nearest(spot: float, drawn := false) -> int:
	var best := -1
	for i in spots.size():
		var off := absf((_at(i) if drawn else spots[i]) - spot)
		if best < 0 or off < absf((_at(best) if drawn else spots[best]) - spot):
			best = i
	return best


func can_scroll(way: float) -> bool:
	if spots.is_empty():
		return false
	if way < 0.0:
		return turn > 0.3
	return turn < spots[spots.size() - 1] - 0.3


# The item under a point on the screen, or "" for none: the one whose place on the rim is
# nearest, which gives the few at the top a wide target each
func item_at(at: Vector2) -> String:
	if spots.is_empty():
		return ""
	var from_hub := at - global_position - _hub()
	var spot := turn + atan2(from_hub.x, -from_hub.y) / _step()
	var i := _nearest(spot, true)
	return ids[i] if absf(_at(i) - spot) < 0.5 + GAP * 0.5 else ""


# Whether a point on the screen is on the wheel: what is above the rim is the room
func has_point(at: Vector2) -> bool:
	if not visible or not get_global_rect().has_point(at):
		return false
	return (at - global_position).distance_to(_hub()) < (_radius() + REACH) * _unit()


# Turns, of itself, to bring this item to the top and keep it there ("" to leave off)
func bring(id: String) -> void:
	sought = id
	if id != "":
		speed = 0.0


func grab() -> void:
	sought = ""
	held = true
	speed = 0.0


# Turned by a finger that moved this far across the screen
func drag(by: float, delta: float) -> void:
	var moved := -by / _unit() / PITCH
	turn += moved
	if delta > 0.0:
		speed = lerpf(speed, moved / delta, 0.5)
	_limit()


func let_go() -> void:
	held = false


# Turns until this item is at the top (for the tests, and for showing off something new)
func show_item(id: String) -> void:
	var i := ids.find(id)
	if i >= 0:
		turn = spots[i]
		speed = 0.0
		slips.fill(0.0)
		fresh.fill(1.0)
		_place()


func _process(delta: float) -> void:
	t += delta
	if not held and not spots.is_empty():
		if absf(speed) > 0.5:
			turn += speed * delta
			speed = move_toward(speed, 0.0, delta * (3.0 + absf(speed) * 2.0))
			_limit()
		else:
			# Let go, it runs down and comes to rest with a thing at the top
			speed = 0.0
			turn = lerpf(turn, spots[ids.find(sought) if ids.has(sought) else _nearest(turn)], 1.0 - exp(-delta * 9.0))
	# The things close up where one has gone, and make room where one has come
	for i in slips.size():
		slips[i] = 0.0 if absf(slips[i]) < 0.002 else lerpf(slips[i], 0.0, 1.0 - exp(-delta * 10.0))
		fresh[i] = minf(fresh[i] + delta * 5.0, 1.0)
	for gone in going.duplicate():
		gone["left"] -= delta * 6.0
		if gone["left"] <= 0.0:
			gone["stand"].queue_free()
			going.erase(gone)
	_place()
	overlay.queue_redraw()


# Stands each thing where it rides just now: leaning with the rim, turned away from the middle,
# tipped a little towards the eye to show its top, and bobbing where it hangs to show its shape
func _place() -> void:
	var radius := _radius()
	var hub := Vector3(0, TALL * 0.5 - CREST - radius, 0)
	for i in stands.size():
		var a := _angle(i)
		var stand := stands[i]
		# (what has gone under is not drawn: there is more than one turn of the wheel of it)
		stand.visible = absf(a) < UNDER
		if not stand.visible:
			continue
		stand.position = hub + Vector3(sin(a) * radius, cos(a) * radius, cos(a))
		stand.basis = (Basis(Vector3.BACK, -a) * Basis(Vector3.RIGHT, 0.3)).scaled(Vector3.ONE * _size_at(a) * maxf(fresh[i], 0.01))
		var spin: Node3D = stand.get_child(0)
		spin.position.y = -0.3 + sin(t * 1.3 + i * 2.3) * 0.03
		spin.rotation.y = 0.35 + a * 0.9 + sin(t * 0.9 + i * 1.7) * 0.35
		if ids[i] == beckon or ids[i] == sought:
			spin.position.y = -0.3 + absf(sin(t * 3.2)) * 0.12
			spin.rotation.y = t * 2.4
	for gone in going:
		var a: float = (gone["at"] - turn) * _step()
		var stand: Node3D = gone["stand"]
		stand.visible = absf(a) < UNDER
		stand.position = hub + Vector3(sin(a) * radius, cos(a) * radius, cos(a))
		stand.basis = (Basis(Vector3.BACK, -a) * Basis(Vector3.RIGHT, 0.3)).scaled(Vector3.ONE * _size_at(a) * maxf(gone["left"], 0.01))


# What is drawn sharp over the picture: the marks, each going round with its thing, and a hint
# of more either side
func _paint() -> void:
	var w := overlay.size.x
	var h := overlay.size.y
	var font := get_theme_default_font()
	for i in ids.size():
		if not stands[i].visible or fresh[i] < 0.6:
			continue
		var at := _seat(i)
		var reach := _unit() * _size_at(_angle(i))
		if at.x < -reach or at.x > w + reach or at.y > h + reach:
			continue
		var id := ids[i]
		if id == beckon:
			# A four-pointed glint that comes and goes at its shoulder
			var spark := at + Vector2(reach * 0.26, -reach * 0.3 - absf(sin(t * 3.2)) * reach * 0.12)
			var big := reach * 0.16 * maxf(sin(t * 5.0), 0.0)
			if big > 1.0:
				overlay.draw_colored_polygon(PackedVector2Array([spark + Vector2(0, -big), spark + Vector2(big * 0.22, -big * 0.22), spark + Vector2(big, 0), spark + Vector2(big * 0.22, big * 0.22), spark + Vector2(0, big), spark + Vector2(-big * 0.22, big * 0.22), spark + Vector2(-big, 0), spark + Vector2(-big * 0.22, -big * 0.22)]), Icons.BONE)
		if out.get(id, false):
			overlay.draw_circle(at + Vector2(0, reach * 0.46), 4.0, Icons.AMBER)
		if marks.has(id):
			Icons.paint(overlay, marks[id], at + Vector2(reach * 0.3, -reach * 0.3), h * 0.085)
		if counts.has(id):
			var corner := at + Vector2(reach * 0.14, reach * 0.42)
			overlay.draw_string_outline(font, corner, "x%d" % counts[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0, 0, 0, 0.8))
			overlay.draw_string(font, corner, "x%d" % counts[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Icons.BONE)
	for way: float in [-1.0, 1.0]:
		if can_scroll(way):
			var c := Vector2(w * 0.5 + way * (w * 0.5 - 14.0), h * 0.3)
			overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(7 * way, 0), c + Vector2(-5 * way, -10), c + Vector2(-5 * way, 10)]), Color(Icons.AMBER, 0.55))


# Where on the screen an item is just now (the middle of it), or off the screen if it is not on
# the top half of the wheel
func where(id: String) -> Vector2:
	var i := ids.find(id)
	return global_position + _seat(i) if i >= 0 and absf(_angle(i)) < UNDER else Vector2(-1, -1)


# Where on the screen an item is, turning the wheel to bring it to the top first if it is not
# among the few up there that a finger can get at whole
func point_of(id: String) -> Vector2:
	var i := ids.find(id)
	if i < 0:
		return Vector2(-1, -1)
	var at := _seat(i)
	var room := _unit() * 0.4
	# (nor if it has gone right under: far enough round, its place comes up the other side)
	if at.x < room or at.x > size.x - room or at.y > size.y - room or absf(_angle(i)) >= UNDER:
		show_item(id)
	return where(id)
