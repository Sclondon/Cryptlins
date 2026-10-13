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

# What the notebook says of each kind's knack, once it has been seen: what it does, in a line, and
# nothing of what comes of it
const NOTES: Array[String] = [
	"gets at the lamp's cord until the light flickers",
	"goes out of focus if it is looked at too long, and then is somewhere else",
	"stares one of the others stiff and grey as stone",
	"flies up and circles the bulb",
	"gets its teeth into a thing and leaves it shrivelled",
	"takes its food with its tongue, sooner than walk to it",
	"sinks in the pool to its hump, and comes up somewhere else",
	"comes down the floor with its mouth open, like a slip in the cutting",
	"puts frost on the floor where it stands",
	"calls one of the dry ones down into the water after it",
	"sings, and a quarrel stops",
	"makes the cellar go strange while it sleeps",
	"stands like an ornament while it is watched, and shifts things about when it is not",
	"shakes its dust over one of the others, which then has to dance",
	"puffs out spores, and toadstools come up where it sat",
	"throws its voice, and bolts the other way",
	"lifts things in a beam of green light and sets them down somewhere else",
	"shakes snow out of its coat",
	"stands guard, three heads of three minds",
	"digs straight down and comes up somewhere else",
	"walks straight through a thing as if it were not there",
	"snatches the toy and takes it up out of reach",
	"takes a long run at flying and comes down in a heap",
	"lets out a sour green mist from under its skirt",
	"goes up into the vent and screams down it",
	"spits, and leaves a yellow puddle",
	"throws things the length of the cellar with both hands",
	"goes up in a hop and comes down somewhere else",
	"dives and skims the pool with its beak, or whatever else is standing about",
	"combs its hair until the lamp glints off it",
]
# How likely it is to take a turn at it, next to the 34 of wandering off
const WEIGHT := 7.0
# How long before it will do it again, at least and at most (seconds)
const REST := Vector2(45.0, 110.0)
const STONE := Color(0.42, 0.42, 0.44)
# What the merling sings, as how high each note is next to the first
const TUNE: Array[float] = [1.0, 1.19, 1.33, 1.5, 1.33, 1.19, 1.0, 0.89, 1.0, 1.33, 1.19, 1.0]
# The mist of the Flatwoods monster, the soot in the flue, and what the death worm spits
const MIST := Color(0.5, 0.78, 0.26)
const SOOT := Color(0.05, 0.05, 0.055)
const SPIT := Color(0.86, 0.8, 0.12)

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
# How long the gnome has stood stock still this turn
var stiff := 0.0
# Which way the jackalope is jinking; the beam of the alien, whether it has hold of anything
# with it and how high that has been lifted; how long before Cerberus will growl again, and
# the three small faces over its heads
var zig := 1.0
var beam: MeshInstance3D
var carrying := false
var height := 0.0
var growl := 0.0
var minds: Array[MeshInstance3D] = []
# Where the nightcrawler comes out on the far side of what it walks through, and how far over
# the boar has gone in its tumble
var far := Vector3.ZERO
var spun := 0.0
# The mist the Flatwoods monster has let out; the soot on the Jersey devil, and whether it is
# out of sight up the vent; and what the death worm has spat, while it is in the air
var fog: Node3D
var soot: ShaderMaterial
var hid := false
var gob: MeshInstance3D
# Where the kongamato took off from for its dive, and how far over what it has knocked is lying
var launch := Vector3.ZERO
var tipped := 0.0
# The stone the yowie has scrabbled up to throw, which way it is going, and how often it has come
# down
var missile: MeshInstance3D
var flung := Vector3.ZERO
var bounces := 0


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
		Cryptlin.Kind.MERFOLK:
			return world.pets().size() > 1
		Cryptlin.Kind.SPAWN:
			return true
		Cryptlin.Kind.GNOME:
			return _trinket() != null
		Cryptlin.Kind.FAE:
			return pet._someone() != null
		Cryptlin.Kind.FUNGUS, Cryptlin.Kind.MOLE:
			return Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.JACKALOPE, Cryptlin.Kind.CERBERUS:
			return true
		Cryptlin.Kind.ALIEN:
			return _cargo() != null
		Cryptlin.Kind.YETI:
			return world.lamp_mode != Den.Lamp.HEAT and Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.NIGHTCRAWLER:
			return _obstacle() != null and Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.MONKEY:
			return _loot() != null and pet.energy > 25.0
		Cryptlin.Kind.BOAR:
			return pet.energy > 30.0 and Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.FLATWOODS:
			return Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.DEVIL:
			return pet.energy > 25.0 and Den.wade(pet.position) <= 0.0 and Den.wade(Den.in_room(_vent(), 0.4)) <= 0.0
		Cryptlin.Kind.WORM:
			return Den.wade(pet.position) <= 0.0 and _puddles() < 2
		Cryptlin.Kind.YOWIE:
			return pet.energy > 25.0 and Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.KANGAROO:
			return pet.energy > 25.0 and Den.wade(pet.position) <= 0.0
		Cryptlin.Kind.KONGAMATO:
			return pet.energy > 25.0 and Den.wade(pet.position) <= 0.0 and (Den.shore != Den.Shore.NONE or _skittle() != null)
		Cryptlin.Kind.MERMAID:
			return world.light_on
	return false


func weight() -> float:
	# The mothman is up at the bulb a good deal more when there is trouble on the way
	# (as the merling sings a good deal more when there is a quarrel to settle)
	if pet.kind in [Cryptlin.Kind.MOTHMAN, Cryptlin.Kind.MERFOLK] and _trouble():
		return WEIGHT * 3.0
	return WEIGHT


# Time passing, whatever it is doing
func always(delta: float) -> void:
	again -= delta
	if pet.kind == Cryptlin.Kind.YETI:
		_weather(delta)
	# The room goes strange for as long as a Cthulhu spawn is asleep in it, or dreaming on its feet
	if pet.kind == Cryptlin.Kind.SPAWN and (pet.state == Cryptlin.State.SLEEP or (pet.state == Cryptlin.State.TRICK and pet.state_time > 0.8)):
		pet.world.strange = 1.0
		if pet.world.weird > 0.9 and not pet.world.resting:
			pet.world.learned(pet, "knack")


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
		Cryptlin.Kind.GNOME:
			mark = _trinket()
			stiff = 0.0
		Cryptlin.Kind.FAE:
			victim = pet._someone()
		Cryptlin.Kind.JACKALOPE:
			# (the voice comes from the far side of the room from where it is)
			pet.target = pet._footing(Vector3(Den.half.x * (-0.7 if pet.position.x > 0.0 else 0.7), 0, Den.half.y * (-0.5 if pet.position.z > 0.0 else 0.5)), 0.4)
		Cryptlin.Kind.ALIEN:
			var cargo := _cargo()
			height = 0.0
			if cargo is Cryptlin:
				victim = cargo as Cryptlin
			else:
				mark = cargo
		Cryptlin.Kind.CERBERUS:
			mark = _ward()
			growl = 0.0
			var post := Vector3(mark.position.x, 0, mark.position.z)
			pet.target = pet._footing(post + (Vector3(0, 0, 0.6) - post).normalized() * 0.6, 0.4)
		Cryptlin.Kind.NIGHTCRAWLER:
			mark = _obstacle()
			_line_up()
		Cryptlin.Kind.MONKEY:
			mark = _loot()
			height = 0.0
		Cryptlin.Kind.BOAR:
			# (the long way of the room, from whichever end it is nearer)
			pet.target = pet._footing(Vector3(Den.half.x * (0.8 if pet.position.x > 0.0 else -0.8), 0, pet.position.z), 0.5)
			spun = 0.0
		Cryptlin.Kind.DEVIL:
			var under := _vent()
			pet.target = pet._footing(Vector3(under.x, 0, under.z + 0.5), 0.4)
			height = 0.0
		Cryptlin.Kind.WORM:
			pet.target = _spittoon()
		Cryptlin.Kind.KELPIE:
			victim = _dupe()
			if victim != null:
				# (well out, and a little to one side, to leave it room to come in)
				pet.target = Den.in_room(Den.shore_by(victim.position + Den.place(-1.0 if victim.position.x > 0.0 else 1.0, 0.0), -0.9), 0.5)
		Cryptlin.Kind.YOWIE:
			mark = _to_hand()
			bounces = 0
		Cryptlin.Kind.KANGAROO:
			for i in 8:
				pet.target = Den.on_dry(Vector3(randf_range(-Den.half.x, Den.half.x), 0, randf_range(-Den.half.y, Den.half.y)), 0.5, 0.4)
				if pet.target.distance_to(pet.position) > 1.4:
					break
			height = 0.0
		Cryptlin.Kind.KONGAMATO:
			_aim()
		Cryptlin.Kind.MERMAID:
			mark = _perch()
			if mark != null:
				pet.target = Vector3(mark.position.x, 0, mark.position.z)
			elif Den.shore != Den.Shore.NONE:
				pet.target = Den.in_room(Den.shore_by(pet.position, -0.1), 0.4)
			else:
				pet.target = pet.position
			height = 0.0


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
		Cryptlin.Kind.MERFOLK:
			_sing(delta)
		Cryptlin.Kind.SPAWN:
			_dream(delta)
		Cryptlin.Kind.GNOME:
			_meddle(delta)
		Cryptlin.Kind.FAE:
			_dust(delta)
		Cryptlin.Kind.FUNGUS:
			_spore(delta)
		Cryptlin.Kind.JACKALOPE:
			_throw(delta)
		Cryptlin.Kind.ALIEN:
			_beam(delta)
		Cryptlin.Kind.YETI:
			_snow(delta)
		Cryptlin.Kind.CERBERUS:
			_guard(delta)
		Cryptlin.Kind.MOLE:
			_tunnel(delta)
		Cryptlin.Kind.NIGHTCRAWLER:
			_pass(delta)
		Cryptlin.Kind.MONKEY:
			_snatch(delta)
		Cryptlin.Kind.BOAR:
			_charge(delta)
		Cryptlin.Kind.FLATWOODS:
			_mist(delta)
		Cryptlin.Kind.DEVIL:
			_flue(delta)
		Cryptlin.Kind.WORM:
			_spit(delta)
		Cryptlin.Kind.YOWIE:
			_lob(delta)
		Cryptlin.Kind.KANGAROO:
			_vanish(delta)
		Cryptlin.Kind.KONGAMATO:
			_swoop(delta)
		Cryptlin.Kind.MERMAID:
			_comb(delta)
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
	pet.rotation.x = 0.0
	for eye in pet.eye_mats:
		eye.set_shader_parameter("glow", 0.85)
	if beam != null:
		beam.queue_free()
		beam = null
	if carrying:
		# (what the beam had hold of is let go where it is)
		carrying = false
		if not is_instance_valid(mark):
			pass
		elif mark is Ball and pet.world.grab != Den.Grab.BALL:
			mark.held = false
		elif mark is Snack:
			_let_fall(mark)
	height = 0.0
	for face in minds:
		face.visible = false
	if tongue != null:
		tongue.queue_free()
		tongue = null
		if mark is Snack:
			_let_fall(mark)
	if stone != null:
		stone = null
		pet._unghost()
	if fog != null:
		fog.queue_free()
		fog = null
	_clean()
	if hid:
		hid = false
		pet.visible = true
	_swallow()
	if missile != null:
		missile.queue_free()
		missile = null
	if pet.kind == Cryptlin.Kind.KANGAROO:
		pet.visible = true
		pet.thin(1.0)
	if pet.kind == Cryptlin.Kind.KONGAMATO and tipped != 0.0:
		tipped = 0.0
		if is_instance_valid(mark):
			mark.rotation.x = 0.0
			mark.rotation.z = 0.0
	if pet.tresses != null:
		pet.tresses.set_shader_parameter("glow", 0.0)
	spell = ""
	caster = null


# A bit of food that its knack had hold of drops to the floor where it is, unless a finger has it
func _let_fall(food: Snack) -> void:
	if is_instance_valid(food) and food.held and pet.world.held_snack != food:
		food.held = false
		food.landed = true
		food.position.y = 0.0



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
		"dance":
			# Its feet will not keep still
			pet._halt(delta)
			pet.arm_goal = Cryptlin.UP_ARM
			pet.wag = 10.0
			pet.wiggle = sin(pet.anim_t * 7.0) * 0.18
			pet.yaw += delta * 2.2
			pet.eye_goal = 1.2
			if not pet.airborne:
				pet.hop(1.9)
				pet.fun = minf(pet.fun + 1.0, 100.0)
		"beamed":
			# Up in the light of the alien, and carried: it is the alien that moves it
			pet.eye_goal = 1.3
			pet.arm_goal = Cryptlin.UP_ARM
			pet.velocity = Vector3.ZERO
			if not is_instance_valid(caster) or caster.state != Cryptlin.State.TRICK:
				pet.state_len = 0.0
		"lured":
			# Down the bank and in, as if it were walking in its sleep
			pet.eye_goal = 0.55
			pet.arm_goal = Vector3(-1.2, 0.0, 0.2)
			if is_instance_valid(caster):
				pet.gaze = caster.global_position + Vector3(0, caster.top() * 0.7, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 0.7, delta, 0.12):
				pet.state_len = minf(pet.state_len, pet.state_time + 0.6)
		"queasy":
			# Green about the gills: it stands and sways with its eyes half shut until it passes
			pet._halt(delta)
			pet.eye_goal = 0.45
			pet.droop_goal = 0.9
			pet.mouth_goal = 0.3 + 0.25 * maxf(sin(pet.state_time * 4.0), 0.0)
			pet.wag = 0.0
			pet.nod = 0.22
			pet.roll_goal = sin(pet.state_time * 2.1) * 0.28
			pet.wiggle = sin(pet.state_time * 2.7) * 0.07
			if pet.state_time < delta * 1.5:
				pet.feel(Cryptlin.Feeling.DISGUSTED, pet.state_len)
				pet._cry("whimper", 0.8, -6.0)
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
# to somewhere it cannot be seen, with a look back over its shoulder, and its footprints are
# what is left
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
	# (with one look back over its shoulder as it goes)
	if pet.state_time > 0.5 and pet.state_time - delta <= 0.5:
		pet.glance_back(1.3)
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
# thing in the room that has its full shape (never the pool, nor a gravestone)
func _prey() -> Node3D:
	var world := pet.world
	if world.ball != null and not world.ball.held and world.ball.speed() < 0.5 and not world.shrivelled.has(world.ball) and Den.wade(world.ball.position) <= 0.0:
		return world.ball
	var fair: Array[Node3D] = []
	for d in world.decors:
		if not d.kind in [Decor.Kind.POOL, Decor.Kind.GRAVESTONE] and d != world.held_thing and not world.shrivelled.has(d):
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


# The merling sings. It settles the room: a fight that is going on stops, two that have fallen
# out think a little better of each other and leave each other be for a while, and any that
# are tired go off to bed
func _sing(delta: float) -> void:
	var world := pet.world
	pet._halt(delta)
	pet.gaze = world.bulb.global_position
	pet.arm_goal = Vector3(-0.6, 0.0, 1.2)
	pet.arm_wave = 0.25
	pet.wiggle = sin(pet.state_time * 3.0) * 0.1
	pet.mouth_goal = 0.5 + 0.4 * absf(sin(pet.state_time * 7.0))
	pet.eye_goal = 0.5
	if _beat(0.42, delta):
		var note := int(pet.state_time / 0.42) % TUNE.size()
		pet._cry("coo", TUNE[note], -3.0)
		world.crumbs(pet.global_position + Vector3(0, pet.top() + 0.15, 0), Color(0.6, 0.85, 1.0))
	if pet.step == 0 and pet.state_time > 2.4:
		_next()
		pet.state_time = 2.4
		if world.scuffle != null:
			world.end_fight(true)
		for other in world.pets():
			if other == pet:
				continue
			other.fight_cooldown = maxf(other.fight_cooldown, 90.0)
			for third in world.pets():
				if third != other and world.standing(other, third) < 45.0:
					world.warm(other, third, 2.0)
			if other.state in Cryptlin.INTERRUPTIBLE:
				if other.energy < 55.0:
					other._enter(Cryptlin.State.GO_SLEEP)
				else:
					other.feel(Cryptlin.Feeling.HAPPY, 5.0)
					other.glance_time = 2.0
					other.glance_point = pet.global_position + Vector3(0, pet.top(), 0)
		done = true
	if pet.state_time > 5.0:
		finish()


# The Cthulhu spawn dreams, and the room goes strange with it (see Den.strange). It does so
# whenever it is asleep; as a turn of its own it nods off where it sits for a few seconds
func _dream(delta: float) -> void:
	pet._halt(delta)
	pet.sit_goal = 1.0
	pet.eye_goal = 0.0
	pet.droop_goal = 1.0
	pet.nod = 0.3 + sin(pet.state_time * 1.4) * 0.06
	pet.wag = 0.6
	if _beat(1.6, delta):
		pet._cry("snore", 0.7, -6.0)
	if pet.state_time > 2.5:
		done = true
	if pet.state_time > 6.0:
		pet._cry("yawn", 0.6)
		finish()


# The gnome will not be seen to move. With a finger just off the screen it stands like an
# ornament; left alone, it creeps over to some small thing and shifts it somewhere else
func _meddle(delta: float) -> void:
	var world := pet.world
	if world.left_alone() < 2.5:
		# Caught at it: not a twitch, eyes front, until the keeper has looked away a while
		pet._halt(delta)
		pet.blink = 1.0
		pet.eye_goal = 1.0
		pet.wag = 0.0
		pet.twitch = 0.0
		pet.gaze = pet.global_position + Vector3(sin(pet.yaw), 0.25, cos(pet.yaw)) * 3.0
		stiff += delta
		if stiff > 1.5:
			done = true
		if pet.state_time > 14.0:
			finish()
		return
	if not is_instance_valid(mark):
		finish()
		return
	var at := Vector3(mark.position.x, 0, mark.position.z)
	# (as near as it can get to it: a thing that stands in the room is walked round)
	var reach := 0.3 * pet.grow + ((mark as Decor).radius + 0.05 if mark is Decor else 0.15)
	pet.gaze = mark.global_position + Vector3(0, 0.1, 0)
	if pet.step == 0:
		pet.sit_goal = 0.3
		if pet._steer(at, Cryptlin.WALK * 0.8, delta, reach):
			var away := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * randf_range(0.7, 1.1)
			pet.target = Den.on_dry(at + away, 0.5, 0.4)
			_next()
		elif pet.state_time > 8.0:
			finish()
		return
	# It has hold of it, and off they go
	pet.arm_goal = Vector3(-1.3, 0.0, 0.3)
	var to := at.move_toward(pet.target, delta * 0.45)
	mark.position = Vector3(to.x, mark.position.y, to.z)
	pet._steer(to - (pet.target - at).normalized() * reach, Cryptlin.WALK * 0.8, delta, 0.05)
	if to.distance_to(pet.target) < 0.02 or pet.state_time > 5.0:
		done = true
		pet._cry("chirp", 0.8, -8.0)
		world.save_game()
		finish()


# Some small thing for the gnome to shift: one of the smaller things that stand in the room,
# the toy if it is lying still, or a bit of food
func _trinket() -> Node3D:
	var world := pet.world
	var fair: Array[Node3D] = []
	for d in world.decors:
		if d.kind in [Decor.Kind.SKULL, Decor.Kind.CRYSTAL, Decor.Kind.PUMPKIN, Decor.Kind.FERN, Decor.Kind.DISH, Decor.Kind.POT] and d != world.held_thing:
			fair.append(d)
	if world.ball != null and not world.ball.held and world.ball.speed() < 0.3 and Den.wade(world.ball.position) <= 0.0:
		fair.append(world.ball)
	for food in world.snacks:
		if food.landed and not food.held and Den.wade(food.position) <= 0.0:
			fair.append(food)
	return fair.pick_random() if not fair.is_empty() else null


# The fae flits over to one of the others and shakes its dust out over it, and that one has to
# dance until the dust wears off. Now and then it leaves a little something to eat behind
func _dust(delta: float) -> void:
	var world := pet.world
	if not is_instance_valid(victim) or victim.me.leaving:
		finish()
		return
	var over := victim.global_position + Vector3(0, victim.top() + 0.1, 0)
	pet.gaze = over
	match pet.step:
		0:
			if pet._steer(victim.position, Cryptlin.RUN * 0.7, delta, 0.55) or pet.state_time > 6.0:
				_next()
		1:
			pet._halt(delta)
			pet._face(victim.position, delta)
			pet.arm_goal = Cryptlin.UP_ARM
			pet.arm_wave = 0.8
			pet.wiggle = sin(pet.state_time * 12.0) * 0.1
			if _beat(0.18, delta):
				world.crumbs(over + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15)), Color(1.0, 0.85, 0.35))
				world.sfx.play("jingle", randf_range(1.0, 1.6), -12.0)
			if pet.state_time > 1.1 and not done:
				done = victim.knack.bewitch("dance", pet, 4.0)
			if pet.state_time > 1.8:
				if done and randf() < 0.35:
					world.gift(pet.position + Vector3(sin(pet.yaw), 0, cos(pet.yaw)) * 0.3)
				pet._cry("chirp", 1.2)
				finish()


# The living fungus sits down and puffs out a cloud of spores; and when it has got up and gone,
# tiny toadstools come up where it sat
func _spore(delta: float) -> void:
	var world := pet.world
	if pet.step == 0:
		pet._halt(delta)
		pet.sit_goal = 1.0
		pet.eye_goal = 0.6
		if pet.state_time > 0.9 and _beat(0.5, delta):
			pet.squash_v = 2.4
			world.crumbs(pet.global_position + Vector3(0, pet.top() * 0.8, 0), Color(0.72, 0.8, 0.5))
			world.sfx.play("thud", 1.8, -14.0)
		if pet.state_time > 2.8:
			world.leave_print("toadstools", pet.position, randf() * TAU, 1.0, pet.grow)
			done = true
			pet.target = pet._footing(pet.position + Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.8, 0.4)
			_next()
		return
	pet.gaze = pet.target + Vector3(0, 0.3, 0)
	if pet._steer(pet.target, Cryptlin.WALK, delta, 0.2) or pet.state_time > 3.0:
		finish()


# The jackalope throws its voice: there is a cry from the far side of the room, the others go
# off to see what it was, and it bolts the other way in zigzags
func _throw(delta: float) -> void:
	var world := pet.world
	if pet.step == 0:
		pet._halt(delta)
		pet.gaze = pet.target + Vector3(0, 0.4, 0)
		pet.mouth_goal = 0.7
		pet.eye_goal = 1.2
		if pet.state_time > 0.5 and not done:
			done = true
			world.sfx.play("chirp", 0.55, -2.0)
			world.crumbs(pet.target + Vector3(0, 0.3, 0), Den.DUST)
			for other in world.pets():
				if other != pet and other.state in Cryptlin.INTERRUPTIBLE:
					other.call_to(pet.target + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)))
		if pet.state_time > 1.1:
			zig = 1.0 if randf() < 0.5 else -1.0
			pet.yaw = atan2(pet.position.x - pet.target.x, pet.position.z - pet.target.z)
			_next()
		return
	# Off, a few bounds one way and a few the other
	if _beat(0.4, delta) or pet.state_time < delta * 1.5:
		zig = -zig
		var way := Vector3(sin(pet.yaw + zig * 1.0), 0, cos(pet.yaw + zig * 1.0))
		pet.target = pet._footing(pet.position + way * 1.4, 0.4)
		if pet.target.distance_to(pet.position) < 0.5:
			pet.target = pet._footing(-pet.position * 0.6, 0.4)
		pet.hop(1.6)
	pet.gaze = pet.target + Vector3(0, 0.3, 0)
	pet.droop_goal = 0.9
	pet._steer(pet.target, Cryptlin.RUN * 1.15, delta, 0.1)
	if pet.state_time > 3.0:
		finish()


# The alien lifts something in a beam of light, carries it across the room and sets it down:
# one of the others, the toy, or a bit of food
func _beam(delta: float) -> void:
	var world := pet.world
	var cargo: Node3D = victim if victim != null else mark
	if not is_instance_valid(cargo) or (victim != null and pet.step > 0 and victim.state != Cryptlin.State.SPELL):
		finish()
		return
	if cargo is Ball and world.grab == Den.Grab.BALL or cargo == world.held_snack:
		finish()
		return
	pet._halt(delta)
	pet._face(cargo.position, delta)
	pet.gaze = cargo.global_position + Vector3(0, 0.2, 0)
	pet.arm_goal = Cryptlin.UP_ARM
	pet.eye_goal = 1.3
	for eye in pet.eye_mats:
		eye.set_shader_parameter("glow", 1.6)
	var rest := 0.0 if victim != null else (Ball.R if cargo is Ball else 0.02)
	match pet.step:
		0:
			if pet.state_time > 0.7:
				var light := ShaderMaterial.new()
				light.shader = Track.FROST
				light.set_shader_parameter("tint", Color(0.4, 1.0, 0.7))
				light.set_shader_parameter("depth", 0.4)
				beam = Ps1.part(world, Ps1.drum(8, 0.5), light, cargo.position)
				beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				world.sfx.play("jingle", 0.5, -6.0)
				if victim != null:
					if not victim.knack.bewitch("beamed", pet, 12.0):
						finish()
						return
				elif cargo is Ball:
					cargo.held = true
				else:
					cargo.hold()
				carrying = true
				for i in 8:
					pet.target = Den.on_dry(Vector3(randf_range(-Den.half.x, Den.half.x), 0, randf_range(-Den.half.y, Den.half.y)), 0.5, 0.4)
					if pet.target.distance_to(cargo.position) > 1.2:
						break
				_next()
		1:
			# Up
			height = move_toward(height, 0.9, delta * 0.9)
			if height >= 0.9:
				_next()
		2:
			# Across
			var to := Vector3(cargo.position.x, 0, cargo.position.z).move_toward(pet.target, delta * 1.0)
			cargo.position.x = to.x
			cargo.position.z = to.z
			if to.distance_to(pet.target) < 0.02:
				done = true
				_next()
		3:
			# And down again
			height = move_toward(height, 0.0, delta * 1.1)
			if height <= 0.0:
				pet._cry("chirp", 1.3)
				finish()
				return
	if victim != null:
		victim.lift = height
		victim.velocity = Vector3.ZERO
	else:
		cargo.position.y = rest + height
		if cargo is Ball:
			cargo.vel = Vector3.ZERO
	if beam != null:
		beam.position = Vector3(cargo.position.x, 1.7, cargo.position.z)
		beam.scale = Vector3(0.34, 3.4, 0.34) * Vector3(1.0 + sin(pet.anim_t * 23.0) * 0.06, 1.0, 1.0 + sin(pet.anim_t * 23.0) * 0.06)


# Something for the alien to lift: one of the others that is up and at a loose end on dry
# floor, or else the toy lying still, or else a bit of food
func _cargo() -> Node3D:
	var world := pet.world
	var other := pet._someone()
	if other != null and Den.wade(other.position) <= 0.0:
		return other
	if world.ball != null and not world.ball.held and world.ball.speed() < 0.3:
		return world.ball
	for food in world.snacks:
		if food.landed and not food.held:
			return food
	return null


# The yeti shakes itself, and snow comes out of its coat and lies round it for a while
func _snow(delta: float) -> void:
	var world := pet.world
	pet._halt(delta)
	pet.gaze = world.camera.global_position
	pet.arm_goal = Vector3(-0.3, 0.0, 1.1)
	pet.wiggle = sin(pet.state_time * 26.0) * 0.14 * clampf(2.6 - pet.state_time, 0.0, 1.0)
	pet.eye_goal = 0.4
	if pet.state_time < delta * 1.5:
		pet._cry("grumble", 1.4)
	if pet.state_time < 2.6 and _beat(0.25, delta):
		var around := randf() * TAU
		var out := randf_range(0.25, 0.75) * pet.grow
		world.leave_print("snow", pet.position + Vector3(cos(around), 0, sin(around)) * out, around, 1.0, pet.grow * randf_range(0.7, 1.3))
		world.crumbs(pet.global_position + Vector3(cos(around) * 0.3, pet.top() * 0.7, sin(around) * 0.3), Color(0.92, 0.95, 1.0))
	if pet.state_time > 1.5:
		done = true
	if pet.state_time > 3.4:
		finish()


# What comes of being a yeti in a basement, turn or no turn: its breath shows, and under the
# heat lamp it droops and pants
func _weather(delta: float) -> void:
	var world := pet.world
	if world.lamp_mode == Den.Lamp.HEAT:
		if pet.state in [Cryptlin.State.IDLE, Cryptlin.State.STARE, Cryptlin.State.WANDER]:
			pet.mouth_goal = 0.55 + sin(pet.anim_t * 9.0) * 0.25
			pet.droop_goal = 0.9
			pet.eye_goal = 0.6
	elif pet.state != Cryptlin.State.SLEEP and not pet.xrayed and int(pet.anim_t / 4.0) != int((pet.anim_t - delta) / 4.0):
		world.crumbs(pet.mouth_node.global_position + Vector3(sin(pet.yaw), 0, cos(pet.yaw)) * 0.1, Color(0.85, 0.9, 1.0))


# Cerberus stands guard: over an egg if there is one, or else the nest. It plants itself in
# front of it, each of its three heads of a different mind about the business, and any of the
# others that comes too close is seen off (and none the worse for it)
func _guard(delta: float) -> void:
	var world := pet.world
	if not is_instance_valid(mark):
		finish()
		return
	var post := Vector3(mark.position.x, 0, mark.position.z)
	if pet.step == 0:
		pet.gaze = post + Vector3(0, 0.2, 0)
		if pet._steer(pet.target, Cryptlin.WALK * 1.4, delta, 0.2) or pet.state_time > 7.0:
			_next()
		return
	pet._halt(delta)
	pet._face(pet.position * 2.0 - post, delta)
	pet.sit_goal = 0.4
	pet.wag = 1.5
	pet.eye_goal = 1.15
	pet.gaze = pet.global_position + Vector3(sin(pet.yaw), 0.2, cos(pet.yaw)) * 3.0
	# One head looks left and one right, and they do not keep time
	for i in pet.heads.size():
		var side := -1.0 if i == 0 else 1.0
		pet.heads[i].rotation = Vector3(sin(pet.state_time * (1.7 + i) + i) * 0.25, side * (1.0 + sin(pet.state_time * (2.3 - i * 0.6)) * 0.35), -0.2 * side)
	_three_minds()
	if pet.state_time > 2.0:
		done = true
	growl -= delta
	for other in world.pets():
		if other != pet and growl <= 0.0 and other.lift <= 0.05 and not other.state in [Cryptlin.State.SLEEP, Cryptlin.State.HELD, Cryptlin.State.SHOVED, Cryptlin.State.SCUFFLE, Cryptlin.State.SCANNED, Cryptlin.State.DYING, Cryptlin.State.LEAVE] and other.position.distance_to(post) < 0.9:
			growl = 1.5
			pet._cry("grumble", 0.8)
			pet.mouth_goal = 1.0
			other.cuffed(pet)
	if pet.state_time > 7.0:
		finish()


# The three small faces over its three heads, which never agree: they change places as it stands
func _three_minds() -> void:
	var world := pet.world
	if minds.is_empty():
		for i in 3:
			var face: MeshInstance3D = pet.emote.duplicate()
			face.material_override = pet.emote.material_override.duplicate()
			pet.add_child(face)
			minds.append(face)
	pet.emote.visible = false
	pet.emote_again = maxf(pet.emote_again, 2.0)
	var moods: Array[int] = [Cryptlin.Feeling.GRUMPY, Cryptlin.Feeling.HAPPY, Cryptlin.Feeling.SLEEPY]
	var cam := world.camera
	var above := pet.global_position + Vector3(0, pet.top(), 0)
	var deep := -(cam.global_transform.affine_inverse() * above).z
	var dot := 2.0 * deep * tan(deg_to_rad(cam.fov) * 0.5) / world.view.size.y
	for i in 3:
		var face := minds[i]
		face.visible = true
		face.material_override.albedo_texture = pet.faces[moods[(i + int(pet.state_time / 1.3)) % 3]]
		face.material_override.albedo_color.a = 1.0
		var at := (cam.unproject_position(above) + Vector2((i - 1) * (Cryptlin.FACE + 1.0), -Cryptlin.FACE * 0.5 - 4.0 - (2.0 if i == 1 else 0.0))).round()
		face.global_transform = Transform3D(cam.global_basis * Basis.from_scale(Vector3.ONE * dot * Cryptlin.FACE), cam.project_position(at, deep))


# Where Cerberus would stand guard: by an egg if there is one in the room, or else by the nest
func _ward() -> Node3D:
	for r in pet.world.residents:
		if r.egg != null and r.egg.landed:
			return r.egg
	return pet.world.nest


# The mole person digs straight down, goes along under the floor, and comes up somewhere else,
# with a molehill left at each end of the tunnel
func _tunnel(delta: float) -> void:
	var world := pet.world
	var earth: Color = Den.GROUND_TINTS[world.floor_style]
	match pet.step:
		0:
			pet._halt(delta)
			pet.nod = 0.6
			pet.arm_goal = Vector3(-1.0, 0.0, 0.2)
			pet.arm_wave = 1.0
			if _beat(0.25, delta):
				world.crumbs(pet.global_position + Vector3(0, 0.1, 0), earth)
				world.sfx.play("thud", randf_range(1.2, 1.6), -10.0)
			if pet.state_time > 1.3:
				_next()
		1:
			# Down
			pet._halt(delta)
			pet.dive = move_toward(pet.dive, pet.tall() + 0.1, delta * 1.6)
			if pet.dive >= pet.tall() + 0.1:
				world.leave_mess(Mess.Kind.HEAP, pet.position, pet)
				for i in 8:
					pet.target = pet._footing(Vector3(randf_range(-Den.half.x, Den.half.x), 0, randf_range(-Den.half.y, Den.half.y)), 0.5)
					if pet.target.distance_to(pet.position) > 1.3:
						break
				_next()
		2:
			# Along, with the floor stirring over it
			pet.velocity = Vector3.ZERO
			var to := pet.position.move_toward(pet.target, delta * 1.3)
			pet.position.x = to.x
			pet.position.z = to.z
			if _beat(0.35, delta):
				world.crumbs(Vector3(to.x, 0.05, to.z), earth)
			if Vector2(to.x - pet.target.x, to.z - pet.target.z).length() < 0.05 or pet.state_time > 5.0:
				world.leave_mess(Mess.Kind.HEAP, pet.position + Vector3(0.12, 0, -0.1), pet)
				world.sfx.play("thud", 1.0, -6.0)
				done = true
				_next()
		3:
			# And up
			pet._halt(delta)
			pet.dive = move_toward(pet.dive, 0.0, delta * 1.8)
			if pet.dive <= 0.0:
				world.crumbs(pet.global_position + Vector3(0, 0.15, 0), earth)
				pet.hop(1.6)
				pet._cry("chirp", 0.7)
				finish()


# The Fresno nightcrawler walks straight through a thing in the room as if it were not there:
# up to it, a moment stood dead still, then on at the same stiff pace, out of the far side, and
# not a look back
func _pass(delta: float) -> void:
	var world := pet.world
	var thing := mark as Decor
	if not is_instance_valid(thing) or thing.is_queued_for_deletion() or thing == world.held_thing:
		finish()
		return
	var ahead := pet.global_position + Vector3(sin(pet.yaw), 0.0, cos(pet.yaw)) * 3.0 + Vector3(0, pet.top() * 0.9, 0)
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.5, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 1.2, delta, 0.2) or pet.state_time > 6.0:
				_next()
		1:
			# Stood facing it, not a blink
			pet._halt(delta)
			pet._face(far, delta)
			pet.gaze = ahead
			pet.blink = 1.0
			pet.wag = 0.0
			if pet.state_time > 0.9:
				_next()
		2:
			pet.gaze = ahead
			pet.blink = 1.0
			if _beat(0.45, delta):
				world.sfx.play("click", 0.6, -16.0)
			# (it has done it once it is past the middle of the thing, on its line through it)
			var off := Vector3(pet.position.x - thing.position.x, 0, pet.position.z - thing.position.z)
			var onward := Vector3(far.x - thing.position.x, 0, far.z - thing.position.z).normalized()
			if off.dot(onward) > 0.0 and off.cross(onward).length() < thing.radius + 0.15:
				done = true
			if pet._steer(far, Cryptlin.WALK * 0.9, delta, 0.1) or pet.state_time > 9.0:
				_next()
		3:
			pet._halt(delta)
			pet.gaze = ahead
			if pet.state_time > 1.0:
				finish()


# Whether the nightcrawler is on its way through this thing just now, and so is not kept off it
func through(thing: Decor) -> bool:
	# (nor is the mermaid kept off the rock it is getting up on to comb its hair)
	if pet.kind == Cryptlin.Kind.MERMAID and pet.state == Cryptlin.State.TRICK and pet.step >= 1 and thing == mark:
		return true
	return pet.kind == Cryptlin.Kind.NIGHTCRAWLER and pet.state == Cryptlin.State.TRICK and pet.step >= 2 and thing == mark


# Something standing in the room for the nightcrawler to walk through: the biggest there is on
# dry floor (never the pool, nor a thing a finger has hold of)
func _obstacle() -> Decor:
	var world := pet.world
	var best: Decor = null
	for d in world.decors:
		if d.kind != Decor.Kind.POOL and d != world.held_thing and Den.wade(d.position) <= 0.0 and (best == null or d.radius > best.radius):
			best = d
	return best


# Where the nightcrawler starts from and where it comes out: either side of the thing, on a line
# that has floor at both ends of it, as near as may be to the side it is on already
func _line_up() -> void:
	var thing := mark as Decor
	if thing == null:
		return
	var from := Vector3(pet.position.x - thing.position.x, 0, pet.position.z - thing.position.z)
	from = from.normalized() if from.length() > 0.05 else Vector3.BACK
	var out := thing.radius + 0.3 * pet.grow + 0.3
	for i in 8:
		var way := from.rotated(Vector3.UP, TAU * ceili(i / 2.0) / 8.0 * (1.0 if i % 2 == 0 else -1.0))
		var near := thing.position + way * out
		var beyond := thing.position - way * out
		pet.target = Vector3(near.x, 0, near.z)
		far = Vector3(beyond.x, 0, beyond.z)
		if Den.on_dry(pet.target, 0.35, 0.2).distance_to(pet.target) < 0.05 and Den.on_dry(far, 0.35, 0.2).distance_to(far) < 0.05:
			return


# The flying monkey snatches the toy, or a bit of food, flies up out of reach with it and sits
# on the air chattering; then it comes down and gives it back. Nothing is lost
func _snatch(delta: float) -> void:
	var world := pet.world
	if not _has(mark):
		finish()
		return
	var at := Vector3(mark.position.x, 0, mark.position.z)
	match pet.step:
		0:
			pet.gaze = mark.global_position
			pet.mouth_goal = 0.5
			if pet._steer(at, Cryptlin.RUN * 0.8, delta, 0.22 * pet.grow + 0.12) and not pet.airborne:
				if mark is Ball:
					(mark as Ball).held = true
					(mark as Ball).vel = Vector3.ZERO
				else:
					(mark as Snack).hold()
				carrying = true
				pet._cry("chirp", 1.3)
				_next()
			elif pet.state_time > 7.0:
				finish()
			return
		1:
			# Up
			height = move_toward(height, 1.3, delta * 1.3)
			if height >= 1.3:
				_next()
		2:
			# And there it stays, pleased with itself
			pet.mouth_goal = 0.5 + 0.4 * absf(sin(pet.state_time * 9.0))
			pet.wag = 12.0
			pet.wiggle = sin(pet.state_time * 8.0) * 0.08
			if _beat(0.5, delta):
				pet._cry("squeak", randf_range(0.8, 1.1), -4.0)
			if pet.state_time > 1.0:
				done = true
			if pet.state_time > 3.4:
				_next()
		3:
			# Down again, and it is put back on the floor
			height = move_toward(height, 0.0, delta * 1.2)
			if height <= 0.0:
				carrying = false
				pet.lift = 0.0
				_put_down()
				pet._cry("coo", 1.1)
				finish()
				return
	pet._halt(delta)
	pet.gaze = world.camera.global_position
	pet._face(pet.gaze, delta)
	pet.arm_goal = Vector3(-1.4, 0.0, 0.2)
	pet.lift = height + (sin(pet.anim_t * 3.0) * 0.05 if pet.step == 2 else 0.0)
	pet.flying = true
	# What it has is held out in front of it in both hands
	var hands := pet.global_position + Vector3(sin(pet.yaw), 0, cos(pet.yaw)) * 0.3 * pet.grow + Vector3(0, 0.36 * pet.grow, 0)
	mark.global_position = hands
	if mark is Ball:
		(mark as Ball).vel = Vector3.ZERO


# Whether the monkey can still have what it went for: there, and in nobody's hand but its own
func _has(thing: Node3D) -> bool:
	var world := pet.world
	if not is_instance_valid(thing) or thing.is_queued_for_deletion():
		return false
	if thing is Ball:
		return world.ball == thing and world.grab != Den.Grab.BALL and (carrying or not (thing as Ball).held)
	return world.snacks.has(thing) and world.held_snack != thing and (carrying or not (thing as Snack).held)


# What the monkey was carrying is set down on the floor in front of it
func _put_down() -> void:
	var spot := Den.in_room(pet.position + Vector3(sin(pet.yaw), 0, cos(pet.yaw)) * 0.3 * pet.grow, 0.2)
	if mark is Ball:
		var toy := mark as Ball
		toy.position = Vector3(spot.x, Ball.R, spot.z)
		toy.vel = Vector3.ZERO
		toy.held = false
	elif mark is Snack:
		mark.position = Vector3(spot.x, 0, spot.z)
		_let_fall(mark as Snack)


# Something for the monkey to make off with: the toy, if it is lying still, or else a bit of
# food that is lying on dry floor
func _loot() -> Node3D:
	var world := pet.world
	if world.ball != null and is_instance_valid(world.ball) and not world.ball.held and world.ball.speed() < 0.5 and Den.wade(world.ball.position) <= 0.0:
		return world.ball
	for food in world.snacks:
		if food.landed and not food.held and Den.wade(food.position) <= 0.0:
			return food
	return null


# The flying boar takes a long run at it down the length of the room with its wings going like
# a wasp in a jar, gets off the floor for a moment, and comes down head over heels in a heap
func _charge(delta: float) -> void:
	var world := pet.world
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.2, 0)
			if pet._steer(pet.target, Cryptlin.WALK * 1.4, delta, 0.25) or pet.state_time > 8.0:
				pet.target = pet._footing(Vector3(-pet.target.x, 0, pet.target.z), 0.5)
				pet._cry("grumble", 0.9)
				_next()
		1:
			# It paws the floor, and gets its wings going
			pet._halt(delta)
			pet._face(pet.target, delta)
			pet.gaze = pet.target + Vector3(0, 0.3, 0)
			pet.nod = 0.3
			pet.flying = true
			pet.wiggle = sin(pet.state_time * 18.0) * 0.04
			if _beat(0.3, delta):
				world.crumbs(pet.global_position + Vector3(0, 0.05, 0), Den.DUST)
				world.sfx.play("sweep", 0.7, -12.0)
			if pet.state_time > 1.1:
				_next()
		2:
			# Off down the room, and up
			pet.flying = true
			pet.mouth_goal = 0.7
			pet.eye_goal = 1.2
			pet.gaze = pet.target + Vector3(0, 0.6, 0)
			if pet.state_time > 0.45:
				pet.lift = move_toward(pet.lift, 0.7 * pet.grow, delta * 0.9)
			if _beat(0.12, delta):
				world.sfx.play("click", 0.5, -18.0)
			var away := Vector2(pet.target.x - pet.position.x, pet.target.z - pet.position.z).length()
			if pet._steer(pet.target, Cryptlin.RUN * 1.1, delta, 0.3) or away < Den.half.x * 0.85 or pet.state_time > 2.4:
				height = pet.lift
				pet._cry("squeak", 0.9)
				_next()
		3:
			# Its wings give out: over and over it goes, and down
			pet.flying = false
			pet.eye_goal = 1.3
			pet.arm_goal = Cryptlin.UP_ARM
			pet.velocity = pet.velocity.move_toward(Vector3.ZERO, delta * 4.0)
			spun = minf(spun + delta * 10.0, TAU * 2.0)
			height = move_toward(height, 0.0, delta * 0.9)
			pet.rotation.x = spun
			pet.lift = height + pet.centre_y * pet.grow * (1.0 - cos(spun))
			if spun >= TAU * 2.0:
				pet.rotation.x = 0.0
				pet.lift = 0.0
				pet.squash_v = 4.0
				world.sfx.play("thud", 0.8, -4.0)
				world.crumbs(pet.global_position + Vector3(0, 0.1, 0), Den.DUST)
				done = true
				_next()
		4:
			# Sat in a heap, with the room still going round
			pet._halt(delta)
			pet.sit_goal = 1.0
			pet.eye_goal = 0.5
			pet.roll_goal = 0.3
			pet.droop_goal = 0.8
			pet.nod = sin(pet.state_time * 5.0) * 0.12
			pet.gaze = pet.global_position + Vector3(sin(pet.yaw + sin(pet.state_time * 3.0)), 0.3, cos(pet.yaw + sin(pet.state_time * 3.0))) * 2.0
			if pet.state_time > 1.3:
				pet.wiggle = sin(pet.state_time * 24.0) * 0.1
			if pet.state_time > 1.9:
				pet._cry("grumble", 1.2)
				finish()


# The Flatwoods monster lets out its mist: it draws itself up and hisses, a sour green fog rolls
# out over the floor from under its skirt, and any of the others standing in it comes over
# queasy until it clears
func _mist(delta: float) -> void:
	var world := pet.world
	pet._halt(delta)
	pet.gaze = world.camera.global_position
	pet.eye_goal = 1.3
	pet.blink = 1.0
	for eye in pet.eye_mats:
		eye.set_shader_parameter("glow", 0.85 + minf(pet.state_time, 1.0) * 1.1)
	if pet.step == 0:
		# It draws itself up, with its hands out
		pet.arm_goal = Vector3(-0.45, 0.0, 0.5)
		pet.nod = -0.12
		if pet.state_time < delta * 1.5:
			world.sfx.play("sweep", 0.45, -3.0)
		if pet.state_time > 0.9:
			fog = Node3D.new()
			world.add_child(fog)
			fog.position = Vector3(pet.position.x, 0, pet.position.z)
			var haze := ShaderMaterial.new()
			haze.shader = Track.FROST
			haze.set_shader_parameter("tint", MIST)
			haze.set_shader_parameter("depth", 0.2)
			for i in 6:
				var around := TAU * i / 6.0
				var wisp := Ps1.part(fog, Ps1.ball(), haze, Vector3(cos(around), 0.0, sin(around)) * 0.55 + Vector3(0, 0.09 + 0.04 * (i % 2), 0), Vector3(0.6, 0.13, 0.6))
				wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fog.scale = Vector3.ONE * 0.1
			_next()
		return
	# Out it comes, and lies round it for a while before it thins
	pet.arm_goal = Vector3(-0.2, 0.0, 0.9)
	pet.mouth_goal = 0.7
	pet.wiggle = sin(pet.state_time * 3.0) * 0.03
	var wide := clampf(pet.state_time / 0.9, 0.1, 1.0) * clampf((3.4 - pet.state_time) / 0.5, 0.0, 1.0)
	fog.scale = Vector3(wide * pet.grow, minf(wide * 1.5, 1.0), wide * pet.grow)
	fog.rotation.y = pet.state_time * 0.5
	if _beat(0.45, delta) and pet.state_time < 2.6:
		var where := randf() * TAU
		world.crumbs(pet.global_position + Vector3(cos(where) * 0.5, 0.12, sin(where) * 0.5), MIST)
		world.sfx.play("sweep", randf_range(0.4, 0.5), -12.0)
	if pet.state_time > 0.6 and pet.state_time < 2.6:
		done = true
		for other in world.pets():
			if other != pet and other.position.distance_to(pet.position) < 1.5 * pet.grow + 0.2:
				other.knack.bewitch("queasy", pet, 3.6)
	if pet.state_time > 3.4:
		finish()


# The Jersey devil goes up into the vent in the back wall, and screams down it. The others jump.
# Then it comes out again black with soot from its horns to its hooves, flutters down, and
# shakes it off
func _flue(delta: float) -> void:
	var world := pet.world
	var vent := _vent()
	match pet.step:
		0:
			pet.gaze = vent
			if pet._steer(pet.target, Cryptlin.RUN * 0.8, delta, 0.25) or pet.state_time > 7.0:
				height = 0.0
				pet._cry("chirp", 0.8)
				_next()
			return
		1:
			# Up the wall on its wings, and in through the bars
			pet.gaze = vent
			pet._face(Vector3(vent.x, 0, vent.z - 1.0), delta)
			var up := vent.y - pet.centre_y * pet.grow
			height = move_toward(height, up, delta * 1.7)
			var under := Vector3(pet.position.x, 0, pet.position.z).move_toward(Vector3(vent.x, 0, vent.z + 0.3), delta * 0.8)
			pet.position.x = under.x
			pet.position.z = under.z
			if height >= up:
				world.crumbs(vent + Vector3(0, 0, 0.1), SOOT)
				world.sfx.play("knock", 0.7, -6.0)
				pet.visible = false
				hid = true
				_next()
		2:
			# Gone, but not quiet: the scream comes down the flue, and soot after it
			if pet.state_time > 0.5 and not done:
				done = true
				world.sfx.play("whimper", 2.3 * pet.voice, 2.0)
				world.sfx.play("squeak", 0.5 * pet.voice, 0.0)
				for other in world.pets():
					if other != pet and other.state in Cryptlin.INTERRUPTIBLE and other.lift <= 0.05 and not other.airborne:
						other.hop(2.3)
						other.feel(Cryptlin.Feeling.SCARED, 2.5)
						other.glance_time = 1.5
						other.glance_point = vent
			if pet.state_time > 0.5 and _beat(0.22, delta):
				world.sfx.play("whimper", randf_range(1.7, 2.1) * pet.voice, -8.0 - pet.state_time * 5.0)
				world.crumbs(vent + Vector3(randf_range(-0.3, 0.3), -0.2, 0.1), SOOT)
			if pet.state_time > 1.9:
				pet.visible = true
				hid = false
				soot = Ps1.mat(SOOT, 0.0, 0.15)
				pet._ghost(pet, soot)
				# (its eyes are what still shows of it)
				for eye in pet.eyes:
					for ball: MeshInstance3D in eye.get_children():
						ball.material_override = pet.skin[ball]
						pet.skin.erase(ball)
				world.crumbs(vent + Vector3(0, 0, 0.15), SOOT)
				pet.yaw = 0.0
				# (it comes down in the light, where it can be seen for what it is)
				for spot: Vector3 in [Vector3(vent.x * 0.3, 0, 0.5), Vector3(-0.7, 0, 0.6), Vector3(0.1, 0, 1.2), Vector3(vent.x * 0.3, 0, -0.5)]:
					far = pet._footing(spot, 0.4)
					if world.pets().all(func(other: Cryptlin) -> bool: return other == pet or other.position.distance_to(far) > 0.8):
						break
				_next()
		3:
			# Out and down into the light, a good deal blacker than it went in
			pet.gaze = world.camera.global_position
			pet.eye_goal = 1.3
			height = move_toward(height, 0.0, delta * 1.25)
			var down := Vector3(pet.position.x, 0, pet.position.z).move_toward(far, delta * 2.0)
			pet.position.x = down.x
			pet.position.z = down.z
			if height <= 0.0:
				pet.lift = 0.0
				pet.flying = false
				pet.squash_v = 2.5
				_next()
				return
		4:
			# It coughs, and shakes itself clean
			pet._halt(delta)
			pet.gaze = world.camera.global_position
			pet.eye_goal = 0.5
			if pet.state_time < 1.1:
				pet.mouth_goal = 0.8
				pet.nod = 0.25 * absf(sin(pet.state_time * 12.0))
				if _beat(0.35, delta):
					pet._cry("chomp", 1.5, -6.0)
					world.crumbs(pet.mouth_node.global_position, SOOT)
			else:
				pet.wiggle = sin(pet.state_time * 28.0) * 0.16
				if _beat(0.2, delta):
					world.crumbs(pet.global_position + Vector3(randf_range(-0.2, 0.2), pet.top() * randf_range(0.3, 0.9), 0.1), SOOT)
			if pet.state_time > 2.1:
				_clean()
				pet._cry("chirp", 1.1)
				finish()
			return
	pet._halt(delta)
	pet.lift = height
	pet.flying = true


# Where the vent is: the middle of it, on the back wall
func _vent() -> Vector3:
	return Vector3(Den.half.x - 1.0, Den.lamp_at.y - 0.9, -Den.half.y + 0.02)


# The soot comes off the Jersey devil, and it is its own colour again
func _clean() -> void:
	if soot != null:
		soot = null
		pet._unghost()


# The Mongolian death worm spits: it rears its front end with a crackle of sparks in its mouth,
# and a gob of something yellow goes across the room and lands in a puddle. It does no harm to
# anything, and whichever of the others is nearest where it lands gets out of the way
func _spit(delta: float) -> void:
	var world := pet.world
	pet._halt(delta)
	pet._face(pet.target, delta)
	pet.gaze = pet.target + Vector3(0, 0.3, 0)
	var lips := pet.mouth_node.global_position
	match pet.step:
		0:
			pet.nod = -0.55 * clampf(pet.state_time / 0.5, 0.0, 1.0)
			pet.mouth_goal = 1.0
			for eye in pet.eye_mats:
				eye.set_shader_parameter("glow", 0.85 + pet.state_time * 1.6)
			if _beat(0.16, delta):
				world.crumbs(lips + Vector3(randf_range(-0.05, 0.05), randf_range(0.0, 0.08), 0), SPIT.lightened(0.4))
				world.sfx.play("click", randf_range(1.2, 1.9), -6.0)
			if pet.state_time > 1.3:
				gob = Ps1.part(world, Ps1.ball(), Ps1.mat(SPIT, 0.6), lips, Vector3.ONE * 0.055 * pet.grow)
				far = lips
				pet.squash_v = 3.2
				world.sfx.play("snap", 1.7, -4.0)
				_next()
		1:
			pet.nod = -0.3
			pet.mouth_goal = 0.6
			var gone := minf(pet.state_time / 0.6, 1.0)
			if is_instance_valid(gob):
				gob.position = far.lerp(pet.target, gone) + Vector3(0, sin(gone * PI) * 0.55, 0)
			if gone >= 1.0:
				_swallow()
				world._lay_mess(Mess.Kind.PUDDLE, pet.target, Time.get_unix_time_from_system(), SPIT, pet.grow * 0.85)
				world.crumbs(pet.target + Vector3(0, 0.06, 0), SPIT)
				world.sfx.play("thud", 1.7, -8.0)
				for other in world.pets():
					if other != pet and other.state in Cryptlin.INTERRUPTIBLE and other.lift <= 0.05 and not other.airborne and other.position.distance_to(pet.target) < 0.8:
						other.hop(2.0)
						other.feel(Cryptlin.Feeling.DISGUSTED, 2.5)
				done = true
				_next()
		2:
			# And is satisfied
			pet.mouth_goal = 0.25 + 0.35 * absf(sin(pet.state_time * 9.0))
			pet.wag = 9.0
			if pet.state_time > 1.0:
				pet._cry("grumble", 1.3)
				finish()


# What the worm has spat is gone out of the air
func _swallow() -> void:
	if is_instance_valid(gob):
		gob.queue_free()
	gob = null


# Somewhere for the worm to spit: a bit of dry floor a little way off in front of it, and not
# where one of the others is standing
func _spittoon() -> Vector3:
	var world := pet.world
	var spot := pet.position
	for i in 8:
		var way := pet.yaw + randf_range(-0.9, 0.9) * (1.0 + i * 0.4)
		spot = Den.on_dry(pet.position + Vector3(sin(way), 0, cos(way)) * randf_range(0.9, 1.3), 0.3, 0.2)
		var clear := spot.distance_to(pet.position) > 0.6
		for other in world.pets():
			clear = clear and (other == pet or other.position.distance_to(spot) > 0.45)
		if clear:
			break
	return spot


# How many puddles are lying in the room: the worm leaves off when there are a couple
func _puddles() -> int:
	var count := 0
	for m in pet.world.messes:
		if m.kind == Mess.Kind.PUDDLE:
			count += 1
	return count
# The yowie throws things. The toy, if it is lying still: it goes and gets it, lifts it over its
# head in both hands and throws it the length of the room. With no toy to hand it scrabbles a
# stone up off the floor and throws that, and the stone clatters down, bounces and is gone
func _lob(delta: float) -> void:
	var world := pet.world
	if mark != null and pet.step < 3 and not _has(mark):
		finish()
		return
	var ahead := Vector3(sin(pet.yaw), 0, cos(pet.yaw))
	var hands := pet.global_position + Vector3(0, pet.top() + 0.14 * pet.grow, 0) - ahead * 0.06 * pet.grow
	match pet.step:
		0:
			if mark != null:
				# Over to the toy, and it has hold of it
				pet.gaze = mark.global_position
				if pet._steer(Vector3(mark.position.x, 0, mark.position.z), Cryptlin.WALK * 1.3, delta, 0.25 * pet.grow + 0.12):
					(mark as Ball).held = true
					(mark as Ball).vel = Vector3.ZERO
					carrying = true
					_next()
				elif pet.state_time > 7.0:
					finish()
				return
			# Or it feels about on the floor for a stone
			pet._halt(delta)
			pet.nod = 0.5
			pet.arm_goal = Vector3(-0.9, 0.0, 0.1)
			pet.arm_wave = 0.5
			pet.gaze = pet.global_position + ahead * 0.4
			if _beat(0.3, delta):
				world.crumbs(pet.global_position + ahead * 0.3 * pet.grow + Vector3(0, 0.05, 0), Den.DUST)
				world.sfx.play("sweep", 1.3, -14.0)
			if pet.state_time > 0.9:
				missile = Ps1.part(world, Ps1.ball(), Ps1.mat(Color(0.4, 0.38, 0.36), 0.0, 0.3), hands, Vector3(0.085, 0.065, 0.075) * pet.grow)
				_next()
		1:
			# Up over its head with it, and it leans back
			pet._halt(delta)
			if pet.state_time < delta * 1.5:
				# (the long way of the room, away from whichever end it is nearer)
				pet.target = Den.on_dry(Vector3(Den.half.x * (-0.75 if pet.position.x > 0.0 else 0.75), 0, pet.position.z + randf_range(-0.5, 0.5)), 0.4, 0.3)
				pet._cry("grumble", 0.8)
			pet._face(pet.target, delta)
			pet.gaze = pet.target + Vector3(0, 0.6, 0)
			pet.arm_goal = Vector3(-3.3, 0.0, 0.25)
			pet.nod = -0.25
			pet.mouth_goal = 0.3
			_carry(hands)
			if pet.state_time > 1.0:
				# And away it goes
				var way := Vector3(pet.target.x - pet.position.x, 0, pet.target.z - pet.position.z)
				var fling := way.normalized() * clampf(way.length() * 1.25, 2.4, 4.6) + Vector3.UP * 3.3
				if mark != null:
					var toy := mark as Ball
					toy.held = false
					toy.vel = fling * toy.heft
					carrying = false
					world._notice_ball()
				else:
					flung = fling
				pet._cry("coo", 0.6)
				pet.squash_v = 2.5
				done = true
				_next()
		2:
			# It watches it go, arms flung out after it
			pet._halt(delta)
			pet.arm_goal = Vector3(-1.5, 0.0, 0.5)
			pet.mouth_goal = 0.9
			pet.eye_goal = 1.2
			if mark != null:
				pet.gaze = mark.global_position if is_instance_valid(mark) else pet.target
			elif missile != null:
				pet.gaze = missile.global_position
				flung.y -= 11.0 * delta
				missile.position += flung * delta
				missile.rotate_x(delta * 9.0)
				if missile.position.y < 0.04 or absf(missile.position.x) > Den.half.x - 0.1 or absf(missile.position.z) > Den.half.y - 0.1:
					var at := Den.in_room(missile.position, 0.1)
					missile.position = Vector3(at.x, 0.04, at.z)
					bounces += 1
					if Den.wade(at) > 0.0:
						world.splash(at)
						bounces = 3
					else:
						world.crumbs(Vector3(at.x, 0.06, at.z), Den.DUST)
						world.sfx.play("click", 0.55, -4.0)
					flung = Vector3(flung.x * 0.45, absf(flung.y) * 0.4, flung.z * 0.45)
					if bounces >= 3:
						missile.queue_free()
						missile = null
			if pet.state_time > 1.5 and missile == null:
				_next()
		3:
			# And is pleased with itself
			pet._halt(delta)
			pet.gaze = world.camera.global_position
			pet.mouth_goal = 0.8
			if pet.state_time < delta * 1.5:
				pet.hop(1.9)
				pet._cry("grumble", 1.2)
			if pet.state_time > 0.8:
				finish()


# What the yowie has over its head is kept in its hands
func _carry(hands: Vector3) -> void:
	if mark != null:
		mark.global_position = hands
		(mark as Ball).vel = Vector3.ZERO
	elif missile != null:
		missile.global_position = hands


# The toy, if it is lying still on dry floor for the yowie to pick up
func _to_hand() -> Ball:
	var toy := pet.world.ball
	if toy != null and is_instance_valid(toy) and not toy.held and toy.speed() < 0.5 and Den.wade(toy.position) <= 0.0:
		return toy
	return null


# The phantom kangaroo goes up in a hop and does not come down from it: at the top it is not
# there, and a moment later it is in the air over another part of the floor, and comes down there
func _vanish(delta: float) -> void:
	var world := pet.world
	var mist := Color(0.8, 0.88, 1.0)
	match pet.step:
		0:
			# It gathers itself, facing the way it means to go
			pet._halt(delta)
			pet._face(pet.target, delta)
			pet.gaze = pet.target + Vector3(0, 0.5, 0)
			pet.sit_goal = 0.5
			if pet.state_time > 0.6:
				pet._cry("boing", 1.2, -4.0)
				pet.squash_v = -2.0
				_next()
		1:
			# Up, and a little way along
			pet.sit_goal = 0.0
			pet.gaze = pet.target + Vector3(0, 0.8, 0)
			var rise := minf(pet.state_time / 0.42, 1.0)
			height = 1.15 * pet.grow * sin(rise * PI * 0.5)
			pet.velocity = (pet.target - pet.position).normalized() * 1.3
			# There is less of it the higher it gets, its eyes last of all
			pet.thin(1.0 - smoothstep(0.2, 0.8, rise))
			if rise >= 1.0:
				# And at the top of it, gone
				world.crumbs(pet.body_centre(), mist)
				world.sfx.play("jingle", 0.45, -8.0)
				pet.visible = false
				pet.velocity = Vector3.ZERO
				far = pet.position
				_next()
		2:
			# Nowhere, for a moment
			pet.velocity = Vector3.ZERO
			if pet.state_time > 0.75:
				pet.position.x = pet.target.x
				pet.position.z = pet.target.z
				pet.yaw = atan2(far.x - pet.target.x, far.z - pet.target.z) + randf_range(-0.6, 0.6)
				pet.visible = true
				world.crumbs(pet.global_position + Vector3(0, height + pet.centre_y * pet.grow, 0), mist)
				world.sfx.play("jingle", 0.6, -10.0)
				done = true
				spun = 0.0
				_next()
		3:
			# And down, where it had no business to be
			pet.velocity = Vector3.ZERO
			pet.eye_goal = 1.3
			spun += delta * pet.gravity
			height = maxf(height - spun * delta, 0.0)
			# Its eyes are there first, and the rest of it comes back on the way down
			pet.thin(smoothstep(0.0, 0.4, pet.state_time))
			if height <= 0.0:
				pet.thin(1.0)
				pet.squash_v = 3.6
				world.sfx.play("thud", 1.3, -8.0)
				world.crumbs(pet.global_position + Vector3(0, 0.05, 0), Den.DUST)
				_next()
		4:
			# It looks about it, to see where that is
			pet._halt(delta)
			pet.eye_goal = 1.25
			var about := sin(pet.state_time * 5.0) * 1.2
			pet.gaze = pet.global_position + Vector3(sin(pet.yaw + about), 0.25, cos(pet.yaw + about)) * 2.0
			if pet.state_time > 1.1:
				pet._cry("chirp", 0.9)
				finish()
				return
	pet.lift = height


# The kongamato flies up, comes down in a long dive and skims the pool with its beak trailing in
# the water, and lands on the far side. With no pool it dives at some small thing in the room
# instead and bowls it over on its way past; the thing rocks, and rights itself where it stood
func _swoop(delta: float) -> void:
	var world := pet.world
	var thing := mark as Decor
	if mark != null and (not is_instance_valid(thing) or thing.is_queued_for_deletion() or thing == world.held_thing):
		mark = null
		finish()
		return
	var high := 0.95
	# (no lower than this over the water, or it would be taken for something wading in it)
	var low := 0.3
	match pet.step:
		0:
			# Up off the floor, looking at what it means to come down on
			pet._halt(delta)
			pet._face(far, delta)
			pet.gaze = far + Vector3(0, 0.1, 0)
			pet.flying = true
			pet.lift = move_toward(pet.lift, high, delta * 1.5)
			if pet.state_time < delta * 1.5:
				pet._cry("squeak", 0.7)
			if pet.lift >= high:
				launch = pet.position
				_next()
		1:
			# The dive: down the one side of a curve, low across the middle of it, and up the other
			var path := launch.distance_to(far) + far.distance_to(pet.target)
			var u := minf(pet.state_time * 2.3 / maxf(path, 0.5), 1.0)
			# (a curve that goes through `far` at the middle of it)
			var bend := far * 2.0 - (launch + pet.target) * 0.5
			var at := launch.lerp(bend, u).lerp(bend.lerp(pet.target, u), u)
			var on := launch.lerp(bend, u + 0.03).lerp(bend.lerp(pet.target, u + 0.03), u + 0.03)
			pet.velocity = Vector3.ZERO
			pet.position.x = at.x
			pet.position.z = at.z
			pet.yaw = lerp_angle(pet.yaw, atan2(on.x - at.x, on.z - at.z), 1.0 - exp(-delta * 10.0))
			pet.lift = lerpf(high, low, sin(u * PI))
			pet.rotation.x = 0.55 * cos(u * PI) * sin(u * PI) * 2.0
			pet.flying = true
			pet.mouth_goal = 0.8
			pet.gaze = Vector3(on.x, 0.0, on.z)
			if thing == null:
				if u > 0.3 and u < 0.7 and Den.wade(at) > 0.0 and _beat(0.09, delta):
					world.splash(at)
					done = true
			elif u >= 0.5 and tipped == 0.0:
				tipped = 1.0
				spun = 0.0
				world.sfx.play("thud", 1.5, -6.0)
				world.crumbs(thing.position + Vector3(0, 0.2, 0), Den.DUST)
				done = true
			if u >= 1.0:
				_next()
		2:
			# Down onto dry floor, wings out
			pet._halt(delta)
			pet.flying = true
			pet.rotation.x = 0.0
			pet.lift = move_toward(pet.lift, 0.0, delta * 1.6)
			if pet.lift <= 0.0:
				pet.flying = false
				pet.squash_v = 2.5
				pet._cry("chirp", 0.8)
				_next()
		3:
			# And it looks round at what it has done
			pet._halt(delta)
			pet.gaze = far + Vector3(0, 0.15, 0)
			pet._face(far, delta)
			if pet.state_time > (1.6 if thing != null else 1.0):
				finish()
				return
	if tipped != 0.0 and thing != null:
		# Over it goes, and rocks, each time less far, until it is standing as it was
		spun += delta
		var over := 1.25 * exp(-spun * 2.2) * cos(spun * 7.0) if spun > 0.12 else 1.25 * spun / 0.12
		var way := (pet.target - launch).normalized().rotated(Vector3.UP, -thing.rotation.y)
		thing.rotation.x = over * way.z
		thing.rotation.z = -over * way.x


# What the kongamato dives at, and where it comes down after: the middle of the pool if there is
# one, or else some small thing standing in the room, and dry floor on the far side of either
func _aim() -> void:
	var world := pet.world
	tipped = 0.0
	if Den.shore != Den.Shore.NONE:
		far = world.wading_spot(pet.position)
		# (along the water, not straight in and out of it)
		for i in 12:
			pet.target = Den.on_dry(Vector3(randf_range(-Den.half.x, Den.half.x), 0, randf_range(-Den.half.y, Den.half.y)), 0.5, 0.4)
			if pet.target.distance_to(pet.position) > 1.6:
				break
		return
	mark = _skittle()
	if mark != null:
		far = Vector3(mark.position.x, 0, mark.position.z)
		var on := far - Vector3(pet.position.x, 0, pet.position.z)
		on = on.normalized() if on.length() > 0.05 else Vector3.BACK
		pet.target = Den.on_dry(far + on * 1.2, 0.5, 0.4)


# Some small thing standing on dry floor for the kongamato to bowl over
func _skittle() -> Decor:
	var world := pet.world
	var fair: Array[Decor] = []
	for d in world.decors:
		if d.kind in [Decor.Kind.SKULL, Decor.Kind.CRYSTAL, Decor.Kind.PUMPKIN, Decor.Kind.FERN, Decor.Kind.DISH, Decor.Kind.POT] and d != world.held_thing and Den.wade(d.position) <= 0.0:
			fair.append(d)
	return fair.pick_random() if not fair.is_empty() else null


# The mermaid combs its hair: up on the rock if there is one, or else at the edge of the pool,
# or else where it is. It sits up with its head on one side and runs its fingers through it, the
# lamp glints off it, and the others stop and look
func _comb(delta: float) -> void:
	var world := pet.world
	var rock := mark as Decor
	if not world.light_on or (mark != null and (not is_instance_valid(rock) or rock.is_queued_for_deletion() or rock == world.held_thing)):
		finish()
		return
	match pet.step:
		0:
			pet.gaze = pet.target + Vector3(0, 0.3, 0)
			var near := rock.radius + 0.28 * pet.grow if rock != null else 0.15
			if pet._steer(pet.target, Cryptlin.WALK * 1.2, delta, near) or pet.state_time > 8.0:
				if rock != null:
					pet.hop(2.2)
				_next()
		1:
			# Up onto the rock (or sat up where it is)
			pet._halt(delta)
			pet.sit_goal = 1.0
			pet.gaze = world.camera.global_position
			pet._face(pet.gaze, delta)
			if rock != null:
				var up := 1.0 - exp(-delta * 6.0)
				pet.position.x = lerpf(pet.position.x, pet.target.x, up)
				pet.position.z = lerpf(pet.position.z, pet.target.z, up)
				height = lerpf(height, 0.4, up)
			if pet.state_time > 0.8:
				_next()
		2:
			# One hand up to its hair and down the length of it, over and over
			pet._halt(delta)
			pet.sit_goal = 1.0
			pet.gaze = world.camera.global_position + Vector3(1.5, 0.5, 0)
			pet._face(world.camera.global_position, delta)
			pet.roll_goal = 0.32
			pet.eye_goal = 0.55
			pet.wag = 1.5
			var stroke := fmod(pet.state_time, 0.9) / 0.9
			pet.arm_goal = Vector3(lerpf(-2.9, -1.9, stroke), 0.0, 0.55)
			pet.mouth_goal = 0.2 + 0.15 * sin(pet.state_time * 4.0)
			var shine := maxf(sin(pet.state_time * 7.0), 0.0)
			pet.tresses.set_shader_parameter("glow", 0.15 + 0.55 * shine * shine)
			if _beat(0.45, delta):
				var hair := pet.neck.global_position + Vector3(randf_range(-0.15, 0.15), randf_range(0.0, 0.3), randf_range(-0.1, 0.05)) * pet.grow
				world.crumbs(hair, Color(1.0, 0.97, 0.8))
				world.sfx.play("jingle", randf_range(1.5, 2.1), -16.0)
			if pet.state_time > 1.2 and not done:
				done = true
				for other in world.pets():
					if other != pet and other.state in Cryptlin.INTERRUPTIBLE:
						other.glance_time = 2.5
						other.glance_point = pet.global_position + Vector3(0, pet.top(), 0)
			if pet.state_time > 4.6:
				pet.tresses.set_shader_parameter("glow", 0.0)
				if rock != null:
					pet.target = pet._footing(pet.position + Vector3(sin(pet.yaw), 0, cos(pet.yaw)) * (rock.radius + 0.35 * pet.grow), 0.4)
				_next()
		3:
			# And down again
			pet._halt(delta)
			if rock != null:
				var down := 1.0 - exp(-delta * 5.0)
				pet.position.x = lerpf(pet.position.x, pet.target.x, down)
				pet.position.z = lerpf(pet.position.z, pet.target.z, down)
				height = move_toward(height, 0.0, delta * 1.2)
			if height <= 0.0 and pet.state_time > 0.4:
				pet._cry("coo", 1.2)
				finish()
				return
	pet.lift = height


# The rock, for the mermaid to sit on while it combs its hair, if there is one on dry floor
func _perch() -> Decor:
	var world := pet.world
	for d in world.decors:
		if d.kind == Decor.Kind.ROCK and d != world.held_thing and Den.wade(d.position) <= 0.0:
			return d
	return null
