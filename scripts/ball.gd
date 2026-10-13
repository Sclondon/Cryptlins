class_name Ball
extends Node3D
## A toy: something that bounces or rolls, and can be picked up and thrown. A striped ball, a
## heavy stone, a bell that rings, or an orb that glows in the dark. Being played with wears it
## out: it gets scuffed, then cracked or patched and out of shape, and in the end it comes apart
## (see Den.wear_toy and Den.break_toy).
## Four more are each played with in a way of their own: a tin mouse that runs off by clockwork
## and is chased, a knot of rope that two of them pull between them, a rubber duck that squeaks
## when it is pounced on, and a top that is set spinning and watched.

signal bounced(strength: float)

enum Kind { BALL, STONE, BELL, GLOW, MOUSE, ROPE, DUCK, TOP }

const NAMES: Array[String] = ["Ball", "Stone", "Bell", "Glow orb", "Tin mouse", "Rope knot", "Rubber duck", "Top"]
# As in "its favourite toy is the ..."
const PLAIN: Array[String] = ["ball", "stone", "bell", "glow orb", "tin mouse", "rope knot", "rubber duck", "top"]
const R := 0.16
# How much wear it takes before it comes apart, and how worn it is when it starts to show: first
# scuffed, then badly gone
const WORN_OUT := 100.0
const SCUFFED := 35.0
const FAR_GONE := 70.0
# How much one kick from an ordinary grown cryptlin wears each (see Cryptlin.rough): the stone
# takes the most killing and the orb the least. Three of them with the ball on the floor get some
# 370 kicks at it in ten minutes and one by itself some 50, so at ten minutes of play a day a
# ball lasts a room of three about three days, and one alone some weeks.
# The four that came later wear by each time one is pounced on, tossed or set going, which is
# less often than a ball is kicked: the mouse's clockwork and the top go soonest, the duck much as
# the ball does, and the rope lasts nearly as long as the stone (a pull at it counts as two for
# each of the two pulling).
const WEARS: Array[float] = [0.12, 0.06, 0.09, 0.16, 0.2, 0.07, 0.14, 0.18]
# The colour of the bits each leaves when it breaks
const TINTS: Array[Color] = [Color(0.85, 0.42, 0.12), Color(0.36, 0.35, 0.37), Color(0.6, 0.45, 0.14), Color(0.5, 0.9, 0.6), Color(0.5, 0.56, 0.66), Color(0.74, 0.62, 0.4), Color(0.96, 0.8, 0.14), Color(0.78, 0.16, 0.12)]
# How fast the mouse runs, how long a pull at the rope lasts once both have hold, and how far
# from the middle of it each of them stands (and more for each by its size)
const SCURRY := 1.75
const PULL := 2.8
const REACH := 0.4

var kind: int = Kind.BALL
var vel := Vector3.ZERO
var held := false
var mesh: MeshInstance3D
# How it behaves: how much of a fall it bounces back, how fast it stops rolling, how far a kick
# sends it, how hard it falls, and the sound it makes
var bounce := 0.62
var drag := 1.1
var heft := 1.0
var fall := 12.0
var sound := "boing"
var pitch := 1.0
# How worn it is with being played with, 0 to WORN_OUT, and whether it was bought (and so is one
# of a few) or is one of a kind there is no end of
var wear := 0.0
var bought := false
# Its own shape, the bounce it had when new, and how worn it was last painted (-1: not yet)
var shape := Vector3.ONE
var spring := 0.62
var painted := -1
# The four that came later are built of parts under `mesh` and move in ways of their own: how
# long the mouse has left to run or the top to spin, which way it is turned, how far over the top
# leans and how far round it has spun (or the mouse's key has), how squashed it is just now, how
# taut, whether it is off the floor, and how it sags with wear
var go := 0.0
var turn := 0.0
var tilt := 0.0
var whirl := 0.0
var squeeze := 0.0
var taut := 0.0
var aloft := false
var sag := Vector3.ONE
var key: Node3D
# The two that have the rope between them, how long since they set about it and since both had
# hold (-1: not yet), and where it lay and which way they stand along it
var pullers: Array[Cryptlin] = []
var pull_time := 0.0
var pull_from := -1.0
var pull_at := Vector3.ZERO
var pull_along := Vector3.RIGHT


func _init(which: int = Kind.BALL) -> void:
	kind = which
	var sphere := SphereMesh.new()
	sphere.radius = R
	sphere.height = R * 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	mesh = MeshInstance3D.new()
	mesh.mesh = sphere
	add_child(mesh)
	match kind:
		Kind.STONE:
			bounce = 0.22
			drag = 3.5
			heft = 0.6
			fall = 16.0
			sound = "thud"
			pitch = 1.1
			sphere.radial_segments = 7
			sphere.rings = 3
			shape = Vector3(1.0, 0.82, 0.9)
		Kind.BELL:
			bounce = 0.5
			drag = 1.4
			sound = "jingle"
		Kind.GLOW:
			bounce = 0.72
			drag = 0.7
			heft = 0.85
			fall = 6.5
			pitch = 1.6
		Kind.MOUSE:
			bounce = 0.2
			drag = 2.6
			heft = 0.5
			fall = 14.0
			sound = "click"
			pitch = 1.5
		Kind.ROPE:
			bounce = 0.15
			drag = 4.0
			heft = 0.6
			fall = 13.0
			sound = "thud"
			pitch = 1.5
		Kind.DUCK:
			bounce = 0.72
			drag = 1.6
			heft = 0.9
			fall = 10.0
			sound = "squeak"
			pitch = 1.3
			bounced.connect(func(strength: float) -> void:
				if strength > 2.5:
					squeak())
		Kind.TOP:
			bounce = 0.25
			drag = 2.2
			heft = 0.45
			fall = 14.0
			sound = "knock"
			pitch = 1.4
	if kind >= Kind.MOUSE:
		mesh.mesh = null
	spring = bounce
	show_wear()


# How far gone it is: 0 as good as new, 1 scuffed, 2 cracked or patched and out of shape
func stage() -> int:
	return 2 if wear >= FAR_GONE else (1 if wear >= SCUFFED else 0)


# Makes it look as worn as it is: scuffs painted on it, then a patch or a crack, and it sags,
# bounces less and (the orb) glows less
func show_wear() -> void:
	var s := stage()
	if s == painted:
		return
	painted = s
	if kind >= Kind.MOUSE:
		_dress(s)
		return
	var tex := _texture(func(x: int, y: int) -> Color: return _paint(x, y, s))
	match kind:
		Kind.BELL:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.3 - 0.12 * s, tex)
		Kind.GLOW:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.9 - 0.35 * s, 0.0, tex)
		_:
			mesh.material_override = Ps1.mat(Color.WHITE, 0.0, 0.0, tex)
	var sag: Vector3 = [Vector3.ONE, Vector3(1.04, 0.9, 1.0), Vector3(1.12, 0.74, 0.98)][s]
	mesh.basis = mesh.basis.orthonormalized() * Basis.from_scale(shape * sag)
	bounce = spring * (1.0 - 0.18 * s)


# One dot of what is painted on it, 64 round and 32 down: its own pattern, and over that the
# marks of however much wear
func _paint(x: int, y: int, worn: int) -> Color:
	var c: Color
	match kind:
		Kind.STONE:
			var speck := (x * 7 + y * 13) % 11 == 0
			c = Color(0.2, 0.2, 0.22) if speck else Color(0.36, 0.35, 0.36).lerp(Color(0.3, 0.3, 0.33), float((x / 9 + y / 7) % 2))
		Kind.BELL:
			# Brass, with a dark slot round the middle
			c = Color(0.08, 0.06, 0.03) if y >= 17 and y <= 19 else Color(0.62, 0.46, 0.14).lerp(Color(0.44, 0.3, 0.08), y / 32.0)
		Kind.GLOW:
			var swirl := sin(x * 0.4 + y * 0.5) * 0.5 + 0.5
			c = Color(0.45, 0.95, 0.6).lerp(Color(0.85, 1.0, 0.7), swirl)
		_:
			if y < 4 or y > 27:
				c = Color(0.95, 0.9, 0.75)
			else:
				c = Color(0.95, 0.45, 0.08) if (x / 8) % 2 == 0 else Color(0.36, 0.16, 0.5)
	if worn == 0:
		return c
	# Scuffs: it is duller all over, with grey scrapes on it in blocks big enough to see across
	# the room, a few when it is only scuffed and many when it is far gone
	var grime := Color(0.4, 0.38, 0.34) if kind != Kind.GLOW else Color(0.16, 0.3, 0.22)
	c = c.lerp(grime, 0.22 if worn == 1 else 0.42)
	if ((x / 3) * 5 + (y / 2) * 11) % (9 if worn == 1 else 5) < 2:
		c = c.lerp(grime, 0.75)
	if worn < 2:
		return c
	if kind == Kind.BALL:
		# A big square of sacking sewn over a split, on either side of it, with the stitches showing
		var px := x % 32 - 7
		var py := y - 8
		if px >= 0 and px <= 15 and py >= 0 and py <= 15:
			var hem := px <= 1 or px >= 14 or py <= 1 or py >= 14
			return Color(0.1, 0.08, 0.06) if hem and (px / 2 + py / 2) % 2 == 0 else Color(0.74, 0.66, 0.48).lerp(Color(0.6, 0.52, 0.38), float((px / 2 + py / 2) % 2))
	else:
		# A wide crack right round it, wandering, with another running off it; and on the bell a
		# bloom of green where the brass has gone
		var line := 14 + int(sin(x * 0.55) * 3.0 + sin(x * 0.21) * 2.0)
		if absi(y - line) <= 2 or (x % 32 > 10 and x % 32 < 16 and y > line and y < line + 10):
			return Color(0.04, 0.04, 0.05) if kind != Kind.GLOW else Color(0.03, 0.1, 0.07)
		if kind == Kind.BELL and (x / 5 + y / 4) % 4 == 0:
			return c.lerp(Color(0.2, 0.5, 0.4), 0.8)
	return c


func _texture(paint: Callable) -> ImageTexture:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 64:
			img.set_pixel(x, y, paint.call(x, y))
	return ImageTexture.create_from_image(img)


func speed() -> float:
	return vel.length()


func _process(delta: float) -> void:
	if not pullers.is_empty():
		_tug(delta)
		return
	if held:
		if kind >= Kind.MOUSE and (tilt != 0.0 or squeeze != 0.0):
			# (in the hand it is held upright and in its own shape)
			tilt = 0.0
			squeeze = 0.0
			_pose()
		return
	# On the floor it rests on the floor; out in the pool it floats
	var out := Den.wade(position)
	var rest := lerpf(R, Decor.WATER + R * 0.4, smoothstep(0.0, 0.2, out))
	vel.y -= fall * delta
	position += vel * delta
	if position.y < rest:
		position.y = rest
		if vel.y < -0.9:
			bounced.emit(-vel.y)
			vel.y = -vel.y * bounce * (0.25 if out > 0.0 else 1.0)
		else:
			vel.y = 0.0
	var flat := Vector3(vel.x, 0, vel.z)
	if position.y <= rest + 0.001:
		flat = flat.move_toward(Vector3.ZERO, delta * drag)
		if out > 0.0:
			# The water takes the way off it, and it drifts back to the edge and out onto the floor
			flat = flat.move_toward((Den.shore_by(position, R + 0.1) - position).normalized() * 0.55, delta * 3.0)
		vel.x = flat.x
		vel.z = flat.z
	# The walls of the room, and the unseen one across the front
	var wide := Den.half.x - R
	var deep := Den.half.y - R
	if absf(position.x) > wide:
		if vel.x * position.x > 0.0:
			bounced.emit(absf(vel.x))
			vel.x *= -0.7
		position.x = clampf(position.x, -wide, wide)
	if absf(position.z) > deep:
		if vel.z * position.z > 0.0:
			bounced.emit(absf(vel.z))
			vel.z *= -0.7
		position.z = clampf(position.z, -deep, deep)
	if kind >= Kind.MOUSE:
		_act(delta, Vector3(vel.x, 0, vel.z), position.y <= rest + 0.001, out > 0.0)
	elif flat.length() > 0.02:
		mesh.rotate(Vector3.UP.cross(flat).normalized(), flat.length() / R * delta)


# ---------------------------------------------------------------- the four that came later

# What each of them does with itself, once a frame: `flat` is how it is moving over the floor,
# `down` whether it is on it and `wet` whether that is in the pool
func _act(delta: float, flat: Vector3, down: bool, wet: bool) -> void:
	if not down:
		aloft = true
	elif aloft:
		# Set down, thrown or pounced on, the mouse is wound and the top is spun (but not in water)
		aloft = false
		if kind == Kind.MOUSE and not wet:
			go = randf_range(2.8, 3.8)
			if flat.length() > 0.3:
				turn = atan2(flat.x, flat.z)
		elif kind == Kind.TOP and not wet:
			go = randf_range(5.0, 7.0)
	if wet:
		go = 0.0
	match kind:
		Kind.MOUSE:
			if go > 0.0 and down:
				# It runs where its nose points, wandering as it goes, and turns aside from the
				# walls and from the water; its key goes round, and it ticks
				go -= delta
				var before := whirl
				whirl += delta * 14.0
				turn += sin(whirl * 0.17 + 1.0) * 1.8 * delta
				var next := position + Vector3(sin(turn), 0, cos(turn)) * 0.55
				if absf(next.x) > Den.half.x - R or absf(next.z) > Den.half.y - R or Den.wade(next) > -0.1:
					turn += 4.5 * delta
				flat = flat.move_toward(Vector3(sin(turn), 0, cos(turn)) * SCURRY, delta * 9.0)
				vel.x = flat.x
				vel.z = flat.z
				if int(whirl / 2.8) != int(before / 2.8):
					bounced.emit(0.0)
			elif flat.length() > 0.3:
				turn = atan2(flat.x, flat.z)
		Kind.TOP:
			if go > 0.0 and down:
				# It stands on its point and wanders in a slow curve, leaning further as it slows
				go -= delta
				whirl += delta * 24.0 * clampf(go / 1.5, 0.35, 1.0)
				turn += delta * 1.1
				flat = flat.move_toward(Vector3(sin(turn), 0, cos(turn)) * 0.32, delta * 4.0)
				vel.x = flat.x
				vel.z = flat.z
				tilt = lerpf(0.42, 0.07, clampf(go / 1.6, 0.0, 1.0))
			else:
				# Run down it falls over on its side; in the air it is upright
				tilt = move_toward(tilt, 1.2 if down else 0.0, delta * 5.0)
		Kind.DUCK:
			if flat.length() > 0.4:
				turn = lerp_angle(turn, atan2(flat.x, flat.z), 1.0 - exp(-delta * 8.0))
		Kind.ROPE:
			if not down:
				turn += delta * 7.0
	squeeze = move_toward(squeeze, 0.0, delta * 4.0)
	_pose()


# Stands its parts as it is just now: turned, leaning, squashed or stretched, and sagging with wear
func _pose() -> void:
	var wide := 1.0 + 0.3 * squeeze
	var size := sag * Vector3(wide, 1.0 - 0.5 * squeeze, wide)
	var stood := Basis(Vector3.UP, turn)
	# (its foot stays on the floor however it is squashed)
	mesh.position.y = -R * (1.0 - size.y)
	match kind:
		Kind.TOP:
			stood = stood * Basis(Vector3.RIGHT, tilt) * Basis(Vector3.UP, whirl)
			mesh.position.y -= 0.03 * clampf(tilt / 1.2, 0.0, 1.0)
		Kind.ROPE:
			size *= Vector3(1.0 + taut, 1.0 - 0.12 * taut, 1.0 - 0.12 * taut)
		Kind.MOUSE:
			if key != null:
				key.rotation.y = whirl
	mesh.basis = stood * Basis.from_scale(size)


# A cryptlin has pounced on it or batted it, facing along `dir`: the mouse is knocked a little way
# and runs off when it lands, the top is set spinning, the rope is tossed, and the duck goes up
# like a ball and squeaks. The rest are kicked as they always were.
func kicked(dir: Vector3, by: Cryptlin = null) -> void:
	match kind:
		Kind.MOUSE:
			vel = dir * 1.0 + Vector3.UP * 1.8
			turn = atan2(dir.x, dir.z)
		Kind.TOP:
			vel = dir * 0.9 + Vector3.UP * 1.4
			turn = atan2(dir.x, dir.z)
		Kind.ROPE:
			vel = dir * randf_range(1.5, 2.3) + Vector3.UP * randf_range(2.2, 3.0)
		_:
			vel = (dir * randf_range(2.4, 4.2) + Vector3.UP * randf_range(2.0, 3.8)) * heft
	if kind == Kind.DUCK:
		squeak(by)


# The duck squeaks, squashed flat for a moment: any of them near by that cannot bear the noise
# jumps (see Cryptlin.hear_squeak), but not the one that made it do so
func squeak(by: Cryptlin = null) -> void:
	squeeze = 1.0
	var den := get_parent() as Den
	if den == null:
		return
	for pet in den.pets():
		if pet != by and pet.position.distance_to(position) < 2.4:
			pet.hear_squeak(position)


# Two of them take the rope between them: `first` has got to it, and `other` was after it too
func pull(first: Cryptlin, other: Cryptlin) -> void:
	pullers = [first, other]
	pull_time = 0.0
	pull_from = -1.0
	pull_at = Vector3(position.x, 0, position.z)
	pull_along = Vector3(other.position.x - first.position.x, 0, other.position.z - first.position.z)
	pull_along = pull_along.normalized() if pull_along.length() > 0.05 else Vector3.RIGHT
	held = true
	vel = Vector3.ZERO


# Where one of the two stands to take its end
func end_of(who: Cryptlin) -> Vector3:
	return pull_at + pull_along * (-1.0 if who == pullers[0] else 1.0) * (REACH + 0.3 * who.grow)


# Whether both have hold of it and are pulling
func taken() -> bool:
	return pull_from >= 0.0


# The pull itself: it lies where it was until each has its end, then is up off the floor between
# them, taut and jerked to and fro, and after a few seconds one of them has it off the other (the
# rougher and bigger one more often than not). A finger on it, or either of them called away,
# and it is let go.
func _tug(delta: float) -> void:
	var den := get_parent() as Den
	var a := pullers[0]
	var b := pullers[1]
	var fingered := den != null and den.grab == Den.Grab.BALL
	if fingered or not is_instance_valid(a) or not is_instance_valid(b) or a.state != Cryptlin.State.CHASE_BALL or b.state != Cryptlin.State.CHASE_BALL:
		pullers.clear()
		taut = 0.0
		held = fingered
		_pose()
		# (whichever of them is still after it stands up out of its pull)
		for left: Variant in [a, b]:
			if is_instance_valid(left) and left.state == Cryptlin.State.CHASE_BALL:
				left._enter(Cryptlin.State.CHASE_BALL)
		return
	pull_time += delta
	if pull_from < 0.0:
		position.y = move_toward(position.y, R, delta * 2.0)
		if pull_time > 2.5 or (a.position.distance_to(end_of(a)) < 0.25 and b.position.distance_to(end_of(b)) < 0.25):
			pull_from = pull_time
		return
	var since := pull_time - pull_from
	var span := Vector3(b.position.x - a.position.x, 0, b.position.z - a.position.z)
	var mid := (a.position + b.position) * 0.5 + span.normalized() * sin(since * 11.0) * 0.06
	position = Vector3(mid.x, R + 0.06 + 0.1 * (a.grow + b.grow), mid.z)
	turn = atan2(-span.z, span.x)
	# (stretched to reach from the one to the other)
	taut = minf(since * 4.0, 1.0) * clampf((span.length() - 0.3 * (a.grow + b.grow)) / 0.5 - 1.0, 0.0, 1.2)
	_pose()
	if since < PULL:
		return
	var pulls: Array[float] = [a.rough() * a.grow, b.rough() * b.grow]
	var won := a if randf() < clampf(pulls[0] / (pulls[0] + pulls[1]), 0.2, 0.8) else b
	var lost := b if won == a else a
	pullers.clear()
	taut = 0.0
	held = false
	vel = Vector3(won.position.x - position.x, 0, won.position.z - position.z).normalized() * 1.2 + Vector3.UP * 2.6
	won.tug_over(self, lost, true)
	lost.tug_over(self, won, false)


# Builds one of the four out of its parts, as worn as it is: duller and grimier, and far gone
# the mouse has lost an ear and has its key bent, the rope is frayed, the duck is patched and
# the top is cracked
func _dress(worn: int) -> void:
	for old in mesh.get_children():
		mesh.remove_child(old)
		old.queue_free()
	key = null
	var grime := Color(0.4, 0.38, 0.34)
	var dull: float = [0.0, 0.3, 0.5][worn]
	var gone := worn == 2
	var floor_y := -R
	match kind:
		Kind.MOUSE:
			# (a good size for a mouse, so that it shows across the room)
			var frame := Node3D.new()
			frame.scale = Vector3.ONE * 1.2
			frame.position.y = floor_y * -0.2
			mesh.add_child(frame)
			var tin := Ps1.mat(Color(0.44, 0.52, 0.7).lerp(grime, dull), 0.0, 0.35 - 0.15 * worn)
			var dark := Ps1.mat(Color(0.12, 0.12, 0.15))
			var pink := Ps1.mat(Color(0.9, 0.52, 0.55).lerp(grime, dull))
			var brass := Ps1.mat(Color(0.82, 0.62, 0.18).lerp(grime, dull), 0.0, 0.3)
			Ps1.part(frame, Ps1.ball(), tin, Vector3(0, floor_y + 0.11, -0.03), Vector3(0.12, 0.1, 0.18))
			Ps1.part(frame, Ps1.drum(6, 0.0), tin, Vector3(0, floor_y + 0.09, 0.17), Vector3(0.075, 0.14, 0.065), Vector3(PI * 0.5, 0, 0))
			Ps1.part(frame, Ps1.ball(), pink, Vector3(0, floor_y + 0.09, 0.24), Vector3.ONE * 0.022)
			# (a red saddle painted on its back)
			Ps1.part(frame, Ps1.ball(), Ps1.mat(Color(0.8, 0.18, 0.14).lerp(grime, dull)), Vector3(0, floor_y + 0.135, -0.05), Vector3(0.095, 0.085, 0.1))
			for side: float in [-1.0, 1.0]:
				if not (gone and side > 0.0):
					Ps1.part(frame, Ps1.ball(), pink, Vector3(0.075 * side, floor_y + 0.2, 0.07), Vector3(0.055, 0.055, 0.014), Vector3(0, 0.3 * side, 0))
				Ps1.part(frame, Ps1.ball(), dark, Vector3(0.05 * side, floor_y + 0.13, 0.13), Vector3.ONE * 0.02)
				Ps1.part(frame, Ps1.drum(6), dark, Vector3(0.1 * side, floor_y + 0.045, -0.06), Vector3(0.045, 0.03, 0.045), Vector3(0, 0, PI * 0.5))
			Ps1.part(frame, Ps1.box(), pink, Vector3(0, floor_y + 0.07, -0.23), Vector3(0.018, 0.018, 0.11), Vector3(0.45, 0, 0))
			# Its key, standing up out of its back: it goes round while it runs
			key = Node3D.new()
			key.position = Vector3(0, floor_y + 0.2, -0.07)
			frame.add_child(key)
			Ps1.part(key, Ps1.drum(5), brass, Vector3(0, 0.03, 0), Vector3(0.012, 0.07, 0.012))
			Ps1.part(key, Ps1.box(), brass, Vector3(0, 0.1, 0), Vector3(0.13, 0.075, 0.016), Vector3(0, 0, 0.5 if gone else 0.0))
			if gone:
				Ps1.part(frame, Ps1.ball(), dark, Vector3(0.07, floor_y + 0.14, -0.08), Vector3(0.05, 0.05, 0.05))
		Kind.ROPE:
			# It lies along X: a big knot in the middle, a smaller one at each end, and a tassel
			# beyond that, with the lay of the rope painted round it
			var hemp := Color(0.8, 0.68, 0.42).lerp(grime, dull)
			var twist := Ps1.mat(Color.WHITE, 0.0, 0.0, _texture(func(x: int, y: int) -> Color:
				return hemp.darkened(0.3) if (x + y) % 8 < 3 else hemp))
			var plain := Ps1.mat(hemp)
			var low := floor_y + 0.06
			var thick := 0.042 if gone else 0.05
			Ps1.part(mesh, Ps1.drum(6), twist, Vector3(0, low, 0), Vector3(thick, 0.36, thick), Vector3(0, 0, PI * 0.5))
			Ps1.part(mesh, Ps1.ball(), twist, Vector3(0, low + 0.03, 0), Vector3(0.1, 0.09, 0.1))
			Ps1.part(mesh, Ps1.ball(), plain, Vector3(0.03, low + 0.07, 0.03), Vector3(0.06, 0.05, 0.07), Vector3(0, 0.6, 0.4))
			for side: float in [-1.0, 1.0]:
				Ps1.part(mesh, Ps1.ball(), twist, Vector3(0.17 * side, low, 0), Vector3(0.065, 0.06, 0.065))
				Ps1.part(mesh, Ps1.drum(6, 0.35), Ps1.mat(Color(0.75, 0.2, 0.16).lerp(grime, dull)), Vector3(0.225 * side, low, 0), Vector3(0.06, 0.07, 0.06), Vector3(0, 0, PI * 0.5 * side))
			if gone:
				# (strands of it have come loose and stand out)
				for i in 5:
					var way := (i % 2) * 2.0 - 1.0
					Ps1.part(mesh, Ps1.box(), plain, Vector3(-0.12 + i * 0.06, low + 0.05, 0.03 * way), Vector3(0.012, 0.09, 0.012), Vector3(0.5 * way, 0, 0.5 * ((i % 3) - 1)))
		Kind.DUCK:
			var rubber := Ps1.mat(Color(0.98, 0.82, 0.14).lerp(grime, dull), 0.0, 0.25 - 0.1 * worn)
			var bill := Ps1.mat(Color(0.95, 0.42, 0.08).lerp(grime, dull))
			var dark := Ps1.mat(Color(0.06, 0.06, 0.08))
			Ps1.part(mesh, Ps1.ball(), rubber, Vector3(0, floor_y + 0.11, -0.03), Vector3(0.15, 0.11, 0.18))
			Ps1.part(mesh, Ps1.drum(5, 0.0), rubber, Vector3(0, floor_y + 0.17, -0.19), Vector3(0.07, 0.1, 0.05), Vector3(-0.7, 0, 0))
			Ps1.part(mesh, Ps1.ball(), rubber, Vector3(0, floor_y + 0.25, 0.08), Vector3.ONE * 0.1)
			Ps1.part(mesh, Ps1.ball(), bill, Vector3(0, floor_y + 0.225, 0.19), Vector3(0.065, 0.026, 0.06))
			for side: float in [-1.0, 1.0]:
				Ps1.part(mesh, Ps1.ball(), dark, Vector3(0.055 * side, floor_y + 0.28, 0.155), Vector3.ONE * 0.022)
				Ps1.part(mesh, Ps1.ball(), Ps1.mat(Color(0.9, 0.7, 0.1).lerp(grime, dull)), Vector3(0.14 * side, floor_y + 0.12, -0.05), Vector3(0.03, 0.065, 0.11), Vector3(0.25, 0, 0))
			if gone:
				# (a square of sacking stuck over a split in its side, and a scrape on its head)
				Ps1.part(mesh, Ps1.box(), Ps1.mat(Color(0.7, 0.62, 0.46)), Vector3(0.1, floor_y + 0.13, 0.06), Vector3(0.09, 0.09, 0.09), Vector3(0, 0.5, 0))
				Ps1.part(mesh, Ps1.ball(), Ps1.mat(grime), Vector3(-0.04, floor_y + 0.32, 0.05), Vector3(0.05, 0.03, 0.05))
		Kind.TOP:
			# Bands of colour down it, and a few slanting stripes so that its spinning shows
			var bands: Array[Color] = [Color(0.8, 0.14, 0.12), Color(0.96, 0.8, 0.2), Color(0.16, 0.36, 0.7)]
			var body := Ps1.mat(Color.WHITE, 0.0, 0.2, _texture(func(x: int, y: int) -> Color:
				var band := bands[(y / 3) % 3]
				if (x + y) % 16 < 3:
					band = Color(0.95, 0.93, 0.86)
				if gone and absi(x % 32 - 12 - y / 2) <= 1:
					band = Color(0.05, 0.04, 0.04)
				return band.lerp(grime, dull)))
			var wood := Ps1.mat(Color(0.62, 0.42, 0.2).lerp(grime, dull))
			Ps1.part(mesh, Ps1.drum(8, 0.0), body, Vector3(0, floor_y + 0.1, 0), Vector3(0.15, 0.2, 0.15), Vector3(PI, 0, 0))
			Ps1.part(mesh, Ps1.drum(8, 0.4), body, Vector3(0, floor_y + 0.23, 0), Vector3(0.15, 0.06, 0.15))
			Ps1.part(mesh, Ps1.drum(6), wood, Vector3(0, floor_y + 0.31, 0), Vector3(0.022, 0.1, 0.022))
			Ps1.part(mesh, Ps1.ball(), wood, Vector3(0, floor_y + 0.37, 0), Vector3.ONE * 0.034)
	sag = [Vector3.ONE, Vector3(1.03, 0.94, 1.0), Vector3(1.08, 0.84, 1.0)][worn]
	bounce = spring * (1.0 - 0.18 * worn)
	_pose()
