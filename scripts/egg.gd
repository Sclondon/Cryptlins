class_name Egg
extends Node3D
## The egg a cryptlin comes out of. Lamplight warms it slowly and a rubbing finger warms it fast;
## it cracks twice on the way and hatches when it is warm through. What is painted on its shell
## tells you what is inside.

signal cracked(stage: int)
signal hatched

const WIDTH := 0.27
const HEIGHT := 0.36
const CENTRE := Vector3(0, 0.34, 0)
const RADII := Vector3(WIDTH, HEIGHT, WIDTH)
const SIZE := 1.25
# One for each kind of cryptlin (Cryptlin.Kind)
const SHELLS: Array[Color] = [
	Color(0.42, 0.52, 0.3), Color(0.34, 0.28, 0.21), Color(0.56, 0.5, 0.4), Color(0.4, 0.4, 0.44), Color(0.3, 0.36, 0.3),
	Color(0.26, 0.44, 0.24), Color(0.22, 0.36, 0.44), Color(0.36, 0.36, 0.38), Color(0.2, 0.2, 0.24),
	Color(0.14, 0.2, 0.22), Color(0.18, 0.4, 0.42), Color(0.2, 0.32, 0.26), Color(0.62, 0.52, 0.4), Color(0.78, 0.6, 0.85),
	Color(0.68, 0.14, 0.1), Color(0.55, 0.45, 0.32), Color(0.1, 0.14, 0.22), Color(0.62, 0.72, 0.82), Color(0.13, 0.11, 0.12),
	Color(0.36, 0.27, 0.2), Color(0.88, 0.88, 0.84), Color(0.2, 0.2, 0.5), Color(0.4, 0.28, 0.18),
	Color(0.1, 0.19, 0.16), Color(0.33, 0.16, 0.13), Color(0.62, 0.1, 0.08),
	Color(0.74, 0.58, 0.36),
	Color(0.4, 0.44, 0.5),
	Color(0.4, 0.12, 0.1),
	Color(0.8, 0.5, 0.52),
]
const MARKS: Array[Color] = [
	Color(0.2, 0.3, 0.15), Color(0.2, 0.16, 0.12), Color(0.5, 0.18, 0.1), Color(0.6, 0.58, 0.56), Color(0.45, 0.14, 0.1),
	Color(0.5, 0.6, 0.3), Color(0.5, 0.66, 0.7), Color(0.2, 0.2, 0.22), Color(0.85, 0.82, 0.72),
	Color(0.1, 0.32, 0.2), Color(0.5, 0.75, 0.7), Color(0.4, 0.3, 0.46), Color(0.66, 0.1, 0.08), Color(1.0, 0.95, 0.7),
	Color(0.9, 0.87, 0.78), Color(0.9, 0.87, 0.8), Color(0.4, 1.0, 0.5), Color(0.95, 0.97, 1.0), Color(0.62, 0.1, 0.08),
	Color(0.17, 0.12, 0.09), Color(0.3, 0.32, 0.38), Color(0.92, 0.72, 0.22), Color(0.16, 0.1, 0.07),
	Color(0.8, 0.14, 0.1), Color(0.82, 0.76, 0.62), Color(0.3, 0.04, 0.05),
	Color(0.56, 0.24, 0.1),
	Color(0.14, 0.18, 0.28),
	Color(0.1, 0.07, 0.08),
	Color(0.94, 0.84, 0.8),
]
const TITLES: Array[String] = [
	"A mossy egg", "A streaky egg", "A speckled egg", "A silk-wound egg", "A thorn-patterned egg",
	"A slimy egg", "A rippled egg", "A stone egg", "A frost-bitten egg",
	"A weed-streaked egg", "A scaly egg", "A sucker-ringed egg", "A red-capped egg", "A glimmering egg",
	"A toadstool egg", "A dappled egg", "A starry egg", "A frosted egg", "An ember-veined egg",
	"A tunnelled egg", "A long-shanked egg", "A gold-braided egg", "A bristly egg",
	"A spade-marked egg", "A hoof-printed egg", "A banded egg",
	"A shaggy egg",
	"A moon-pale egg",
	"A leathery egg",
	"A scalloped egg",
]
# How much of its own light each shell gives off, and how wide and how tall it is next to the usual
const GLOWS: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.35, 0.0, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12, 0.0, 0.0]
const SHAPES: Array[Vector2] = [
	Vector2(1.0, 1.0), Vector2(1.06, 1.04), Vector2(0.96, 0.98), Vector2(0.95, 1.06), Vector2(0.94, 1.04),
	Vector2(1.06, 0.94), Vector2(1.0, 1.06), Vector2(1.08, 0.96), Vector2(0.92, 1.08),
	Vector2(0.96, 1.06), Vector2(1.02, 1.0), Vector2(1.06, 0.98), Vector2(1.04, 0.94), Vector2(0.9, 0.96),
	Vector2(1.08, 0.92), Vector2(1.0, 0.94), Vector2(0.94, 1.08), Vector2(1.08, 1.06), Vector2(1.04, 1.0),
	Vector2(1.08, 0.95), Vector2(0.9, 1.1), Vector2(0.98, 1.02), Vector2(1.1, 0.95),
	Vector2(0.94, 1.1), Vector2(0.98, 1.04), Vector2(1.0, 1.1),
	Vector2(1.1, 0.97),
	Vector2(0.95, 1.08),
	Vector2(0.94, 1.1),
	Vector2(1.04, 0.96),
]

var world: Den
var kind := 0
var look_seed := 1
var warmth := 0.0
var stage := 0
var landed := true
var fall := 0.0
var rock := Vector2.ZERO
var rock_v := Vector2.ZERO
var stir := 2.0
var last_rub := -10.0
var t := 0.0
var hatching := -1.0
var shell: Node3D
var cracks: Array[Node3D] = []
# Where the blotches on its shell are, for the kinds that have them: across, down, and how big
var blots: Array[Vector3] = []
var peek: MeshInstance3D
var shards: CPUParticles3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	scale = Vector3.ONE * SIZE
	shell = Node3D.new()
	add_child(shell)
	# The shell is a plain egg, a little rounder or taller by its kind, told apart by what is
	# painted on it
	shell.scale = Vector3(SHAPES[kind].x, SHAPES[kind].y, SHAPES[kind].x)
	blots.clear()
	for i in 12:
		blots.append(Vector3(rng.randi() % 64, rng.randi_range(3, 28), rng.randf_range(2.0, 4.5)))
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 64:
			img.set_pixel(x, y, _paint(x, y))
	var base := Ps1.mat(Color.WHITE, GLOWS[kind], 0.0, ImageTexture.create_from_image(img))
	_part(Ps1.ball(), base, CENTRE, RADII)

	# The cracks, made ahead of time and shown as it warms
	var black := Ps1.flat(Color(0.02, 0.01, 0.02))
	var first: Array[Vector3] = [_on(-1.0, 0.25), _on(-0.7, 0.05), _on(-0.45, 0.3), _on(-0.2, 0.1)]
	var second: Array[Vector3] = [_on(-0.2, 0.1), _on(0.05, 0.38), _on(0.3, 0.12), _on(0.55, 0.36), _on(0.85, 0.15)]
	var branch: Array[Vector3] = [_on(0.05, 0.38), _on(-0.05, 0.7), _on(0.15, 0.9)]
	cracks = [_crack(black, [first]), _crack(black, [second, branch])]
	# Through the second crack, an eye
	var hole := _on(0.3, 0.6)
	var out := _normal(hole)
	var dark := _part(Ps1.ball(), black, hole, Vector3.ONE, Vector3.ZERO, cracks[1])
	dark.basis = Basis.looking_at(-out).scaled_local(Vector3(0.075, 0.06, 0.012))
	var eye_colour := Cryptlin.colours(kind, look_seed)[1]
	peek = _part(Ps1.ball(), Ps1.mat(eye_colour, 0.85), hole + out * 0.01, Vector3.ONE * 0.036, Vector3.ZERO, cracks[1])
	stage = clampi(int(warmth / 34.0), 0, 2)
	for i in cracks.size():
		cracks[i].visible = i < stage

	var bit := BoxMesh.new()
	bit.size = Vector3(0.09, 0.02, 0.07)
	bit.material = base
	shards = CPUParticles3D.new()
	shards.mesh = bit
	shards.one_shot = true
	shards.emitting = false
	shards.amount = 14
	shards.lifetime = 0.9
	shards.explosiveness = 1.0
	shards.direction = Vector3.UP
	shards.spread = 70.0
	shards.initial_velocity_min = 1.6
	shards.initial_velocity_max = 3.4
	shards.angular_velocity_min = -400.0
	shards.angular_velocity_max = 400.0
	shards.gravity = Vector3(0, -9, 0)
	shards.position = CENTRE
	add_child(shards)


func _part(mesh: Mesh, mat: Material, at: Vector3, size := Vector3.ONE, turn := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.scale = size
	mi.rotation = turn
	(shell if parent == null else parent).add_child(mi)
	return mi


# The colour of one dot of the shell's picture, 64 round by 32 from top to bottom
func _paint(x: int, y: int) -> Color:
	var shell_colour := SHELLS[kind]
	var mark := MARKS[kind]
	# A scatter that looks like chance and is the same every time
	var chance := (x * 37 + y * 101 + x * y * 7) % 23
	match kind:
		Cryptlin.Kind.GREMLIN:
			# Moss in patches, and the odd wart
			if _blot(x, y) < 1.0:
				return mark
			return shell_colour.darkened(0.35) if chance == 0 else shell_colour
		Cryptlin.Kind.SQUATCH:
			# Streaked from top to bottom like wet hair
			return mark if (x * 5 + (y / 4) * 7) % 4 == 0 else (shell_colour.lightened(0.12) if (x + y / 5) % 5 == 0 else shell_colour)
		Cryptlin.Kind.COCKATRICE:
			return mark if chance < 2 else shell_colour
		Cryptlin.Kind.MOTHMAN:
			# Wound round and round with silk
			return mark if (y + x / 3) % 5 == 0 else shell_colour
		Cryptlin.Kind.CHUPACABRA:
			# Rows of thorns, drawn on
			return mark if absi(x % 8 - 4) < (y % 10) - 5 else shell_colour
		Cryptlin.Kind.FROGMAN:
			# Wet blotches, with a shine on each
			var wet := _blot(x, y)
			if wet < 0.35:
				return mark.lightened(0.3)
			return mark if wet < 1.3 else shell_colour
		Cryptlin.Kind.NESSIE:
			# Ripples
			return mark if (y + int(sin(x * 0.4) * 2.0) + 32) % 6 == 0 else shell_colour
		Cryptlin.Kind.BOLTER:
			# Grey stone in slabs, cracked across and pitted
			if chance == 0:
				return mark
			return shell_colour.lerp(shell_colour.lightened(0.14), float((x / 9 + y / 7) % 2)) if (x + y / 2) % 9 != 0 else mark
		Cryptlin.Kind.WENDIGO:
			# Bone-pale at the crown, and frost creeping up from under it
			if y < 5 + (x * 3) % 3:
				return mark
			return Color(0.5, 0.6, 0.68) if y > 13 and chance < y - 13 else shell_colour
		Cryptlin.Kind.KELPIE:
			# Weed hanging down it from the top, each strand its own length
			var strand := 9 + (x / 3 * 11) % 16
			if y < strand and x % 3 != 2:
				return mark if (x / 3) % 2 == 0 else mark.lightened(0.18)
			return Color(0.4, 0.6, 0.7) if chance == 0 else shell_colour
		Cryptlin.Kind.MERFOLK:
			# Scales, each lapped over the one below
			var row := y / 6
			var along := (x + (row % 2) * 4) % 8 - 4
			var edge := Vector2(along, y % 6).length()
			return mark if edge > 3.2 and edge < 4.4 else (shell_colour.lightened(0.15) if edge < 1.6 else shell_colour)
		Cryptlin.Kind.SPAWN:
			# Rings like the marks of suckers, in wandering rows
			var ring := Vector2((x + (y / 8) * 3) % 8 - 4, (y + int(sin(x * 0.2) * 2.0) + 32) % 8 - 4).length()
			return mark if ring > 1.6 and ring < 2.8 else shell_colour
		Cryptlin.Kind.GNOME:
			# Clay below, and a red cap painted on above with a stitched edge
			var brim := 11 + int(sin(x * 0.6) * 1.5)
			if y < brim:
				return mark
			if y == brim + 1 and x % 3 != 0:
				return Color(0.9, 0.86, 0.74)
			return shell_colour.darkened(0.25) if chance == 0 else shell_colour
		Cryptlin.Kind.FAE:
			# Soft colours running into one another, and sparks
			if chance == 0 or (chance == 11 and x % 2 == 0):
				return mark
			return shell_colour.lerp(Color(0.6, 0.8, 0.95), sin(x * 0.3 + y * 0.25) * 0.5 + 0.5)
		Cryptlin.Kind.FUNGUS:
			# A toadstool's spots
			return mark if _blot(x, y) < 0.9 else shell_colour
		Cryptlin.Kind.JACKALOPE:
			# Dappled like a leveret, paler underneath
			if y > 22 + (x * 5) % 3:
				return mark
			return shell_colour.lightened(0.22) if _blot(x, y) < 0.7 or chance < 2 else shell_colour
		Cryptlin.Kind.ALIEN:
			# The night sky, with a row of lights round the middle that no bird put there
			if y == 16 and x % 8 < 2:
				return mark
			if chance == 0:
				return Color(0.95, 0.95, 0.8)
			return shell_colour.lerp(Color(0.2, 0.12, 0.3), sin(x * 0.2 + y * 0.3) * 0.5 + 0.5)
		Cryptlin.Kind.YETI:
			# Snow on top, and frost the rest of the way down
			if y < 9 + (x * 7) % 4:
				return mark
			return mark.lerp(shell_colour, 0.4) if chance < 3 else shell_colour
		Cryptlin.Kind.CERBERUS:
			# Black, with fire showing through the cracks in it
			var vein := absi(y - 16 - (absi(x % 16 - 8) - 4))
			if vein == 0 or (x % 16 == 5 and y > 6 and y < 13) or (x % 16 == 12 and y > 19 and y < 27):
				return Color(1.0, 0.5, 0.12)
			return mark.darkened(0.5) if vein == 1 else shell_colour
		Cryptlin.Kind.MOLE:
			# Packed earth with stones in it, and the dark runs of tunnels through it
			var run := (y + int(sin(x * 0.35 + (y / 11) * 2.0) * 3.0) + 32) % 11
			if run == 0 or (run == 1 and x % 7 < 4):
				return mark
			return Color(0.55, 0.5, 0.44) if chance == 0 else (shell_colour.lightened(0.1) if chance < 4 else shell_colour)
		Cryptlin.Kind.NIGHTCRAWLER:
			# Chalk white, with pairs of long legs walking round it, a dot of a head on each
			var across := x % 16 - 8
			if y >= 10 and y <= 25 and absi(across) == 1 + (y - 10) / 5:
				return mark
			if y >= 7 and y <= 9 and absi(across) <= 1:
				return mark
			return shell_colour.darkened(0.08) if chance == 0 else shell_colour
		Cryptlin.Kind.MONKEY:
			# A bellhop's jacket: gold braid round it top and bottom, and two rows of buttons
			if y == 8 or y == 9 or y == 23 or y == 24 or y < 3:
				return mark
			if y > 11 and y < 21 and y % 4 == 0 and x % 16 in [5, 10]:
				return mark
			return Color(0.6, 0.1, 0.12) if y > 9 and y < 23 and x % 16 > 5 and x % 16 < 10 else shell_colour
		Cryptlin.Kind.BOAR:
			# Bristles all over it, and the pale stripes of a young boar down its length
			if (x * 7 + (y / 3) * 13) % 11 == 0:
				return mark
			return shell_colour.lightened(0.28) if (x + int(sin(y * 0.5) * 1.5) + 64) % 16 < 3 else shell_colour
		Cryptlin.Kind.FLATWOODS:
			# Dark and pleated like its skirt, with the ace of spades in red round the middle
			var across := absi((x + 16) % 32 - 16)
			if y >= 6 and y <= 19 and across <= mini((y - 6) * 3 / 5, 7) and not (y == 19 and across < 2):
				return mark
			if (y >= 19 and y <= 23 and across <= 1) or (y == 24 and across <= 3):
				return mark
			return shell_colour.lightened(0.14) if x % 4 == 0 else shell_colour
		Cryptlin.Kind.DEVIL:
			# The prints of a cloven hoof going up and round it, as on a roof after snow
			var row := y / 8
			var across := (x + row * 5) % 12 - 6
			var down := y % 8
			if down >= 2 and down <= 5 and (absi(across) == 2 or (absi(across) == 1 and down >= 3)):
				return mark
			return shell_colour.darkened(0.25) if chance == 0 else shell_colour
		Cryptlin.Kind.WORM:
			# Red, in rings from one end to the other
			if y % 5 == 0:
				return mark
			return shell_colour.lightened(0.16) if y % 5 == 2 else shell_colour
		Cryptlin.Kind.YOWIE:
			# Sand, with rust-red hair hanging down it in three ragged rows
			var hang := (y + 3) % 10
			if hang < 3 + (x * 7 + (y / 10) * 5) % 5:
				return mark if (x + y / 10) % 3 != 0 else mark.lightened(0.2)
			return shell_colour.darkened(0.1) if chance == 0 else shell_colour
		Cryptlin.Kind.KANGAROO:
			# Ash, with the long prints of a pair of feet going round it in hops, and a gap where
			# one hop in three ought to have come down
			var along := x % 12
			var hop := x / 12
			if hop % 3 != 2 and y >= 17 and y <= 25 and along in [2, 3, 7, 8] and (y < 23 or along < 4):
				return mark
			if hop % 3 != 2 and y == 9 + absi(along - 5) and along % 3 != 0:
				return mark.lightened(0.3)
			return shell_colour.lightened(0.1) if chance < 2 else shell_colour
		Cryptlin.Kind.KONGAMATO:
			# Red leather, creased, with the long dark fingers of a wing spread down it from the top
			var finger := (x + 64 - y / 3) % 16
			if finger == 0 or (finger == 15 and y > 20):
				return mark
			if y == 26 - absi(finger - 8) / 2:
				return mark
			return shell_colour.darkened(0.3) if (x * 3 + y * 5) % 13 == 0 else shell_colour
		Cryptlin.Kind.MERMAID:
			# A scallop shell: pale ribs fanning down it from the top, growth rings across them, and
			# a wavy edge near the bottom with mother-of-pearl under it
			if y > 25 + int(sin(x * PI / 4.0) * 1.5):
				return Color(0.7, 0.86, 0.88) if (x + y) % 3 == 0 else mark
			if x % 8 == 0 or (x % 8 == 1 and y > 14):
				return mark
			return shell_colour.darkened(0.18) if y % 7 == 3 else shell_colour
	return shell_colour


# How near a dot of the picture is to the middle of the nearest blotch, in blotch-widths
# (under 1 is inside it); the picture joins up round the back
func _blot(x: int, y: int) -> float:
	var nearest := INF
	for b in blots:
		var across := absf(wrapf(x - b.x, -32.0, 32.0))
		nearest = minf(nearest, Vector2(across, (y - b.y) * 1.6).length() / b.z)
	return nearest



# A point on the shell: `around` is the angle from the front, `up` the angle above the middle
func _on(around: float, up: float) -> Vector3:
	return CENTRE + Vector3(sin(around) * cos(up), sin(up), cos(around) * cos(up)) * RADII


func _normal(at: Vector3) -> Vector3:
	return ((at - CENTRE) / (RADII * RADII)).normalized()


func _crack(mat: Material, lines: Array) -> Node3D:
	var group := Node3D.new()
	shell.add_child(group)
	for line: Array in lines:
		for i in line.size() - 1:
			var a: Vector3 = line[i]
			var b: Vector3 = line[i + 1]
			var box := BoxMesh.new()
			box.size = Vector3(0.024, 0.012, a.distance_to(b) + 0.02)
			var mid := (a + b) * 0.5
			var out := _normal(mid)
			var seg := _part(box, mat, mid, Vector3.ONE, Vector3.ZERO, group)
			seg.basis = Basis.looking_at(b - a, out)
			seg.position = mid + out * 0.002
	return group


func title() -> String:
	return TITLES[kind]


func centre() -> Vector3:
	return global_position + CENTRE * SIZE


func drop(from: Vector3) -> void:
	position = from
	fall = -1.0
	landed = false


# A finger rubbed over it
func rub() -> void:
	last_rub = t
	rock_v.x += sin(t * 23.0) * 0.5


# A tap: it knocks back
func tap() -> void:
	if hatching >= 0.0 or not landed:
		return
	warmth += 2.5
	rock_v += Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4)).normalized() * 4.5
	world.sfx.play("knock", 1.0 + stage * 0.15)


func _process(delta: float) -> void:
	t += delta
	if not landed:
		fall -= 14.0 * delta
		position.y += fall * delta
		if position.y <= 0.0:
			position.y = 0.0
			world.sfx.play("thud", 0.9, -5.0)
			if fall > -2.6:
				landed = true
				rock_v = Vector2(randf_range(-2.5, 2.5), 1.5)
			else:
				fall = -fall * 0.3
	elif hatching >= 0.0:
		hatching += delta
		rock = Vector2(sin(t * 38.0), cos(t * 31.0)) * 0.17
		rock_v = Vector2.ZERO
		if hatching > 1.3:
			set_process(false)
			hatched.emit()
			return
	else:
		if t - last_rub < 0.25:
			warmth += delta * 9.0
		var away := Vector2(position.x - world.light_point.x, position.z - world.light_point.z).length()
		if away < 1.8:
			warmth += delta * 1.1 * world.lamp_warmth()
		# One asleep beside it broods it, wherever the lamp is
		for pet in world.pets():
			if pet.state == Cryptlin.State.SLEEP and pet.position.distance_to(position) < 0.7:
				warmth += delta * 0.8
		warmth = minf(warmth, 100.0)
		if warmth >= 100.0:
			hatching = 0.0
			world.sfx.play("crack", 0.8)
		elif int(warmth / 34.0) > stage:
			stage = int(warmth / 34.0)
			cracks[stage - 1].visible = true
			rock_v += Vector2(3.5, 1.0)
			world.sfx.play("crack")
			cracked.emit(stage)
		# Whatever is inside shifts about, more as it warms
		stir -= delta
		if stir <= 0.0:
			stir = randf_range(1.0, 4.5 - warmth * 0.03)
			var a := randf() * TAU
			rock_v += Vector2(cos(a), sin(a) * 0.5) * (1.6 + stage * 1.4)
			if stage > 0:
				world.sfx.play("knock", 0.8, -9.0)
	rock_v += (-rock * 90.0 - rock_v * 5.0) * delta
	rock += rock_v * delta
	shell.rotation = Vector3(rock.y, 0, rock.x)
	peek.scale.y = 0.036 * (0.1 if fmod(t, 2.7) < 0.12 else 1.0)


# The shell flies apart; the egg is gone a moment later
func burst() -> void:
	shell.visible = false
	shards.emitting = true
	get_tree().create_timer(1.5).timeout.connect(queue_free)
