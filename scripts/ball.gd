class_name Ball
extends Node3D
## A striped ball: bounces, rolls, and can be picked up and thrown.

signal bounced(strength: float)

const R := 0.16
const LIMIT := 4.3

var vel := Vector3.ZERO
var held := false
var mesh: MeshInstance3D


func _init() -> void:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 64:
			var stripe := (x / 8) % 2 == 0
			var c := Color(0.95, 0.45, 0.08) if stripe else Color(0.36, 0.16, 0.5)
			if y < 4 or y > 27:
				c = Color(0.95, 0.9, 0.75)
			img.set_pixel(x, y, c)
	var mat := Ps1.mat(Color.WHITE, 0.0, 0.0, ImageTexture.create_from_image(img))
	var sphere := SphereMesh.new()
	sphere.radius = R
	sphere.height = R * 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	mesh = MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = mat
	add_child(mesh)


func speed() -> float:
	return vel.length()


func _process(delta: float) -> void:
	if held:
		return
	vel.y -= 12.0 * delta
	position += vel * delta
	if position.y < R:
		position.y = R
		if vel.y < -0.9:
			bounced.emit(-vel.y)
			vel.y = -vel.y * 0.62
		else:
			vel.y = 0.0
	var flat := Vector3(vel.x, 0, vel.z)
	if position.y <= R + 0.001:
		flat = flat.move_toward(Vector3.ZERO, delta * 1.1)
		vel.x = flat.x
		vel.z = flat.z
	# The unseen walls of the crypt
	var out := Vector2(position.x, position.z)
	if out.length() > LIMIT:
		var n := out.normalized()
		var along := vel.x * n.x + vel.z * n.y
		if along > 0.0:
			vel.x -= n.x * along * 1.7
			vel.z -= n.y * along * 1.7
			bounced.emit(along)
		position.x = n.x * LIMIT
		position.z = n.y * LIMIT
	if flat.length() > 0.02:
		mesh.rotate(Vector3.UP.cross(flat).normalized(), flat.length() / R * delta)
