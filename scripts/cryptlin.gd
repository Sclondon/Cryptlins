class_name Cryptlin
extends Node3D
## One cryptlin: its body (built from primitives, shaped by a seed), its needs, its small brain,
## and its animation, which is all done here in code. It faces +Z.

enum State {
	IDLE, WANDER, STARE, LURK, COME, GO_FOOD, EAT, CHASE_BALL, CHASE_LIGHT,
	BEG, ZOOMIES, DANCE, PETTED, STARTLED, GO_SLEEP, SLEEP,
}

const WALK := 1.0
const RUN := 2.6
const ROOM := 4.6
const REST_ARM := Vector3(0.0, 0.0, 0.35)
const UP_ARM := Vector3(-0.3, 0.0, 2.5)
const BELLY_ARM := Vector3(-0.9, 0.0, -0.35)
# States that give way to food, a thrown ball, the moving light or tiredness
const INTERRUPTIBLE: Array[int] = [
	State.IDLE, State.WANDER, State.STARE, State.LURK, State.COME, State.BEG, State.ZOOMIES, State.DANCE,
]
const FURS: Array[Color] = [
	Color(0.36, 0.5, 0.3), Color(0.44, 0.36, 0.56), Color(0.26, 0.47, 0.48),
	Color(0.46, 0.46, 0.5), Color(0.58, 0.36, 0.26), Color(0.52, 0.52, 0.3),
]
const EYES: Array[Color] = [
	Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.15), Color(0.6, 1.0, 0.3), Color(1.0, 0.45, 0.7), Color(0.4, 0.95, 1.0),
]

var world: Crypt
var look_seed := 1

# Needs, 0 (bad) to 100 (good)
var belly := 70.0
var fun := 60.0
var energy := 80.0
var love := 20.0

var state: int = State.IDLE
var state_time := 0.0
var state_len := 2.0
var step := 0
var velocity := Vector3.ZERO
var yaw := 0.0
var target := Vector3.ZERO
var gaze := Vector3.ZERO
var snack: Snack
var kicks := 0
var kicks_total := 0
var kick_limit := 3
var ball_cooldown := 0.0
var beg_cooldown := 6.0
var pounce_cooldown := 0.0
var last_stroke := -10.0
var beg_for_ball := false
var glance_time := 0.0
var glance_point := Vector3.ZERO

# Animation: states set the goals, _animate() eases toward them
var anim_t := 0.0
var phase := 0.0
var gait := 0.0
var sit := 0.0
var sit_goal := 0.0
var curl := 0.0
var curl_goal := 0.0
var eye_open := 1.0
var eye_goal := 1.0
var blink := 2.0
var mouth := 0.12
var mouth_goal := 0.12
var droop := 0.1
var droop_goal := 0.1
var twitch := 0.0
var twitch_side := 0
var head_yaw := 0.0
var head_pitch := 0.0
var head_roll := 0.0
var roll_goal := 0.0
var nod := 0.0
var arm := REST_ARM
var arm_goal := REST_ARM
var arm_wave := 0.0
var wag := 3.0
var wiggle := 0.0
var squash := 0.0
var squash_v := 0.0
var jump_y := 0.0
var jump_v := 0.0
var airborne := false

var torso: Node3D
var neck: Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var ears: Array[Node3D] = []
var eyes: Array[Node3D] = []
var pupils: Array[Node3D] = []
var mouth_node: Node3D
var tail: Node3D
var bubble: Node3D
var bubble_food: Node3D
var bubble_ball: Node3D
var hearts: CPUParticles3D
var zzz: Array[Label3D] = []


func _ready() -> void:
	_build()
	position = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.6, 0.8))
	_enter(State.IDLE, 1.5)


# ---------------------------------------------------------------- body

func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var fur_colour: Color = FURS[rng.randi() % FURS.size()]
	var eye_colour: Color = EYES[rng.randi() % EYES.size()]
	var ear_len := rng.randf_range(0.34, 0.52)
	var chub := rng.randf_range(0.94, 1.14)
	var horns := rng.randf() < 0.45
	var odd_eyes := rng.randf() < 0.35
	var fur := _fur(fur_colour * 0.82)
	var pale := _fur(fur_colour.lightened(0.25))
	var dark := _fur(fur_colour.darkened(0.5))
	var bone := _fur(Color(0.92, 0.89, 0.78))
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.02, 0.01, 0.02)
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var maw := StandardMaterial3D.new()
	maw.albedo_color = Color(0.16, 0.03, 0.06)
	maw.roughness = 0.6
	# The eyes give off their own light, so they are all you see of it in the dark
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = eye_colour
	eye_mat.roughness = 0.2
	eye_mat.emission_enabled = true
	eye_mat.emission = eye_colour
	eye_mat.emission_energy_multiplier = 0.85

	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.13 * side, 0.2, 0))
		_part(leg, _capsule(0.07, 0.2), fur, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.16, 0.06), Vector3(0.09, 0.05, 0.14))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.42, 0), Vector3(0.3 * chub, 0.3, 0.27 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.39, 0.17 * chub), Vector3(0.21 * chub, 0.21, 0.12))
	tail = _pivot(torso, Vector3(0, 0.3, -0.22 * chub))
	_part(tail, _capsule(0.035, 0.3), fur, Vector3(0, 0.08, -0.12), Vector3.ONE, Vector3(-1.0, 0, 0))
	_part(tail, _sphere(), dark, Vector3(0, 0.17, -0.26), Vector3.ONE * 0.06)

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.27 * chub * side, 0.55, 0.03))
		_part(a, _capsule(0.045, 0.26), fur, Vector3(0, -0.1, 0))
		_part(a, _sphere(), dark, Vector3(0, -0.23, 0), Vector3.ONE * 0.065)
		arms.append(a)

	neck = _pivot(torso, Vector3(0, 0.64, 0.02))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.34, 0.285, 0.3))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.27 * side, 0.3, -0.02))
		_part(ear, _cone(), fur, Vector3(0, ear_len * 0.5, 0), Vector3(0.13, ear_len, 0.045))
		_part(ear, _cone(), pale, Vector3(0, ear_len * 0.42, 0.028), Vector3(0.08, ear_len * 0.78, 0.02))
		ears.append(ear)
		var size := 0.1
		if odd_eyes:
			size = 0.112 if side < 0.0 else 0.088
		var eye := _pivot(neck, Vector3(0.135 * side, 0.25, 0.215))
		_part(eye, _sphere(), eye_mat, Vector3.ZERO, Vector3.ONE * size)
		var pupil := _part(eye, _sphere(), black, Vector3(0, 0, size * 0.68), Vector3.ONE * size * 0.5)
		eyes.append(eye)
		pupils.append(pupil)
		_part(neck, _cone(), bone, Vector3(0.055 * side, 0.112, 0.283), Vector3(0.022, 0.05, 0.022))
		if horns:
			_part(neck, _cone(), bone, Vector3(0.12 * side, 0.5, 0.03), Vector3(0.04, 0.14, 0.04), Vector3(0, 0, -0.35 * side))
	_part(neck, _sphere(), dark, Vector3(0, 0.175, 0.3), Vector3(0.035, 0.025, 0.03))
	mouth_node = _pivot(neck, Vector3(0, 0.085, 0.262))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.15, 0.07, 0.06))

	_build_bubble()
	_build_hearts()
	for i in 3:
		var z := Label3D.new()
		z.text = "z"
		z.font_size = 96
		z.pixel_size = 0.0022 + 0.0008 * i
		z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		z.modulate = Color(0.8, 0.85, 1.0, 0.0)
		z.outline_size = 0
		z.visible = false
		add_child(z)
		zzz.append(z)


func _fur(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.7
	return m


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _sphere() -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	m.radial_segments = 24
	m.rings = 12
	return m


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 12
	m.rings = 4
	return m


func _cone() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = 1.0
	m.height = 1.0
	m.radial_segments = 12
	return m


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = at
	parent.add_child(n)
	return n


func _part(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3, size := Vector3.ONE, turn := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.scale = size
	mi.rotation = turn
	parent.add_child(mi)
	return mi


# A thought bubble that shows what it is asking for
func _build_bubble() -> void:
	bubble = _pivot(self, Vector3(0.35, 1.5, 0))
	var white := _flat(Color(0.95, 0.95, 0.9))
	for p: MeshInstance3D in [
		_part(bubble, _sphere(), white, Vector3.ZERO, Vector3(0.24, 0.2, 0.01)),
		_part(bubble, _sphere(), white, Vector3(-0.2, -0.22, 0), Vector3(0.06, 0.06, 0.01)),
		_part(bubble, _sphere(), white, Vector3(-0.27, -0.33, 0), Vector3(0.035, 0.035, 0.01)),
	]:
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bubble_food = _pivot(bubble, Vector3(0, 0, 0.02))
	var sandy := _flat(Color(0.62, 0.5, 0.34))
	_part(bubble_food, _capsule(0.03, 0.26), sandy, Vector3.ZERO, Vector3(1, 1, 0.2), Vector3(0, 0, 1.0))
	for end: float in [-1.0, 1.0]:
		for off: float in [-1.0, 1.0]:
			var at := Vector3(-sin(1.0), cos(1.0), 0) * 0.11 * end + Vector3(cos(1.0), sin(1.0), 0) * 0.035 * off
			_part(bubble_food, _sphere(), sandy, at, Vector3(0.045, 0.045, 0.01))
	bubble_ball = _pivot(bubble, Vector3(0, 0, 0.02))
	_part(bubble_ball, _sphere(), _flat(Color(0.95, 0.45, 0.08)), Vector3.ZERO, Vector3(0.11, 0.11, 0.01))
	_part(bubble_ball, _sphere(), _flat(Color(0.36, 0.16, 0.5)), Vector3(0, 0, 0.004), Vector3(0.035, 0.11, 0.01))
	bubble.visible = false


func _build_hearts() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for py in 32:
		for px in 32:
			var x := (px - 15.5) / 12.5
			var y := (15.5 - py) / 12.5 + 0.15
			var v := pow(x * x + y * y - 1.0, 3.0) - x * x * y * y * y
			img.set_pixel(px, py, Color(1.0, 0.35, 0.5, 1.0 if v <= 0.0 else 0.0))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.17, 0.17)
	quad.material = mat
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	hearts = CPUParticles3D.new()
	hearts.mesh = quad
	hearts.amount = 6
	hearts.lifetime = 1.3
	hearts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	hearts.emission_sphere_radius = 0.25
	hearts.direction = Vector3.UP
	hearts.spread = 30.0
	hearts.gravity = Vector3(0, 0.4, 0)
	hearts.initial_velocity_min = 0.4
	hearts.initial_velocity_max = 0.8
	hearts.scale_amount_min = 0.6
	hearts.scale_amount_max = 1.1
	hearts.color_ramp = fade
	hearts.position = Vector3(0, 1.05, 0)
	hearts.emitting = false
	hearts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hearts)


# ---------------------------------------------------------------- needs

func mood() -> float:
	return (belly + fun + energy) / 3.0


func get_needs() -> Dictionary:
	return {"belly": belly, "fun": fun, "energy": energy, "love": love}


func set_needs(d: Dictionary) -> void:
	belly = clampf(float(d.get("belly", belly)), 0.0, 100.0)
	fun = clampf(float(d.get("fun", fun)), 0.0, 100.0)
	energy = clampf(float(d.get("energy", energy)), 0.0, 100.0)
	love = clampf(float(d.get("love", love)), 0.0, 100.0)


func _tick_needs(delta: float) -> void:
	var asleep := state == State.SLEEP
	var speed := velocity.length()
	belly -= delta / (16.0 if asleep else 7.0)
	fun -= delta / (30.0 if asleep else 5.5)
	if asleep:
		energy += delta * 3.2
	else:
		energy -= delta * (0.1 + speed * 0.12) * (1.0 if world.light_on else 1.8)
	if belly < 15.0:
		love -= delta / 40.0
	elif mood() > 60.0:
		love += delta / 45.0
	belly = clampf(belly, 0.0, 100.0)
	fun = clampf(fun, 0.0, 100.0)
	energy = clampf(energy, 0.0, 100.0)
	love = clampf(love, 0.0, 100.0)


# ---------------------------------------------------------------- what you can do to it

func body_centre() -> Vector3:
	return global_position + Vector3(0, 0.55 - curl * 0.2, 0)


# A quick tap
func boop() -> void:
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
		world.sfx.play("grumble")
		_enter(State.STARTLED, 1.4)
		roll_goal = 0.3
		eye_goal = 0.6
		droop_goal = 0.9
		return
	love = minf(love + 1.0, 100.0)
	world.sfx.play("squeak")
	_enter(State.STARTLED, 0.6)


# A finger rubbed over it
func stroke() -> void:
	last_stroke = anim_t
	if state == State.SLEEP:
		hearts.emitting = true
		return
	if state != State.PETTED:
		_enter(State.PETTED)


func call_to(point: Vector3) -> void:
	if state in [State.SLEEP, State.GO_SLEEP, State.EAT, State.PETTED, State.STARTLED]:
		return
	target = point
	_enter(State.COME)


# The player threw the ball: worth chasing even if it had just lost interest
func notice_ball() -> void:
	ball_cooldown = 0.0


func hop(power := 2.6) -> void:
	if airborne:
		return
	airborne = true
	jump_v = power
	squash_v = -1.5


# ---------------------------------------------------------------- brain

func _process(delta: float) -> void:
	if world == null:
		return
	anim_t += delta
	state_time += delta
	ball_cooldown -= delta
	beg_cooldown -= delta
	pounce_cooldown -= delta
	glance_time -= delta
	_tick_needs(delta)
	gaze = _default_gaze()
	_think(delta)
	_move(delta)
	_animate(delta)


func _default_gaze() -> Vector3:
	if glance_time > 0.0:
		return glance_point
	if world.hover_fresh():
		return world.hover_point + Vector3(0, 0.3, 0)
	return world.camera.global_position


func _enter(s: int, length := 0.0) -> void:
	if state == State.PETTED and s != State.PETTED:
		world.sfx.purr(false)
	hearts.emitting = false
	state = s
	state_time = 0.0
	state_len = length
	step = 0
	sit_goal = 0.0
	curl_goal = 0.0
	eye_goal = 1.0
	mouth_goal = 0.12
	droop_goal = 0.1 if energy > 30.0 else 0.5
	roll_goal = 0.0
	nod = 0.0
	arm_goal = REST_ARM
	arm_wave = 0.0
	wag = 3.0
	wiggle = 0.0
	bubble.visible = false
	for z in zzz:
		z.visible = false
	match s:
		State.IDLE:
			if length <= 0.0:
				state_len = randf_range(1.0, 2.6)
		State.STARE:
			state_len = randf_range(3.0, 5.5)
			sit_goal = 1.0
			roll_goal = randf_range(0.2, 0.35) * (1.0 if randf() < 0.5 else -1.0)
			wag = 5.0
		State.LURK:
			var a := randf_range(PI * 0.95, PI * 2.05)
			target = world.light_point + Vector3(cos(a), 0, sin(a)) * randf_range(3.3, 3.9)
		State.COME:
			world.sfx.play("chirp")
		State.GO_FOOD:
			snack = null
			wag = 9.0
		State.CHASE_BALL:
			kicks = 0
			kick_limit = randi_range(2, 4)
			wag = 9.0
		State.CHASE_LIGHT:
			wag = 9.0
		State.BEG:
			state_len = 5.5
			beg_cooldown = 16.0
			beg_for_ball = belly >= 25.0
			target = world.light_point + Vector3(randf_range(-0.6, 0.6), 0, 1.5)
		State.ZOOMIES:
			state_len = randf_range(0.0, TAU)
			world.sfx.play("chirp", 1.2)
		State.DANCE:
			arm_goal = UP_ARM
			wag = 10.0
		State.PETTED:
			eye_goal = 0.3
			droop_goal = 0.6
			wag = 12.0
			hearts.emitting = true
			world.sfx.purr(true)
		State.STARTLED:
			hop(3.0)
			eye_goal = 1.25
			arm_goal = UP_ARM
		State.GO_SLEEP:
			world.sfx.play("yawn")
			target = world.nest_pos
			droop_goal = 0.8
			eye_goal = 0.6
		State.SLEEP:
			curl_goal = 1.0
			eye_goal = 0.0
			droop_goal = 1.0
			wag = 0.6
			for z in zzz:
				z.visible = true


func _interrupt() -> bool:
	if energy < 12.0 or (not world.light_on and energy < 70.0):
		_enter(State.GO_SLEEP)
	elif belly < 97.0 and not world.snacks.is_empty():
		_enter(State.GO_FOOD)
	elif world.light_dragging:
		_enter(State.CHASE_LIGHT)
	elif world.ball != null and ball_cooldown <= 0.0 and (world.ball.held or world.ball.speed() > 1.5):
		_enter(State.CHASE_BALL)
	else:
		return false
	return true


# Nothing pressing: pick something to do
func _decide() -> void:
	if _interrupt():
		return
	if beg_cooldown <= 0.0 and world.light_on and (belly < 25.0 or (fun < 22.0 and world.ball == null)):
		_enter(State.BEG)
		return
	if world.ball != null and fun < 35.0 and energy > 20.0:
		_enter(State.CHASE_BALL)
		return
	var options := {State.WANDER: 34.0, State.STARE: 20.0, State.IDLE: 8.0}
	if world.light_on:
		options[State.LURK] = 11.0
	if world.ball != null and energy > 30.0:
		options[State.CHASE_BALL] = 16.0
	if fun > 65.0 and energy > 45.0:
		options[State.ZOOMIES] = 8.0
	if mood() > 62.0:
		options[State.DANCE] = 8.0
	var total := 0.0
	for w: float in options.values():
		total += w
	var roll := randf() * total
	for s: int in options:
		roll -= float(options[s])
		if roll <= 0.0:
			if s == State.WANDER:
				var a := randf() * TAU
				target = world.light_point + Vector3(cos(a), 0, sin(a)) * sqrt(randf()) * 2.1
			_enter(s)
			return
	_enter(State.IDLE)


func _think(delta: float) -> void:
	if state in INTERRUPTIBLE and _interrupt():
		return
	match state:
		State.IDLE:
			_halt(delta)
			if glance_time < -3.0 and randf() < delta * 0.5:
				glance_time = randf_range(0.5, 1.2)
				var a := randf() * TAU
				glance_point = position + Vector3(cos(a) * 2.0, randf_range(0.0, 1.2), sin(a) * 2.0)
			if energy < 30.0 and randf() < delta * 0.12:
				world.sfx.play("yawn")
				mouth_goal = 1.0
				eye_goal = 0.3
			if state_time > state_len:
				_decide()
		State.WANDER:
			if not world.hover_fresh():
				gaze = target + Vector3(0, 0.3, 0)
			if _steer(target, WALK, delta) or state_time > 8.0:
				_enter(State.IDLE)
		State.STARE:
			_halt(delta)
			gaze = world.camera.global_position
			_face(gaze, delta)
			if state_time > state_len:
				_enter(State.IDLE, 0.6)
		State.LURK:
			gaze = world.camera.global_position
			if step == 0:
				if _steer(target, WALK * 1.3, delta) or state_time > 9.0:
					step = 1
					state_time = 0.0
					state_len = randf_range(3.0, 5.0)
					eye_goal = 1.2
			else:
				_halt(delta)
				_face(gaze, delta)
				if state_time > state_len:
					target = world.light_point + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-0.8, 1.2))
					_enter(State.WANDER)
		State.COME:
			if _steer(target, RUN, delta, 0.25) or state_time > 6.0:
				hop(1.8)
				_enter(State.STARE)
				state_len = 2.0
		State.GO_FOOD:
			_go_food(delta)
		State.EAT:
			_eat(delta)
		State.CHASE_BALL:
			_chase_ball(delta)
		State.CHASE_LIGHT:
			if not world.light_dragging:
				_enter(State.IDLE, 0.8)
				return
			fun = minf(fun + delta * 2.5, 100.0)
			gaze = world.light_goal
			if _steer(world.light_goal, RUN, delta, 0.3) and pounce_cooldown <= 0.0:
				pounce_cooldown = 0.9
				hop(2.3)
				fun = minf(fun + 3.0, 100.0)
				world.sfx.play("chirp", 1.1)
		State.BEG:
			gaze = world.camera.global_position
			if step == 0:
				if _steer(target, WALK * 1.4, delta) or state_time > 5.0:
					step = 1
					state_time = 0.0
					world.sfx.play("whimper")
			else:
				_halt(delta)
				_face(gaze, delta)
				droop_goal = 0.85
				eye_goal = 0.85
				bubble.visible = true
				bubble_food.visible = not beg_for_ball
				bubble_ball.visible = beg_for_ball
				if not beg_for_ball:
					arm_goal = BELLY_ARM
					arm_wave = 0.25
				if state_time > state_len:
					_enter(State.IDLE)
		State.ZOOMIES:
			fun = minf(fun + delta * 3.0, 100.0)
			var a := state_len + step * 1.9
			var point := world.light_point + Vector3(cos(a), 0, sin(a)) * 1.9
			gaze = point + Vector3(0, 0.3, 0)
			mouth_goal = 0.7
			if _steer(point, RUN * 1.45, delta, 0.55):
				step += 1
				if step >= 7:
					hop(2.2)
					world.sfx.play("coo")
					_enter(State.IDLE, 1.8)
					mouth_goal = 0.7
		State.DANCE:
			_halt(delta)
			fun = minf(fun + delta * 2.0, 100.0)
			wiggle = sin(anim_t * 7.0) * 0.18
			yaw += delta * 2.2
			if not airborne:
				hop(1.9)
				step += 1
				if step % 2 == 0:
					world.sfx.play("chirp", 0.9 + 0.1 * (step % 4))
			if step > 7:
				_enter(State.IDLE, 1.0)
		State.PETTED:
			_halt(delta)
			gaze = world.camera.global_position
			_face(gaze, delta)
			wiggle = sin(anim_t * 10.0) * 0.07
			love = minf(love + delta * 5.0, 100.0)
			fun = minf(fun + delta * 3.0, 100.0)
			if anim_t - last_stroke > 0.7:
				world.sfx.play("coo")
				hop(2.0)
				_enter(State.IDLE, 1.5)
		State.STARTLED:
			_halt(delta)
			if state_time > state_len:
				_enter(State.IDLE, 1.0)
		State.GO_SLEEP:
			mouth_goal = 1.0 if state_time < 0.9 else 0.12
			gaze = target + Vector3(0, 0.2, 0)
			if state_time < 0.9:
				_halt(delta)
			elif _steer(target, WALK * 0.85, delta, 0.12) or state_time > 12.0:
				_enter(State.SLEEP)
		State.SLEEP:
			_halt(delta)
			_face(world.camera.global_position + Vector3(4.0, 0, 0), delta)
			hearts.emitting = anim_t - last_stroke < 0.5
			if int(state_time / 3.4) > step:
				step = int(state_time / 3.4)
				world.sfx.play("snore", 1.0, -8.0)
			if energy >= 98.0 or (world.light_on and energy > 55.0 and state_len < 0.0):
				world.sfx.play("coo", 0.9)
				_enter(State.STARTLED, 0.8)
				eye_goal = 1.0
			# Sent to bed by the dark: remember, so that the lamp coming back on wakes it
			if not world.light_on:
				state_len = -1.0


func _go_food(delta: float) -> void:
	if not is_instance_valid(snack):
		snack = world.nearest_snack(position)
		if snack == null:
			_enter(State.IDLE, 0.6)
			return
	gaze = snack.global_position
	var away := Vector2(snack.position.x - position.x, snack.position.z - position.z).length()
	mouth_goal = 0.6 if away < 1.2 else 0.12
	if _steer(snack.position, RUN, delta, 0.42) and snack.landed:
		var s := snack
		_enter(State.EAT)
		snack = s
	elif state_time > 12.0:
		_enter(State.IDLE)


func _eat(delta: float) -> void:
	_halt(delta)
	if not is_instance_valid(snack):
		_enter(State.IDLE)
		return
	gaze = snack.global_position
	_face(snack.global_position, delta)
	var cycle := fmod(state_time, 0.5) / 0.5
	nod = 0.35 + sin(cycle * TAU) * 0.2
	mouth_goal = 0.2 + 0.8 * absf(sin(cycle * PI))
	if int(state_time / 0.5) > step:
		step = int(state_time / 0.5)
		world.sfx.play("chomp")
		world.crumbs(snack.global_position + Vector3(0, 0.1, 0), snack.colour)
		if snack.bite():
			world.remove_snack(snack)
			snack = null
			belly = minf(belly + Snack.VALUE, 100.0)
			love = minf(love + 2.0, 100.0)
			world.sfx.play("coo")
			hop(2.0)
			_enter(State.IDLE, 1.2)
			arm_goal = BELLY_ARM
			eye_goal = 0.5


func _chase_ball(delta: float) -> void:
	var b := world.ball
	if b == null or energy < 12.0 or state_time > 16.0:
		_enter(State.IDLE)
		return
	fun = minf(fun + delta * 1.5, 100.0)
	gaze = b.global_position
	if b.held:
		# Held over its head: stand under it and jump for it
		arm_goal = UP_ARM
		mouth_goal = 0.6
		if _steer(Vector3(b.position.x, 0, b.position.z), RUN, delta, 0.5) and not airborne:
			hop(2.8)
		state_time = minf(state_time, 4.0)
		return
	if step > 0:
		# A beat to watch it fly before going after it again
		_halt(delta)
		if state_time > 0.35:
			step = 0
		return
	arm_goal = REST_ARM
	if _steer(b.position + b.vel * 0.2, RUN * 1.05, delta, 0.38) and b.position.y < 0.75:
		_kick(b)


func _kick(b: Ball) -> void:
	var dir := Vector3(sin(yaw), 0, cos(yaw))
	# Fetch it back if it has gone off into the dark
	var home := world.light_point - position
	home.y = 0.0
	if home.length() > 1.5:
		dir = (dir + home.normalized() * 1.6).normalized()
	b.vel = dir * randf_range(2.4, 4.2) + Vector3.UP * randf_range(2.0, 3.8)
	hop(2.0)
	world.sfx.play("boing", 1.2)
	kicks += 1
	kicks_total += 1
	fun = minf(fun + 10.0, 100.0)
	if kicks >= kick_limit:
		ball_cooldown = 4.0
		world.sfx.play("coo")
		_enter(State.IDLE, 1.6)
	else:
		step = 1
		state_time = 0.0


# ---------------------------------------------------------------- moving

func _halt(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 9.0)


func _face(point: Vector3, delta: float) -> void:
	var to := point - position
	if Vector2(to.x, to.z).length() > 0.05:
		yaw = rotate_toward(yaw, atan2(to.x, to.z), delta * 4.0)


# Runs toward a point on the floor; true once it is there
func _steer(point: Vector3, speed: float, delta: float, arrive := 0.18) -> bool:
	var to := Vector3(point.x - position.x, 0, point.z - position.z)
	var away := to.length()
	if away < arrive:
		_halt(delta)
		return true
	yaw = rotate_toward(yaw, atan2(to.x, to.z), delta * 7.5)
	var ahead := Vector3(sin(yaw), 0, cos(yaw))
	var aligned := maxf(ahead.dot(to / away), 0.0)
	# Slow into the stop so it doesn't overshoot and circle
	var want := speed * aligned * clampf(away / 0.5, 0.35, 1.0)
	velocity = velocity.move_toward(ahead * want, delta * 10.0)
	return false


func _move(delta: float) -> void:
	position.x += velocity.x * delta
	position.z += velocity.z * delta
	var flat := Vector2(position.x, position.z)
	if flat.length() > ROOM:
		flat = flat.normalized() * ROOM
	for o in world.obstacles:
		var off := flat - Vector2(o.x, o.z)
		if off.length() < 0.6 and off.length() > 0.001:
			flat = Vector2(o.x, o.z) + off.normalized() * 0.6
	position.x = flat.x
	position.z = flat.y
	if airborne:
		jump_v -= 12.0 * delta
		jump_y += jump_v * delta
		if jump_y <= 0.0:
			jump_y = 0.0
			airborne = false
			squash_v = 3.2
	position.y = jump_y
	rotation.y = yaw


# ---------------------------------------------------------------- animation

func _animate(delta: float) -> void:
	var ease_fast := 1.0 - exp(-delta * 12.0)
	var ease_slow := 1.0 - exp(-delta * 5.0)
	var speed := Vector2(velocity.x, velocity.z).length()
	gait = move_toward(gait, clampf(speed / 0.7, 0.0, 1.0), delta * 5.0)
	phase += delta * (3.0 + speed * 5.5)
	var swing := sin(phase) * gait
	sit = lerpf(sit, sit_goal, ease_slow)
	curl = lerpf(curl, curl_goal, ease_slow)

	# Springy squash and stretch, kicked by take-offs and landings
	squash_v += (-squash * 140.0 - squash_v * 11.0) * delta
	squash = clampf(squash + squash_v * delta, -0.3, 0.4)
	var breath := sin(anim_t * (1.3 if curl > 0.5 else 2.6)) * (0.03 if curl > 0.5 else 0.012)
	torso.position.y = absf(sin(phase)) * 0.05 * gait - sit * 0.1 - curl * 0.15
	torso.rotation.x = gait * minf(speed, 3.5) * 0.07 + curl * 0.12
	torso.rotation.z = wiggle
	torso.scale = Vector3(1.0 + squash * 0.6 + breath, 1.0 - squash + breath, 1.0 + squash * 0.6 + breath)

	var fold := sit * 1.3 + curl * 1.35
	legs[0].rotation.x = swing * 0.9 - fold
	legs[1].rotation.x = -swing * 0.9 - fold

	arm = arm.lerp(arm_goal, ease_fast)
	var wave := sin(anim_t * 9.0) * arm_wave
	var tuck := curl * 0.8
	arms[1].rotation = Vector3(arm.x - swing * 0.7 * (1.0 - curl) + wave - tuck, arm.y, arm.z)
	arms[0].rotation = Vector3(arm.x + swing * 0.7 * (1.0 - curl) - wave - tuck, -arm.y, -arm.z)

	# Head turns to whatever it is looking at; the pupils go the rest of the way
	var seen := torso.global_transform.affine_inverse() * gaze - neck.position - Vector3(0, 0.2, 0)
	var want_yaw := clampf(atan2(seen.x, seen.z), -1.25, 1.25)
	var want_pitch := clampf(-atan2(seen.y, Vector2(seen.x, seen.z).length()), -0.7, 0.5)
	if curl_goal > 0.5:
		want_yaw = 0.35
		want_pitch = 0.45
	head_yaw = lerpf(head_yaw, want_yaw, ease_slow * 1.6)
	head_pitch = lerpf(head_pitch, want_pitch, ease_slow * 1.6)
	head_roll = lerpf(head_roll, roll_goal, ease_slow)
	neck.rotation = Vector3(head_pitch + nod, head_yaw, head_roll)
	neck.position.y = 0.64 - curl * 0.1

	blink -= delta
	if blink < -0.12:
		blink = randf_range(1.5, 5.0)
	eye_open = lerpf(eye_open, eye_goal if blink > 0.0 else 0.0, 1.0 - exp(-delta * 30.0))
	var to_head := neck.global_transform.affine_inverse()
	for i in 2:
		eyes[i].scale = Vector3(1.0, maxf(eye_open, 0.07), 1.0)
		var d := (to_head * gaze - eyes[i].position).normalized()
		var off := Vector2(d.x, d.y).limit_length(0.55)
		if d.z < 0.0:
			off = Vector2(d.x, d.y).normalized() * 0.55
		var reach := pupils[i].scale.x / 0.5 * 0.68
		pupils[i].position = pupils[i].position.lerp(Vector3(off.x, off.y, sqrt(1.0 - off.length_squared())) * reach, ease_fast)

	mouth = lerpf(mouth, mouth_goal, ease_fast)
	mouth_node.scale = Vector3(1.0 - 0.25 * mouth, maxf(mouth, 0.1), 1.0)

	# Ears: perk, droop, flop with each step, and twitch now and then
	droop = lerpf(droop, droop_goal, ease_slow)
	twitch = maxf(twitch - delta * 5.0, 0.0)
	if twitch <= 0.0 and randf() < delta * 0.35:
		twitch = 1.0
		twitch_side = randi() % 2
	var flop := sin(phase * 2.0) * 0.1 * gait
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var jerk := sin(twitch * PI * 3.0) * 0.25 if twitch_side == i else 0.0
		ears[i].rotation = Vector3(-gait * 0.35, 0, -side * (1.0 + droop * 0.75 + flop + jerk))

	tail.rotation.y = sin(anim_t * wag) * 0.55
	tail.rotation.x = sin(anim_t * 1.3) * 0.12 - curl * 0.4

	if bubble.visible:
		bubble.global_basis = world.camera.global_basis
		bubble.position.y = 1.5 + sin(anim_t * 2.0) * 0.03
	if zzz[0].visible:
		var cam_right := world.camera.global_basis.x
		for i in 3:
			var u := fmod(anim_t * 0.4 + i / 3.0, 1.0)
			zzz[i].global_position = global_position + Vector3(0, 0.75 + u * 0.9, 0) + cam_right * (0.3 + sin(u * 5.0) * 0.12)
			zzz[i].modulate.a = sin(u * PI) * 0.9
