class_name Cryptlin
extends Node3D
## One cryptlin: its body (built from primitives, shaped by its kind and a seed), its needs, its
## small brain, and its animation, which is all done here in code. It faces +Z.

signal left

enum State {
	IDLE, WANDER, STARE, LURK, COME, GO_FOOD, EAT, CHASE_BALL, CHASE_LIGHT,
	BEG, ZOOMIES, DANCE, PETTED, STARTLED, GO_SLEEP, SLEEP, LEAVE, HELD, SHOVED, INSPECT, SCANNED, VISIT, MOVE_NEST,
}
# The cryptids they are the young of
enum Kind { GREMLIN, SQUATCH, COCKATRICE, MOTHMAN, CHUPACABRA, FROGMAN, NESSIE, BOLTER, WENDIGO }

# What sets the kinds apart besides their looks: pace on the ground, appetite, how fast they tire,
# the spring in their hop, the pitch of their voice, and what they like to do with a free moment
const KINDS: Array[Dictionary] = [
	{"title": "gremlin", "pace": 1.0, "hunger": 1.0, "tire": 1.0, "spring": 1.0, "voice": 1.0, "lurk": 1.0, "zoom": 1.0, "dance": 1.0, "stare": 1.0},
	{"title": "squatchling", "pace": 0.85, "hunger": 1.25, "tire": 1.1, "spring": 0.7, "voice": 0.55, "lurk": 2.2, "zoom": 0.5, "dance": 1.1, "stare": 1.4},
	{"title": "cockatrice", "pace": 1.1, "hunger": 1.0, "tire": 1.0, "spring": 1.2, "voice": 1.45, "lurk": 0.5, "zoom": 1.2, "dance": 1.5, "stare": 2.4},
	{"title": "mothman", "pace": 1.2, "hunger": 0.8, "tire": 1.2, "spring": 1.4, "voice": 1.6, "lurk": 1.2, "zoom": 2.2, "dance": 1.0, "stare": 1.5},
	{"title": "chupacabra", "pace": 1.25, "hunger": 1.6, "tire": 1.0, "spring": 1.2, "voice": 0.85, "lurk": 1.8, "zoom": 1.6, "dance": 0.6, "stare": 1.0},
	{"title": "Loveland frogman", "pace": 0.9, "hunger": 1.1, "tire": 0.9, "spring": 1.7, "voice": 0.75, "lurk": 0.6, "zoom": 1.0, "dance": 1.8, "stare": 1.2},
	{"title": "Loch Ness monster", "pace": 0.75, "hunger": 1.2, "tire": 0.8, "spring": 0.6, "voice": 0.9, "lurk": 2.2, "zoom": 0.4, "dance": 1.0, "stare": 1.6},
	{"title": "slide-rock bolter", "pace": 0.8, "hunger": 1.8, "tire": 1.2, "spring": 0.6, "voice": 0.5, "lurk": 0.6, "zoom": 3.0, "dance": 0.6, "stare": 0.9},
	{"title": "wendigo", "pace": 1.0, "hunger": 2.0, "tire": 0.7, "spring": 0.9, "voice": 0.6, "lurk": 2.6, "zoom": 0.5, "dance": 0.5, "stare": 1.8},
]
# What the numbers in saves from before this list stood for (gremlin, bogle, spook, flit)
const OLD_KINDS: Array[int] = [Kind.GREMLIN, Kind.FROGMAN, Kind.WENDIGO, Kind.MOTHMAN]

# How it is feeling just now, which shows in its eyes, its ears and how it holds its head
enum Feeling { CONTENT, HAPPY, EXCITED, LOVING, HUNGRY, BORED, SLEEPY, GRUMPY, SCARED, SAD, DISGUSTED }
# What goes up over its head when a feeling comes over it (nothing, for content)
const EMOTES: Array[String] = ["", "^_^", "\\(^o^)/", "<3", ":Q", "-_-", "u_u", ">:(", "D:", "T_T", ":S"]
const EMOTE_COLOURS: Array[Color] = [
	Color.WHITE, Color(1.0, 0.95, 0.6), Color(1.0, 0.85, 0.4), Color(1.0, 0.5, 0.65), Color(1.0, 0.75, 0.45), Color(0.75, 0.78, 0.85),
	Color(0.7, 0.8, 1.0), Color(1.0, 0.45, 0.35), Color(0.7, 0.9, 1.0), Color(0.6, 0.75, 1.0), Color(0.7, 0.95, 0.5),
]
const FEELINGS: Array[Dictionary] = [
	{"title": "content", "eye": 1.0, "droop": 0.0, "hang": 0.0, "shake": 0.0},
	{"title": "happy", "eye": 1.05, "droop": -0.05, "hang": -0.06, "shake": 0.0},
	{"title": "excited", "eye": 1.2, "droop": -0.1, "hang": -0.1, "shake": 0.03},
	{"title": "loving", "eye": 0.7, "droop": 0.25, "hang": 0.0, "shake": 0.0},
	{"title": "hungry", "eye": 0.9, "droop": 0.3, "hang": 0.12, "shake": 0.0},
	{"title": "bored", "eye": 0.6, "droop": 0.35, "hang": 0.18, "shake": 0.0},
	{"title": "sleepy", "eye": 0.45, "droop": 0.6, "hang": 0.25, "shake": 0.0},
	{"title": "grumpy", "eye": 0.55, "droop": 0.5, "hang": 0.14, "shake": 0.0},
	{"title": "scared", "eye": 1.3, "droop": 0.8, "hang": 0.1, "shake": 0.07},
	{"title": "sad", "eye": 0.7, "droop": 0.8, "hang": 0.32, "shake": 0.0},
	{"title": "disgusted", "eye": 0.5, "droop": 0.45, "hang": -0.1, "shake": 0.03},
]
# Each cryptlin has two natures of its own on top of what its kind is like: how each changes its
# needs and habits, and how it takes being picked up ("carry") or pushed about ("push"), which
# goes by the first of the two
const NATURES: Array[Dictionary] = [
	{"title": "greedy", "hunger": 1.35, "carry": Feeling.CONTENT, "push": Feeling.GRUMPY},
	{"title": "playful", "bore": 1.4, "zoom": 1.8, "dance": 1.3, "carry": Feeling.EXCITED, "push": Feeling.EXCITED},
	{"title": "shy", "lurk": 2.2, "stare": 0.7, "cuddle": 0.8, "carry": Feeling.SCARED, "push": Feeling.SCARED},
	{"title": "sleepy", "tire": 1.45, "pace": 0.9, "zoom": 0.5, "carry": Feeling.CONTENT, "push": Feeling.GRUMPY},
	{"title": "cuddly", "cuddle": 1.7, "stare": 1.4, "lurk": 0.5, "carry": Feeling.LOVING, "push": Feeling.SAD},
	{"title": "bold", "lurk": 0.3, "pace": 1.1, "stare": 1.5, "carry": Feeling.EXCITED, "push": Feeling.GRUMPY},
	{"title": "grumpy", "cuddle": 0.7, "dance": 0.5, "lurk": 1.3, "carry": Feeling.GRUMPY, "push": Feeling.GRUMPY},
	{"title": "restless", "zoom": 2.0, "tire": 1.2, "pace": 1.15, "bore": 1.2, "carry": Feeling.GRUMPY, "push": Feeling.EXCITED},
]
# The two foods and two toys each kind leans towards (Snack.Kind, Ball.Kind); one of each is its favourite
const FOOD_LIKES: Array[Array] = [
	[Snack.Kind.CANDY, Snack.Kind.BONE], [Snack.Kind.BERRIES, Snack.Kind.TOADSTOOL], [Snack.Kind.BEETLE, Snack.Kind.BERRIES],
	[Snack.Kind.CANDY, Snack.Kind.BERRIES], [Snack.Kind.BONE, Snack.Kind.FISH], [Snack.Kind.BEETLE, Snack.Kind.FISH],
	[Snack.Kind.FISH, Snack.Kind.TOADSTOOL], [Snack.Kind.BONE, Snack.Kind.TOADSTOOL], [Snack.Kind.BONE, Snack.Kind.FISH],
]
const TOY_LIKES: Array[Array] = [
	[Ball.Kind.BALL, Ball.Kind.BELL], [Ball.Kind.STONE, Ball.Kind.BALL], [Ball.Kind.BELL, Ball.Kind.STONE],
	[Ball.Kind.GLOW, Ball.Kind.BELL], [Ball.Kind.BALL, Ball.Kind.GLOW], [Ball.Kind.BALL, Ball.Kind.GLOW],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.STONE, Ball.Kind.BELL], [Ball.Kind.GLOW, Ball.Kind.STONE],
]
# Natures that will not go together (shy and bold, sleepy and restless, cuddly and grumpy)
const OPPOSED: Array[Array] = [[2, 5], [3, 7], [4, 6]]
# What each kind leans towards in its room: two things to have about (Decor.Kind), two grounds
# (Den.GROUNDS) and a lamp setting (Den.Lamp)
const DECOR_LIKES: Array[Array] = [
	[Decor.Kind.SKULL, Decor.Kind.PUMPKIN], [Decor.Kind.LOG, Decor.Kind.FERN], [Decor.Kind.ROCK, Decor.Kind.GRAVESTONE],
	[Decor.Kind.CRYSTAL, Decor.Kind.PUMPKIN], [Decor.Kind.SKULL, Decor.Kind.ROCK], [Decor.Kind.DISH, Decor.Kind.FERN],
	[Decor.Kind.DISH, Decor.Kind.ROCK], [Decor.Kind.ROCK, Decor.Kind.CRYSTAL], [Decor.Kind.SKULL, Decor.Kind.GRAVESTONE],
]
const GROUND_LIKES: Array[Array] = [[1, 3], [2, 4], [4, 5], [1, 3], [5, 4], [2, 4], [6, 5], [6, 0], [2, 0]]
const LAMP_LIKES: Array[int] = [1, 1, 2, 0, 2, 2, 1, 0, 1]
# It lives in real time, like a pet: these are hours of the clock on the wall, and they pass
# whether or not anyone is looking. A full belly lasts most of a day, and a baby is grown in a
# day and a half.
const HOUR := 3600.0
const BELLY_HOURS := 14.0
const FUN_HOURS := 10.0
const AWAKE_HOURS := 15.0
const SLEEP_HOURS := 7.0
const GROW_AGE := 36.0 * HOUR
# The longest it is taken to have been left alone, however long it really was
const LONGEST_AWAY := 14.0 * 24.0 * HOUR
const BABY_SIZE := 0.55

const WALK := 1.0
const RUN := 2.6
const REST_ARM := Vector3(0.0, 0.0, 0.35)
const UP_ARM := Vector3(-0.3, 0.0, 2.5)
const BELLY_ARM := Vector3(-0.9, 0.0, -0.35)
# States that give way to food, a thrown ball, the moving light or tiredness
const INTERRUPTIBLE: Array[int] = [
	State.IDLE, State.WANDER, State.STARE, State.LURK, State.COME, State.BEG, State.ZOOMIES, State.DANCE,
]
# Fur and eye colours to draw from, by kind
const FURS: Array[Array] = [
	[Color(0.36, 0.5, 0.3), Color(0.44, 0.36, 0.56), Color(0.26, 0.47, 0.48), Color(0.46, 0.46, 0.5), Color(0.58, 0.36, 0.26), Color(0.52, 0.52, 0.3)],
	[Color(0.33, 0.27, 0.21), Color(0.26, 0.22, 0.18), Color(0.4, 0.34, 0.26), Color(0.29, 0.27, 0.25), Color(0.36, 0.26, 0.19)],
	[Color(0.5, 0.46, 0.38), Color(0.42, 0.26, 0.16), Color(0.3, 0.3, 0.34), Color(0.46, 0.38, 0.2)],
	[Color(0.24, 0.24, 0.29), Color(0.3, 0.26, 0.24), Color(0.34, 0.34, 0.37), Color(0.26, 0.21, 0.31)],
	[Color(0.3, 0.36, 0.3), Color(0.36, 0.31, 0.33), Color(0.27, 0.32, 0.37), Color(0.38, 0.35, 0.27)],
	[Color(0.24, 0.42, 0.2), Color(0.36, 0.42, 0.18), Color(0.2, 0.38, 0.32), Color(0.4, 0.36, 0.2)],
	[Color(0.2, 0.34, 0.4), Color(0.24, 0.38, 0.3), Color(0.27, 0.3, 0.44), Color(0.32, 0.33, 0.34)],
	[Color(0.34, 0.34, 0.37), Color(0.38, 0.34, 0.3), Color(0.3, 0.34, 0.4), Color(0.4, 0.38, 0.33)],
	[Color(0.19, 0.18, 0.21), Color(0.24, 0.2, 0.18), Color(0.17, 0.21, 0.24), Color(0.27, 0.27, 0.3)],
]
const EYES: Array[Array] = [
	[Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.15), Color(0.6, 1.0, 0.3), Color(1.0, 0.45, 0.7), Color(0.4, 0.95, 1.0)],
	[Color(1.0, 0.8, 0.3), Color(0.7, 1.0, 0.5), Color(1.0, 0.45, 0.25), Color(0.6, 0.9, 1.0)],
	[Color(1.0, 0.3, 0.2), Color(1.0, 0.6, 0.15), Color(1.0, 0.9, 0.3), Color(0.6, 1.0, 0.4)],
	[Color(1.0, 0.15, 0.1), Color(1.0, 0.3, 0.1), Color(1.0, 0.1, 0.3)],
	[Color(1.0, 0.2, 0.15), Color(1.0, 0.5, 0.1), Color(0.8, 1.0, 0.2)],
	[Color(1.0, 0.8, 0.2), Color(1.0, 0.5, 0.15), Color(0.9, 1.0, 0.4)],
	[Color(1.0, 0.9, 0.4), Color(0.5, 1.0, 0.9), Color(1.0, 0.6, 0.3)],
	[Color(1.0, 0.85, 0.3), Color(0.6, 0.9, 1.0), Color(1.0, 0.5, 0.3)],
	[Color(0.5, 0.9, 1.0), Color(1.0, 0.3, 0.2), Color(0.8, 1.0, 0.5), Color(1.0, 1.0, 0.8)],
]

var world: Den
var kind: int = Kind.GREMLIN
var look_seed := 1

# Set from KINDS and the body that was built
var pace := 1.0
var hunger := 1.0
var tire := 1.0
var spring := 1.0
var voice := 1.0
var likes := {}
var gravity := 12.0
var hover := 0.0
var neck_y := 0.64
# How far above the neck the middle of the head is
var head_y := 0.2
var centre_y := 0.55
var top_y := 1.15
var ear_splay := 1.0
var wings := false
var fur: ShaderMaterial
var pale: ShaderMaterial
var dark: ShaderMaterial
var bone: ShaderMaterial
var black: ShaderMaterial
var maw: ShaderMaterial
var eye_mat: ShaderMaterial

# Needs, 0 (bad) to 100 (good)
var belly := 70.0
var fun := 60.0
var energy := 80.0
var love := 20.0

# Who it is (see profile()), how old, how big, and how it feels
var nature := 0
var nature2 := 1
var fav_food := 0
var yuck_food := 0
var fav_toy := 0
# What it wants of its room: two things it likes having about and one it cannot stand
# (Decor.Kind), and the ground and lamp setting it is happiest with
var like_decor: Array[int] = []
var hate_decor := 0
var fav_ground := 0
var fav_lamp := 0
# How well its room suits it, 0 to 100 (Den works it out)
var comfort := 50.0
var cuddle := 1.0
var bore := 1.0
# How fast it gets hungry and tired next to the usual, once kind and natures are counted
var appetite := 1.0
var weariness := 1.0
var age := GROW_AGE
var adult_size := 1.0
var grow := 1.0
var feeling: int = Feeling.CONTENT
var flash_feeling: int = Feeling.CONTENT
var flash_time := 0.0
var hang := 0.0
var pokes := 0
var poke_time := -10.0
var carry_point := Vector3.ZERO
# The thing in the room it is making use of (hiding in, sitting on, drinking from), and how long
# before it next thinks of dragging its nest somewhere else
var visiting: Decor
var nest_cooldown := 240.0
# What it has gone to look over (see look_over)
var inspect_liking := 0
var inspect_key := ""
# Under the scanner: its insides, and what its skin wore before
var xrayed := false
var brain_at := Vector3.ZERO
var insides: Array[Node3D] = []
var skin := {}
var stomach: Node3D
var stomach_fill: MeshInstance3D
var heart: MeshInstance3D
var lungs: Array[MeshInstance3D] = []
var brain: MeshInstance3D
var lift := 0.0
var fall_v := 0.0

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
var emote: Label3D # the little face over its head
var emote_time := 0.0 # seconds it has been up
var emote_for := -1 # the feeling it was last put up for
var emote_again := 0.0 # seconds till a feeling that lasts shows again


func _ready() -> void:
	_build()
	position = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.6, 0.8))
	_enter(State.IDLE, 1.5)


# ---------------------------------------------------------------- body

# What a kind and seed make of it besides its looks: its nature, its favourite food and toy, the
# food it cannot stand, and the size it grows to
static func profile(k: int, s: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = s * 7919 + k * 104729 + 17
	var foods: Array = FOOD_LIKES[k]
	var toys: Array = TOY_LIKES[k]
	var others: Array[int] = []
	for i in Snack.NAMES.size():
		if not i in foods:
			others.append(i)
	var me := {
		"nature": rng.randi() % NATURES.size(),
		"food": foods[rng.randi() % foods.size()],
		"yuck": others[rng.randi() % others.size()],
		"toy": toys[rng.randi() % toys.size()],
		"size": rng.randf_range(0.8, 1.3),
	}
	# A second nature, never the first again nor its opposite
	var first: int = me["nature"]
	var second := rng.randi() % NATURES.size()
	while second == first or [mini(second, first), maxi(second, first)] in OPPOSED:
		second = (second + 1) % NATURES.size()
	me["nature2"] = second
	# One of the two things its kind likes to have about, one more of its own, and one it hates
	var kin: Array = DECOR_LIKES[k]
	var liked: Array[int] = [kin[rng.randi() % kin.size()]]
	var rest: Array[int] = []
	for i in Decor.IDS.size():
		if i != liked[0]:
			rest.append(i)
	liked.append(rest.pop_at(rng.randi() % rest.size()))
	me["decor"] = liked
	me["hates"] = rest[rng.randi() % rest.size()]
	var grounds: Array = GROUND_LIKES[k]
	me["ground"] = grounds[rng.randi() % grounds.size()]
	me["lamp"] = LAMP_LIKES[k] if rng.randf() < 0.65 else rng.randi() % 3
	return me


# The fur and eye colour a kind and seed give (the egg shows the eye before it hatches)
static func colours(k: int, s: int) -> Array[Color]:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var furs: Array = FURS[k]
	var eye_set: Array = EYES[k]
	var fur_colour: Color = furs[rng.randi() % furs.size()]
	var eye_colour: Color = eye_set[rng.randi() % eye_set.size()]
	return [fur_colour, eye_colour]


func _build() -> void:
	var traits: Dictionary = KINDS[kind]
	pace = traits["pace"]
	hunger = traits["hunger"]
	tire = traits["tire"]
	spring = traits["spring"]
	voice = traits["voice"]
	likes = traits.duplicate()
	var me := profile(kind, look_seed)
	nature = me["nature"]
	fav_food = me["food"]
	yuck_food = me["yuck"]
	fav_toy = me["toy"]
	adult_size = me["size"]
	nature2 = me["nature2"]
	like_decor.assign(me["decor"])
	hate_decor = me["hates"]
	fav_ground = me["ground"]
	fav_lamp = me["lamp"]
	for mine: Dictionary in [NATURES[nature], NATURES[nature2]]:
		hunger *= float(mine.get("hunger", 1.0))
		tire *= float(mine.get("tire", 1.0))
		pace *= float(mine.get("pace", 1.0))
		bore *= float(mine.get("bore", 1.0))
		cuddle *= float(mine.get("cuddle", 1.0))
		for habit: String in ["lurk", "zoom", "dance", "stare"]:
			likes[habit] = float(likes[habit]) * float(mine.get(habit, 1.0))
	# Kinds differ a great deal in appetite; over a whole day that is evened out a good way
	appetite = lerpf(1.0, hunger, 0.35)
	weariness = lerpf(1.0, tire, 0.5)
	bore = lerpf(1.0, bore, 0.5)
	grow = size_goal()
	scale = Vector3.ONE * grow
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var picked := colours(kind, look_seed)
	rng.randi()
	rng.randi()
	var fur_colour := picked[0]
	var eye_colour := picked[1]
	var ear_len := rng.randf_range(0.34, 0.52)
	var chub := rng.randf_range(0.94, 1.14)
	var horns := rng.randf() < 0.45
	var odd_eyes := rng.randf() < 0.35
	fur = Ps1.mat(fur_colour * 0.76, 0.0, 0.35)
	pale = Ps1.mat(fur_colour.lightened(0.2) * 0.9, 0.0, 0.35)
	dark = Ps1.mat(fur_colour.darkened(0.5), 0.0, 0.35)
	bone = Ps1.mat(Color(0.92, 0.89, 0.78), 0.0, 0.35)
	black = Ps1.flat(Color(0.02, 0.01, 0.02))
	maw = Ps1.mat(Color(0.16, 0.03, 0.06))
	# The eyes give off their own light, so they are all you see of it in the dark
	eye_mat = Ps1.mat(eye_colour, 0.85)
	match kind:
		Kind.SQUATCH:
			_build_squatch(chub, rng)
		Kind.COCKATRICE:
			_build_cockatrice(chub)
		Kind.MOTHMAN:
			_build_mothman(chub, ear_len)
		Kind.CHUPACABRA:
			_build_chupacabra(chub, ear_len)
		Kind.FROGMAN:
			_build_frogman(chub)
		Kind.NESSIE:
			_build_nessie(chub)
		Kind.BOLTER:
			_build_bolter(chub, rng)
		Kind.WENDIGO:
			_build_wendigo(chub)
		_:
			_build_gremlin(chub, ear_len, horns, odd_eyes)

	if brain_at == Vector3.ZERO:
		brain_at = Vector3(0, head_y + 0.02, 0)
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
	emote = Label3D.new()
	emote.font_size = 96
	emote.pixel_size = 0.0034
	emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	emote.no_depth_test = true
	emote.outline_size = 22
	emote.outline_modulate = Color(0.05, 0.04, 0.03, 0.9)
	emote.visible = false
	add_child(emote)


func _build_gremlin(chub: float, ear_len: float, horns: bool, odd_eyes: bool) -> void:
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

	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.34, 0.285, 0.3))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.27 * side, 0.3, -0.02))
		_part(ear, _cone(), fur, Vector3(0, ear_len * 0.5, 0), Vector3(0.13, ear_len, 0.045))
		_part(ear, _cone(), pale, Vector3(0, ear_len * 0.42, 0.028), Vector3(0.08, ear_len * 0.78, 0.02))
		ears.append(ear)
		var size := 0.1
		if odd_eyes:
			size = 0.112 if side < 0.0 else 0.088
		_eye(Vector3(0.135 * side, 0.25, 0.215), size)
		_part(neck, _cone(), bone, Vector3(0.055 * side, 0.112, 0.283), Vector3(0.022, 0.05, 0.022))
		if horns:
			_part(neck, _cone(), bone, Vector3(0.12 * side, 0.5, 0.03), Vector3(0.04, 0.14, 0.04), Vector3(0, 0, -0.35 * side))
	_part(neck, _sphere(), dark, Vector3(0, 0.175, 0.3), Vector3(0.035, 0.025, 0.03))
	mouth_node = _pivot(neck, Vector3(0, 0.085, 0.262))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.15, 0.07, 0.06))


# A young sasquatch: no head and no arms yet, just a shaggy mound of hair with two tall eyes,
# on feet it has not grown into
func _build_squatch(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.24
	centre_y = 0.5
	top_y = 0.95
	gravity = 15.0
	brain_at = Vector3(0, 0.4, 0.04)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.18 * side, 0.24, 0.02))
		_part(leg, _capsule(0.07, 0.24), dark, Vector3(0, -0.1, 0))
		# Big flat feet, toes out
		var foot := _pivot(leg, Vector3(0, -0.185, 0))
		foot.rotation.y = 1.0 * side
		_part(foot, _sphere(), dark, Vector3(0, 0, 0.14), Vector3(0.13, 0.065, 0.27))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	tail = _pivot(torso, Vector3(0, 0.3, -0.2))
	for side: float in [-1.0, 1.0]:
		arms.append(_pivot(torso, Vector3(0.3 * side, 0.4, 0)))

	# The whole body turns to look, so it hangs from the neck
	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	var body := _pivot(neck, Vector3.ZERO)
	body.scale = Vector3(chub, 1.0, 0.8 * chub)
	# One smooth mound, wider than it is tall, flaring out to the hem
	var shape: Array[Vector2] = [
		Vector2(0.5, 0.0), Vector2(0.58, 0.03), Vector2(0.56, 0.1), Vector2(0.47, 0.19), Vector2(0.4, 0.28),
		Vector2(0.35, 0.37), Vector2(0.28, 0.45), Vector2(0.17, 0.51), Vector2(0.0, 0.53),
	]
	_part(body, _lathe(shape, 10), fur, Vector3.ZERO)
	var shag := Ps1.mat(fur.get_shader_parameter("tint") * 0.62, 0.0, 0.35)
	# Hair hangs off the hem in a row of round hanks, light and dark
	for i in 12:
		var around := TAU * (i + 0.5) / 12.0
		var out := Vector3(sin(around), 0, cos(around))
		var hank := rng.randf_range(0.08, 0.13)
		_part(body, _sphere(), pale if i % 2 == 0 else shag, out * 0.52 + Vector3(0, 0.0, 0), Vector3(0.14, hank, 0.09), Vector3(0, around, 0))
	# And lies in long locks down the rest of it
	for i in 22:
		var around := TAU * i / 22.0 + rng.randf_range(-0.12, 0.12)
		if absf(wrapf(around, -PI, PI)) < 0.5:
			continue
		var up := rng.randf_range(0.12, 0.44)
		var wide := lerpf(0.53, 0.3, (up - 0.1) / 0.34)
		var out := Vector3(sin(around), 0, cos(around))
		var lock := _part(body, _cone(), shag if i % 2 == 0 else pale, out * wide + Vector3(0, up, 0))
		lock.basis = Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, 2.35) * Basis.from_scale(Vector3(0.035, rng.randf_range(0.14, 0.22), 0.02))

	# Two tall dark eyes, wide at the bottom and drawn up to a point, with a light in each
	for side: float in [-1.0, 1.0]:
		var eye := _pivot(neck, Vector3(0.12 * chub * side, 0.2, 0.385 * chub))
		eye.rotation.x = -0.62
		_part(eye, _sphere(), black, Vector3.ZERO, Vector3(0.068, 0.078, 0.03))
		_part(eye, _cone(), black, Vector3(0, 0.16, 0), Vector3(0.06, 0.28, 0.026))
		var pupil := _part(eye, _sphere(), eye_mat, Vector3(0, 0, 0.03), Vector3(0.036, 0.046, 0.03))
		eyes.append(eye)
		pupils.append(pupil)
	# Its mouth is somewhere under the hair, and only shows when it opens
	mouth_node = _pivot(neck, Vector3(0, 0.07, 0.47 * chub))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.11, 0.06, 0.04))


# A rooster hatched wrong: feathers in front, a serpent's tail behind, and a stare it is proud of
func _build_cockatrice(chub: float) -> void:
	neck_y = 0.5
	centre_y = 0.45
	top_y = 1.02
	gravity = 9.0
	wings = true
	var yellow := Ps1.mat(Color(0.62, 0.46, 0.12), 0.0, 0.35)
	var red := Ps1.mat(Color(0.6, 0.1, 0.08), 0.0, 0.35)
	var scales := Ps1.mat(Color(0.18, 0.34, 0.2), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.1 * side, 0.2, 0))
		_part(leg, _capsule(0.025, 0.2), yellow, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), yellow, Vector3(0, -0.175, 0.04), Vector3(0.075, 0.022, 0.11))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.38, -0.02), Vector3(0.24 * chub, 0.24, 0.28 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.38, 0.14 * chub), Vector3(0.17 * chub, 0.18, 0.12))
	tail = _pivot(torso, Vector3(0, 0.34, -0.24 * chub))
	_part(tail, _capsule(0.05, 0.42), scales, Vector3(0, 0.1, -0.16), Vector3.ONE, Vector3(-1.1, 0, 0))
	_part(tail, _cone(), scales, Vector3(0, 0.22, -0.4), Vector3(0.09, 0.14, 0.03), Vector3(-1.1, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.22 * chub * side, 0.48, -0.02))
		_part(a, _sphere(), fur, Vector3(0, -0.12, -0.02), Vector3(0.04, 0.16, 0.13))
		_part(a, _cone(), pale, Vector3(0, -0.28, -0.05), Vector3(0.03, 0.14, 0.09), Vector3(PI, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.07))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.2, 0.2, 0.2))
	_part(neck, _cone(), yellow, Vector3(0, 0.19, 0.24), Vector3(0.065, 0.16, 0.045), Vector3(PI * 0.5, 0, 0))
	for i in 3:
		_part(neck, _cone(), red, Vector3(0, 0.43 - i * 0.02, 0.09 - i * 0.09), Vector3(0.035, 0.13 - i * 0.02, 0.06), Vector3(-0.2 - i * 0.2, 0, 0))
	_part(neck, _sphere(), red, Vector3(0, 0.06, 0.17), Vector3(0.03, 0.06, 0.03))
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.12 * side, 0.25, 0.13), 0.065)
	mouth_node = _pivot(neck, Vector3(0, 0.15, 0.18))
	_part(mouth_node, _cone(), yellow, Vector3(0, -0.02, 0.05), Vector3(0.05, 0.11, 0.06), Vector3(PI * 0.5, 0, 0))


# Small, dark and furry, with great red eyes, feathered feelers and wings it is still growing into
func _build_mothman(chub: float, ear_len: float) -> void:
	neck_y = 0.5
	centre_y = 0.5
	top_y = 1.1
	ear_splay = 0.45
	gravity = 7.0
	wings = true
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.09 * side, 0.2, 0))
		_part(leg, _capsule(0.035, 0.2), dark, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.17, 0.04), Vector3(0.06, 0.03, 0.1))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.38, 0), Vector3(0.22 * chub, 0.26, 0.2 * chub))
	# A ruff of fluff at the neck
	_part(torso, _sphere(), pale, Vector3(0, 0.56, 0.02), Vector3(0.26, 0.1, 0.23))
	tail = _pivot(torso, Vector3(0, 0.22, -0.18 * chub))
	_part(tail, _sphere(), fur, Vector3(0, 0, -0.03), Vector3.ONE * 0.05)

	var skin := Ps1.mat(fur.get_shader_parameter("tint") * 0.6, 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.2 * chub * side, 0.52, -0.04))
		_part(a, _capsule(0.025, 0.42), dark, Vector3(0, -0.19, 0))
		# The wing hangs behind the arm, and opens out when the arm lifts; an eye looks out of it
		_part(a, _cone(), skin, Vector3(0.1 * side, -0.17, -0.03), Vector3(0.2, 0.38, 0.012))
		_part(a, _sphere(), skin, Vector3(0.1 * side, -0.36, -0.03), Vector3(0.15, 0.12, 0.012))
		_part(a, _sphere(), eye_mat, Vector3(0.1 * side, -0.34, -0.015), Vector3(0.045, 0.045, 0.008))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.24, 0.22, 0.22))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.08 * side, 0.38, 0.02))
		_part(ear, _cone(), dark, Vector3(0, ear_len * 0.5, 0), Vector3(0.02, ear_len, 0.02))
		_part(ear, _cone(), pale, Vector3(0, ear_len * 0.55, 0), Vector3(0.075, ear_len * 0.8, 0.012))
		ears.append(ear)
		_eye(Vector3(0.115 * side, 0.22, 0.155), 0.105)
	mouth_node = _pivot(neck, Vector3(0, 0.07, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.04, 0.04))


# Lean and hunched, with spines down its back, fangs, and an eye on anything that bleeds
func _build_chupacabra(chub: float, ear_len: float) -> void:
	neck_y = 0.52
	centre_y = 0.45
	top_y = 1.02
	ear_splay = 0.9
	var spine := Ps1.mat(Color(0.42, 0.13, 0.1), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.11 * side, 0.22, -0.03))
		_part(leg, _capsule(0.05, 0.22), fur, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.185, 0.07), Vector3(0.07, 0.035, 0.16))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.39, -0.03), Vector3(0.21 * chub, 0.25, 0.27 * chub), Vector3(0.35, 0, 0))
	_part(torso, _sphere(), pale, Vector3(0, 0.36, 0.1 * chub), Vector3(0.15 * chub, 0.17, 0.12))
	for i in 4:
		_part(torso, _cone(), spine, Vector3(0, 0.63 - i * 0.085, -0.13 - i * 0.055), Vector3(0.03, 0.15 - i * 0.015, 0.045), Vector3(-0.7 - i * 0.3, 0, 0))
	tail = _pivot(torso, Vector3(0, 0.26, -0.27 * chub))
	_part(tail, _capsule(0.022, 0.4), fur, Vector3(0, 0.04, -0.17), Vector3.ONE, Vector3(-1.3, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.2 * chub * side, 0.52, 0.06))
		_part(a, _capsule(0.035, 0.3), fur, Vector3(0, -0.12, 0))
		for claw: float in [-1.0, 0.0, 1.0]:
			_part(a, _cone(), bone, Vector3(0.025 * claw, -0.31, 0.01), Vector3(0.013, 0.08, 0.013), Vector3(PI, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.11))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.25, 0.21, 0.25))
	_part(neck, _sphere(), fur, Vector3(0, 0.13, 0.2), Vector3(0.12, 0.09, 0.12))
	for i in 2:
		_part(neck, _cone(), spine, Vector3(0, 0.43 - i * 0.07, -0.02 - i * 0.12), Vector3(0.03, 0.14, 0.045), Vector3(-0.25 - i * 0.6, 0, 0))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.2 * side, 0.3, -0.03))
		_part(ear, _cone(), fur, Vector3(0, ear_len * 0.25, 0), Vector3(0.06, ear_len * 0.5, 0.03))
		ears.append(ear)
		_eye(Vector3(0.125 * side, 0.25, 0.165), 0.095)
		_part(neck, _cone(), bone, Vector3(0.05 * side, 0.045, 0.285), Vector3(0.02, 0.1, 0.02), Vector3(PI, 0, 0))
	mouth_node = _pivot(neck, Vector3(0, 0.08, 0.28))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.1, 0.05, 0.05))


# A frog that stands up: wide mouth, eyes on top of its head, and legs made for jumping
func _build_frogman(chub: float) -> void:
	neck_y = 0.38
	centre_y = 0.4
	top_y = 0.88
	head_y = 0.16
	gravity = 9.0
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.2 * side, 0.2, -0.02))
		_part(leg, _sphere(), fur, Vector3(0, -0.04, 0), Vector3(0.1, 0.13, 0.13))
		_part(leg, _sphere(), dark, Vector3(0.02 * side, -0.175, 0.12), Vector3(0.14, 0.03, 0.2), Vector3(0, 0.45 * side, 0))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.32, 0), Vector3(0.32 * chub, 0.25, 0.29 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.28, 0.15 * chub), Vector3(0.25 * chub, 0.18, 0.15))
	tail = _pivot(torso, Vector3(0, 0.26, -0.25))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.29 * chub * side, 0.4, 0.08))
		_part(a, _capsule(0.04, 0.22), fur, Vector3(0, -0.08, 0))
		_part(a, _sphere(), dark, Vector3(0, -0.2, 0.02), Vector3(0.075, 0.03, 0.075))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.03))
	_part(neck, _sphere(), fur, Vector3(0, 0.16, 0), Vector3(0.36, 0.2, 0.3))
	_part(neck, _sphere(), pale, Vector3(0, 0.1, 0.08), Vector3(0.31, 0.13, 0.22))
	for side: float in [-1.0, 1.0]:
		_part(neck, _sphere(), fur, Vector3(0.17 * side, 0.31, 0.07), Vector3.ONE * 0.105)
		_eye(Vector3(0.17 * side, 0.335, 0.115), 0.085)
	mouth_node = _pivot(neck, Vector3(0, 0.13, 0.27))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.26, 0.05, 0.06))


# A hump, four flippers and a long neck with a small head on the end of it
func _build_nessie(chub: float) -> void:
	neck_y = 0.38
	head_y = 0.62
	centre_y = 0.4
	top_y = 1.22
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.25 * chub * side, 0.13, -0.16))
		_part(leg, _sphere(), dark, Vector3(0.07 * side, -0.08, -0.03), Vector3(0.16, 0.035, 0.11))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.28, 0), Vector3(0.32 * chub, 0.24, 0.42 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.22, 0.04), Vector3(0.28 * chub, 0.19, 0.38 * chub))
	_part(torso, _sphere(), fur, Vector3(0, 0.47, -0.12), Vector3(0.16, 0.1, 0.17))
	tail = _pivot(torso, Vector3(0, 0.26, -0.36 * chub))
	_part(tail, _cone(), fur, Vector3(0, 0, -0.2), Vector3(0.11, 0.42, 0.09), Vector3(-PI * 0.5, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.29 * chub * side, 0.25, 0.17))
		_part(a, _sphere(), dark, Vector3(0.1 * side, -0.14, 0.02), Vector3(0.17, 0.035, 0.1))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.24 * chub))
	_part(neck, _capsule(0.075, 0.66), fur, Vector3(0, 0.3, 0.02), Vector3.ONE, Vector3(0.08, 0, 0))
	_part(neck, _sphere(), fur, Vector3(0, 0.62, 0.08), Vector3(0.14, 0.11, 0.19))
	for side: float in [-1.0, 1.0]:
		_part(neck, _sphere(), pale, Vector3(0.055 * side, 0.73, 0.02), Vector3.ONE * 0.028)
		_eye(Vector3(0.09 * side, 0.67, 0.13), 0.05)
	mouth_node = _pivot(neck, Vector3(0, 0.585, 0.23))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.08, 0.035, 0.05))


# A whale of the high slopes: mostly mouth, grey as scree, with a hooked tail for hanging on to ridges
func _build_bolter(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.2
	centre_y = 0.42
	top_y = 0.92
	gravity = 15.0
	brain_at = Vector3(0, 0.36, 0.22)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.17 * side, 0.15, 0.05))
		_part(leg, _sphere(), dark, Vector3(0, -0.1, 0.04), Vector3(0.1, 0.05, 0.14))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	# All of it turns to look, tail and flippers too
	neck = _pivot(torso, Vector3(0, neck_y, 0))
	_part(neck, _sphere(), fur, Vector3(0, 0.22, -0.02), Vector3(0.36 * chub, 0.31, 0.47 * chub))
	_part(neck, _sphere(), pale, Vector3(0, 0.13, 0.05), Vector3(0.33 * chub, 0.24, 0.43 * chub))
	var rock := BoxMesh.new()
	for i in 4:
		var at := Vector3(rng.randf_range(-0.16, 0.16), 0.5 - i * 0.02, 0.05 - i * 0.12)
		_part(neck, rock, dark, at, Vector3(0.11, 0.07, 0.1) * rng.randf_range(0.7, 1.2), Vector3(rng.randf(), rng.randf(), rng.randf()))
	tail = _pivot(neck, Vector3(0, 0.24, -0.42 * chub))
	_part(tail, _capsule(0.07, 0.4), fur, Vector3(0, 0.1, -0.13), Vector3.ONE, Vector3(-0.9, 0, 0))
	for side: float in [-1.0, 1.0]:
		# The flukes curl over into hooks
		_part(tail, _cone(), dark, Vector3(0.09 * side, 0.3, -0.27), Vector3(0.06, 0.22, 0.03), Vector3(0.5, 0, -1.9 * side))
		var a := _pivot(neck, Vector3(0.35 * chub * side, 0.2, 0.08))
		_part(a, _sphere(), dark, Vector3(0, -0.1, 0), Vector3(0.04, 0.13, 0.09))
		arms.append(a)
		_eye(Vector3(0.25 * chub * side, 0.37, 0.24 * chub), 0.05)
	mouth_node = _pivot(neck, Vector3(0, 0.15, 0.4 * chub))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.3 * chub, 0.11, 0.09))
	for i in 6:
		var x := (i - 2.5) * 0.085 * chub
		_part(neck, _cone(), bone, Vector3(x, 0.21, 0.455 * chub - x * x * 1.6), Vector3(0.028, 0.07, 0.022), Vector3(PI, 0, 0))


# Thin as hunger: a deer's skull on a dark, long-armed body, and a light in the sockets
func _build_wendigo(chub: float) -> void:
	neck_y = 0.76
	centre_y = 0.66
	top_y = 1.6
	ear_splay = 1.3
	var skull := Ps1.mat(Color(0.64, 0.61, 0.52), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.09 * side, 0.32, 0))
		_part(leg, _capsule(0.04, 0.34), fur, Vector3(0, -0.14, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.285, 0.03), Vector3(0.06, 0.04, 0.09))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.54, 0), Vector3(0.18 * chub, 0.27, 0.15 * chub))
	for i in 3:
		_part(torso, _sphere(), skull, Vector3(0, 0.5 + i * 0.065, 0.125 * chub), Vector3(0.13 - i * 0.012, 0.014, 0.04))
	_part(torso, _sphere(), fur, Vector3(0, 0.74, -0.02), Vector3(0.26, 0.1, 0.18))
	tail = _pivot(torso, Vector3(0, 0.36, -0.14))
	_part(tail, _sphere(), fur, Vector3(0, 0, -0.03), Vector3.ONE * 0.045)

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.24 * side, 0.72, 0))
		_part(a, _capsule(0.03, 0.52), fur, Vector3(0, -0.23, 0))
		for claw: float in [-1.0, 0.0, 1.0]:
			_part(a, _cone(), skull, Vector3(0.028 * claw, -0.53, 0), Vector3(0.012, 0.11, 0.012), Vector3(PI, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.03))
	_part(neck, _sphere(), skull, Vector3(0, 0.2, 0), Vector3(0.17, 0.17, 0.18))
	_part(neck, _sphere(), skull, Vector3(0, 0.13, 0.17), Vector3(0.085, 0.075, 0.17))
	_part(neck, _sphere(), black, Vector3(0, 0.15, 0.335), Vector3(0.035, 0.025, 0.012))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.15 * side, 0.24, -0.08))
		_part(ear, _cone(), fur, Vector3(0, 0.06, 0), Vector3(0.04, 0.12, 0.02))
		ears.append(ear)
		_eye(Vector3(0.085 * side, 0.23, 0.125), 0.068, true)
		# Antlers: a beam and two tines
		_part(neck, _cone(), skull, Vector3(0.15 * side, 0.52, -0.04), Vector3(0.03, 0.44, 0.03), Vector3(0, 0, -0.5 * side))
		_part(neck, _cone(), skull, Vector3(0.24 * side, 0.52, -0.04), Vector3(0.02, 0.2, 0.02), Vector3(0, 0, -1.15 * side))
		_part(neck, _cone(), skull, Vector3(0.13 * side, 0.5, 0.05), Vector3(0.02, 0.18, 0.02), Vector3(0.7, 0, -0.15 * side))
	mouth_node = _pivot(neck, Vector3(0, 0.065, 0.2))
	_part(mouth_node, _sphere(), black, Vector3.ZERO, Vector3(0.065, 0.035, 0.11))


# An eye on the head. Hollow ones are dark with the light in the pupil.
func _eye(at: Vector3, size: float, hollow := false) -> void:
	var eye := _pivot(neck, at)
	_part(eye, _sphere(), black if hollow else eye_mat, Vector3.ZERO, Vector3.ONE * size)
	var pupil := _part(eye, _sphere(), eye_mat if hollow else black, Vector3(0, 0, size * 0.68), Vector3.ONE * size * 0.5)
	eyes.append(eye)
	pupils.append(pupil)


func _sphere() -> SphereMesh:
	return Ps1.ball()


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 6
	m.rings = 2
	return m


func _drum(top: float, bottom: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = 8
	m.rings = 1
	return m


# A shape turned on a lathe: points of (radius, height) from the bottom up, spun round
func _lathe(shape: Array[Vector2], sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in shape.size():
		var before := shape[maxi(i - 1, 0)]
		var after := shape[mini(i + 1, shape.size() - 1)]
		var along := (after - before).normalized()
		for j in sides + 1:
			var around := TAU * j / sides
			var out := Vector3(sin(around), 0, cos(around))
			st.set_normal((out * along.y + Vector3.UP * -along.x).normalized())
			st.set_uv(Vector2(float(j) / sides, float(i) / shape.size()))
			st.add_vertex(out * shape[i].x + Vector3.UP * shape[i].y)
	for i in shape.size() - 1:
		for j in sides:
			var a := i * (sides + 1) + j
			var b := a + sides + 1
			for index: int in [a, a + 1, b, a + 1, b + 1, b]:
				st.add_index(index)
	return st.commit()


func _cone() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = 1.0
	m.height = 1.0
	m.radial_segments = 6
	m.rings = 1
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
	bubble = _pivot(self, Vector3(0.35, top_y + 0.35, 0))
	var white := Ps1.flat(Color(0.95, 0.95, 0.9))
	for p: MeshInstance3D in [
		_part(bubble, _sphere(), white, Vector3.ZERO, Vector3(0.24, 0.2, 0.01)),
		_part(bubble, _sphere(), white, Vector3(-0.2, -0.22, 0), Vector3(0.06, 0.06, 0.01)),
		_part(bubble, _sphere(), white, Vector3(-0.27, -0.33, 0), Vector3(0.035, 0.035, 0.01)),
	]:
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bubble_food = _pivot(bubble, Vector3(0, 0, 0.02))
	var sandy := Ps1.flat(Color(0.62, 0.5, 0.34))
	_part(bubble_food, _capsule(0.03, 0.26), sandy, Vector3.ZERO, Vector3(1, 1, 0.2), Vector3(0, 0, 1.0))
	for end: float in [-1.0, 1.0]:
		for off: float in [-1.0, 1.0]:
			var at := Vector3(-sin(1.0), cos(1.0), 0) * 0.11 * end + Vector3(cos(1.0), sin(1.0), 0) * 0.035 * off
			_part(bubble_food, _sphere(), sandy, at, Vector3(0.045, 0.045, 0.01))
	bubble_ball = _pivot(bubble, Vector3(0, 0, 0.02))
	_part(bubble_ball, _sphere(), Ps1.flat(Color(0.95, 0.45, 0.08)), Vector3.ZERO, Vector3(0.11, 0.11, 0.01))
	_part(bubble_ball, _sphere(), Ps1.flat(Color(0.36, 0.16, 0.5)), Vector3(0, 0, 0.004), Vector3(0.035, 0.11, 0.01))
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
	hearts.position = Vector3(0, top_y - 0.1, 0)
	hearts.emitting = false
	hearts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hearts)


# ---------------------------------------------------------------- needs

# How it is doing all round: mostly its needs, and partly how well its room suits it
func mood() -> float:
	return (belly + fun + energy) / 3.0 * 0.75 + comfort * 0.25


func get_needs() -> Dictionary:
	return {"belly": belly, "fun": fun, "energy": energy, "love": love, "age": age}


func set_needs(d: Dictionary) -> void:
	belly = clampf(float(d.get("belly", belly)), 0.0, 100.0)
	fun = clampf(float(d.get("fun", fun)), 0.0, 100.0)
	energy = clampf(float(d.get("energy", energy)), 0.0, 100.0)
	love = clampf(float(d.get("love", love)), 0.0, 100.0)
	# Saves from before there were babies hold a grown one
	age = float(d.get("age", GROW_AGE))
	grow = size_goal()
	scale = Vector3.ONE * grow


func _tick_needs(delta: float) -> void:
	var was_baby := is_baby()
	_wear(delta, state == State.SLEEP, 1.0 + velocity.length() * 0.5, not world.light_on)
	comfort = move_toward(comfort, world.comfort_of(self), delta * 4.0)
	if was_baby and not is_baby():
		hop(3.0)
		_cry("coo", 0.8)
		hearts.emitting = true
		feel(Feeling.HAPPY, 6.0)
		world.grew_up()


# Time passing, for `seconds` of the clock on the wall: it gets hungrier, more bored and more
# tired (or more rested, asleep), and older. `effort` is how hard it is working.
func _wear(seconds: float, asleep: bool, effort: float, dark: bool) -> void:
	belly -= seconds * appetite * (0.5 if asleep else 1.0) * 100.0 / (BELLY_HOURS * HOUR)
	fun -= seconds * bore * (0.3 if asleep else 1.0) * 100.0 / (FUN_HOURS * HOUR)
	if asleep:
		energy += seconds * 100.0 / (SLEEP_HOURS * HOUR)
	else:
		energy -= seconds * weariness * effort * (1.5 if dark else 1.0) * 100.0 / (AWAKE_HOURS * HOUR)
	# The bond wears away over a couple of days of going hungry, and grows over a few good ones
	if belly < 15.0:
		love -= seconds * 100.0 / (48.0 * HOUR)
	elif mood() > 60.0:
		love += seconds * 100.0 / (96.0 * HOUR)
	age += seconds
	belly = clampf(belly, 0.0, 100.0)
	fun = clampf(fun, 0.0, 100.0)
	energy = clampf(energy, 0.0, 100.0)
	love = clampf(love, 0.0, 100.0)


# The time nobody was looking, lived through in five-minute steps: it sleeps when it is worn out
# (or left in the dark) and wakes when it is rested. True if it is asleep at the end of it.
func pass_time(seconds: float, dark: bool) -> bool:
	var left := minf(seconds, LONGEST_AWAY)
	var asleep := false
	while left > 0.0:
		var chunk := minf(left, 300.0)
		left -= chunk
		_wear(chunk, asleep, 1.1, dark)
		if asleep:
			asleep = energy < 98.0
		else:
			asleep = energy < 12.0 or (dark and energy < 70.0)
	grow = size_goal()
	scale = Vector3.ONE * grow
	return asleep


# ---------------------------------------------------------------- what you can do to it

func body_centre() -> Vector3:
	return global_position + Vector3(0, (centre_y - curl * 0.2) * grow, 0)


func is_baby() -> bool:
	return age < GROW_AGE


func size_goal() -> float:
	return BABY_SIZE if is_baby() else adult_size


# Both of its natures, as in "a shy, greedy gremlin"
func nature_name() -> String:
	return "%s, %s" % [NATURES[nature]["title"], NATURES[nature2]["title"]]


# How long until it is grown, in seconds (0 once it is)
func growing_left() -> float:
	return maxf(GROW_AGE - age, 0.0)


func feeling_name() -> String:
	return FEELINGS[feeling]["title"]


# Something has just made it feel this way, for a while
func feel(how: int, seconds: float) -> void:
	flash_feeling = how
	feeling = how
	flash_time = seconds


# The face over its head: up with a little bounce whenever its feeling changes, gone after a
# moment; a feeling that goes on (hungry, bored, sad) comes up again every so often. Never
# while it sleeps (it has its z's).
func _show_emote(delta: float) -> void:
	emote_again -= delta
	if feeling != emote_for or (emote_again <= 0.0 and not emote.visible and feeling in [Feeling.HUNGRY, Feeling.BORED, Feeling.SAD, Feeling.GRUMPY]):
		emote_for = feeling
		emote_again = randf_range(9.0, 14.0)
		if EMOTES[feeling] != "" and state != State.SLEEP:
			emote.text = EMOTES[feeling]
			emote.modulate = EMOTE_COLOURS[feeling]
			emote.visible = true
			emote_time = 0.0
		else:
			emote.visible = false
	if not emote.visible:
		return
	emote_time += delta
	var up := 1.0 - exp(-emote_time * 9.0) * cos(emote_time * 16.0) # (pops up and settles)
	var fade := 1.0 - smoothstep(2.2, 2.8, emote_time)
	emote.global_position = global_position + Vector3(0.0, (top_y + 0.28) * grow + 0.12 * up, 0.0)
	emote.scale = Vector3.ONE * maxf(up, 0.01) * (0.8 + 0.2 * grow)
	emote.modulate.a = fade
	emote.outline_modulate.a = fade * 0.9
	if emote_time > 2.8 or state == State.SLEEP:
		emote.visible = false


func _feel(delta: float) -> void:
	_show_emote(delta)
	flash_time -= delta
	if flash_time > 0.0:
		feeling = flash_feeling
	elif state == State.SLEEP or energy < 20.0:
		feeling = Feeling.SLEEPY
	elif belly < 20.0:
		feeling = Feeling.HUNGRY
	elif love < 8.0 and mood() < 40.0:
		feeling = Feeling.SAD
	elif fun < 18.0:
		feeling = Feeling.BORED
	elif state == State.PETTED:
		feeling = Feeling.LOVING
	elif state in [State.ZOOMIES, State.DANCE, State.CHASE_BALL]:
		feeling = Feeling.EXCITED
	elif mood() > 62.0:
		feeling = Feeling.HAPPY
	else:
		feeling = Feeling.CONTENT


# Lifted off the floor by a finger that stayed on it
func pick_up() -> void:
	if state == State.LEAVE:
		return
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
	_enter(State.HELD)
	var how: int = NATURES[nature]["carry"]
	feel(how, 60.0)
	_cry("squeak" if how in [Feeling.SCARED, Feeling.GRUMPY] else "chirp")


func carry(point: Vector3) -> void:
	carry_point = point


func put_down() -> void:
	if state == State.HELD and step == 0:
		step = 1
		fall_v = 0.0
		flash_time = minf(flash_time, 3.0)


# A quick flick across it sends it skidding
func push(dir: Vector3) -> void:
	if state in [State.LEAVE, State.HELD]:
		return
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
	_enter(State.SHOVED, 0.7)
	velocity = Vector3(dir.x, 0, dir.z).normalized() * 3.6
	hop(1.6)
	var how: int = NATURES[nature]["push"]
	feel(how, 5.0)
	_cry("squeak", 0.9)
	if how == Feeling.EXCITED:
		fun = minf(fun + 6.0, 100.0)
	else:
		love = maxf(love - 1.0, 0.0)


# A quick tap
func boop() -> void:
	if state in [State.LEAVE, State.HELD]:
		return
	# Poked again and again, it has had enough
	if anim_t - poke_time > 2.5:
		pokes = 0
	pokes += 1
	poke_time = anim_t
	if pokes >= 4 and state != State.SLEEP:
		pokes = 0
		love = maxf(love - 2.0, 0.0)
		_cry("grumble")
		_enter(State.STARTLED, 1.2)
		roll_goal = 0.3
		feel(Feeling.GRUMPY, 7.0)
		world.fed_up()
		return
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
		_cry("grumble")
		_enter(State.STARTLED, 1.4)
		roll_goal = 0.3
		eye_goal = 0.6
		droop_goal = 0.9
		return
	love = minf(love + 1.0, 100.0)
	_cry("squeak")
	_enter(State.STARTLED, 0.6)


# A finger rubbed over it
func stroke() -> void:
	if state in [State.LEAVE, State.HELD, State.SHOVED]:
		return
	last_stroke = anim_t
	if state == State.SLEEP:
		hearts.emitting = true
		return
	if state != State.PETTED:
		_enter(State.PETTED)


func call_to(point: Vector3) -> void:
	if state in [State.SLEEP, State.GO_SLEEP, State.EAT, State.PETTED, State.STARTLED, State.LEAVE, State.HELD, State.SHOVED, State.SCANNED]:
		return
	target = Den.in_room(point, 0.35)
	_enter(State.COME)


# Something in its room has changed (a thing put in at `point`, new ground, the lamp):
# it goes over to see, and shows what it makes of it. `liking` is 1 if this is what it
# wants, -1 if it cannot stand it and 0 if it does not mind; `key` is what Den.learned() is told.
func look_over(point: Vector3, liking: int, key: String) -> void:
	if not state in INTERRUPTIBLE:
		return
	inspect_liking = liking
	inspect_key = key
	target = Den.in_room(point, 0.35)
	_enter(State.INSPECT)


# The scanner is on it: it holds still and looks at you while it is
func hold_still() -> void:
	if state in INTERRUPTIBLE or state in [State.STARTLED, State.INSPECT]:
		_enter(State.SCANNED)


# The player threw the ball: worth chasing even if it had just lost interest
func notice_ball() -> void:
	ball_cooldown = 0.0


func hop(power := 2.6) -> void:
	if airborne:
		return
	airborne = true
	jump_v = power * spring
	squash_v = -1.5


# Sent off to make room for a new egg: a wave, then away into the dark. Emits `left` once gone.
func leave() -> void:
	_enter(State.LEAVE)


# The kind a save holds: its title, or a number in the oldest saves
static func kind_of(saved: Variant) -> int:
	if saved is String:
		for i in KINDS.size():
			if KINDS[i]["title"] == saved:
				return i
		return Kind.GREMLIN
	return OLD_KINDS[clampi(int(saved), 0, OLD_KINDS.size() - 1)]


func kind_name() -> String:
	return KINDS[kind]["title"]


# Its voice: each kind pitches the same few sounds differently
func _cry(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	world.sfx.play(sound, pitch * voice * (1.3 if is_baby() else 1.0), volume_db)


# ---------------------------------------------------------------- brain

func _process(delta: float) -> void:
	if world == null:
		return
	anim_t += delta
	state_time += delta
	ball_cooldown -= delta
	beg_cooldown -= delta
	pounce_cooldown -= delta
	nest_cooldown -= delta
	glance_time -= delta
	_tick_needs(delta)
	_feel(delta)
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
	if s != State.HELD:
		lift = 0.0
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
			visiting = world.cave()
			target = world.hiding_place(self)
		State.COME:
			_cry("chirp")
		State.GO_FOOD:
			snack = null
			wag = 9.0
		State.CHASE_BALL:
			kicks = 0
			kick_limit = randi_range(2, 4) + (2 if world.ball != null and world.ball.kind == fav_toy else 0)
			wag = 9.0
		State.CHASE_LIGHT:
			wag = 9.0
		State.BEG:
			state_len = 5.5
			beg_cooldown = 30.0
			beg_for_ball = belly >= 25.0
			target = Den.in_room(world.light_point + Vector3(randf_range(-0.6, 0.6), 0, 1.5), 0.4)
		State.ZOOMIES:
			state_len = randf_range(0.0, TAU)
			_cry("chirp", 1.2)
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
			_cry("yawn")
			target = world.nest_pos
			droop_goal = 0.8
			eye_goal = 0.6
		State.HELD:
			carry_point = position + Vector3(0, 0.8, 0)
			arm_goal = UP_ARM
			eye_goal = 1.15
			jump_y = 0.0
			airborne = false
		State.SHOVED:
			eye_goal = 1.25
			arm_goal = UP_ARM
		State.INSPECT:
			wag = 6.0
		State.VISIT:
			visiting = world.somewhere_to_go(self)
			wag = 5.0
		State.MOVE_NEST:
			nest_cooldown = randf_range(400.0, 900.0)
			wag = 6.0
		State.SCANNED:
			eye_goal = 1.15
			roll_goal = 0.2
		State.LEAVE:
			_cry("coo", 0.85)
			arm_goal = UP_ARM
			arm_wave = 0.5
			# Out over the front of the tank, the one side with no wall
			target = Vector3(position.x * 0.5, 0, 4.6)
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
	var options := {State.WANDER: 34.0, State.STARE: 20.0 * float(likes["stare"]), State.IDLE: 8.0}
	if world.light_on:
		options[State.LURK] = 11.0 * float(likes["lurk"])
	if world.ball != null and energy > 30.0:
		options[State.CHASE_BALL] = 30.0 if world.ball.kind == fav_toy else 16.0
	if world.somewhere_to_go(self) != null:
		options[State.VISIT] = 18.0
	if nest_cooldown <= 0.0 and world.light_on and energy > 30.0:
		options[State.MOVE_NEST] = 4.0
	if fun > 65.0 and energy > 45.0:
		options[State.ZOOMIES] = 8.0 * float(likes["zoom"])
	if mood() > 62.0:
		options[State.DANCE] = 8.0 * float(likes["dance"])
	var total := 0.0
	for w: float in options.values():
		total += w
	var roll := randf() * total
	for s: int in options:
		roll -= float(options[s])
		if roll <= 0.0:
			if s == State.WANDER:
				var a := randf() * TAU
				target = Den.in_room(Vector3(cos(a), 0, sin(a)) * sqrt(randf()) * 2.3, 0.4)
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
				_cry("yawn")
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
					if is_instance_valid(visiting):
						# Tucked into the cave, looking out
						state_len += 3.0
						sit_goal = 1.0
			else:
				_halt(delta)
				_face(gaze, delta)
				if state_time > state_len:
					target = Den.in_room(Vector3(randf_range(-1.2, 1.2), 0, randf_range(-0.8, 1.2)), 0.4)
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
			fun = minf(fun + delta * 0.6, 100.0)
			gaze = world.light_goal
			if _steer(world.light_goal, RUN, delta, 0.3) and pounce_cooldown <= 0.0:
				pounce_cooldown = 0.9
				hop(2.3)
				fun = minf(fun + 2.0, 100.0)
				_cry("chirp", 1.1)
		State.BEG:
			gaze = world.camera.global_position
			if step == 0:
				if _steer(target, WALK * 1.4, delta) or state_time > 5.0:
					step = 1
					state_time = 0.0
					_cry("whimper")
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
			var a := state_len + step * 1.9
			var point := Den.in_room(Vector3(cos(a), 0, sin(a)) * 1.6, 0.4)
			gaze = point + Vector3(0, 0.3, 0)
			mouth_goal = 0.7
			if _steer(point, RUN * 1.45, delta, 0.55):
				step += 1
				if step >= 7:
					hop(2.2)
					_cry("coo")
					_enter(State.IDLE, 1.8)
					mouth_goal = 0.7
		State.DANCE:
			_halt(delta)
			wiggle = sin(anim_t * 7.0) * 0.18
			yaw += delta * 2.2
			if not airborne:
				hop(1.9)
				step += 1
				if step % 2 == 0:
					_cry("chirp", 0.9 + 0.1 * (step % 4))
			if step > 7:
				_enter(State.IDLE, 1.0)
		State.PETTED:
			_halt(delta)
			gaze = world.camera.global_position
			_face(gaze, delta)
			wiggle = sin(anim_t * 10.0) * 0.07
			love = minf(love + delta * 0.5 * cuddle, 100.0)
			fun = minf(fun + delta * 0.6, 100.0)
			if anim_t - last_stroke > 0.7:
				_cry("coo")
				hop(2.0)
				_enter(State.IDLE, 1.5)
		State.STARTLED:
			_halt(delta)
			if state_time > state_len:
				_enter(State.IDLE, 1.0)
		State.HELD:
			velocity = Vector3.ZERO
			gaze = world.camera.global_position
			_face(gaze, delta)
			if step == 0:
				# Dangling from the finger
				var near := 1.0 - exp(-delta * 14.0)
				position.x = lerpf(position.x, carry_point.x, near)
				position.z = lerpf(position.z, carry_point.z, near)
				lift = lerpf(lift, carry_point.y, near)
				wiggle = sin(anim_t * 6.0) * 0.1
			else:
				fall_v -= 14.0 * delta
				lift += fall_v * delta
				if lift <= 0.0:
					lift = 0.0
					squash_v = 4.0
					world.sfx.play("thud", 1.2, -8.0)
					_enter(State.STARTLED, 0.5)
		State.SHOVED:
			velocity = velocity.move_toward(Vector3.ZERO, delta * 6.0)
			wiggle = sin(state_time * 22.0) * 0.2 * (1.0 - state_time / state_len)
			if state_time > state_len:
				_enter(State.IDLE, 1.0)
		State.INSPECT:
			gaze = target + Vector3(0, 0.3, 0)
			if step == 0:
				if _steer(target, WALK * 1.5, delta, 0.6) or state_time > 6.0:
					step = 1
					state_time = 0.0
					_halt(delta)
					if inspect_liking > 0:
						hop(2.4)
						_cry("coo")
						hearts.emitting = true
						feel(Feeling.LOVING, 6.0)
					elif inspect_liking < 0:
						_cry("grumble", 1.2)
						roll_goal = 0.35
						feel(Feeling.DISGUSTED, 6.0)
					else:
						_cry("chirp", 0.9)
					if inspect_liking != 0:
						world.learned(inspect_key)
			else:
				_halt(delta)
				if inspect_liking > 0:
					wiggle = sin(anim_t * 9.0) * 0.1
				if state_time > 1.8:
					_enter(State.IDLE, 1.0)
		State.VISIT:
			if not is_instance_valid(visiting) or visiting.is_queued_for_deletion():
				_enter(State.IDLE, 0.6)
				return
			var at := visiting.position
			gaze = at + Vector3(0, 0.3, 0)
			if step == 0:
				var near := 0.2 if visiting.hollow else visiting.radius + 0.28 * grow
				if _steer(at, WALK * 1.2, delta, near) or state_time > 7.0:
					step = 1
					state_time = 0.0
					state_len = randf_range(4.0, 7.5)
					if visiting.kind == Decor.Kind.ROCK:
						hop(2.6)
			else:
				_halt(delta)
				match visiting.kind:
					Decor.Kind.DISH:
						# Drinks
						_face(at, delta)
						nod = 0.5 + sin(state_time * 7.0) * 0.12
						mouth_goal = 0.5
						if int(state_time / 0.8) + 1 > step:
							step = int(state_time / 0.8) + 1
							_cry("chomp", 1.7, -14.0)
					Decor.Kind.ROCK:
						# Climbs up and sits on top of it, lord of the room
						var up := 1.0 - exp(-delta * 6.0)
						position.x = lerpf(position.x, at.x, up)
						position.z = lerpf(position.z, at.z, up)
						lift = lerpf(lift, 0.4, up)
						sit_goal = 1.0
						gaze = world.camera.global_position
						_face(gaze, delta)
					Decor.Kind.CAVE:
						# Sits inside, looking out
						sit_goal = 1.0
						eye_goal = 1.2
						gaze = world.camera.global_position
						_face(gaze, delta)
					_:
						# Has a sniff at it, then settles down beside it
						_face(at, delta)
						if state_time < 1.6:
							nod = 0.3 + sin(state_time * 11.0) * 0.08
						else:
							nod = 0.0
							sit_goal = 1.0
							gaze = world.camera.global_position
				if state_time > state_len:
					fun = minf(fun + 1.5, 100.0)
					if visiting.kind in like_decor:
						love = minf(love + 0.3, 100.0)
					_enter(State.IDLE, 1.0)
		State.MOVE_NEST:
			if step == 0:
				gaze = world.nest_pos + Vector3(0, 0.1, 0)
				if _steer(world.nest_pos, WALK, delta, 0.5) or state_time > 8.0:
					step = 1
					state_time = 0.0
					target = world.nest_spot(self)
					arm_goal = BELLY_ARM
					_cry("chirp", 0.8)
			elif step == 1:
				# Drags it along behind to wherever it has decided it ought to be
				gaze = target + Vector3(0, 0.2, 0)
				var there := _steer(target, WALK * 0.7, delta, 0.3)
				world.move_nest(position - Vector3(sin(yaw), 0, cos(yaw)) * 0.5 * grow)
				if there or state_time > 9.0:
					step = 2
					state_time = 0.0
					world.settle_nest()
					hop(1.8)
					_cry("coo")
			else:
				_halt(delta)
				gaze = world.nest_pos
				if state_time > 1.2:
					_enter(State.IDLE, 1.0)
		State.SCANNED:
			_halt(delta)
			gaze = world.camera.global_position
			_face(gaze, delta)
			if not world.scanning or state_time > 30.0:
				_enter(State.IDLE, 0.8)
		State.GO_SLEEP:
			mouth_goal = 1.0 if state_time < 0.9 else 0.12
			gaze = target + Vector3(0, 0.2, 0)
			if state_time < 0.9:
				_halt(delta)
			elif _steer(target, WALK * 0.85, delta, 0.12) or state_time > 12.0:
				_enter(State.SLEEP)
		State.LEAVE:
			if step == 0:
				_halt(delta)
				gaze = world.camera.global_position
				_face(gaze, delta)
				if state_time > 1.5:
					step = 1
					state_time = 0.0
					arm_goal = REST_ARM
					arm_wave = 0.0
			else:
				gaze = target + Vector3(0, 0.3, 0)
				if _steer(target, WALK * 1.8, delta, 0.3) or state_time > 7.0:
					set_process(false)
					left.emit()
		State.SLEEP:
			_halt(delta)
			_face(world.camera.global_position + Vector3(4.0, 0, 0), delta)
			hearts.emitting = anim_t - last_stroke < 0.5
			if int(state_time / 3.4) > step:
				step = int(state_time / 3.4)
				_cry("snore", 1.0, -8.0)
			if energy >= 98.0 or (world.light_on and energy > 55.0 and state_len < 0.0):
				_cry("coo", 0.9)
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
		_cry("chomp")
		world.crumbs(snack.global_position + Vector3(0, 0.1, 0), snack.colour)
		var eaten := snack.kind
		if eaten == yuck_food and belly >= 15.0:
			# One taste is enough, unless it is starving
			world.remove_snack(snack)
			snack = null
			love = maxf(love - 1.0, 0.0)
			_cry("grumble", 1.3)
			_enter(State.STARTLED, 1.0)
			roll_goal = 0.35
			feel(Feeling.DISGUSTED, 5.0)
			world.learned("yuck")
			return
		if snack.bite():
			world.remove_snack(snack)
			snack = null
			var loved := eaten == fav_food
			belly = minf(belly + Snack.VALUE * (1.3 if loved else (0.5 if eaten == yuck_food else 1.0)), 100.0)
			love = minf(love + (6.0 if loved else 2.0), 100.0)
			_cry("coo")
			hop(2.0)
			_enter(State.IDLE, 1.2)
			arm_goal = BELLY_ARM
			eye_goal = 0.5
			if loved:
				fun = minf(fun + 8.0, 100.0)
				hearts.emitting = true
				feel(Feeling.LOVING, 5.0)
				world.learned("food")


func _chase_ball(delta: float) -> void:
	var b := world.ball
	if b == null or energy < 12.0 or state_time > 16.0:
		_enter(State.IDLE)
		return
	fun = minf(fun + delta * 0.4, 100.0)
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
	var home := -position
	home.y = 0.0
	if home.length() > 1.3:
		dir = (dir + home.normalized() * 1.6).normalized()
	b.vel = (dir * randf_range(2.4, 4.2) + Vector3.UP * randf_range(2.0, 3.8)) * b.heft
	hop(2.0)
	world.sfx.play(b.sound, b.pitch * 1.2)
	kicks += 1
	kicks_total += 1
	var loved := b.kind == fav_toy
	fun = minf(fun + (9.0 if loved else 6.0), 100.0)
	if loved:
		love = minf(love + 1.0, 100.0)
		feel(Feeling.EXCITED, 4.0)
		world.learned("toy")
	if kicks >= kick_limit:
		ball_cooldown = 4.0
		_cry("coo")
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
	var want := speed * pace * aligned * clampf(away / 0.5, 0.35, 1.0)
	velocity = velocity.move_toward(ahead * want, delta * 10.0)
	return false


func _move(delta: float) -> void:
	position.x += velocity.x * delta
	position.z += velocity.z * delta
	if state != State.LEAVE:
		# It walks round the things in its tank, and stays inside the walls
		if lift <= 0.05:
			for thing in world.decors:
				var off := Vector2(position.x - thing.position.x, position.z - thing.position.z)
				var room := thing.radius + 0.2 * grow
				# Not the cave it is tucked into, nor the rock it is sat on
				if (thing.hollow and state in [State.SLEEP, State.GO_SLEEP, State.MOVE_NEST]) or (thing == visiting and state in [State.LURK, State.VISIT]):
					continue
				if off.length() < room:
					# Eased out of the way, not snapped: it slides round things
					off = (off.normalized() if off.length() > 0.001 else Vector2.RIGHT) * room
					var clear := Vector2(position.x, position.z).move_toward(Vector2(thing.position.x, thing.position.z) + off, delta * 4.0)
					position.x = clear.x
					position.z = clear.y
		var kept := Den.in_room(position, 0.3)
		position.x = kept.x
		position.z = kept.z
	if airborne:
		jump_v -= gravity * delta
		jump_y += jump_v * delta
		if jump_y <= 0.0:
			jump_y = 0.0
			airborne = false
			squash_v = 3.2
	position.y = jump_y + lift
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
	torso.position.y = absf(sin(phase)) * 0.05 * gait - sit * 0.1 - curl * 0.15 + hover * (1.0 - curl) * (1.0 + sin(anim_t * 2.2) * 0.22)
	torso.rotation.x = gait * minf(speed, 3.5) * 0.07 + curl * 0.12
	torso.rotation.z = wiggle + sin(anim_t * 42.0) * float(FEELINGS[feeling]["shake"])
	torso.scale = Vector3(1.0 + squash * 0.6 + breath, 1.0 - squash + breath, 1.0 + squash * 0.6 + breath)

	var fold := sit * 1.3 + curl * 1.35
	legs[0].rotation.x = swing * 0.9 - fold
	legs[1].rotation.x = -swing * 0.9 - fold
	if lift > 0.05:
		# Feet off the floor: they pedal
		legs[0].rotation.x = sin(anim_t * 9.0) * 0.6
		legs[1].rotation.x = -sin(anim_t * 9.0) * 0.6

	# A baby is small with a big head, and grows into its size
	grow = move_toward(grow, size_goal(), delta * 0.25)
	scale = Vector3.ONE * grow
	neck.scale = Vector3.ONE * lerpf(1.0, 1.28, clampf(inverse_lerp(adult_size, BABY_SIZE, grow), 0.0, 1.0))

	arm = arm.lerp(arm_goal, ease_fast)
	var wave := sin(anim_t * 9.0) * arm_wave
	var tuck := curl * 0.8
	# Wings beat while it is off the ground
	var lift := (1.2 + sin(anim_t * 30.0) * 0.7) if wings and airborne else 0.0
	arms[1].rotation = Vector3(arm.x - swing * 0.7 * (1.0 - curl) + wave - tuck, arm.y, arm.z + lift)
	arms[0].rotation = Vector3(arm.x + swing * 0.7 * (1.0 - curl) - wave - tuck, -arm.y, -arm.z - lift)

	# Head turns to whatever it is looking at; the pupils go the rest of the way
	var seen := torso.global_transform.affine_inverse() * gaze - neck.position - Vector3(0, head_y, 0)
	var want_yaw := clampf(atan2(seen.x, seen.z), -1.25, 1.25)
	var want_pitch := clampf(-atan2(seen.y, Vector2(seen.x, seen.z).length()), -0.7, 0.5)
	if curl_goal > 0.5:
		want_yaw = 0.35
		want_pitch = 0.45
	head_yaw = lerpf(head_yaw, want_yaw, ease_slow * 1.6)
	head_pitch = lerpf(head_pitch, want_pitch, ease_slow * 1.6)
	head_roll = lerpf(head_roll, roll_goal, ease_slow)
	hang = lerpf(hang, float(FEELINGS[feeling]["hang"]), ease_slow)
	neck.rotation = Vector3(head_pitch + nod + hang, head_yaw, head_roll)
	neck.position.y = neck_y - curl * 0.1

	blink -= delta
	if blink < -0.12:
		blink = randf_range(1.5, 5.0)
	eye_open = lerpf(eye_open, eye_goal * float(FEELINGS[feeling]["eye"]) if blink > 0.0 else 0.0, 1.0 - exp(-delta * 30.0))
	var to_head := neck.global_transform.affine_inverse()
	for i in eyes.size():
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
	droop = lerpf(droop, droop_goal + float(FEELINGS[feeling]["droop"]), ease_slow)
	twitch = maxf(twitch - delta * 5.0, 0.0)
	if twitch <= 0.0 and randf() < delta * 0.35:
		twitch = 1.0
		twitch_side = randi() % 2
	var flop := sin(phase * 2.0) * 0.1 * gait
	for i in ears.size():
		var side := -1.0 if i == 0 else 1.0
		var jerk := sin(twitch * PI * 3.0) * 0.25 if twitch_side == i else 0.0
		ears[i].rotation = Vector3(-gait * 0.35, 0, -side * (ear_splay + droop * 0.75 + flop + jerk))

	tail.rotation.y = sin(anim_t * wag) * 0.55
	tail.rotation.x = sin(anim_t * 1.3) * 0.12 - curl * 0.4 - hover * minf(speed, 2.0) * 1.2
	tail.rotation.z = sin(anim_t * wag * 0.5) * hover

	if xrayed:
		_show_insides()
	if bubble.visible:
		bubble.global_basis = world.camera.global_basis
		bubble.position.y = top_y + 0.35 + sin(anim_t * 2.0) * 0.03
	if zzz[0].visible:
		var cam_right := world.camera.global_basis.x
		for i in 3:
			var u := fmod(anim_t * 0.4 + i / 3.0, 1.0)
			zzz[i].global_position = global_position + Vector3(0, (top_y - 0.4) * grow + u * 0.9, 0) + cam_right * (0.3 + sin(u * 5.0) * 0.12)
			zzz[i].modulate.a = sin(u * PI) * 0.9


# ---------------------------------------------------------------- under the scanner

# Turns it to a ghost of its outline with its insides showing, or back again
func xray(on: bool) -> void:
	if on == xrayed:
		return
	xrayed = on
	if insides.is_empty():
		_build_insides()
	for part in insides:
		part.visible = on
	if on:
		_ghost(self, Ps1.xray(Color(0.35, 0.85, 1.0)))
	else:
		for mi: MeshInstance3D in skin:
			if is_instance_valid(mi):
				mi.material_override = skin[mi]
		skin.clear()


func _ghost(node: Node, ghost: Material) -> void:
	if node == bubble or node in insides:
		return
	if node is MeshInstance3D:
		skin[node] = node.material_override
		node.material_override = ghost
	for child in node.get_children():
		_ghost(child, ghost)


# Where the scanner's notes point: "stomach", "heart", "lungs" or "brain", in the room
func inside_at(what: String) -> Vector3:
	if insides.is_empty():
		_build_insides()
	match what:
		"stomach": return stomach.global_position
		"heart": return heart.global_position
		"lungs": return lungs[0].global_position
		"brain": return brain.global_position
	return body_centre()


# A spine and ribs, a bone in each limb, and the four things worth knowing: a stomach that
# fills as it eats, a heart for the bond, lungs for how rested it is and a brain for how amused
func _build_insides() -> void:
	var white := Ps1.organ(Color(0.75, 0.85, 0.9))
	var chest := _pivot(torso, Vector3.ZERO)
	insides.append(chest)
	var top: float = neck_y + brain_at.y * 0.5
	_part(chest, _capsule(0.014, maxf(top - centre_y + 0.22, 0.1)), white, Vector3(0, (top + centre_y - 0.22) * 0.5, -0.06))
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.82
	hoop.outer_radius = 1.0
	hoop.rings = 8
	hoop.ring_segments = 3
	for i in 3:
		_part(chest, hoop, white, Vector3(0, centre_y + 0.14 - i * 0.07, 0), Vector3(0.14 - i * 0.012, 0.02, 0.11))
	for limb in legs + arms:
		insides.append(_part(limb, _capsule(0.012, 0.16), white, Vector3(0, -0.09, 0)))

	stomach = _pivot(chest, Vector3(0, centre_y - 0.11, 0.03))
	_part(stomach, _sphere(), Ps1.organ(Color(0.32, 0.2, 0.1)), Vector3.ZERO, Vector3(0.125, 0.105, 0.1))
	stomach_fill = _part(stomach, _sphere(), Ps1.organ(Color(1.0, 0.72, 0.2)), Vector3.ZERO, Vector3(0.11, 0.09, 0.085))
	stomach_fill.material_override.render_priority = 3
	heart = _part(chest, _sphere(), Ps1.organ(Color(1.0, 0.25, 0.35)), Vector3(0.06, centre_y + 0.08, 0.06), Vector3.ONE * 0.04)
	heart.material_override.render_priority = 3
	for side: float in [-1.0, 1.0]:
		lungs.append(_part(chest, _sphere(), Ps1.organ(Color(0.3, 0.6, 0.9)), Vector3(0.075 * side - 0.02, centre_y + 0.1, -0.005), Vector3(0.045, 0.07, 0.04)))
	var head := _pivot(neck, brain_at)
	insides.append(head)
	brain = _part(head, _sphere(), Ps1.organ(Color(0.9, 0.6, 0.75)), Vector3.ZERO, Vector3(0.075, 0.06, 0.07))
	for part in insides:
		part.visible = false


func _show_insides() -> void:
	# The stomach fills from the bottom
	var full := belly / 100.0
	stomach_fill.scale = Vector3(0.11 * lerpf(0.5, 1.0, full), 0.09 * maxf(full, 0.04), 0.085 * lerpf(0.5, 1.0, full))
	stomach_fill.position.y = -0.09 * (1.0 - full)
	# The heart is bigger and quicker the fonder it is
	var beat := maxf(sin(anim_t * lerpf(4.0, 9.0, love / 100.0)), 0.0)
	heart.scale = Vector3.ONE * lerpf(0.035, 0.068, love / 100.0) * (1.0 + beat * 0.25)
	# Lungs bright when it is rested, dull when it is worn out; they fill as it breathes
	var breath := 1.0 + sin(anim_t * (1.3 if curl > 0.5 else 2.6)) * 0.12
	for lung in lungs:
		lung.scale = Vector3(0.045, 0.07, 0.04) * breath
		lung.material_override.set_shader_parameter("tint", Color(0.08, 0.14, 0.24).lerp(Color(0.4, 0.85, 1.0), energy / 100.0))
	# The brain grey when it is bored, and lit up and flickering when it is having fun
	var spark := 0.85 + 0.15 * sin(anim_t * 23.0) * sin(anim_t * 7.0)
	brain.material_override.set_shader_parameter("tint", Color(0.3, 0.3, 0.34).lerp(Color(1.0, 0.65, 0.85) * spark, fun / 100.0))
