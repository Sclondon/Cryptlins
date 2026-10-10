class_name Snack
extends Node3D
## Something dropped into the light for the cryptlin to eat: a bone, a toadstool or a candy corn.

signal thud(strength: float)

enum Kind { BONE, TOADSTOOL, CANDY }

const BITES := 3
const VALUE := 34.0

var kind: int = Kind.BONE
var vel := Vector3.ZERO
var landed := false
var bites_left := BITES
var colour := Color.WHITE
var spin := Vector3.ZERO
var visual: Node3D


func _init(which: int = Kind.BONE) -> void:
	kind = which
	visual = Node3D.new()
	add_child(visual)
	match kind:
		Kind.BONE:
			colour = Color(0.9, 0.86, 0.74)
			var shaft := CapsuleMesh.new()
			shaft.radius = 0.035
			shaft.height = 0.32
			_add(shaft, colour, Vector3(0, 0.06, 0), Vector3(0, 0, PI * 0.5))
			for x in [-0.15, 0.15]:
				for z in [-0.035, 0.035]:
					_add(_ball(0.05), colour, Vector3(x, 0.06, z))
		Kind.TOADSTOOL:
			colour = Color(0.72, 0.16, 0.22)
			var stem := CylinderMesh.new()
			stem.top_radius = 0.035
			stem.bottom_radius = 0.05
			stem.height = 0.14
			_add(stem, Color(0.88, 0.84, 0.74), Vector3(0, 0.07, 0))
			var cap := _add(_ball(1.0), colour, Vector3(0, 0.15, 0))
			cap.scale = Vector3(0.14, 0.08, 0.14)
			for i in 5:
				var a := TAU * i / 5.0
				_add(_ball(0.022), Color(0.95, 0.93, 0.85), Vector3(cos(a) * 0.08, 0.2, sin(a) * 0.08))
		Kind.CANDY:
			colour = Color(1.0, 0.55, 0.1)
			var bands: Array[Color] = [Color(1.0, 0.85, 0.15), Color(1.0, 0.5, 0.08), Color(0.97, 0.95, 0.9)]
			var radii: Array[float] = [0.1, 0.07, 0.04, 0.005]
			for i in 3:
				var band := CylinderMesh.new()
				band.bottom_radius = radii[i]
				band.top_radius = radii[i + 1]
				band.height = 0.075
				band.radial_segments = 16
				_add(band, bands[i], Vector3(0, 0.0375 + 0.075 * i, 0))


func _ball(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


func _add(mesh: Mesh, c: Color, at: Vector3, turn := Vector3.ZERO) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.rotation = turn
	visual.add_child(mi)
	return mi


func drop(from: Vector3) -> void:
	position = from
	vel = Vector3(randf_range(-0.4, 0.4), -1.0, randf_range(-0.4, 0.4))
	spin = Vector3(randf_range(-6, 6), randf_range(-4, 4), randf_range(-6, 6))
	landed = false


func _process(delta: float) -> void:
	if landed:
		return
	vel.y -= 14.0 * delta
	position += vel * delta
	visual.rotation += spin * delta
	if position.y <= 0.0:
		position.y = 0.0
		thud.emit(-vel.y)
		if vel.y > -2.2:
			landed = true
			vel = Vector3.ZERO
			visual.rotation = Vector3(0, visual.rotation.y, 0)
		else:
			vel = Vector3(vel.x * 0.5, -vel.y * 0.32, vel.z * 0.5)
			spin *= 0.4


# Takes a bite out; true when that was the last of it
func bite() -> bool:
	bites_left -= 1
	var s := 0.45 + 0.55 * bites_left / float(BITES)
	visual.scale = Vector3.ONE * s
	return bites_left <= 0
