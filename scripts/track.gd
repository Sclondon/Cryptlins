class_name Track
extends Node3D
## Something left on the floor for a while: a footprint pressed into it by one of the heavy kinds
## as it walks, a patch of frost where a wendigo stood, or the tiny toadstools that come up
## where a living fungus sat. It fades back into the ground (or shrinks back into it) and is
## gone. Only something to look at: it is not kept in the save, is not a mess, and nothing can
## be done to it.

const SHADER: Shader = preload("res://shaders/print.gdshader")
const FROST: Shader = preload("res://shaders/frost.gdshader")
# How long a print shows on a soft floor and on a hard one (seconds), and how much darker than
# the ground it starts on each; the same for a patch of frost, which is paler than the ground;
# and how long toadstools stand
const LASTS_SOFT := 90.0
const LASTS_HARD := 40.0
const DEPTH_SOFT := 0.55
const DEPTH_HARD := 0.24
const LASTS_FROST := 24.0
const DEPTH_FROST := 0.34
const LASTS_TOADSTOOLS := 45.0

var age := 0.0
var lasts := LASTS_HARD
var depth := DEPTH_HARD
var mat: ShaderMaterial
# For what stands up off the floor: how big it is when it is full grown (it comes up out of the
# floor, and goes back into it at the end)
var full := 0.0


# `shape` is whose foot it was ("sasquatch": a long sole and five toes, the big one inside),
# "frost" for a ragged patch of it or "toadstools" for a little clump of them; `side` is -1 for
# a left foot and 1 for a right, `big` how big next to the usual
func _init(shape: String, side: float, big: float, soft: bool) -> void:
	lasts = LASTS_SOFT if soft else LASTS_HARD
	depth = DEPTH_SOFT if soft else DEPTH_HARD
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	scale = Vector3.ONE * big
	match shape:
		"sasquatch":
			_pad(Vector3(0, 0, -0.03), Vector2(0.105, 0.17))
			_pad(Vector3(0.01 * side, 0, -0.16), Vector2(0.075, 0.08))
			for toe in 5:
				var size := 0.052 - toe * 0.006
				_pad(Vector3((toe - 2.0) * 0.058 * side, 0, 0.21 - toe * 0.02), Vector2(size, size * 1.25))
		"frost":
			lasts = LASTS_FROST
			depth = DEPTH_FROST
			mat.shader = FROST
			# A middle and a few long fingers out of it
			_pad(Vector3.ZERO, Vector2(0.12, 0.1))
			for i in 5:
				var around := TAU * i / 5.0 + randf_range(-0.4, 0.4)
				var out := randf_range(0.1, 0.2)
				_pad(Vector3(cos(around), 0, sin(around)) * out, Vector2(0.035, out), -around + PI * 0.5)
		"toadstools":
			lasts = LASTS_TOADSTOOLS
			full = big
			scale = Vector3.ONE * 0.001
			var stalk := Ps1.mat(Color(0.8, 0.76, 0.62))
			var cap := Ps1.mat(Color(0.7, 0.16, 0.12))
			for i in 4:
				var around := TAU * i / 4.0 + randf_range(-0.5, 0.5)
				var at := Vector3(cos(around), 0, sin(around)) * randf_range(0.06, 0.24)
				var tall := randf_range(0.07, 0.13)
				Ps1.part(self, Ps1.drum(5), stalk, at + Vector3(0, tall * 0.5, 0), Vector3(0.014, tall, 0.014))
				Ps1.part(self, Ps1.ball(), cap, at + Vector3(0, tall, 0), Vector3(0.05, 0.03, 0.05))
	mat.set_shader_parameter("depth", depth)


# One flat patch of the mark, so far across and so long, turned so far round
func _pad(at: Vector3, size: Vector2, turn := 0.0) -> void:
	var pad := Ps1.part(self, Ps1.drum(7), mat, at + Vector3(0, 0.003, 0), Vector3(size.x, 0.004, size.y), Vector3(0, turn, 0))
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	age += delta
	if age >= lasts:
		queue_free()
		return
	if full > 0.0:
		scale = Vector3.ONE * maxf(full * minf(age / 2.5, 1.0) * minf((lasts - age) / 3.0, 1.0), 0.001)
		return
	# It keeps its depth for the first half of its time, then fills in
	var left := clampf((1.0 - age / lasts) * 2.0, 0.0, 1.0)
	mat.set_shader_parameter("depth", depth * left)
