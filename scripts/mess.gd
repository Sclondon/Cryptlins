class_name Mess
extends Node3D
## What a cryptlin leaves on the floor: a dropping, which stays until the keeper taps it away; a
## puddle, which dries up by itself; or the heap of earth from a dig, which settles in a while.

enum Kind { DROPPING, PUDDLE, HEAP }

# How long a puddle and a heap last, in seconds of the clock on the wall (a dropping: for ever)
const LASTS: Array[float] = [0.0, 3600.0, 600.0]

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


# How far through its time it is, 0 to 1 (a dropping is always 0)
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
