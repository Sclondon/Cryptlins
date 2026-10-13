class_name Snack
extends Node3D
## Something dropped into the light for the cryptlin to eat. What it makes of each is up to it.

signal thud(strength: float)
# It has landed in the pool
signal splashed

enum Kind { BONE, TOADSTOOL, CANDY, FISH, BEETLE, BERRIES, WORM, SAUSAGE, TURNIP, CHEESE }

const NAMES: Array[String] = ["Bone", "Toadstool", "Candy corn", "Fish", "Beetle", "Berries", "Worm", "Sausage", "Turnip", "Cheese"]
# As in "it loves ..."
const PLURALS: Array[String] = ["bones", "toadstools", "candy corn", "fish", "beetles", "berries", "worms", "sausages", "turnips", "cheese"]
const BITES := 3
const VALUE := 34.0

var kind: int = Kind.BONE
var vel := Vector3.ZERO
var landed := false
# On the end of a finger: it hangs where it is put and does not fall
var held := false
var bites_left := BITES
var colour := Color.WHITE
var spin := Vector3.ZERO
var visual: Node3D
# How long it has been floating in the pool
var afloat := 0.0


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
		Kind.WORM:
			colour = Color(0.86, 0.5, 0.52)
			# A fat one, ring on ring in a wriggle, with a pale saddle and its front end up off the floor
			for i in 11:
				var u := i / 10.0
				var ring := colour if i % 2 == 0 else Color(0.72, 0.36, 0.42)
				_add(_ball(0.05 - 0.014 * absf(u - 0.4)), Color(0.96, 0.8, 0.74) if i == 3 or i == 4 else ring, Vector3(lerpf(-0.16, 0.16, u), 0.045 + 0.09 * maxf(u - 0.7, 0.0) / 0.3, sin(u * TAU * 1.1) * 0.055))
		Kind.SAUSAGE:
			colour = Color(0.62, 0.25, 0.15)
			# Two fat links, tied off with string between them and at the ends
			var link := CapsuleMesh.new()
			link.radius = 0.058
			link.height = 0.21
			link.radial_segments = 6
			link.rings = 2
			for side: float in [-1.0, 1.0]:
				_add(link, colour if side < 0.0 else Color(0.7, 0.3, 0.17), Vector3(0.1 * side, 0.06, -0.02), Vector3(0, 0.35 * side, PI * 0.5))
				_add(_ball(0.022), Color(0.9, 0.86, 0.74), Vector3(0.21 * side, 0.06, -0.06))
			_add(_ball(0.026), Color(0.9, 0.86, 0.74), Vector3(0, 0.06, 0.015))
		Kind.TURNIP:
			colour = Color(0.92, 0.9, 0.82)
			# White below and purple above, on the point of its root, with its leaves still on
			var bulb := _add(_ball(1.0), colour, Vector3(0, 0.125, 0))
			bulb.scale = Vector3(0.105, 0.095, 0.105)
			var crown := _add(_ball(1.0), Color(0.62, 0.24, 0.56), Vector3(0, 0.16, 0))
			crown.scale = Vector3(0.107, 0.068, 0.107)
			var point := CylinderMesh.new()
			point.top_radius = 0.045
			point.bottom_radius = 0.0
			point.height = 0.07
			point.radial_segments = 5
			_add(point, colour, Vector3(0, 0.035, 0))
			for i in 3:
				var a := TAU * i / 3.0 + 0.5
				var leaf := _add(_ball(1.0), Color(0.24, 0.5, 0.2), Vector3(cos(a) * 0.045, 0.27, sin(a) * 0.045), Vector3(0, -a, -0.5))
				leaf.scale = Vector3(0.028, 0.075, 0.045)
		Kind.CHEESE:
			colour = Color(0.96, 0.78, 0.24)
			# A wedge of it lying flat, the rind along its back and holes in its top and sides
			var wedge := PrismMesh.new()
			wedge.size = Vector3(0.28, 0.24, 0.13)
			_add(wedge, colour, Vector3(0, 0.065, 0), Vector3(PI * 0.5, 0, 0))
			var rind := BoxMesh.new()
			rind.size = Vector3(0.29, 0.135, 0.016)
			_add(rind, Color(0.82, 0.36, 0.1), Vector3(0, 0.066, -0.124))
			var holes: Array[Vector3] = [Vector3(-0.05, 0.132, -0.06), Vector3(0.05, 0.132, -0.03), Vector3(0.0, 0.132, 0.05)]
			for at: Vector3 in holes:
				var hole := _add(_ball(1.0), Color(0.72, 0.5, 0.1), at)
				hole.scale = Vector3(0.03, 0.004, 0.03)
			for side: float in [-1.0, 1.0]:
				var hole := _add(_ball(1.0), Color(0.72, 0.5, 0.1), Vector3(0.075 * side, 0.07, 0.0), Vector3(0, -0.53 * side, 0))
				hole.scale = Vector3(0.006, 0.028, 0.028)


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


# Taken hold of by a finger, off the row of things or up off the floor
func hold() -> void:
	held = true
	landed = false
	vel = Vector3.ZERO
	spin = Vector3.ZERO


func drop(from: Vector3) -> void:
	held = false
	position = from
	vel = Vector3(randf_range(-0.4, 0.4), -1.0, randf_range(-0.4, 0.4))
	spin = Vector3(randf_range(-6, 6), randf_range(-4, 4), randf_range(-6, 6))
	landed = false


func _process(delta: float) -> void:
	if held:
		return
	var wet := Den.wade(position) > 0.0
	if landed:
		# In the pool it floats, low in the water, and drifts in to the shallows, where any of
		# them can get at it from the edge
		if wet:
			afloat += delta
			position = position.move_toward(Den.shore_by(position, -0.12), delta * 0.3)
			position.y = Decor.WATER + sin(afloat * 2.6) * 0.012
		else:
			position.y = 0.0
		return
	vel.y -= 14.0 * delta
	position += vel * delta
	visual.rotation += spin * delta
	if wet:
		if position.y <= Decor.WATER:
			position.y = Decor.WATER
			landed = true
			vel = Vector3.ZERO
			visual.rotation = Vector3(0, visual.rotation.y, 0)
			splashed.emit()
	elif position.y <= 0.0:
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
