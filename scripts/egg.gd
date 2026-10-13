class_name Egg
extends Node3D
## The egg a cryptlin comes out of. Lamplight warms it slowly and a rubbing finger warms it fast;
## it cracks twice on the way and hatches when it is warm through. Its shell tells you what is inside.

signal cracked(stage: int)
signal hatched

const WIDTH := 0.27
const HEIGHT := 0.36
const CENTRE := Vector3(0, 0.34, 0)
const RADII := Vector3(WIDTH, HEIGHT, WIDTH)
const SIZE := 1.25
# One for each kind of cryptlin (Cryptlin.Kind)
const SHELLS: Array[Color] = [
	Color(0.42, 0.52, 0.3), Color(0.34, 0.28, 0.21), Color(0.56, 0.5, 0.4), Color(0.4, 0.4, 0.44), Color(0.3, 0.36, 0.3),
	Color(0.26, 0.44, 0.24), Color(0.22, 0.36, 0.44), Color(0.36, 0.36, 0.38), Color(0.2, 0.2, 0.24),
]
const MARKS: Array[Color] = [
	Color(0.2, 0.3, 0.15), Color(0.2, 0.16, 0.12), Color(0.5, 0.18, 0.1), Color(0.6, 0.58, 0.56), Color(0.45, 0.14, 0.1),
	Color(0.5, 0.6, 0.3), Color(0.5, 0.66, 0.7), Color(0.2, 0.2, 0.22), Color(0.85, 0.82, 0.72),
]
const TITLES: Array[String] = [
	"A mossy egg", "A hairy egg", "A speckled egg", "A silk-wound egg", "A spiny egg",
	"A slimy egg", "A cold, wet egg", "A stone egg", "An antlered egg",
]

var world: Den
var kind := 0
var look_seed := 1
var warmth := 0.0
var stage := 0
var landed := true
var fall := 0.0
var rock := Vector2.ZERO
var rock_v := Vector2.ZERO
var stir := 2.0
var last_rub := -10.0
var t := 0.0
var hatching := -1.0
var shell: Node3D
var cracks: Array[Node3D] = []
var peek: MeshInstance3D
var shards: CPUParticles3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	scale = Vector3.ONE * SIZE
	shell = Node3D.new()
	add_child(shell)
	var base := Ps1.mat(SHELLS[kind])
	var mark := Ps1.mat(MARKS[kind])
	_part(Ps1.ball(), base, CENTRE, RADII)
	var point := CylinderMesh.new()
	point.top_radius = 0.0
	point.bottom_radius = 1.0
	point.height = 1.0
	point.radial_segments = 5
	match kind:
		Cryptlin.Kind.GREMLIN:
			# Warts
			for i in 8:
				var at := _on(rng.randf_range(-PI, PI), rng.randf_range(-0.9, 1.1))
				_part(Ps1.ball(), mark, at, Vector3.ONE * rng.randf_range(0.035, 0.07))
		Cryptlin.Kind.SQUATCH:
			# Hanks of hair all over, lying downwards
			for i in 16:
				var around := TAU * i / 16.0 + rng.randf_range(-0.15, 0.15)
				var hair := _part(point, mark if i % 2 == 0 else base, _on(around, rng.randf_range(-0.7, 1.0)))
				hair.basis = Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, 2.5) * Basis.from_scale(Vector3(0.05, rng.randf_range(0.1, 0.16), 0.03))
		Cryptlin.Kind.COCKATRICE:
			# Speckles
			for i in 14:
				var at := _on(rng.randf_range(-1.6, 1.6), rng.randf_range(-0.9, 1.2))
				_spot(mark, at, rng.randf_range(0.02, 0.045))
		Cryptlin.Kind.MOTHMAN:
			# Wound round with silk
			for i in 5:
				var band := _part(Ps1.ball(), mark, CENTRE + Vector3(0, -0.22 + i * 0.11, 0), Vector3.ONE)
				var wide := cos(asin((-0.22 + i * 0.11) / HEIGHT)) * WIDTH + 0.006
				band.basis = Basis.from_euler(Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))) * Basis.from_scale(Vector3(wide, 0.016, wide))
		Cryptlin.Kind.CHUPACABRA:
			# Spines all round, thickest at the top
			for i in 9:
				var around := TAU * i / 9.0
				var up := 0.15 + (i % 3) * 0.4
				var root := _on(around, up)
				var spike := _part(point, mark, root + _normal(root) * 0.07)
				spike.basis = Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, PI * 0.5 - up) * Basis.from_scale(Vector3(0.045, 0.2, 0.045))
		Cryptlin.Kind.FROGMAN:
			# Wet blotches
			for i in 7:
				_spot(mark, _on(rng.randf_range(-1.5, 1.5), rng.randf_range(-0.8, 1.1)), rng.randf_range(0.04, 0.075))
		Cryptlin.Kind.NESSIE:
			# Ripples
			for i in 3:
				var band := _part(Ps1.ball(), mark, CENTRE + Vector3(0, -0.12 + i * 0.12, 0), Vector3.ONE)
				var wide := cos(asin((-0.12 + i * 0.12) / HEIGHT)) * WIDTH + 0.005
				band.basis = Basis.from_scale(Vector3(wide, 0.012 + i * 0.004, wide))
		Cryptlin.Kind.BOLTER:
			# Chips of rock stuck in it
			var chip := BoxMesh.new()
			for i in 9:
				var at := _on(rng.randf_range(-PI, PI), rng.randf_range(-0.8, 1.1))
				_part(chip, mark if i % 2 == 0 else base, at, Vector3(0.09, 0.06, 0.08) * rng.randf_range(0.7, 1.3), Vector3(rng.randf(), rng.randf(), rng.randf()) * 2.0)
		Cryptlin.Kind.WENDIGO:
			# Two prongs of bone on top, and frost
			for side: float in [-1.0, 1.0]:
				_part(point, mark, CENTRE + Vector3(0.1 * side, 0.4, 0), Vector3(0.03, 0.26, 0.03), Vector3(0, 0, -0.45 * side))
				_part(point, mark, CENTRE + Vector3(0.17 * side, 0.4, 0), Vector3(0.02, 0.12, 0.02), Vector3(0, 0, -1.2 * side))
			var frost := Ps1.mat(Color(0.5, 0.6, 0.68))
			for i in 6:
				_spot(frost, _on(rng.randf_range(-1.5, 1.5), rng.randf_range(-0.9, 0.2)), rng.randf_range(0.03, 0.06))

	# The cracks, made ahead of time and shown as it warms
	var black := Ps1.flat(Color(0.02, 0.01, 0.02))
	var first: Array[Vector3] = [_on(-1.0, 0.25), _on(-0.7, 0.05), _on(-0.45, 0.3), _on(-0.2, 0.1)]
	var second: Array[Vector3] = [_on(-0.2, 0.1), _on(0.05, 0.38), _on(0.3, 0.12), _on(0.55, 0.36), _on(0.85, 0.15)]
	var branch: Array[Vector3] = [_on(0.05, 0.38), _on(-0.05, 0.7), _on(0.15, 0.9)]
	cracks = [_crack(black, [first]), _crack(black, [second, branch])]
	# Through the second crack, an eye
	var hole := _on(0.3, 0.6)
	var out := _normal(hole)
	var dark := _part(Ps1.ball(), black, hole, Vector3.ONE, Vector3.ZERO, cracks[1])
	dark.basis = Basis.looking_at(-out).scaled_local(Vector3(0.075, 0.06, 0.012))
	var eye_colour := Cryptlin.colours(kind, look_seed)[1]
	peek = _part(Ps1.ball(), Ps1.mat(eye_colour, 0.85), hole + out * 0.01, Vector3.ONE * 0.036, Vector3.ZERO, cracks[1])
	stage = clampi(int(warmth / 34.0), 0, 2)
	for i in cracks.size():
		cracks[i].visible = i < stage

	var bit := BoxMesh.new()
	bit.size = Vector3(0.09, 0.02, 0.07)
	bit.material = base
	shards = CPUParticles3D.new()
	shards.mesh = bit
	shards.one_shot = true
	shards.emitting = false
	shards.amount = 14
	shards.lifetime = 0.9
	shards.explosiveness = 1.0
	shards.direction = Vector3.UP
	shards.spread = 70.0
	shards.initial_velocity_min = 1.6
	shards.initial_velocity_max = 3.4
	shards.angular_velocity_min = -400.0
	shards.angular_velocity_max = 400.0
	shards.gravity = Vector3(0, -9, 0)
	shards.position = CENTRE
	add_child(shards)


func _part(mesh: Mesh, mat: Material, at: Vector3, size := Vector3.ONE, turn := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.scale = size
	mi.rotation = turn
	(shell if parent == null else parent).add_child(mi)
	return mi


# A flat mark lying on the shell
func _spot(mat: Material, at: Vector3, size: float) -> void:
	var spot := _part(Ps1.ball(), mat, at)
	spot.basis = Basis.looking_at(-_normal(at)).scaled_local(Vector3(size, size * 1.2, 0.008))


# A point on the shell: `around` is the angle from the front, `up` the angle above the middle
func _on(around: float, up: float) -> Vector3:
	return CENTRE + Vector3(sin(around) * cos(up), sin(up), cos(around) * cos(up)) * RADII


func _normal(at: Vector3) -> Vector3:
	return ((at - CENTRE) / (RADII * RADII)).normalized()


func _crack(mat: Material, lines: Array) -> Node3D:
	var group := Node3D.new()
	shell.add_child(group)
	for line: Array in lines:
		for i in line.size() - 1:
			var a: Vector3 = line[i]
			var b: Vector3 = line[i + 1]
			var box := BoxMesh.new()
			box.size = Vector3(0.024, 0.012, a.distance_to(b) + 0.02)
			var mid := (a + b) * 0.5
			var out := _normal(mid)
			var seg := _part(box, mat, mid, Vector3.ONE, Vector3.ZERO, group)
			seg.basis = Basis.looking_at(b - a, out)
			seg.position = mid + out * 0.002
	return group


func title() -> String:
	return TITLES[kind]


func centre() -> Vector3:
	return global_position + CENTRE * SIZE


func drop(from: Vector3) -> void:
	position = from
	fall = -1.0
	landed = false


# A finger rubbed over it
func rub() -> void:
	last_rub = t
	rock_v.x += sin(t * 23.0) * 0.5


# A tap: it knocks back
func tap() -> void:
	if hatching >= 0.0 or not landed:
		return
	warmth += 2.5
	rock_v += Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4)).normalized() * 4.5
	world.sfx.play("knock", 1.0 + stage * 0.15)


func _process(delta: float) -> void:
	t += delta
	if not landed:
		fall -= 14.0 * delta
		position.y += fall * delta
		if position.y <= 0.0:
			position.y = 0.0
			world.sfx.play("thud", 0.9, -5.0)
			if fall > -2.6:
				landed = true
				rock_v = Vector2(randf_range(-2.5, 2.5), 1.5)
			else:
				fall = -fall * 0.3
	elif hatching >= 0.0:
		hatching += delta
		rock = Vector2(sin(t * 38.0), cos(t * 31.0)) * 0.17
		rock_v = Vector2.ZERO
		if hatching > 1.3:
			set_process(false)
			hatched.emit()
			return
	else:
		if t - last_rub < 0.25:
			warmth += delta * 9.0
		var away := Vector2(position.x - world.light_point.x, position.z - world.light_point.z).length()
		if away < 1.8:
			warmth += delta * 1.1 * world.lamp_warmth()
		warmth = minf(warmth, 100.0)
		if warmth >= 100.0:
			hatching = 0.0
			world.sfx.play("crack", 0.8)
		elif int(warmth / 34.0) > stage:
			stage = int(warmth / 34.0)
			cracks[stage - 1].visible = true
			rock_v += Vector2(3.5, 1.0)
			world.sfx.play("crack")
			cracked.emit(stage)
		# Whatever is inside shifts about, more as it warms
		stir -= delta
		if stir <= 0.0:
			stir = randf_range(1.0, 4.5 - warmth * 0.03)
			var a := randf() * TAU
			rock_v += Vector2(cos(a), sin(a) * 0.5) * (1.6 + stage * 1.4)
			if stage > 0:
				world.sfx.play("knock", 0.8, -9.0)
	rock_v += (-rock * 90.0 - rock_v * 5.0) * delta
	rock += rock_v * delta
	shell.rotation = Vector3(rock.y, 0, rock.x)
	peek.scale.y = 0.036 * (0.1 if fmod(t, 2.7) < 0.12 else 1.0)


# The shell flies apart; the egg is gone a moment later
func burst() -> void:
	shell.visible = false
	shards.emitting = true
	get_tree().create_timer(1.5).timeout.connect(queue_free)
