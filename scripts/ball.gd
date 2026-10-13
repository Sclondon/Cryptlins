class_name Ball
extends Node3D
## A toy: something that bounces or rolls, and can be picked up and thrown. A striped ball, a
## heavy stone, a bell that rings, or an orb that glows in the dark.

signal bounced(strength: float)

enum Kind { BALL, STONE, BELL, GLOW }

const NAMES: Array[String] = ["Ball", "Stone", "Bell", "Glow orb"]
# As in "its favourite toy is the ..."
const PLAIN: Array[String] = ["ball", "stone", "bell", "glow orb"]
const R := 0.16

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
			mesh.scale = Vector3(1.0, 0.82, 0.9)
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.0, _texture(func(x: int, y: int) -> Color:
				var speck := (x * 7 + y * 13) % 11 == 0
				return Color(0.2, 0.2, 0.22) if speck else Color(0.36, 0.35, 0.36).lerp(Color(0.3, 0.3, 0.33), float((x / 9 + y / 7) % 2))))
		Kind.BELL:
			bounce = 0.5
			drag = 1.4
			sound = "jingle"
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.3, _texture(func(_x: int, y: int) -> Color:
				# Brass, with a dark slot round the middle
				return Color(0.08, 0.06, 0.03) if y >= 17 and y <= 19 else Color(0.62, 0.46, 0.14).lerp(Color(0.44, 0.3, 0.08), y / 32.0)))
		Kind.GLOW:
			bounce = 0.72
			drag = 0.7
			heft = 0.85
			fall = 6.5
			pitch = 1.6
			mesh.material_override = Ps1.mat(Color.WHITE, 0.9, 0.0, _texture(func(x: int, y: int) -> Color:
				var swirl := sin(x * 0.4 + y * 0.5) * 0.5 + 0.5
				return Color(0.45, 0.95, 0.6).lerp(Color(0.85, 1.0, 0.7), swirl)))
		_:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.0, _texture(func(x: int, y: int) -> Color:
				if y < 4 or y > 27:
					return Color(0.95, 0.9, 0.75)
				return Color(0.95, 0.45, 0.08) if (x / 8) % 2 == 0 else Color(0.36, 0.16, 0.5)))


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
	vel.y -= fall * delta
	position += vel * delta
	if position.y < R:
		position.y = R
		if vel.y < -0.9:
			bounced.emit(-vel.y)
			vel.y = -vel.y * bounce
		else:
			vel.y = 0.0
	var flat := Vector3(vel.x, 0, vel.z)
	if position.y <= R + 0.001:
		flat = flat.move_toward(Vector3.ZERO, delta * drag)
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
