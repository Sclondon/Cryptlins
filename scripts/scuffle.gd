class_name Scuffle
extends Node3D
## Two cryptlins that have come to blows, as it is drawn in the funny papers: a tumbling ball
## of dust with the odd limb coming out of it and stars flying off. The two themselves are out
## of sight until it is over (Den has them, and says when that is).

var t := 0.0
var size := 1.0
var ball: Node3D
var puffs: Array[MeshInstance3D] = []
var limbs: Array[Node3D] = []
var stars: Array[Node3D] = []
# When each limb was last thrown out, and which way each star is flying
var thrown: Array[float] = []
var ways: Array[Vector3] = []


# `tints` are the colours of the two in it; `big` is how big they are next to the usual
func _init(tints: Array[Color], big: float) -> void:
	size = big
	ball = Node3D.new()
	add_child(ball)
	var dust := Ps1.mat(Color(0.6, 0.56, 0.5))
	var pale := Ps1.mat(Color(0.74, 0.71, 0.66))
	for i in 7:
		var a := TAU * i / 7.0
		var at := Vector3(cos(a), sin(a * 2.0) * 0.6, sin(a)) * 0.2
		puffs.append(Ps1.part(ball, Ps1.ball(), dust if i % 2 == 0 else pale, at, Vector3.ONE * 0.2))
	var arm := CapsuleMesh.new()
	arm.radius = 0.05
	arm.height = 0.36
	arm.radial_segments = 5
	arm.rings = 2
	for i in 5:
		var limb := Node3D.new()
		ball.add_child(limb)
		var skin := Ps1.mat(tints[i % 2] * 0.76, 0.0, 0.35)
		Ps1.part(limb, arm, skin, Vector3(0, 0.3, 0))
		Ps1.part(limb, Ps1.ball(), skin, Vector3(0, 0.5, 0), Vector3.ONE * 0.075)
		limbs.append(limb)
		thrown.append(-1.0)
	var gold := Ps1.mat(Color(1.0, 0.85, 0.25), 1.0)
	for i in 3:
		var star := Node3D.new()
		add_child(star)
		for turn: float in [0.0, PI * 0.25]:
			Ps1.part(star, Ps1.box(), gold, Vector3.ZERO, Vector3(0.11, 0.11, 0.02), Vector3(0, 0, turn))
		stars.append(star)
		ways.append(Vector3.UP)
	# (drawn a good deal bigger than the two in it: it is all flying fur and dust)
	scale = Vector3.ONE * size * 1.6


func _process(delta: float) -> void:
	t += delta
	# The ball rolls about on the spot and bounces a little
	ball.position = Vector3(sin(t * 5.0) * 0.12, 0.3 + absf(sin(t * 9.0)) * 0.1, cos(t * 4.0) * 0.1)
	ball.rotation += Vector3(7.0, 5.0, 9.0) * delta
	for i in puffs.size():
		puffs[i].scale = Vector3.ONE * (0.2 + sin(t * 13.0 + i * 1.9) * 0.05)
	# A limb is thrown out of it every so often, and drawn back in
	for i in limbs.size():
		if t - thrown[i] > 0.55 and randf() < delta * 2.5:
			thrown[i] = t
			limbs[i].rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		limbs[i].scale = Vector3.ONE * maxf(sin(clampf((t - thrown[i]) / 0.45, 0.0, 1.0) * PI), 0.01)
	# Stars fly off it, one after another
	for i in stars.size():
		var u := fmod(t * 1.6 + i / 3.0, 1.0)
		if u < delta * 1.6:
			ways[i] = Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 1.2), randf_range(-0.3, 0.6)).normalized()
		stars[i].position = Vector3(0, 0.35, 0) + ways[i] * (0.25 + u * 0.55)
		stars[i].rotation.z = t * 6.0 + i
		stars[i].scale = Vector3.ONE * sin(u * PI)
