class_name Ball
extends Node3D
## A toy: something that bounces or rolls, and can be picked up and thrown. A striped ball, a
## heavy stone, a bell that rings, or an orb that glows in the dark. Being played with wears it
## out: it gets scuffed, then cracked or patched and out of shape, and in the end it comes apart
## (see Den.wear_toy and Den.break_toy).

signal bounced(strength: float)

enum Kind { BALL, STONE, BELL, GLOW }

const NAMES: Array[String] = ["Ball", "Stone", "Bell", "Glow orb"]
# As in "its favourite toy is the ..."
const PLAIN: Array[String] = ["ball", "stone", "bell", "glow orb"]
const R := 0.16
# How much wear it takes before it comes apart, and how worn it is when it starts to show: first
# scuffed, then badly gone
const WORN_OUT := 100.0
const SCUFFED := 35.0
const FAR_GONE := 70.0
# How much one kick from an ordinary grown cryptlin wears each (see Cryptlin.rough): the stone
# takes the most killing and the orb the least. Three of them with the ball on the floor get some
# 370 kicks at it in ten minutes and one by itself some 50, so at ten minutes of play a day a
# ball lasts a room of three about three days, and one alone some weeks.
const WEARS: Array[float] = [0.12, 0.06, 0.09, 0.16]
# The colour of the bits each leaves when it breaks
const TINTS: Array[Color] = [Color(0.85, 0.42, 0.12), Color(0.36, 0.35, 0.37), Color(0.6, 0.45, 0.14), Color(0.5, 0.9, 0.6)]

var kind: int = Kind.BALL
var vel := Vector3.ZERO
var held := false
var mesh: MeshInstance3D
# How it behaves: how much of a fall it bounces back, how fast it stops rolling, how far a kick
# sends it, how hard it falls, and the sound it makes
var bounce := 0.62
var drag := 1.1
var heft := 1.0
var fall := 12.0
var sound := "boing"
var pitch := 1.0
# How worn it is with being played with, 0 to WORN_OUT, and whether it was bought (and so is one
# of a few) or is one of a kind there is no end of
var wear := 0.0
var bought := false
# Its own shape, the bounce it had when new, and how worn it was last painted (-1: not yet)
var shape := Vector3.ONE
var spring := 0.62
var painted := -1


func _init(which: int = Kind.BALL) -> void:
	kind = which
	var sphere := SphereMesh.new()
	sphere.radius = R
	sphere.height = R * 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	mesh = MeshInstance3D.new()
	mesh.mesh = sphere
	add_child(mesh)
	match kind:
		Kind.STONE:
			bounce = 0.22
			drag = 3.5
			heft = 0.6
			fall = 16.0
			sound = "thud"
			pitch = 1.1
			sphere.radial_segments = 7
			sphere.rings = 3
			shape = Vector3(1.0, 0.82, 0.9)
		Kind.BELL:
			bounce = 0.5
			drag = 1.4
			sound = "jingle"
		Kind.GLOW:
			bounce = 0.72
			drag = 0.7
			heft = 0.85
			fall = 6.5
			pitch = 1.6
	spring = bounce
	show_wear()


# How far gone it is: 0 as good as new, 1 scuffed, 2 cracked or patched and out of shape
func stage() -> int:
	return 2 if wear >= FAR_GONE else (1 if wear >= SCUFFED else 0)


# Makes it look as worn as it is: scuffs painted on it, then a patch or a crack, and it sags,
# bounces less and (the orb) glows less
func show_wear() -> void:
	var s := stage()
	if s == painted:
		return
	painted = s
	var tex := _texture(func(x: int, y: int) -> Color: return _paint(x, y, s))
	match kind:
		Kind.BELL:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.3 - 0.12 * s, tex)
		Kind.GLOW:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.9 - 0.35 * s, 0.0, tex)
		_:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.0, tex)
	var sag: Vector3 = [Vector3.ONE, Vector3(1.04, 0.9, 1.0), Vector3(1.12, 0.74, 0.98)][s]
	mesh.basis = mesh.basis.orthonormalized() * Basis.from_scale(shape * sag)
	bounce = spring * (1.0 - 0.18 * s)


# One dot of what is painted on it, 64 round and 32 down: its own pattern, and over that the
# marks of however much wear
func _paint(x: int, y: int, worn: int) -> Color:
	var c: Color
	match kind:
		Kind.STONE:
			var speck := (x * 7 + y * 13) % 11 == 0
			c = Color(0.2, 0.2, 0.22) if speck else Color(0.36, 0.35, 0.36).lerp(Color(0.3, 0.3, 0.33), float((x / 9 + y / 7) % 2))
		Kind.BELL:
			# Brass, with a dark slot round the middle
			c = Color(0.08, 0.06, 0.03) if y >= 17 and y <= 19 else Color(0.62, 0.46, 0.14).lerp(Color(0.44, 0.3, 0.08), y / 32.0)
		Kind.GLOW:
			var swirl := sin(x * 0.4 + y * 0.5) * 0.5 + 0.5
			c = Color(0.45, 0.95, 0.6).lerp(Color(0.85, 1.0, 0.7), swirl)
		_:
			if y < 4 or y > 27:
				c = Color(0.95, 0.9, 0.75)
			else:
				c = Color(0.95, 0.45, 0.08) if (x / 8) % 2 == 0 else Color(0.36, 0.16, 0.5)
	if worn == 0:
		return c
	# Scuffs: it is duller all over, with grey scrapes on it in blocks big enough to see across
	# the room, a few when it is only scuffed and many when it is far gone
	var grime := Color(0.4, 0.38, 0.34) if kind != Kind.GLOW else Color(0.16, 0.3, 0.22)
	c = c.lerp(grime, 0.22 if worn == 1 else 0.42)
	if ((x / 3) * 5 + (y / 2) * 11) % (9 if worn == 1 else 5) < 2:
		c = c.lerp(grime, 0.75)
	if worn < 2:
		return c
	if kind == Kind.BALL:
		# A big square of sacking sewn over a split, on either side of it, with the stitches showing
		var px := x % 32 - 7
		var py := y - 8
		if px >= 0 and px <= 15 and py >= 0 and py <= 15:
			var hem := px <= 1 or px >= 14 or py <= 1 or py >= 14
			return Color(0.1, 0.08, 0.06) if hem and (px / 2 + py / 2) % 2 == 0 else Color(0.74, 0.66, 0.48).lerp(Color(0.6, 0.52, 0.38), float((px / 2 + py / 2) % 2))
	else:
		# A wide crack right round it, wandering, with another running off it; and on the bell a
		# bloom of green where the brass has gone
		var line := 14 + int(sin(x * 0.55) * 3.0 + sin(x * 0.21) * 2.0)
		if absi(y - line) <= 2 or (x % 32 > 10 and x % 32 < 16 and y > line and y < line + 10):
			return Color(0.04, 0.04, 0.05) if kind != Kind.GLOW else Color(0.03, 0.1, 0.07)
		if kind == Kind.BELL and (x / 5 + y / 4) % 4 == 0:
			return c.lerp(Color(0.2, 0.5, 0.4), 0.8)
	return c


func _texture(paint: Callable) -> ImageTexture:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 64:
			img.set_pixel(x, y, paint.call(x, y))
	return ImageTexture.create_from_image(img)


func speed() -> float:
	return vel.length()


func _process(delta: float) -> void:
	if held:
		return
	# On the floor it rests on the floor; out in the pool it floats
	var out := Den.wade(position)
	var rest := lerpf(R, Decor.WATER + R * 0.4, smoothstep(0.0, 0.2, out))
	vel.y -= fall * delta
	position += vel * delta
	if position.y < rest:
		position.y = rest
		if vel.y < -0.9:
			bounced.emit(-vel.y)
			vel.y = -vel.y * bounce * (0.25 if out > 0.0 else 1.0)
		else:
			vel.y = 0.0
	var flat := Vector3(vel.x, 0, vel.z)
	if position.y <= rest + 0.001:
		flat = flat.move_toward(Vector3.ZERO, delta * drag)
		if out > 0.0:
			# The water takes the way off it, and it drifts back to the edge and out onto the floor
			flat = flat.move_toward((Den.shore_by(position, R + 0.1) - position).normalized() * 0.55, delta * 3.0)
		vel.x = flat.x
		vel.z = flat.z
	# The walls of the room, and the unseen one across the front
	var wide := Den.half.x - R
	var deep := Den.half.y - R
	if absf(position.x) > wide:
		if vel.x * position.x > 0.0:
			bounced.emit(absf(vel.x))
			vel.x *= -0.7
		position.x = clampf(position.x, -wide, wide)
	if absf(position.z) > deep:
		if vel.z * position.z > 0.0:
			bounced.emit(absf(vel.z))
			vel.z *= -0.7
		position.z = clampf(position.z, -deep, deep)
	if flat.length() > 0.02:
		mesh.rotate(Vector3.UP.cross(flat).normalized(), flat.length() / R * delta)
