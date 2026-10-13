class_name Track
extends Node3D
## A footprint pressed into the floor by one of the heavy kinds as it walks: a few flat dark
## shapes that fade back into the ground and are gone. Only something to look at: it is not
## kept in the save, is not a mess, and nothing can be done to it.

const SHADER: Shader = preload("res://shaders/print.gdshader")
# How long a print shows on a soft floor and on a hard one (seconds), and how much darker than
# the ground it starts on each
const LASTS_SOFT := 90.0
const LASTS_HARD := 40.0
const DEPTH_SOFT := 0.55
const DEPTH_HARD := 0.24

var age := 0.0
var lasts := LASTS_HARD
var depth := DEPTH_HARD
var mat: ShaderMaterial


# `shape` is whose foot it was ("sasquatch": a long sole and five toes, the big one inside),
# `side` -1 for a left foot and 1 for a right, `big` how big next to the usual
func _init(shape: String, side: float, big: float, soft: bool) -> void:
	lasts = LASTS_SOFT if soft else LASTS_HARD
	depth = DEPTH_SOFT if soft else DEPTH_HARD
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("depth", depth)
	scale = Vector3.ONE * big
	match shape:
		"sasquatch":
			_pad(Vector3(0, 0, -0.03), Vector2(0.105, 0.17))
			_pad(Vector3(0.01 * side, 0, -0.16), Vector2(0.075, 0.08))
			for toe in 5:
				var size := 0.052 - toe * 0.006
				_pad(Vector3((toe - 2.0) * 0.058 * side, 0, 0.21 - toe * 0.02), Vector2(size, size * 1.25))


# One flat patch of the print, so far across and so long
func _pad(at: Vector3, size: Vector2) -> void:
	var pad := Ps1.part(self, Ps1.drum(7), mat, at + Vector3(0, 0.003, 0), Vector3(size.x, 0.004, size.y))
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	age += delta
	if age >= lasts:
		queue_free()
		return
	# It keeps its depth for the first half of its time, then fills in
	var left := clampf((1.0 - age / lasts) * 2.0, 0.0, 1.0)
	mat.set_shader_parameter("depth", depth * left)
