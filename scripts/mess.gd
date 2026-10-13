class_name Mess
extends Node3D
## What gets left on the floor: a dropping, which stays until the keeper sweeps it up; a puddle,
## which dries up by itself; the heap of earth from a dig, which settles in a while; or the bits of
## a toy that has been played with until it broke, which stay until they are swept up too.

enum Kind { DROPPING, PUDDLE, HEAP, BITS }

# How long a puddle and a heap last, in seconds of the clock on the wall (a dropping and the bits
# of a toy: for ever)
const LASTS: Array[float] = [0.0, 3600.0, 600.0, 0.0]

var kind: int = Kind.DROPPING
# When it was left (unix time), its colour, and how big next to the usual
var made := 0.0
var tint := Color(0.3, 0.2, 0.1)
var size := 1.0
var body: Node3D


func _init(which: int, when: float, colour: Color, big := 1.0) -> void:
	kind = which
	made = when
	tint = colour
	size = big
	body = Node3D.new()
	body.scale = Vector3.ONE * size
	add_child(body)
	match kind:
		Kind.DROPPING:
			# A coil of three, each smaller than the last
			var mat := Ps1.mat(tint)
			for i in 3:
				Ps1.part(body, Ps1.ball(), mat, Vector3(0.012 * (i % 2), 0.035 + i * 0.045, 0), Vector3(0.085 - i * 0.024, 0.04 - i * 0.006, 0.085 - i * 0.024))
		Kind.PUDDLE:
			Ps1.part(body, Ps1.drum(9), Ps1.mat(tint, 0.1), Vector3(0, 0.006, 0), Vector3(0.2, 0.012, 0.16))
			Ps1.part(body, Ps1.drum(7), Ps1.mat(tint, 0.1), Vector3(0.13, 0.006, 0.07), Vector3(0.09, 0.012, 0.08))
		Kind.HEAP:
			var mat := Ps1.mat(tint)
			Ps1.part(body, Ps1.ball(), mat, Vector3(0, 0.03, 0), Vector3(0.16, 0.07, 0.14))
			Ps1.part(body, Ps1.ball(), mat, Vector3(0.1, 0.02, 0.06), Vector3(0.09, 0.04, 0.08))
		Kind.BITS:
			# A split half of it lying open, and shards and scraps round about, in its own colour,
			# a darker one and the pale of its insides
			var shades: Array[ShaderMaterial] = [Ps1.mat(tint), Ps1.mat(tint.darkened(0.45)), Ps1.mat(tint.lerp(Color(0.85, 0.8, 0.7), 0.6))]
			Ps1.part(body, Ps1.ball(), shades[0], Vector3(-0.03, 0.012, 0.02), Vector3(0.12, 0.05, 0.1), Vector3(0.2, 0.4, 0.15))
			Ps1.part(body, Ps1.ball(), shades[1], Vector3(-0.03, 0.03, 0.02), Vector3(0.09, 0.034, 0.075), Vector3(0.2, 0.4, 0.15))
			for i in 7:
				var a := i * 0.9 + 0.4
				var far := 0.13 + 0.035 * (i % 3)
				Ps1.part(body, Ps1.box(), shades[i % 3], Vector3(cos(a) * far, 0.012, sin(a) * far), Vector3(0.07 - 0.012 * (i % 3), 0.02, 0.035 + 0.01 * (i % 2)), Vector3(0.3 * (i % 2), a * 1.7, 0.25))


# How far through its time it is, 0 to 1 (0 always, for what stays until it is swept up)
func gone() -> float:
	if LASTS[kind] <= 0.0:
		return 0.0
	return clampf((Time.get_unix_time_from_system() - made) / LASTS[kind], 0.0, 1.0)


func _process(_delta: float) -> void:
	# A puddle shrinks as it dries, and a heap sinks back into the floor
	var left := 1.0 - gone()
	if kind == Kind.PUDDLE:
		body.scale = Vector3(size * sqrt(left), size, size * sqrt(left))
	elif kind == Kind.HEAP:
		body.scale = Vector3(size, size * left, size)
