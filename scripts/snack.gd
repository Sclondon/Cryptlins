class_name Snack
extends Node3D
## Something dropped into the light for the cryptlin to eat. What it makes of each is up to it.

signal thud(strength: float)

enum Kind { BONE, TOADSTOOL, CANDY, FISH, BEETLE, BERRIES }

const NAMES: Array[String] = ["Bone", "Toadstool", "Candy corn", "Fish", "Beetle", "Berries"]
# As in "it loves ..."
const PLURALS: Array[String] = ["bones", "toadstools", "candy corn", "fish", "beetles", "berries"]
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
			shaft.radial_segments = 6
			shaft.rings = 2
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
			stem.radial_segments = 6
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
				band.radial_segments = 6
				_add(band, bands[i], Vector3(0, 0.0375 + 0.075 * i, 0))
		Kind.FISH:
			colour = Color(0.45, 0.6, 0.7)
			var body := _add(_ball(1.0), colour, Vector3(0, 0.06, 0))
			body.scale = Vector3(0.17, 0.065, 0.04)
			var belly := _add(_ball(1.0), Color(0.8, 0.82, 0.78), Vector3(0, 0.045, 0))
			belly.scale = Vector3(0.14, 0.045, 0.035)
			var fin := CylinderMesh.new()
			fin.top_radius = 0.0
			fin.bottom_radius = 0.07
			fin.height = 0.1
			fin.radial_segments = 4
			var tail := _add(fin, Color(0.3, 0.42, 0.52), Vector3(-0.2, 0.06, 0), Vector3(0, 0, -PI * 0.5))
			tail.scale = Vector3(1, 1, 0.25)
			_add(_ball(0.014), Color(0.05, 0.05, 0.05), Vector3(0.11, 0.075, 0.03))
			_add(_ball(0.014), Color(0.05, 0.05, 0.05), Vector3(0.11, 0.075, -0.03))
		Kind.BEETLE:
			colour = Color(0.12, 0.34, 0.26)
			var shell := _add(_ball(1.0), colour, Vector3(0, 0.05, -0.01))
			shell.scale = Vector3(0.09, 0.06, 0.11)
			_add(_ball(0.04), Color(0.06, 0.07, 0.08), Vector3(0, 0.04, 0.1))
			var leg := BoxMesh.new()
			leg.size = Vector3(0.24, 0.012, 0.014)
			for i in 3:
				_add(leg, Color(0.06, 0.07, 0.08), Vector3(0, 0.02, -0.07 + i * 0.06), Vector3(0, (i - 1) * 0.4, 0))
			var feeler := BoxMesh.new()
			feeler.size = Vector3(0.01, 0.01, 0.08)
			for side: float in [-1.0, 1.0]:
				_add(feeler, Color(0.06, 0.07, 0.08), Vector3(0.03 * side, 0.06, 0.16), Vector3(-0.4, 0.4 * side, 0))
		Kind.BERRIES:
			colour = Color(0.5, 0.1, 0.4)
			for i in 5:
				var a := TAU * i / 5.0
				var up := 0.05 if i < 3 else 0.12
				var out := 0.06 if i < 3 else 0.02
				_add(_ball(0.055), colour if i % 2 == 0 else Color(0.62, 0.12, 0.3), Vector3(cos(a) * out, up, sin(a) * out))
			var leaf := _add(_ball(1.0), Color(0.2, 0.45, 0.18), Vector3(0.03, 0.18, 0), Vector3(0, 0.6, 0.3))
			leaf.scale = Vector3(0.07, 0.012, 0.04)


func _ball(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 8
	m.rings = 4
	return m


func _add(mesh: Mesh, c: Color, at: Vector3, turn := Vector3.ZERO) -> MeshInstance3D:
	var mat := Ps1.mat(c)
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
