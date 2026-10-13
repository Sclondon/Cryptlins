class_name Knack
extends RefCounted
## The one thing each kind does that no other does, out of its own legend: its knack. Each
## cryptlin has one of these. A knack is a turn it takes now and then (State.TRICK, with a
## weight in Cryptlin._decide like anything else it might do), with its own antics and noises,
## and for some a small real effect on the room or on another of them that soon wears off. What
## is done to another is a spell on it (State.SPELL), which that one's own knack keeps the time
## of. Nothing here gets round the room's rules: no knack hurts, pairs, or starts a fight, and
## one that needs something that is not there is simply not ready. The keeper learns a knack by
## seeing it done ("knack" in what is known of it), and then it is written in the notebook.

# What the notebook says of each kind's knack, once it has been seen
const NOTES: Array[String] = [
	"tinkers with the lamp's cord until the light flickers",
	"goes still and blurred when it has been looked at too long, and slips away leaving footprints",
	"stares one of the others stiff and grey as stone for a few seconds",
	"flies up and circles the bulb, its eyes glaring when there is trouble coming",
	"latches on to a toy or a thing in the room and leaves it shrivelled for a while",
	"flicks food into its mouth from a little way off with its tongue",
	"sinks in the pool until its hump is all there is to see, and comes up somewhere else",
	"slides the length of the room with its mouth wide open, and scoops up any food in its way",
	"makes frost creep over the floor where it stands, and the others keep their distance when it is hungry",
	"calls one of the others down into the water after it",
	"", "", "", "", "", "", "", "", "", "",
]
# How likely it is to take a turn at it, next to the 34 of wandering off
const WEIGHT := 7.0
# How long before it will do it again, at least and at most (seconds)
const REST := Vector2(45.0, 110.0)
const STONE := Color(0.42, 0.42, 0.44)

var pet: Cryptlin
# What it has picked to work its knack on: a thing, or another of them
var mark: Node3D
var victim: Cryptlin
# Whether what it does came off this time, and how long before it will do it again
var done := false
var again := 20.0
# The spell on it, if another's knack has been worked on it: which, how it looked before, and
# who cast it
var spell := ""
var caster: Cryptlin
var stone: ShaderMaterial
# The tongue of the frogman, while it is out
var tongue: MeshInstance3D


func _init(whose: Cryptlin) -> void:
	pet = whose
	again = randf_range(15.0, REST.x)


# Whether it could do it just now: rested from the last time, and with whatever it needs there
func ready() -> bool:
	if again > 0.0 or pet.xrayed:
		return false
	var world := pet.world
	match pet.kind:
		Cryptlin.Kind.GREMLIN, Cryptlin.Kind.MOTHMAN:
			return world.light_on
		Cryptlin.Kind.SQUATCH:
			return true
		Cryptlin.Kind.COCKATRICE:
			return pet._someone() != null
		Cryptlin.Kind.CHUPACABRA:
			return _prey() != null
		Cryptlin.Kind.FROGMAN:
			return _in_reach() != null
		Cryptlin.Kind.NESSIE:
			return Den.shore != Den.Shore.NONE
		Cryptlin.Kind.BOLTER:
			return pet.energy > 30.0
		Cryptlin.Kind.WENDIGO:
			return Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.KELPIE:
			return Den.shore != Den.Shore.NONE and _dupe() != null
	return false


func weight() -> float:
	# The mothman is up at the bulb a good deal more when there is trouble on the way
	if pet.kind == Cryptlin.Kind.MOTHMAN and _trouble():
		return WEIGHT * 3.0
	return WEIGHT


# Time passing, whatever it is doing
func always(delta: float) -> void:
	again -= delta


func begin() -> void:
	done = false
	mark = null
	victim = null
	var world := pet.world
	match pet.kind:
		Cryptlin.Kind.GREMLIN:
			pet.target = pet._footing(Vector3(Den.lamp_at.x + randf_range(-0.2, 0.2), 0, Den.lamp_at.z + 0.25), 0.4)
		Cryptlin.Kind.SQUATCH:
			pet.target = world.hiding_place(pet)
		Cryptlin.Kind.COCKATRICE:
			victim = pet._someone()
		Cryptlin.Kind.CHUPACABRA:
			mark = _prey()
		Cryptlin.Kind.FROGMAN:
			mark = _in_reach()
		Cryptlin.Kind.NESSIE:
			pet.target = world.wading_spot(pet.position)
		Cryptlin.Kind.BOLTER:
			# From whichever side it is nearer, and through the food if there is any lying about
			var along := pet.position.z if world.snacks.is_empty() else world.snacks[0].position.z
			pet.target = pet._footing(Vector3(Den.half.x * (1.0 if pet.position.x > 0.0 else -1.0), 0, along), 0.5)
		Cryptlin.Kind.KELPIE:
			victim = _dupe()
			if victim != null:
				# (well out, and a little to one side, to leave it room to come in)
				pet.target = Den.in_room(Den.shore_by(victim.position + Den.place(-1.0 if victim.position.x > 0.0 else 1.0, 0.0), -0.9), 0.5)


func tick(delta: float) -> void:
	match pet.kind:
		Cryptlin.Kind.GREMLIN:
			_tinker(delta)
		Cryptlin.Kind.SQUATCH:
			_blur(delta)
		Cryptlin.Kind.COCKATRICE:
			_stare(delta)
		Cryptlin.Kind.MOTHMAN:
			_circle(delta)
		Cryptlin.Kind.CHUPACABRA:
			_latch(delta)
		Cryptlin.Kind.FROGMAN:
			_flick(delta)
		Cryptlin.Kind.NESSIE:
			_sink(delta)
		Cryptlin.Kind.BOLTER:
			_slide(delta)
		Cryptlin.Kind.WENDIGO:
			_frost(delta)
		Cryptlin.Kind.KELPIE:
			_lure(delta)
		_:
			finish()


# The turn is over: it has a rest from it, and if it came off in front of the keeper it is known
func finish() -> void:
	again = randf_range(REST.x, REST.y)
	if done and not pet.world.resting:
		pet.world.learned(pet, "knack")
	pet._enter(Cryptlin.State.IDLE, 1.0)


# Whatever its knack (or a spell on it) had changed about it is put back: called whenever it
# leaves either, however that comes about
func over() -> void:
	pet.torso.position.x = 0.0
	pet.dive = 0.0
	for eye in pet.eye_mats:
		eye.set_shader_parameter("glow", 0.85)
	if tongue != null:
		tongue.queue_free()
		tongue = null
		# (what was on the end of it is let fall)
		var food := mark as Snack
		if is_instance_valid(food) and food.held and pet.world.held_snack != food:
			food.held = false
			food.landed = true
			food.position.y = 0.0
	if stone != null:
		stone = null
		pet._unghost()
	spell = ""
	caster = null


# On to the next part of the turn
func _next() -> void:
	pet.step += 1
	pet.state_time = 0.0


# Every so often through a part of the turn: true once each time `every` seconds have gone by
func _beat(every: float, delta: float) -> bool:
	return int(pet.state_time / every) != int((pet.state_time - delta) / every)


# ---------------------------------------------------------------- what is done to another

# Another's knack is worked on this one for so many seconds, if it is in a state to be worked
# on: up, on the floor, in nobody's hands and in the middle of nothing that matters
func bewitch(how: String, by: Cryptlin, seconds: float) -> bool:
	if not pet.state in Cryptlin.INTERRUPTIBLE or pet.xrayed or pet.lift > 0.05:
		return false
	pet._enter(Cryptlin.State.SPELL, seconds)
	spell = how
	caster = by
	return true


func spelled(delta: float) -> void:
	match spell:
		"stone":
			# Stiff and grey where it stood, eyes wide, not so much as a blink
			if stone == null:
				stone = Ps1.mat(STONE, 0.0, 0.2)
				pet._ghost(pet, stone)
			pet._halt(delta)
			pet.blink = 1.0
			pet.eye_goal = 1.25
			pet.wag = 0.0
			pet.twitch = 0.0
			if is_instance_valid(caster):
				pet.gaze = caster.global_position + Vector3(0, caster.top() * 0.8, 0)
		"lured":
			# Down the bank and in, as if it were walking in its sleep
			pet.eye_goal = 0.55
			pet.arm_goal = Vector3(-1.2, 0.0, 0.2)
			if is_instance_valid(caster):
				pet.gaze = caster.global_position + Vector3(0, caster.top() * 0.7, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 0.7, delta, 0.12):
				pet.state_len = minf(pet.state_len, pet.state_time + 0.6)
	if pet.state_time > pet.state_len:
		var was := spell
		pet._enter(Cryptlin.State.IDLE, 1.0)
		if was == "stone":
			pet.hop(1.6)
			pet.feel(Cryptlin.Feeling.SCARED, 3.0)


# ---------------------------------------------------------------- the knacks

# The gremlin goes and gets at the lamp's cord: it jumps for it, and the light flickers
func _tinker(delta: float) -> void:
	var world := pet.world
	if pet.step == 0:
		pet.gaze = world.bulb.global_position
		if pet._steer(pet.target, Cryptlin.WALK * 1.5, delta, 0.25) or pet.state_time > 6.0:
			_next()
		return
	pet._halt(delta)
	pet.gaze = world.bulb.global_position
	pet.arm_goal = Cryptlin.UP_ARM
	pet.arm_wave = 0.6
	pet.mouth_goal = 0.6
	if world.light_on:
		world.flicker = 0.35
		done = true
	if _beat(0.9, delta):
		pet.hop(3.2)
	if _beat(0.3, delta):
		pet._cry("click", randf_range(0.8, 1.4), -8.0)
	if pet.state_time > 3.6:
		pet._cry("chirp", 1.2)
		finish()


# The squatchling, looked at too long, goes still and will not come into focus; then it is off
# to somewhere it cannot be seen, and its footprints are what is left
func _blur(delta: float) -> void:
	# (never quite where it was drawn the frame before)
	pet.torso.position.x = (0.045 if Engine.get_process_frames() % 2 == 0 else -0.045) * (0.6 + 0.4 * sin(pet.anim_t * 31.0))
	if pet.step == 0:
		pet._halt(delta)
		pet.gaze = pet.world.camera.global_position
		pet._face(pet.gaze, delta)
		pet.eye_goal = 1.2
		if pet.state_time > 2.6:
			done = true
			_next()
		return
	pet.gaze = pet.target + Vector3(0, 0.3, 0)
	if pet._steer(pet.target, Cryptlin.WALK * 1.3, delta, 0.3) or pet.state_time > 6.0:
		finish()


# The cockatrice fixes one of the others with its eye, and that one is stone for a few seconds
func _stare(delta: float) -> void:
	pet._halt(delta)
	if not is_instance_valid(victim) or victim.me.leaving:
		finish()
		return
	pet.gaze = victim.global_position + Vector3(0, victim.top() * 0.8, 0)
	pet._face(victim.position, delta)
	if pet.step == 0:
		pet.eye_goal = 1.45
		pet.blink = 1.0
		for eye in pet.eye_mats:
			eye.set_shader_parameter("glow", 0.85 + pet.state_time * 1.2)
		if pet.state_time > 1.7:
			done = victim.knack.bewitch("stone", pet, 4.5)
			if done:
				pet.world.sfx.play("crack", 0.6, -6.0)
			_next()
		return
	# And is pleased with itself
	pet.mouth_goal = 0.8
	if _beat(0.6, delta):
		pet._cry("chirp", 0.8)
		pet.hop(1.8)
	if pet.state_time > 1.3:
		finish()


# The mothman flies up and goes round and round the bulb. When there is trouble coming (one of
# them poorly, two of them close to blows) its eyes glare while it does
func _circle(delta: float) -> void:
	var world := pet.world
	var bulb := world.bulb.global_position
	var omen := _trouble()
	pet.arm_goal = Cryptlin.UP_ARM
	pet.arm_wave = 1.0
	pet.gaze = bulb
	if pet.step == 0:
		var around := pet.state_time * 2.8
		var at := Vector3(bulb.x + cos(around) * 0.55, 0, bulb.z + sin(around) * 0.55)
		var up := 1.0 - exp(-delta * 2.5)
		pet.position.x = lerpf(pet.position.x, at.x, up)
		pet.position.z = lerpf(pet.position.z, at.z, up)
		pet.lift = lerpf(pet.lift, maxf(bulb.y - 0.35 - pet.tall(), 0.6), up)
		pet.yaw = lerp_angle(pet.yaw, atan2(-sin(around), cos(around)), up * 2.0)
		pet.velocity = Vector3.ZERO
		if omen:
			pet.eye_goal = 1.5
			pet.blink = 1.0
			for eye in pet.eye_mats:
				eye.set_shader_parameter("glow", 2.2 + sin(pet.anim_t * 11.0) * 0.6)
			if _beat(0.8, delta):
				pet._cry("squeak", 0.7)
		if pet.state_time > 2.0:
			done = true
		if pet.state_time > 5.5:
			pet.target = pet._footing(pet.position, 0.4)
			_next()
		return
	# Down again, on to dry floor
	var down := 1.0 - exp(-delta * 4.0)
	pet.position.x = lerpf(pet.position.x, pet.target.x, down)
	pet.position.z = lerpf(pet.position.z, pet.target.z, down)
	pet.lift = move_toward(pet.lift, 0.0, delta * 1.6)
	if pet.lift <= 0.0:
		finish()


# Whether there is trouble in the room: one of them poorly, or two that are near to blows
func _trouble() -> bool:
	var all := pet.world.pets()
	for one in all:
		if one.health < Cryptlin.POORLY:
			return true
		for other in all:
			if other != one and pet.world.standing(one, other) < 30.0:
				return true
	return pet.world.scuffle != null


# The chupacabra creeps up on the toy, or on something in the room, gets its teeth into it and
# sucks; and the thing is shrivelled for a while after
func _latch(delta: float) -> void:
	if not is_instance_valid(mark):
		finish()
		return
	var at := Vector3(mark.position.x, 0, mark.position.z)
	pet.gaze = mark.global_position + Vector3(0, 0.1, 0)
	if pet.step == 0:
		var reach := 0.3 * pet.grow + (float(mark.get("radius")) if mark is Decor else 0.1)
		if pet._steer(at, Cryptlin.WALK * 0.8, delta, reach):
			_next()
		elif pet.state_time > 7.0:
			finish()
		return
	pet._halt(delta)
	pet._face(at, delta)
	pet.nod = 0.4 + sin(pet.state_time * 9.0) * 0.08
	pet.mouth_goal = 0.9
	pet.wiggle = sin(pet.state_time * 14.0) * 0.04
	if _beat(0.45, delta):
		pet._cry("chomp", 1.5, -6.0)
		pet.world.crumbs(mark.global_position + Vector3(0, 0.15, 0), Color(0.5, 0.08, 0.1))
	if pet.state_time > 2.6:
		pet.world.shrivel(mark, 40.0)
		pet.belly = minf(pet.belly + 5.0, 100.0)
		done = true
		pet._cry("coo", 0.7)
		finish()


# Something for the chupacabra to get its teeth into: the toy, if it is lying still, or else a
# thing in the room that has its full shape (never the pool, nor anybody's marker)
func _prey() -> Node3D:
	var world := pet.world
	if world.ball != null and not world.ball.held and world.ball.speed() < 0.5 and not world.shrivelled.has(world.ball) and Den.wade(world.ball.position) <= 0.0:
		return world.ball
	var fair: Array[Node3D] = []
	for d in world.decors:
		if not d.kind in [Decor.Kind.POOL, Decor.Kind.MARKER] and d != world.held_thing and not world.shrivelled.has(d):
			fair.append(d)
	return fair.pick_random() if not fair.is_empty() else null


# The frogman does not always trouble to walk to its food: from a little way off its tongue
# goes out, and the food comes back on the end of it
func _flick(delta: float) -> void:
	var food := mark as Snack
	if not is_instance_valid(food) or pet.world.held_snack == food or not pet.world.snacks.has(food):
		finish()
		return
	pet._halt(delta)
	pet.gaze = food.global_position
	pet._face(food.position, delta)
	var lips := pet.mouth_node.global_position
	match pet.step:
		0:
			# It takes aim
			pet.sit_goal = 0.6
			pet.mouth_goal = 0.3
			pet.eye_goal = 1.3
			if pet.state_time > 0.55:
				pet._cry("boing", 1.6, -4.0)
				tongue = Ps1.part(pet.world, Ps1.box(), Ps1.mat(Color(0.85, 0.25, 0.35), 0.3), lips)
				tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_next()
		1:
			# Out it goes
			pet.mouth_goal = 1.0
			_stretch(lips, lips.lerp(food.global_position + Vector3(0, 0.06, 0), minf(pet.state_time / 0.16, 1.0)))
			if pet.state_time > 0.16:
				food.hold()
				_next()
		2:
			# And back, with its dinner stuck to the end of it
			pet.mouth_goal = 1.0
			var back := minf(pet.state_time / 0.22, 1.0)
			food.position = food.position.lerp(Vector3(lips.x, 0.12 * pet.grow, lips.z), back)
			_stretch(lips, food.global_position)
			if back >= 1.0:
				again = randf_range(REST.x, REST.y) * 0.4
				done = true
				if not pet.world.resting:
					pet.world.learned(pet, "knack")
				pet._enter(Cryptlin.State.EAT)
				pet.snack = food


# Lays the frogman's tongue from its lips to wherever the end of it has got to
func _stretch(from: Vector3, to: Vector3) -> void:
	tongue.global_position = (from + to) * 0.5
	if from.distance_to(to) > 0.01:
		tongue.look_at(to, Vector3.UP)
	tongue.scale = Vector3(0.035, 0.02, maxf(from.distance_to(to), 0.01))


# Food lying where the frogman's tongue will reach and its feet have not yet: not what it
# will not eat, not one it has turned its nose up at, and not one in the keeper's hand
func _in_reach() -> Snack:
	if pet.belly >= 97.0:
		return null
	for food in pet.world.snacks:
		var off := Vector2(food.position.x - pet.position.x, food.position.z - pet.position.z).length()
		if food.landed and not food.held and food.kind != pet.yuck_food and not food.get_instance_id() in pet.spurned and off > 0.7 and off < 2.6:
			return food
	return null


# The Loch Ness monster wades out, sinks until its hump is all there is to see, and comes up
# in another part of the pool
func _sink(delta: float) -> void:
	var world := pet.world
	if Den.shore == Den.Shore.NONE:
		finish()
		return
	var deep := 0.2 * pet.grow
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.2, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 1.2, delta, 0.3) or pet.state_time > 8.0:
				if Den.wade(pet.position) < 0.3:
					finish()
					return
				world.splash(pet.position)
				_next()
		1:
			# Down, with its neck laid along the water
			pet._halt(delta)
			pet.nod = minf(pet.state_time * 1.2, 1.0)
			pet.dive = move_toward(pet.dive, deep, delta * 0.5)
			if pet.dive >= deep:
				for i in 8:
					pet.target = world.wading_spot(pet.position)
					if pet.target.distance_to(pet.position) > 1.0:
						break
				_next()
		2:
			# A hump going across the pool, and a ripple after it
			pet.nod = 1.0
			pet.dive = deep
			pet.gaze = pet.target
			if _beat(0.6, delta):
				world.splash(pet.position)
			if pet._steer(pet.target, Cryptlin.WALK * 0.8, delta, 0.25) or pet.state_time > 7.0:
				done = true
				_next()
		3:
			# And up it comes
			pet._halt(delta)
			pet.dive = move_toward(pet.dive, 0.0, delta * 1.4)
			pet.gaze = world.camera.global_position
			if pet.dive <= 0.0:
				world.splash(pet.position)
				pet._cry("coo", 0.8)
				finish()


# The slide-rock bolter goes to one side of the room, opens its mouth as far as it will go and
# comes down the length of the floor like a landslide; any food in its way goes in
func _slide(delta: float) -> void:
	var world := pet.world
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.2, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 1.4, delta, 0.25) or pet.state_time > 8.0:
				pet.target = pet._footing(Vector3(-pet.target.x, 0, pet.target.z), 0.5)
				pet._cry("grumble", 0.6)
				_next()
		1:
			pet._halt(delta)
			pet._face(pet.target, delta)
			pet.mouth_goal = 1.0
			pet.wiggle = sin(pet.state_time * 20.0) * 0.05
			if pet.state_time > 0.7:
				_next()
		2:
			pet.mouth_goal = 1.0
			pet.gaze = pet.target + Vector3(0, 0.1, 0)
			for food in world.snacks.duplicate():
				if food.landed and not food.held and food.kind != pet.yuck_food and food.position.distance_to(pet.position) < 0.55 * pet.grow + 0.2:
					var share := float(food.bites_left) / Snack.BITES
					pet.belly = minf(pet.belly + Snack.VALUE * share * 0.8, 100.0)
					pet.digest += 100.0 * share
					pet._cry("chomp", 0.7)
					world.crumbs(food.global_position + Vector3(0, 0.1, 0), food.colour)
					world.remove_snack(food)
			if pet.state_time > 0.5:
				done = true
			if pet._steer(pet.target, Cryptlin.RUN * 1.15, delta, 0.3) or pet.state_time > 4.0:
				pet.squash_v = 3.0
				pet._cry("thud", 0.7)
				finish()


# Where the wendigo stands still, frost creeps out over the floor round it
func _frost(delta: float) -> void:
	pet._halt(delta)
	pet.gaze = pet.world.camera.global_position
	pet._face(pet.gaze, delta)
	pet.eye_goal = 1.2
	pet.arm_goal = Vector3(-0.2, 0.0, 0.7)
	if pet.state_time < delta * 1.5:
		pet._cry("whimper", 0.5, -4.0)
	if _beat(0.3, delta):
		var around := randf() * TAU
		var out := 0.15 + pet.state_time * 0.22 * randf_range(0.6, 1.0)
		pet.world.leave_print("frost", pet.position + Vector3(cos(around), 0, sin(around)) * out, around, 1.0, pet.grow * randf_range(0.7, 1.2))
		pet.world.sfx.play("crack", randf_range(1.6, 2.2), -20.0)
	if pet.state_time > 1.5:
		done = true
	if pet.state_time > 4.2:
		finish()


# Whether the others give it a wide berth just now: a wendigo that is hungry
func dread() -> bool:
	return pet.kind == Cryptlin.Kind.WENDIGO and pet.belly < 35.0 and not pet.state in [Cryptlin.State.SLEEP, Cryptlin.State.GO_SLEEP, Cryptlin.State.EAT]


# Whether its knack is how it will get at the food that is lying about just now
func fetches() -> bool:
	return pet.kind == Cryptlin.Kind.FROGMAN and ready() and randf() < 0.6


# The kelpie wades in, turns and calls to one of those that do not belong in the water; and
# that one comes down the bank and in after it, and has to get itself out again
func _lure(delta: float) -> void:
	if not is_instance_valid(victim) or Den.shore == Den.Shore.NONE:
		finish()
		return
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.2, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 1.3, delta, 0.25) or pet.state_time > 8.0:
				_next()
		1:
			pet._halt(delta)
			pet._face(victim.position, delta)
			pet.gaze = victim.global_position + Vector3(0, victim.top() * 0.7, 0)
			pet.nod = sin(pet.state_time * 6.0) * 0.25
			pet.wag = 9.0
			if _beat(0.7, delta):
				pet._cry("coo", 0.8)
			if pet.state_time > 1.5:
				if victim.knack.bewitch("lured", pet, 6.0):
					victim.target = Den.in_room(Den.shore_by(victim.position, -0.4), 0.4)
					_next()
				else:
					finish()
		2:
			pet._halt(delta)
			pet._face(victim.position, delta)
			pet.gaze = victim.global_position + Vector3(0, victim.top() * 0.7, 0)
			pet.wag = 9.0
			if Den.wade(victim.position) > 0.1:
				done = true
			if victim.state != Cryptlin.State.SPELL or pet.state_time > 7.0:
				pet._cry("chirp", 0.7)
				pet.hop(2.2)
				finish()


# One for the kelpie to call into the water: up, at a loose end, on dry floor, well, and not
# one that lives in water itself
func _dupe() -> Cryptlin:
	var fair: Array[Cryptlin] = []
	for other in pet.world.pets():
		if other != pet and not other.needs_water() and other.state in Cryptlin.INTERRUPTIBLE and other.health >= Cryptlin.POORLY and Den.wade(other.position) <= 0.0:
			fair.append(other)
	return fair.pick_random() if not fair.is_empty() else null
