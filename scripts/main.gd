class_name Den
extends Node
## Cryptlins: a bare bulb in a brick basement and the little monsters that live under it.
## This builds the room, the lamp and the shelf of things, reads the touches and keeps the save.
## Up to four live here at once (see Resident): each starts as an egg (scripts/egg.gd) and is a
## cryptlin once it hatches. `who()` is the one in question when a single one is meant.
## Nothing is written on the screen to say how any of it works, and the notebook says little more:
## the keeper finds out by trying.

enum Grab { NONE, FLOOR, PET, BALL, EGG, SHELF, THING, SNACK, LAMP, SCANNER, BROOM, TAB }
enum Lamp { BRIGHT, LOW, HEAT, OFF }
# The part of the floor the pool lies over
enum Shore { NONE, BACK, LEFT, RIGHT }

# How far below where its cord is fixed the lamp's bulb hangs
const LAMP_DROP := 0.6
const LIGHT_REACH := 1.2
const LAMPS: Array[Dictionary] = [
	{"title": "bright", "energy": 3.0, "angle": 48.0, "colour": Color(1.0, 0.93, 0.78), "warmth": 1.0},
	{"title": "low", "energy": 1.1, "angle": 40.0, "colour": Color(0.95, 0.8, 0.58), "warmth": 0.5},
	{"title": "heat", "energy": 2.3, "angle": 44.0, "colour": Color(1.0, 0.4, 0.2), "warmth": 2.5},
	{"title": "off", "energy": 0.0, "angle": 40.0, "colour": Color(0.2, 0.17, 0.15), "warmth": 0.0},
]
const MAX_SNACKS := 3
# How many eggs and cryptlins the room holds at once
const MAX_RESIDENTS := 4
# How much a fight fought out lowers what each of the two thinks of the other, and the colour
# of the dust it raises
const FIGHT_SOURS := 12.0
const DUST := Color(0.6, 0.56, 0.5)
# How many of those that have died the notebook keeps a page for
const MAX_DEPARTED := 12
# Pairing off: what each must think of the other, how many days before either will again, how
# many hours after it the egg is laid, and (with nobody watching) how many hours a pair that
# would takes to get round to it
const PAIR_REGARD := 70.0
const PAIR_REST_DAYS := 3.0
const EGG_HOURS := 6.0
const PAIR_AWAY_HOURS := 8.0
const NAME_HEADS: Array[String] = ["Grub", "Mog", "Snag", "Fizz", "Bork", "Nib", "Skrit", "Womp", "Gloom", "Pim", "Zog", "Murk"]
const NAME_TAILS: Array[String] = ["nik", "let", "wort", "bo", "gle", "kin", "zle", "by", "mort", "ix"]
const EGG_SPOT := Vector3(0, 0, 0.3)
const GROUNDS: Array[String] = ["Flagstones", "Floorboards", "Moss", "Checkers", "Dirt", "Sand", "Gravel"]
# As in "it is happiest on ..."
const GROUND_PLAIN: Array[String] = ["flagstones", "floorboards", "moss", "checkered tiles", "dirt", "sand", "gravel"]
const SCAN_SECONDS := 9.0
# How long after a toy there is no end of has broken before there is another of its kind
const TOY_AGAIN_HOURS := 12.0
# The broom: how near a mess it has to be brought to set about it, how long the sweeping takes,
# and how long each stroke of it is
const BROOM_REACH := 0.32
const SWEEP_SECONDS := 0.7
const SWEEP_STROKE := 0.24
# The grounds a foot sinks into (moss, dirt, sand, gravel), and the most footprints there are at once
const SOFT_GROUNDS: Array[int] = [2, 4, 5, 6]
const MAX_TRACKS := 28
# How far up off the bottom edge the wheel rides on an upright phone, as parts of the height of
# the screen: about what a phone's browser draws over the bottom of a page, and no less than
# this much on a short screen, where there is less dark under the floor to put it in (that dark
# is so much of the height, and the wheel wants so many screen units of it)
const WHEEL_LIFT := 0.08
const WHEEL_LIFT_LEAST := 0.045
const WHEEL_SPARE := Vector2(0.175, 110.0)
# The scanner in use: how far in from the side of the screen and up from the shelf its body is
# held and how long it is drawn, all as parts of the screen's short side; how far from the eye;
# and the angle between its barrel and the line of sight to it
const SCANNER_IN := Vector2(0.2, 0.23)
const SCANNER_SIZE := 0.3
const SCANNER_AWAY := 3.0
const SCANNER_SLANT := 0.9
# The colour of each ground, for what gets dug out of it
const GROUND_TINTS: Array[Color] = [
	Color(0.4, 0.4, 0.42), Color(0.4, 0.28, 0.16), Color(0.2, 0.34, 0.14), Color(0.5, 0.5, 0.5),
	Color(0.3, 0.2, 0.13), Color(0.62, 0.52, 0.34), Color(0.4, 0.4, 0.42),
]

# Half the room's width and depth: walls left, right and behind, and you in front. The room is
# cut to the screen (see _fit): wide and low on a wide one, narrow, deep and tall on an upright
# phone, so that the lamp hangs near the top of the screen and the floor runs down to the shelf.
static var half := Vector2(2.9, 2.5)
# Where the lamp's cord is fixed
static var lamp_at := Vector3(0, 3.4, 0.1)
# Where the pool is, if there is one: it covers about half the floor, from the walls on its
# side to an edge that wanders across the room (see wade). SHORE_MIDS is how far across the
# room from the middle of it that edge runs, for each place the pool can be: a little short of
# the middle on either side, and a little past it at the back, which is a long way off.
static var shore: int = Shore.NONE
const SHORE_MIDS: Array[float] = [0.0, 0.2, -0.3, -0.3]

var save_path := "user://cryptlin.json"
# Set before it is added to the tree to choose what a new game's egg holds (tests); -1 for any
var first_kind := -1
# Tests turn this off: the card that asks for a name would be in the way of their fingers
var ask_names := true

var view: SubViewport
# The floor, walls, vent and pipe: built again whenever the room changes shape
var shell: Node3D
var cord: MeshInstance3D
var tall_room := false
var eye := Vector3(0, 4.0, 8.4)
var eye_on := Vector3(0, 1.0, 0)
var screen: TextureRect
var camera: Camera3D
var spot: SpotLight3D
var beam: ShaderMaterial
var lamp_head: Node3D
var bulb: MeshInstance3D
var bounce: OmniLight3D
var motes: CPUParticles3D
var crumb_puff: CPUParticles3D
var ripple: MeshInstance3D
var sfx: Sfx
# Everything that lives here, eggs and cryptlins, the eldest first; the number the next to
# arrive will be given; and the one last tapped or scanned
var residents: Array[Resident] = []
var next_id := 1
var chosen: Resident
# Those that have died, the longest gone first: each keeps a page in the notebook
var departed: Array[Resident] = []
# Grave markers the keeper has put away: the colour of each and whose it is
var markers_away: Array = []
# A fight, while one is going on: the ball of dust, the two in it, how long it has left to
# run, and how long till the next squeak out of it
var scuffle: Scuffle
var fighters: Array[Cryptlin] = []
var scuffle_left := 0.0
var scuffle_beat := 0.0
var ball: Ball
# Toys that were bought, have been out in the room and were put away again, by item id: how worn
# each is (see Ball.wear). And how worn the one of each kind there is no end of was when it was
# last put away.
# The thing or toy on the end of a finger that is held down over the wheel, on its way back
# there (its item id, or "" for none)
var stowing := ""
var toybox := {}
var scuffs := {}
# By item id, for a kind of toy there is no end of whose last one broke: when (unix time) there
# will be another
var broken := {}
# Inside a host page, how many of each of the things given once (Items.GIVEN) the keeper has had:
# the bones that have been fed, the ball that has been brought out (and is the room's from then on,
# like one that was bought, until it breaks)
var used := {}
var saved_toy := {}
# Whether the save had the wheel tucked away (see tuck)
var saved_tucked := false
var snacks: Array[Snack] = []
var decors: Array[Decor] = []
# What the cryptlins have left on the floor (see Mess)
var messes: Array[Mess] = []
# Footprints on the floor just now (see leave_print)
var tracks: Array[Track] = []
# What their knacks have done to the room for the moment (see Knack): how long the lamp has
# left to flicker, and the things that are shrivelled, each with how long it has left to be
var flicker := 0.0
var shrivelled := {}
# How strange the room is asked to be just now (a Cthulhu spawn asleep in it sets this every
# frame: see Knack), and how strange it has got
var strange := 0.0
var weird := 0.0
var nest: Node3D
var nest_pos := Vector3(-1.6, 0, -1.2)

var saved_decor: Array = []
var saved_mess: Array = []
# How long the game was shut, for them to live through when they are put back in the room
var away := 0.0
var _muted_at_start := false
# The room as it has been done up
var floor_style := 4
var nest_style := 0
var floor_mat: ShaderMaterial
# Played inside a site with a shop (see _bridge): what has been bought there, item id to how
# many (-1 for as many as you like). By itself the game has everything.
var embedded := false
# The save was written inside the station since eggs there came by post (see _load_game)
var posted := false
var stock := {}
var _on_message: JavaScriptObject
# What the page is told (see _post), for the tests to hear
signal told(message: Dictionary)
# Whether the page has put the game in front yet, and whether it is resting out of sight
var shown := false
var resting := false
var rested_at := 0.0

var clock := 0.0
var save_timer := 0.0
var lamp_mode: int = Lamp.BRIGHT
var light_on: bool:
	get:
		return lamp_mode != Lamp.OFF
var light_level := 1.0
var lamp_energy := 3.0
var lamp_angle := 48.0
var light_point := Vector3.ZERO
var light_goal := Vector3.ZERO
var light_dragging := false
var light_dragging_was := false
var hover_point := Vector3.ZERO
var hover_time := -100.0

var grab: int = Grab.NONE
var finger := -1
var press_time := 0.0
var release_time := -100.0
var press_floor := Vector3.ZERO
var moved := 0.0
var hold_point := Vector3.ZERO
var hold_vel := Vector3.ZERO
var carrying := false
var press_at := Vector2.ZERO
var last_at := Vector2.ZERO
# What a finger on the shelf is doing: which item it came down on, and whether it has started
# to slide the shelf along
var shelf_item := ""
var sliding := false
# The thing from the room (a Decor or the nest) or the bit of food that a finger has hold of
var held_thing: Node3D
var held_snack: Snack
var thing_new := false
# Whether the food being held was picked up off the floor, not pulled new off the row
var snack_lying := false
# The cryptlin or the egg a finger came down on
var held_pet: Cryptlin
var held_egg: Egg

# The scanner, the one it is pointed at, and which lower corner of the view it is held in (-1
# for the left). On it, the bar that runs up and down its readout; from it, its cone of light.
var scanned: Resident
var scanning := false
var scan_time := 0.0
var scan_side := -1.0
var scanner: Node3D
var scan_bar: MeshInstance3D
var scan_ray: Node3D
var ray_light: ShaderMaterial
# The broom and its dustpan, out in the room while there is sweeping to do: the mess they are at
# just now, and how long they have been at it
var broom: Node3D
var sweeping: Mess
var sweep_time := 0.0

var shelf: Shelf
var scan_notes: Control
var notebook: Notebook
var ask: PanelContainer
var ask_text: Label
var namer: PanelContainer
var name_edit: LineEdit
# The one the card that is up is about: being named, or about to be let go
var naming: Resident
var parting: Resident
var toast: Label
var card: StyleBoxFlat
# The test panel (see dev_toggle)
var dev: VBoxContainer
var dev_label: Label
var dev_egg: Button
var dev_taps := 0
var dev_tap_time := -10.0


func _ready() -> void:
	randomize()
	shore = Shore.NONE
	_load_game()
	_build_room()
	_build_lamp()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.muted = _muted_at_start
	_build_hud()
	shelf.tucked = saved_tucked
	shelf.sunk = 1.0 if saved_tucked else 0.0
	for d: Variant in saved_decor:
		if d is Dictionary and int(d.get("k", -1)) >= 0 and int(d["k"]) < Decor.IDS.size():
			_stand(int(d["k"]), Vector3(float(d.get("x", 0.0)), 0, float(d.get("z", 0.0))), float(d.get("r", 0.0)), Color.html(str(d.get("c", "808085"))), int(d.get("w", 0)))
	for m: Variant in saved_mess:
		if m is Dictionary and int(m.get("k", -1)) >= 0 and int(m["k"]) < Mess.LASTS.size():
			var laid := _lay_mess(int(m["k"]), Vector3(float(m.get("x", 0.0)), 0, float(m.get("z", 0.0))), float(m.get("t", 0.0)), Color.html(str(m.get("c", "4d331a"))), float(m.get("s", 1.0)))
			laid.visible = laid.gone() < 1.0
	if saved_toy.has("k") and int(saved_toy["k"]) >= 0 and int(saved_toy["k"]) < Ball.NAMES.size():
		# The toy that was left lying on the floor, as worn as it was
		var toy := Ball.new(int(saved_toy["k"]))
		toy.wear = clampf(float(saved_toy.get("w", 0.0)), 0.0, Ball.WORN_OUT - 1.0)
		toy.bought = bool(saved_toy.get("b", false))
		toy.position = in_room(Vector3(float(saved_toy.get("x", 0.0)), Ball.R, float(saved_toy.get("z", 0.0))), Ball.R)
		toy.show_wear()
		_set_ball(toy)
	get_viewport().size_changed.connect(_fit)
	_fit()
	if OS.has_feature("web") and str(JavaScriptBridge.eval("window.location.search", true)).contains("dev"):
		dev_toggle()
	for r in residents:
		if r.hatched:
			_spawn_pet(r, on_dry(Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.6, 0.8)), 0.3, 0.2))
		else:
			_lay_egg(r, false)
	# They have been living their lives while the game was shut (grown, asleep, hungry, glad to
	# see you: they show all that themselves)
	if away > 0.0:
		pass_time(away)
		away = 0.0
	_bridge()
	if embedded:
		_keep_own()
	# A new game, or a room with nobody left in it. Played by itself it is given one egg for
	# nothing. Inside a host page eggs are the keeper's own, out of the stock the page sends: the
	# room stands empty until one is laid from the wheel, which shows which thing that is (see
	# _sync).
	if residents.is_empty() and not embedded:
		new_egg(first_kind)
	_sync()


# Keeps a point on the floor inside the walls, `margin` clear of them
static func in_room(p: Vector3, margin := 0.0) -> Vector3:
	return Vector3(clampf(p.x, -half.x + margin, half.x - margin), p.y, clampf(p.z, -half.y + margin, half.y - margin))


# ---------------------------------------------------------------- the pool

# The parts of the floor the pool fits over in a room this shape: the back of any room, and
# either side of one wide enough to leave four of them room on the other
static func shores() -> Array[int]:
	var fit: Array[int] = [Shore.BACK]
	if half.x >= 2.4:
		fit.append_array([Shore.LEFT, Shore.RIGHT])
	return fit


# How far into one of those parts a place on the floor is, as a share of the way from the
# middle of the room to the wall
static func into(where: int, p: Vector3) -> float:
	match where:
		Shore.LEFT:
			return -p.x / half.x
		Shore.RIGHT:
			return p.x / half.x
	return -p.z / half.y


# The one of those parts that a place on the floor is furthest into
static func shore_near(p: Vector3) -> int:
	var best: int = Shore.BACK
	for where in shores():
		if into(where, p) > into(best, p):
			best = where
	return best


# The middle of the water, for a pool over that part of the floor
static func middle(where: int) -> Vector3:
	match where:
		Shore.LEFT:
			return Vector3((SHORE_MIDS[where] - half.x) * 0.5, 0, 0)
		Shore.RIGHT:
			return Vector3((half.x - SHORE_MIDS[where]) * 0.5, 0, 0)
	return Vector3(0, 0, (SHORE_MIDS[where] - half.y) * 0.5)


# A place on the floor from how far `along` the water's edge it is and how far `across` the room
# from the middle of it, away from the pool's side
static func place(along: float, across: float) -> Vector3:
	match shore:
		Shore.LEFT:
			return Vector3(across, 0, along)
		Shore.RIGHT:
			return Vector3(-across, 0, along)
	return Vector3(along, 0, across)


# How far across the room the water's edge is at a point along it: a line that wanders (the
# same line shore.gdshaderinc draws, which has to be changed with it)
static func _edge(along: float) -> float:
	return SHORE_MIDS[shore] + sin(along * 1.3 + 0.7 + shore * 1.9) * 0.2 + sin(along * 3.1 + 2.1) * 0.1 + sin(along * 6.7 + 4.0) * 0.04


# The place this far `out` into the water from its edge (or back from it, below zero)
static func at_shore(along: float, out: float) -> Vector3:
	return place(along, _edge(along) - out)


# The shape test. How far out into the pool a place on the floor is, from the water's edge:
# above zero in the water, below it on dry floor (and with no pool, as far below as can be)
static func wade(p: Vector3) -> float:
	match shore:
		Shore.BACK:
			return _edge(p.x) - p.z
		Shore.LEFT:
			return _edge(p.z) - p.x
		Shore.RIGHT:
			return _edge(p.z) + p.x
	return -INF


# How deep the water is at a place: nothing on dry floor, shelving down from the edge
static func deep(p: Vector3) -> float:
	return clampf(wade(p) * Decor.SHELVE, 0.0, Decor.DEEP)


# Straight across from a place to the water's edge: `back` from it on the dry side (or, below
# zero, that far into the shallows)
static func shore_by(p: Vector3, back := 0.0) -> Vector3:
	if shore == Shore.NONE:
		return p
	var over := wade(p) + back
	return p + (Vector3(0, 0, over) if shore == Shore.BACK else Vector3(over if shore == Shore.LEFT else -over, 0, 0))


# Keeps a point on dry floor: inside the walls, `margin` clear of them, and out of the pool,
# `clear` back from the water's edge
static func on_dry(p: Vector3, margin := 0.0, clear := 0.0) -> Vector3:
	var kept := in_room(p, margin)
	return shore_by(kept, clear) if wade(kept) > -clear else kept


# ---------------------------------------------------------------- who lives here

# The one in question, when a single one is meant: the one last tapped or scanned, or else the
# eldest. Never null once the room is built: an empty room is given an egg.
func who() -> Resident:
	if chosen != null and chosen in residents:
		return chosen
	return residents[0] if not residents.is_empty() else null


# The cryptlins in the room: not the eggs, nor one that is on its way out
func pets() -> Array[Cryptlin]:
	var all: Array[Cryptlin] = []
	for r in residents:
		if r.pet != null and not r.leaving:
			all.append(r.pet)
	return all


# The cryptlin nearest a place on the floor, or null if there is none
func nearest_pet(to: Vector3) -> Cryptlin:
	var best: Cryptlin = null
	for pet in pets():
		if best == null or pet.position.distance_squared_to(to) < best.position.distance_squared_to(to):
			best = pet
	return best


func room_for_more() -> bool:
	return residents.size() < MAX_RESIDENTS


# Time that went by with nobody looking (the game shut, or covered by the page it is played
# in): each of them lives through it, and is found asleep in its bed if that is how it ended
func pass_time(seconds: float) -> void:
	end_fight(true)
	# A pair that would pair off may well have done, with nobody there to see
	var all := pets()
	for i in all.size():
		for j in range(i + 1, all.size()):
			if would_pair(all[i], all[j]) and randf() < 1.0 - exp(-seconds / (PAIR_AWAY_HOURS * Cryptlin.HOUR)):
				paired(all[i], all[j], seconds * randf_range(0.2, 0.8))
	for pet in pets():
		if pet.pass_time(seconds, not light_on):
			# (in the nest, or for one that lives in water at the edge of the pool)
			pet.position = pet._bed() + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
			pet._enter(Cryptlin.State.SLEEP)
		elif pet.state == Cryptlin.State.SLEEP:
			pet._enter(Cryptlin.State.IDLE)
	# Those that slept the time out in the one nest come through it better friends
	for a in pets():
		for b in pets():
			if a != b and a.state == Cryptlin.State.SLEEP and b.state == Cryptlin.State.SLEEP and regard(a, b) >= 35.0:
				warm(a, b, minf(seconds / Cryptlin.HOUR * Cryptlin.SLEEP_WARMS, 4.0))
	_lay_due()
	_sync()


# ---------------------------------------------------------------- how they get on

# What one cryptlin thinks of another, 0 to 100. Until something has passed between them it is
# a little either side of indifferent, by how their natures suit.
func regard(a: Cryptlin, b: Cryptlin) -> float:
	return float(a.me.regard.get(str(b.me.id), 50.0 + a.suits(b)))


# One of them thinks better of another (or worse, below zero) for something that has happened
func warm(a: Cryptlin, b: Cryptlin, by: float) -> void:
	a.me.regard[str(b.me.id)] = clampf(regard(a, b) + by, 0.0, 100.0)


# How two of them stand with each other: no better than the one that thinks less of the other
func standing(a: Cryptlin, b: Cryptlin) -> float:
	return minf(regard(a, b), regard(b, a))


# Two of them have fallen out badly enough to fight: a short scuffle, out of which one comes
# the loser. A grown one does not fight a baby: it cuffs it out of the way, and that is that.
func start_fight(a: Cryptlin, b: Cryptlin) -> void:
	if scuffle != null:
		return
	if a.is_baby() != b.is_baby():
		var small := a if a.is_baby() else b
		var big := b if a.is_baby() else a
		small.cuffed(big)
		big._cry("grumble")
		small.fight_cooldown = 60.0
		big.fight_cooldown = 60.0
		warm(small, big, -3.0)
		return
	if finger != -1 and grab == Grab.PET:
		_release()
	if scanning and scanned.pet in [a, b]:
		stop_scan()
	var tints: Array[Color] = [a.fur.get_shader_parameter("tint"), b.fur.get_shader_parameter("tint")]
	scuffle = Scuffle.new(tints, (a.grow + b.grow) * 0.5)
	add_child(scuffle)
	# (on dry floor, wherever the two of them were standing)
	scuffle.position = on_dry(Vector3((a.position.x + b.position.x) * 0.5, 0, (a.position.z + b.position.z) * 0.5), 0.3, 0.3)
	scuffle_left = randf_range(2.6, 3.8)
	fighters = [a, b]
	a.partner = b
	b.partner = a
	for f in fighters:
		f._enter(Cryptlin.State.SCUFFLE)
		f.visible = false
	crumbs(scuffle.position + Vector3(0, 0.3, 0), DUST)


# The scuffle while it lasts: squeaks and grumbles out of it, and an end to it when it has run
# its course, or sooner if the keeper drops food on it or swings the lamp over it
func _tick_fight(delta: float) -> void:
	scuffle_left -= delta
	scuffle_beat -= delta
	for f in fighters:
		f.position = scuffle.position
	if scuffle_beat <= 0.0:
		scuffle_beat = randf_range(0.2, 0.38)
		var voice: String = ["squeak", "grumble", "squeak", "chirp"].pick_random()
		fighters.pick_random()._cry(voice, randf_range(0.9, 1.3))
		crumbs(scuffle.position + Vector3(0, 0.2, 0), DUST)
	var broken := light_dragging and light_point.distance_to(scuffle.position) < 0.8
	for s in snacks:
		if s.position.y < 0.5 and Vector2(s.position.x - scuffle.position.x, s.position.z - scuffle.position.z).length() < 0.7:
			broken = true
	if broken or scuffle_left <= 0.0:
		end_fight(broken)


# The dust settles. Fought out, the weaker comes off worse and backs away, and they think the
# less of each other for it; broken up by the keeper, nobody is hurt and less harm is done.
func end_fight(broken: bool) -> void:
	if scuffle == null:
		return
	var at := scuffle.position
	crumbs(at + Vector3(0, 0.3, 0), DUST)
	scuffle.queue_free()
	scuffle = null
	var a := fighters[0]
	var b := fighters[1]
	fighters.clear()
	var apart := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.5
	a.position = on_dry(at + apart, 0.3, 0.1)
	b.position = on_dry(at - apart, 0.3, 0.1)
	for f: Cryptlin in [a, b]:
		f.visible = true
		f.fight_cooldown = randf_range(90.0, 150.0)
	warm(a, b, -FIGHT_SOURS * (0.3 if broken else 1.0))
	warm(b, a, -FIGHT_SOURS * (0.3 if broken else 1.0))
	if broken:
		for f: Cryptlin in [a, b]:
			f._enter(Cryptlin.State.STARTLED, 1.0)
			f.feel(Cryptlin.Feeling.SCARED, 3.0)
	else:
		var loser := a if a.might() < b.might() else b
		var winner := b if loser == a else a
		winner._enter(Cryptlin.State.STARTLED, 0.8)
		winner._cry("grumble")
		winner.feel(Cryptlin.Feeling.GRUMPY, 5.0)
		loser.beaten(winner)
	save_game()


# ---------------------------------------------------------------- pairing off

# Close kin: one is the other's parent, or they have a parent in common
func kin(a: Resident, b: Resident) -> bool:
	if a.id in b.parents or b.id in a.parents:
		return true
	for parent in a.parents:
		if parent in b.parents:
			return true
	return false


# Whether two cryptlins would pair off, which is the only way an egg is ever come by between
# them. Both must be grown. Each must think well of the other: one willing is not enough. They
# must not be close kin. And both must want for nothing: fed, well, rested, at home in the room,
# and not lately paired nor with an egg on the way.
func would_pair(a: Cryptlin, b: Cryptlin) -> bool:
	if a == b or a.is_baby() or b.is_baby():
		return false
	if regard(a, b) < PAIR_REGARD or regard(b, a) < PAIR_REGARD:
		return false
	if kin(a.me, b.me):
		return false
	var now := Time.get_unix_time_from_system()
	for pet: Cryptlin in [a, b]:
		if pet.belly < 50.0 or pet.health < 70.0 or pet.energy < 35.0 or pet.comfort < 55.0:
			return false
		if not pet.me.expecting.is_empty() or now - pet.me.paired < PAIR_REST_DAYS * 86400.0:
			return false
	return true


# Two of them have paired off (see Cryptlin._pair), `ago` seconds since: one or other of them
# will lay an egg some hours on. What will be in it is settled now: the kind of one parent and
# the size of its head, the coat and markings of the other, a nature from one of them, and the
# rest of its look and its tastes from a seed mixed out of both of theirs.
func paired(a: Cryptlin, b: Cryptlin, ago := 0.0) -> void:
	var when := Time.get_unix_time_from_system() - ago
	a.me.paired = when
	b.me.paired = when
	warm(a, b, 2.0)
	warm(b, a, 2.0)
	var pair: Array[Cryptlin] = [a, b]
	pair.shuffle()
	var egg := Resident.new()
	egg.kind = pair[0].kind
	egg.fur = pair[1].fur_colour.to_html(false)
	egg.nature = pair.pick_random().nature
	egg.looks = {"marks": pair[1].marks, "head": pair[0].shape["head"]}
	egg.look_seed = Cryptlin.OLD_SEEDS + 1 + (a.look_seed * 31 + b.look_seed * 17 + next_id * 7919) % 1000000
	egg.parents = [a.me.id, b.me.id]
	egg.parent_names = [a.me.name, b.me.name]
	pair.pick_random().me.expecting = {"due": when + EGG_HOURS * Cryptlin.HOUR, "egg": egg.to_save()}
	save_game()


# Any egg that is due is laid: in the nest, if the room has space for one more (and not at all
# if it has not)
func _lay_due() -> void:
	var now := Time.get_unix_time_from_system()
	for r in residents.duplicate():
		if r.expecting.is_empty() or now < float(r.expecting.get("due", 0.0)):
			continue
		var laid: Variant = r.expecting.get("egg")
		r.expecting = {}
		if laid is Dictionary and room_for_more():
			var egg := Resident.from_save(laid)
			egg.id = next_id
			next_id += 1
			egg.hatched = false
			egg.at = nest_pos + Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.12, 0.12))
			residents.append(egg)
			_lay_egg(egg, false)
			crumbs(egg.egg.centre(), Egg.SHELLS[egg.kind])
			sfx.play("knock", 0.8, -4.0)
			# (whoever laid it comes to have a look at it, if it is up)
			if r.pet != null and not r.leaving:
				r.pet.look_over(nest_pos + Vector3(0, 0, 0.5), 1, "")
		save_game()


# ---------------------------------------------------------------- dying

# One of them has come to the end (see Cryptlin._dying): it is out of everybody's hands, and no
# longer one to be called, fed or counted
func dying(pet: Cryptlin) -> void:
	if pet in fighters:
		end_fight(true)
	if finger != -1 and held_pet == pet:
		_release()
	if scanned == pet.me:
		stop_scan()
	pet.me.leaving = true
	_sync()


# It is gone. A marker of its own stands where it lay, and its page stays in the notebook.
func died(pet: Cryptlin) -> void:
	var r := pet.me
	r.needs = pet.get_needs()
	r.lived = pet.age
	r.died = Time.get_unix_time_from_system()
	r.pet = null
	r.leaving = false
	residents.erase(r)
	departed.append(r)
	if departed.size() > MAX_DEPARTED:
		departed.pop_front()
	for other in residents:
		other.regard.erase(str(r.id))
	var marker := _stand(Decor.Kind.MARKER, pet.position, randf_range(-0.3, 0.3), pet.fur.get_shader_parameter("tint"), r.id)
	crumbs(marker.position + Vector3(0, 0.1, 0), DUST)
	if pets().is_empty():
		_clear_toys()
	# (the last of them, in a room played by itself: an egg comes for nothing)
	if residents.is_empty() and not embedded:
		new_egg(-1, r.kind)
	_sync()
	save_game()


# ---------------------------------------------------------------- eggs and hatchlings

# Drops a new egg into the room: of a given kind, or of any that is not here already (nor
# `not_kind`, the kind of one that has just gone)
func new_egg(kind := -1, not_kind := -1) -> Resident:
	var r := Resident.new()
	r.id = next_id
	next_id += 1
	r.look_seed = Cryptlin.new_seed()
	r.kind = kind
	if kind < 0:
		var fresh: Array[int] = []
		for k in Cryptlin.KINDS.size():
			if k != not_kind and not residents.any(func(other: Resident) -> bool: return other.kind == k):
				fresh.append(k)
		r.kind = fresh.pick_random()
	r.at = _clear_spot(EGG_SPOT, 1.1)
	residents.append(r)
	_lay_egg(r, true)
	return r


# The egg on the shelf: one more in the room, if there is room
func lay_egg() -> void:
	if not room_for_more() or not owns("egg"):
		sfx.play("click", 0.7)
		return
	if not light_on:
		set_lamp(Lamp.BRIGHT)
	new_egg()
	_spend("egg")
	sfx.play("click")
	save_game()


func _lay_egg(r: Resident, from_above: bool) -> void:
	var egg := Egg.new()
	egg.world = self
	egg.kind = r.kind
	egg.look_seed = r.look_seed
	egg.warmth = r.warmth
	add_child(egg)
	r.egg = egg
	r.hatched = false
	egg.position = on_dry(r.at if r.at != Vector3.INF else EGG_SPOT, 0.4, 0.4)
	if from_above:
		egg.drop(egg.position + Vector3(0, 5.5, 0))
	egg.cracked.connect(_on_cracked.bind(r))
	egg.hatched.connect(_on_hatched.bind(r))
	_sync()


func _on_cracked(_stage: int, r: Resident) -> void:
	crumbs(r.egg.centre(), Egg.SHELLS[r.kind])
	Input.vibrate_handheld(30)


func _on_hatched(r: Resident) -> void:
	var at := r.egg.position
	crumbs(r.egg.centre(), Egg.SHELLS[r.kind])
	if scanned == r:
		stop_scan()
	r.egg.burst()
	r.egg = null
	r.hatched = true
	r.born = Time.get_unix_time_from_system()
	r.needs = {"belly": 55.0, "fun": 50.0, "energy": 85.0, "love": 10.0, "age": 0.0}
	r.known = {}
	r.name = roll_name()
	_spawn_pet(r, at)
	r.pet.boop()
	r.pet.hearts.emitting = true
	sfx.play("crack", 0.7)
	Input.vibrate_handheld(60)
	# Once it has had its moment, it wants a name
	if ask_names:
		get_tree().create_timer(3.5).timeout.connect(open_namer.bind(r))
	save_game()


func _spawn_pet(r: Resident, at: Vector3) -> void:
	var pet := Cryptlin.new()
	pet.world = self
	pet.me = r
	pet.kind = r.kind
	pet.look_seed = r.look_seed
	pet.set_needs(r.needs)
	add_child(pet)
	pet.position = at
	pet.comfort = comfort_of(pet)
	pet.left.connect(_on_left.bind(r))
	r.pet = pet
	_sync()


func roll_name() -> String:
	return NAME_HEADS.pick_random() + NAME_TAILS.pick_random()


# The card that asks what one of them is to be called: the one that has just hatched, or the
# one whose page the notebook is open at. It has a name already (made up when it hatched), so
# shutting the card without typing keeps that one.
func open_namer(r: Resident) -> void:
	if not r in residents or r.pet == null or r.leaving or ask.visible or namer.visible:
		return
	if finger != -1:
		_release()
	stop_scan()
	notebook.visible = false
	naming = r
	name_edit.text = r.name
	namer.visible = true
	sfx.play("click")


func _name_roll() -> void:
	name_edit.text = roll_name()
	sfx.play("click", 1.2)


func _name_done(_typed := "") -> void:
	if not namer.visible:
		return
	namer.visible = false
	name_edit.release_focus()
	var typed := name_edit.text.strip_edges().left(14)
	if typed != "":
		naming.name = typed
	sfx.play("click", 0.8)
	_sync()
	save_game()


# "Let go" on a cryptlin's page of the notebook: asks first, since it sends it away for good
func ask_let_go(r: Resident) -> void:
	end_fight(true)
	if not r in residents or r.pet == null or r.leaving:
		return
	if finger != -1:
		_release()
	stop_scan()
	notebook.visible = false
	parting = r
	ask_text.text = "Let %s go off into the dark,
and not come back?" % r.name
	ask.visible = true
	sfx.play("click")


func _answer(yes: bool) -> void:
	ask.visible = false
	sfx.play("click", 0.8)
	if yes and parting in residents and parting.pet != null and not parting.leaving:
		parting.leaving = true
		parting.pet.leave()
		_sync()


func _on_left(r: Resident) -> void:
	r.pet.queue_free()
	for other in residents:
		other.regard.erase(str(r.id))
	r.pet = null
	residents.erase(r)
	if pets().is_empty():
		_clear_toys()
	if residents.is_empty() and not embedded:
		# Nobody is left: an egg comes for nothing, and never the same kind twice running (but
		# not inside a host page, where eggs are the keeper's own: see _ready)
		if not light_on:
			set_lamp(Lamp.BRIGHT)
		new_egg(-1, r.kind)
	_sync()
	save_game()


# ---------------------------------------------------------------- test panel

# A panel for trying every kind without waiting on eggs. Opened by five quick taps in the top
# left corner, the ` key, or ?dev on the address of the web build.
func dev_toggle() -> void:
	dev.visible = not dev.visible
	_sync()
	_say("Test panel on" if dev.visible else "Test panel off")


# Turns the one in question into a cryptlin of this kind at once, or its egg
func dev_show(kind: int, as_egg := false, new_look := false) -> void:
	end_fight(true)
	if finger != -1:
		_release()
	stop_scan()
	ask.visible = false
	namer.visible = false
	var r := _dev_one()
	var at := EGG_SPOT
	if r.body() != null:
		at = Vector3(r.body().position.x, 0, r.body().position.z)
		r.body().queue_free()
	r.pet = null
	r.egg = null
	r.leaving = false
	carrying = false
	r.known = {}
	_clear_toys()
	r.kind = posmod(kind, Cryptlin.KINDS.size())
	if new_look:
		r.look_seed = Cryptlin.new_seed()
	r.warmth = 0.0
	r.at = at
	if not light_on:
		set_lamp(Lamp.BRIGHT)
	if as_egg:
		r.name = ""
		_lay_egg(r, true)
	else:
		r.hatched = true
		r.needs = {"belly": 60.0, "fun": 55.0, "energy": 85.0, "love": 40.0, "age": Cryptlin.GROW_AGE}
		r.born = Time.get_unix_time_from_system() - Cryptlin.GROW_AGE
		if r.name == "":
			r.name = roll_name()
		_spawn_pet(r, at)
	save_game()


# The one the panel works on: the one in question, or in an empty room an egg put there for it
func _dev_one() -> Resident:
	return who() if who() != null else new_egg()


func _dev_step(by: int) -> void:
	dev_show(_dev_one().kind + by)


func _dev_look() -> void:
	dev_show(_dev_one().kind, who().egg != null, true)


# With a cryptlin: its egg instead. With an egg: hatch it now.
func _dev_egg() -> void:
	if _dev_one().egg != null:
		who().egg.warmth = 100.0
	else:
		dev_show(who().kind, true)


# Baby to adult and back
func _dev_age() -> void:
	var pet := _dev_one().pet
	if pet != null:
		pet.age = 0.0 if not pet.is_baby() else Cryptlin.GROW_AGE
		_sync()


# A day goes by, as if the game had been shut for it
func _dev_day() -> void:
	pass_time(86400.0)
	for r in residents:
		r.born -= 86400.0
	_say("A day later")


func _clear_toys() -> void:
	for s in snacks:
		s.queue_free()
	snacks.clear()
	_clear_ball()
	_sync()


# ---------------------------------------------------------------- what a cryptlin lets on

# One of them has shown a taste for the first time: "food" (its favourite), "yuck", "toy",
# "ground", "lamp", a thing in the room it likes ("decor+rock") or cannot stand ("decor-rock"),
# or whether it is one that needs water ("water")
func learned(pet: Cryptlin, what: String) -> void:
	var known := pet.me.known
	if known.get(what, false):
		return
	# (nothing is said about it on the screen: how it took it shows over its head, and what was
	# learned is written in the notebook for whoever looks)
	known[what] = true
	_sync()
	save_game()

func fed_up() -> void:
	pass # (it shows it: nothing is written up)


func grew_up() -> void:
	sfx.play("coo", 0.7)
	Input.vibrate_handheld(60)
	_sync()
	save_game()


# How well the room suits a cryptlin, 0 to 100: the ground and the lamp it wants, the things
# it likes to have about (and not the one it hates), not being left with bare floor or in its
# own mess, and water
# if it is one that needs it
func comfort_of(who: Cryptlin) -> float:
	var c := 35.0
	if floor_style == who.fav_ground:
		c += 18.0
	if lamp_mode == who.fav_lamp:
		c += 12.0
	# One from underground is as well off in the dark, and never at ease under the bright lamp
	if who.likes.get("dim", false):
		c += 12.0 if lamp_mode == Lamp.OFF else (-14.0 if lamp_mode == Lamp.BRIGHT else 0.0)
	var others := 0
	for d in decors:
		if d.kind in who.like_decor:
			c += 14.0
		elif d.kind == who.hate_decor:
			c -= 18.0
		else:
			others += 1
	# A yeti cannot bear the heat lamp
	if who.kind == Cryptlin.Kind.YETI and lamp_mode == Lamp.HEAT:
		c -= 22.0
	# A kind that lives in water is never at home without a pool to get into
	if who.needs_water():
		c += 14.0 if decor_of(Decor.Kind.POOL) != null else -24.0
	# What it has left lying about spoils the place for it: droppings most, puddles a little
	var foul := 0.0
	for m in messes:
		if m.kind != Mess.Kind.HEAP:
			foul += 9.0 if m.kind == Mess.Kind.DROPPING else 3.0
	return clampf(c + mini(others, 3) * 4.0 - minf(foul, 36.0), 0.0, 100.0)


# ---------------------------------------------------------------- the room's things

# Whether something is on the shelf: everything when the game is played by itself; inside a
# site with a shop, what comes free and what has been bought
func owns(id: String) -> bool:
	# (what is being put away has a place on it, whatever else)
	if id == stowing and id != "":
		return true
	# (a grave marker is never bought: it is on the shelf while one has been put away)
	if id in Items.KEPT:
		return not markers_away.is_empty()
	# (nor is a toy that has been out in the room and was put away again: it is the room's)
	if not toybox.get(id, []).is_empty():
		return true
	# (and a toy of a kind there is no end of is not to be had for a while after one has broken,
	# except by the test panel)
	if broken.has(id) and left_of(id) < 0 and not (dev != null and dev.visible):
		if Time.get_unix_time_from_system() < float(broken[id]):
			return false
		broken.erase(id)
	return _has_all() or id in Items.FREE or left_of(id) != 0


# Whether a finger is far enough down the screen to be putting what it holds away: on the wheel,
# or anywhere in the lower part of the strip the wheel is in (its rim falls away to the corners,
# and a thing let go there is meant for it all the same)
func _over_wheel(at: Vector2) -> bool:
	return shelf.has_point(at) or (shelf.visible and at.y > shelf.global_position.y + (shelf.size.y - shelf.drop) * 0.35)


# Tucks the wheel of things away off the bottom of the screen, so that the whole room can be
# seen, or brings it back: by the tab in its corner, a flick down on it, or a flick up from the
# bottom edge. The scanner and the broom are put back first. It is not to be tucked away while
# an empty room inside a host page has an egg held out on it (see _sync). Kept in the save.
func tuck(away: bool) -> void:
	if away and _egg_waiting():
		away = false
	if shelf.tucked == away:
		return
	if away:
		stop_scan()
		if broom.visible and grab != Grab.BROOM:
			if sweeping != null:
				sweeping.scale = Vector3.ONE
			sweeping = null
			broom.visible = false
		shelf.let_go()
		shelf.bring("")
	shelf.tucked = away
	sfx.play("click", 0.8 if away else 1.1, -8.0)
	save_game()


# An empty room inside a host page, and an egg in stock to lay in it
func _egg_waiting() -> bool:
	return embedded and residents.is_empty() and owns("egg")


# A thing on the end of a finger has come down over the wheel (or, with "", gone back up): the
# wheel makes room for it at its place and turns to show where that is
func _offer(id: String) -> void:
	# (tucked away, it comes back up for the thing to be put away on)
	if id != "":
		tuck(false)
	if id == stowing:
		return
	stowing = id
	_sync()
	shelf.bring(id)


# Whether a thing is out in the room just now, and so not on the wheel: a thing standing there,
# the nest and the ground that are in use, the toy on the floor. What gets used up (food, eggs)
# and the tools are never off the wheel for being in use.
func in_room_now(id: String) -> bool:
	# (what is on the end of a finger over the wheel is as good as back on it)
	if id == stowing:
		return false
	var item := Items.find(id)
	var n: int = item["n"]
	match item["group"]:
		"decor":
			return decor_of(n) != null and not id in Items.KEPT
		"nest":
			return n == nest_style
		"ground":
			return n == floor_style
		"toy":
			return ball != null and ball.kind == n
	return false


# How many of a thing that gets used up are left, or -1 for no end of them
func left_of(id: String) -> int:
	if _has_all() or id in Items.FREE:
		return -1
	var bought := int(stock.get(id, 0))
	# (what was given and has not been used yet is so many more than were bought)
	return bought + _given(id) if bought >= 0 else bought


# How many the keeper still has of what they were given of a thing (Items.GIVEN)
func _given(id: String) -> int:
	return maxi(int(Items.GIVEN.get(id, 0)) - int(used.get(id, 0)), 0)


# Everything without end: the game played by itself, or the test panel open (inside a page with
# a shop, too: what is used while it is open is not taken from stock, nor the page told)
func _has_all() -> bool:
	return not embedded or (dev != null and dev.visible)


func _spend(id: String) -> void:
	if left_of(id) <= 0:
		return
	if _given(id) > 0:
		# What was given goes first, and is none of the page's business: it is not told
		used[id] = int(used.get(id, 0)) + 1
		save_game()
	else:
		stock[id] = int(stock.get(id, 0)) - 1
		_post({"type": "CRYPTLINS_USED", "item": id})
	_sync()


# One of a thing that gets used up is put back unused (the page is not told)
func _unspend(id: String) -> void:
	if left_of(id) < 0:
		return
	if int(used.get(id, 0)) > 0:
		used[id] = int(used[id]) - 1
	else:
		stock[id] = int(stock.get(id, 0)) + 1
	_sync()


# Inside a host page the ball is given once (Items.GIVEN) and is the room's own like one that was
# bought. One from a save made before that was so, lying on the floor or put away, is that one;
# a keeper who had neither has theirs still to come, whatever had broken.
func _keep_own() -> void:
	for id: String in Items.GIVEN:
		if Items.find(id)["group"] != "toy":
			continue
		if ball != null and not ball.bought and Items.id_of("toy", ball.kind) == id:
			ball.bought = true
			used[id] = Items.GIVEN[id]
		elif scuffs.has(id):
			if not toybox.has(id):
				toybox[id] = []
			toybox[id].append(scuffs[id])
			used[id] = Items.GIVEN[id]
		scuffs.erase(id)
		broken.erase(id)


# A tap on something on the shelf (or its key): the quick way to use it
func use(id: String) -> void:
	var item := Items.find(id)
	if item.is_empty() or not owns(id) or _modal():
		return
	var n: int = item["n"]
	match item["group"]:
		"tool":
			if id == "notebook":
				notebook.open()
			elif id == "broom":
				sweep_one()
			elif scanning:
				stop_scan()
			else:
				start_scan()
		"food":
			feed(n)
		"toy":
			play_ball(n)
		"egg":
			lay_egg()
		"decor" when id == "marker":
			_bring_marker(_free_spot(Decor.RADII[n]))
			sfx.play("thud", 1.1, -6.0)
			_sync()
			save_game()
		"decor":
			# In if it is out, out if it is in
			var there := decor_of(n)
			if there != null:
				remove_decor(there)
			else:
				# (the pool over whichever part of the floor has least on it)
				place_decor(n, middle(_emptiest_shore()) if n == Decor.Kind.POOL else _free_spot(Decor.RADII[n]))
		"nest":
			set_nest(n)
		"ground":
			set_ground(n)


# Drops something to eat into the light: a given food, or any
func feed(which := -1, at := Vector3.INF) -> void:
	if pets().is_empty():
		sfx.play("click", 0.7)
		return
	var kind := which if which >= 0 else randi() % Snack.NAMES.size()
	var id := Items.id_of("food", kind)
	if snacks.size() >= MAX_SNACKS or not owns(id):
		sfx.play("click", 0.7)
		return
	if at == Vector3.INF:
		var a := randf() * TAU
		at = in_room(light_point + Vector3(cos(a), 0, sin(a)) * sqrt(randf()) * 1.3, 0.3) + Vector3(0, 4.5, 0)
	var snack := Snack.new(kind)
	add_child(snack)
	snack.drop(at)
	_serve(snack)
	sfx.play("click")


# A bit of food let go of in the room: it is for whichever of them gets there first
func _serve(snack: Snack) -> void:
	snack.thud.connect(func(strength: float) -> void: sfx.play("thud", 1.3, clampf(strength * 2.0 - 16.0, -24.0, -4.0)))
	snack.splashed.connect(func() -> void: splash(snack.position))
	snacks.append(snack)
	_spend(Items.id_of("food", snack.kind))


# Throws a toy in: a given one, or whichever is out already (the ball, if none is)
func play_ball(which := -1) -> void:
	if pets().is_empty():
		sfx.play("click", 0.7)
		return
	# (one the keeper has not got is not to be had by asking: nothing is said, it only clicks)
	if (ball == null or (which >= 0 and which != ball.kind)) and not owns(Items.id_of("toy", maxi(which, 0))):
		sfx.play("click", 0.7)
		return
	if ball != null and which >= 0 and which != ball.kind:
		_clear_ball()
	if ball == null:
		_new_ball(maxi(which, 0))
		ball.position = Vector3(randf_range(-1.0, 1.0), 1.5, half.y - 0.2)
		ball.vel = Vector3(randf_range(-0.8, 0.8), 2.4, -3.6) * ball.heft
	else:
		var a := randf() * TAU
		ball.vel += Vector3(cos(a) * 2.5, 4.2, sin(a) * 2.5) * ball.heft
	_notice_ball()
	sfx.play("click")
	_sync()


# The keeper has thrown the toy or taken hold of it: worth a chase to any of them
func _notice_ball() -> void:
	for pet in pets():
		pet.notice_ball()


# A toy comes out into the room: one that was put away, if there is one, as worn as it was; or
# else one out of what was bought, which is then the room's and no longer the shop's; or else,
# of a kind there is no end of, the one there always is
func _new_ball(which: int) -> void:
	var id := Items.id_of("toy", which)
	var toy := Ball.new(which)
	if not toybox.get(id, []).is_empty():
		toy.bought = true
		toy.wear = float(toybox[id].pop_back())
	elif left_of(id) > 0:
		toy.bought = true
		_spend(id)
	else:
		toy.wear = float(scuffs.get(id, 0.0))
	toy.show_wear()
	_set_ball(toy)


func _set_ball(toy: Ball) -> void:
	ball = toy
	add_child(ball)
	ball.bounced.connect(func(strength: float) -> void:
		sfx.play(toy.sound, toy.pitch, clampf(strength * 3.0 - 16.0, -24.0, -3.0))
		if wade(toy.position) > 0.0:
			splash(toy.position))


# One of them has had a kick at the toy, which wears it; and with wear enough it breaks
func wear_toy(toy: Ball, by: Cryptlin) -> void:
	if toy != ball:
		return
	toy.wear += Ball.WEARS[toy.kind] * by.rough()
	toy.show_wear()
	if toy.wear >= Ball.WORN_OUT:
		break_toy(by)


# The toy comes apart: a snap, the pieces of it flying, and whichever of them is near by taking
# it as its nature has it. Then it is gone, and its bits lie on the floor to be swept up. It does
# not go back on the wheel: one that was bought is no more, and of a kind there is no end of
# there is not another to be had for some hours (see owns).
func break_toy(by: Cryptlin = null) -> void:
	if ball == null:
		return
	var toy := ball
	var at := toy.position
	var tint: Color = Ball.TINTS[toy.kind]
	ball = null
	if grab == Grab.BALL:
		grab = Grab.NONE
		finger = -1
	shrivelled.erase(toy)
	toy.queue_free()
	scuffs.erase(Items.id_of("toy", toy.kind))
	if not toy.bought:
		broken[Items.id_of("toy", toy.kind)] = Time.get_unix_time_from_system() + TOY_AGAIN_HOURS * 3600.0
	sfx.play("snap", 1.0, -2.0)
	sfx.play(toy.sound, toy.pitch * 0.6, -6.0)
	Input.vibrate_handheld(50)
	crumbs(at, tint)
	for i in 7:
		# A piece of it, thrown up and out, turning over, and gone by the time it would land
		var a := TAU * i / 7.0 + randf_range(-0.3, 0.3)
		var piece := Ps1.part(self, Ps1.box(), Ps1.mat(tint.darkened(0.3 * (i % 2))), at, Vector3(0.09, 0.03, 0.06) * randf_range(0.7, 1.2))
		var to := in_room(at + Vector3(cos(a), 0, sin(a)) * randf_range(0.35, 0.8), 0.1)
		var fly := piece.create_tween().set_parallel()
		fly.tween_property(piece, "position:x", to.x, 0.5)
		fly.tween_property(piece, "position:z", to.z, 0.5)
		fly.tween_property(piece, "position:y", at.y + randf_range(0.35, 0.7), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		fly.tween_property(piece, "position:y", 0.02, 0.28).set_delay(0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		fly.tween_property(piece, "rotation", Vector3(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), 0), 0.5)
		fly.chain().tween_callback(piece.queue_free)
	_lay_mess(Mess.Kind.BITS, at, Time.get_unix_time_from_system(), tint, 1.0)
	for pet in pets():
		if pet == by or pet.position.distance_to(at) < 1.6:
			pet.toy_broke(at)
	_sync()
	save_game()


# The toy in the room is put away: back on the wheel, with the wear it has had
func _clear_ball() -> void:
	if ball != null:
		var id := Items.id_of("toy", ball.kind)
		if ball.bought:
			if not toybox.has(id):
				toybox[id] = []
			toybox[id].append(ball.wear)
		else:
			scuffs[id] = ball.wear
		ball.queue_free()
		ball = null
	if grab == Grab.BALL:
		grab = Grab.NONE
		finger = -1


func decor_of(kind: int) -> Decor:
	for d in decors:
		if d.kind == kind:
			return d
	return null


# Stands one of the grave markers that were put away back in the room
func _bring_marker(at: Vector3) -> Decor:
	var kept: Dictionary = markers_away.pop_back()
	return _stand(Decor.Kind.MARKER, at, randf_range(-0.3, 0.3), Color.html(str(kept.get("c", "808085"))), int(kept.get("w", 0)))


func _stand(kind: int, at: Vector3, turn := 0.0, tint := Color(0.5, 0.5, 0.52), whose := 0) -> Decor:
	var d := Decor.new(kind, tint)
	d.whose = whose
	add_child(d)
	decors.append(d)
	if kind == Decor.Kind.POOL:
		_flood(d, shore_near(at))
	else:
		d.position = on_dry(at, d.radius * 0.6, d.radius)
		d.rotation.y = turn
	return d


# The pool comes to lie over one part of the floor (or is built again there, the room having
# changed shape), and whatever was standing where it now is gets moved out onto the dry: the
# nest, the eggs, the things and the messes. Food and toys float, and the cryptlins see to
# themselves.
func _flood(d: Decor, where: int) -> void:
	shore = where
	d.fill()
	d.water.set_shader_parameter("bed", GROUND_TINTS[floor_style])
	floor_mat.set_shader_parameter("shore", shore)
	move_nest(nest_pos)
	for other in decors:
		if other != d:
			other.position = on_dry(other.position, other.radius * 0.6, other.radius)
	for m in messes:
		m.position = on_dry(m.position, 0.15, 0.15)
	for r in residents:
		if r.egg != null:
			r.egg.position = on_dry(r.egg.position, 0.4, 0.4)


# The part of the floor a pool would be least in the way over: the one with the fewest things,
# eggs, cryptlins that do not live in water, and nests on it
func _emptiest_shore() -> int:
	var here: Array[Vector3] = [nest_pos]
	for d in decors:
		here.append(d.position)
	for r in residents:
		if r.body() != null and (r.pet == null or not r.pet.needs_water()):
			here.append(r.body().position)
	var was := shore
	var best: int = Shore.BACK
	var fewest := here.size() + 1
	# (either side sooner than the back, where there is the choice: the pool shows best there)
	var order := shores()
	order.reverse()
	for where in order:
		shore = where
		var count := here.filter(func(p: Vector3) -> bool: return wade(p) > 0.0).size()
		if count < fewest:
			fewest = count
			best = where
	shore = was
	return best


# Stands a thing in the room (or moves the one of its kind already there), and lets the
# cryptlins come and see what they think of it
func place_decor(kind: int, at: Vector3) -> Decor:
	var d := decor_of(kind)
	if d == null:
		d = _stand(kind, at, randf_range(-0.4, 0.4))
		if kind == Decor.Kind.POOL:
			splash(d.position)
		else:
			crumbs(d.position + Vector3(0, 0.1, 0), Color(0.3, 0.25, 0.2))
			sfx.play("thud", 1.1, -6.0)
	elif kind == Decor.Kind.POOL:
		if shore_near(at) != shore:
			_flood(d, shore_near(at))
	else:
		d.position = on_dry(at, d.radius * 0.6, d.radius)
	_judge(d)
	_sync()
	save_game()
	return d


func remove_decor(d: Decor) -> void:
	# Whoever was on it, in it or (the pool) out in its water is turned out, and does not think
	# much of it
	for pet in pets():
		var there := wade(pet.position) > 0.1 if d.kind == Decor.Kind.POOL else Vector2(pet.position.x - d.position.x, pet.position.z - d.position.z).length() < maxf(d.radius * 0.8, 0.3)
		if there or (pet.visiting == d and pet.state in [Cryptlin.State.LURK, Cryptlin.State.VISIT] and pet.step >= 1):
			pet.turned_out()
	if d.kind == Decor.Kind.POOL:
		shore = Shore.NONE
		floor_mat.set_shader_parameter("shore", shore)
	if d.kind == Decor.Kind.MARKER:
		markers_away.append({"c": d.tint.to_html(false), "w": d.whose})
	decors.erase(d)
	d.queue_free()
	sfx.play("click", 0.8)
	_sync()
	save_game()


# Each cryptlin goes over to a thing to show whether it likes it, side by side if there are several
func _judge(d: Decor) -> void:
	var id: String = Decor.IDS[d.kind]
	var all := pets()
	for i in all.size():
		var pet := all[i]
		var beside := (i - (all.size() - 1) * 0.5) * 0.55
		var near := d.position + Vector3(beside, 0, d.radius + 0.35)
		if d.kind == Decor.Kind.POOL:
			# (to the water's edge, the nearest of it to where each is standing)
			near = on_dry(shore_by(pet.position, 0.35) + place(beside, 0.0), 0.35, 0.35)
		if d.kind == Decor.Kind.POOL:
			# Whether it needs water shows the first time it sees some
			pet.look_over(near, 1 if pet.needs_water() else 0, "water")
		elif d.kind in pet.like_decor:
			pet.look_over(near, 1, "decor+" + id)
		elif d.kind == pet.hate_decor:
			pet.look_over(near, -1, "decor-" + id)
		else:
			pet.look_over(near, 0, "")


# How much bare floor there is round a place: how far to the water or the nearest thing, nest,
# egg or cryptlin
func _clearance(p: Vector3) -> float:
	var room := minf(p.distance_to(nest_pos) - 0.6, -wade(p))
	for d in decors:
		room = minf(room, p.distance_to(d.position) - d.radius)
	for r in residents:
		if r.body() != null:
			room = minf(room, Vector2(p.x - r.body().position.x, p.z - r.body().position.z).length() - 0.4)
	return room


# Somewhere on dry floor with nothing standing on it
func _free_spot(radius: float) -> Vector3:
	var best := Vector3.ZERO
	var best_room := -INF
	for i in 24:
		var p := on_dry(Vector3(randf_range(-half.x + radius + 0.2, half.x - radius - 0.2), 0, randf_range(-half.y + radius + 0.1, half.y - radius - 0.7)), 0.0, radius + 0.1)
		if _clearance(p) > best_room:
			best_room = _clearance(p)
			best = p
	return best


# A place for an egg: the given one if it is clear, or else the clearest to be found within
# `reach` of it (near enough the middle for the lamp to warm it)
func _clear_spot(centre: Vector3, reach: float) -> Vector3:
	var best := on_dry(centre, 0.4, 0.4)
	var best_room := _clearance(best)
	for i in 24:
		if best_room > 0.25:
			break
		var a := randf() * TAU
		var p := on_dry(centre + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, reach), 0.4, 0.4)
		if _clearance(p) > best_room:
			best_room = _clearance(p)
			best = p
	return best


func set_ground(style: int) -> void:
	floor_style = clampi(style, 0, GROUNDS.size() - 1)
	floor_mat.set_shader_parameter("style", floor_style)
	# A new floor has nobody's prints in it
	for old in tracks:
		old.queue_free()
	tracks.clear()
	if decor_of(Decor.Kind.POOL) != null:
		decor_of(Decor.Kind.POOL).water.set_shader_parameter("bed", GROUND_TINTS[floor_style])
	sfx.play("thud", 0.7, -8.0)
	for pet in pets():
		var right := floor_style == pet.fav_ground
		pet.look_over(pet.position, 1 if right else 0, "ground" if right else "")
	_sync()
	save_game()


func set_nest(style: int) -> void:
	nest_style = clampi(style, 0, Decor.NESTS.size() - 1)
	_build_nest()
	sfx.play("click")
	_sync()
	save_game()


func _build_nest() -> void:
	if nest != null:
		nest.queue_free()
	nest = Decor.nest(nest_style)
	nest.position = nest_pos
	add_child(nest)


# The nest pushed or dragged to a new place (by a finger, or by the cryptlin itself)
func move_nest(to: Vector3) -> void:
	nest_pos = on_dry(Vector3(to.x, 0, to.z), 0.6, 0.7)
	nest.position = nest_pos


func settle_nest() -> void:
	save_game()


# Where a cryptlin would sooner have its nest: in a shelter if there is one, by something it
# likes, or tucked into a back corner
func nest_spot(who: Cryptlin) -> Vector3:
	var spots: Array[Vector3] = [Vector3(-9.0, 0, -9.0), Vector3(9.0, 0, -9.0)]
	for d in decors:
		if d.hollow and d.kind != who.hate_decor:
			spots.append(d.position)
			spots.append(d.position)
		elif d.kind in who.like_decor:
			spots.append(d.position + Vector3(d.radius + 0.6, 0, 0.1))
	var far: Array[Vector3] = []
	for s in spots:
		if on_dry(s, 0.6, 0.7).distance_to(nest_pos) > 0.8:
			far.append(on_dry(s, 0.6, 0.7))
	return far.pick_random() if not far.is_empty() else on_dry(Vector3(randf_range(-1.5, 1.5), 0, -1.2), 0.6, 0.7)


# A shelter in the room for a cryptlin to get inside (never one it cannot stand): one it likes
# if there is one, or else the nearest; null if there is none
func shelter(who: Cryptlin) -> Decor:
	var best: Decor = null
	var best_way := INF
	for d in decors:
		if not d.hollow or d.kind == who.hate_decor or d == held_thing:
			continue
		var way := d.position.distance_to(who.position) - (100.0 if d.kind in who.like_decor else 0.0)
		if way < best_way:
			best_way = way
			best = d
	return best


# Where a cryptlin goes to watch from: inside a shelter, behind something it likes, or a back corner
func hiding_place(who: Cryptlin) -> Vector3:
	var hole := shelter(who)
	if hole != null:
		return hole.position + Vector3(0, 0, 0.05)
	for d in decors:
		if d.kind in who.like_decor:
			return on_dry(d.position + Vector3(0, 0, -d.radius - 0.4), 0.35, 0.3)
	return on_dry(Vector3(9.0 if randf() < 0.5 else -9.0, 0, -9.0), 0.5, 0.3)


# Somewhere out in the pool for one that lives in water to wade to: well in from its edge
func wading_spot(from: Vector3) -> Vector3:
	for i in 12:
		var p := Vector3(randf_range(-half.x + 0.5, half.x - 0.5), 0, randf_range(-half.y + 0.5, half.y - 0.5))
		if wade(p) > 0.5:
			return p
	return in_room(shore_by(from, -0.8), 0.5)


# A thing in the room for a cryptlin to go and make use of (never the one it hates), or null
func somewhere_to_go(who: Cryptlin) -> Decor:
	var fine: Array[Decor] = []
	for d in decors:
		if d.kind != who.hate_decor and d != held_thing:
			fine.append(d)
			if d.kind in who.like_decor:
				fine.append(d)
			# Water draws a water kind more than anything
			if d.kind == Decor.Kind.POOL and who.needs_water():
				fine.append_array([d, d, d])
	return fine.pick_random() if not fine.is_empty() else null


# ---------------------------------------------------------------- what it leaves on the floor

# A dropping, a puddle or a dug heap, left at a place by a cryptlin `ago` seconds since
func leave_mess(kind: int, at: Vector3, who: Cryptlin, ago := 0.0) -> Mess:
	var tint := who.dropping_colour()
	if kind == Mess.Kind.PUDDLE:
		tint = Color(0.62, 0.58, 0.2)
	elif kind == Mess.Kind.HEAP:
		tint = GROUND_TINTS[floor_style]
	return _lay_mess(kind, at, Time.get_unix_time_from_system() - ago, tint, who.grow)


func _lay_mess(kind: int, at: Vector3, when: float, tint: Color, big: float) -> Mess:
	var m := Mess.new(kind, when, tint, big)
	add_child(m)
	m.position = on_dry(Vector3(at.x, 0, at.z), 0.15, 0.15)
	m.rotation.y = randf() * TAU
	messes.append(m)
	return m


# The keeper clears one up, which is done with the broom (see _tick_broom)
func clear_mess(m: Mess) -> void:
	crumbs(m.position + Vector3(0, 0.08, 0), m.tint)
	sfx.play("click", 1.4, -4.0)
	if sweeping == m:
		sweeping = null
	messes.erase(m)
	m.queue_free()
	save_game()


# A tap on the broom: it goes and sweeps one thing up by itself, whatever spoils the place before
# a heap of earth, and of those the one that has lain longest
func sweep_one() -> void:
	var worst: Mess = null
	for m in messes:
		if m.visible and m != sweeping and (worst == null or (worst.kind == Mess.Kind.HEAP and m.kind != Mess.Kind.HEAP)):
			worst = m
	if worst == null or grab == Grab.BROOM:
		sfx.play("click", 0.7)
		return
	if sweeping == null:
		broom.position = worst.position
	broom.visible = true
	sweeping = worst
	sweep_time = 0.0


# The broom at work. On the end of a finger it follows it across the floor, and whatever mess it
# comes over it stops at and sweeps into the pan: a few strokes with the dust flying, the mess
# dwindling, and then it is gone. Let go of (or sent by a tap) it finishes what it was at and
# goes back to the wheel.
func _tick_broom(delta: float) -> void:
	if not broom.visible:
		return
	var brush: Node3D = broom.get_node("brush")
	var pan: Node3D = broom.get_node("pan")
	if sweeping != null and not sweeping in messes:
		sweeping = null
	if grab == Grab.BROOM and sweeping == null:
		broom.position = broom.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))
		for m in messes:
			if m.visible and Vector2(m.position.x - hold_point.x, m.position.z - hold_point.z).length() < BROOM_REACH:
				sweeping = m
				sweep_time = 0.0
				break
	if sweeping == null:
		brush.position = brush.position.lerp(Vector3(-0.1, 0, 0), 1.0 - exp(-delta * 14.0))
		brush.rotation.z = lerp_angle(brush.rotation.z, Items.BROOM_LEAN, 1.0 - exp(-delta * 14.0))
		pan.position = pan.position.lerp(Vector3(0.17, 0, 0.02), 1.0 - exp(-delta * 14.0))
		broom.visible = grab == Grab.BROOM
		return
	# The pan is held to one side of the mess and the brush comes across at it from the other
	var before := sweep_time
	sweep_time += delta
	var stroke := sin(sweep_time * TAU / SWEEP_STROKE)
	broom.position = broom.position.lerp(sweeping.position, 1.0 - exp(-delta * 14.0))
	brush.position = Vector3(-0.2 + stroke * 0.12, 0, 0.03)
	brush.rotation.z = Items.BROOM_LEAN - 0.15 - stroke * 0.3
	pan.position = Vector3(0.15, 0.01, 0.03)
	sweeping.scale = Vector3.ONE * (1.0 - 0.75 * sweep_time / SWEEP_SECONDS)
	if int(sweep_time / SWEEP_STROKE) != int(before / SWEEP_STROKE) or before == 0.0:
		crumbs(sweeping.position + Vector3(0, 0.06, 0), DUST)
		sfx.play("sweep", 1.0, -9.0)
	if sweep_time >= SWEEP_SECONDS:
		Input.vibrate_handheld(15)
		clear_mess(sweeping)


func droppings() -> int:
	var n := 0
	for m in messes:
		if m.kind == Mess.Kind.DROPPING:
			n += 1
	return n


# Where a cryptlin goes to do its business: a grown one as far as it can get from its nest and
# anything to eat, in a corner or behind something; a baby more or less where it stands
func toilet_spot(who: Cryptlin) -> Vector3:
	if who.is_baby():
		var a := randf() * TAU
		return on_dry(who.position + Vector3(cos(a), 0, sin(a)) * randf_range(0.2, 0.6), 0.3, 0.3)
	var spots: Array[Vector3] = []
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 0.05]:
			spots.append(on_dry(Vector3(9.0 * x, 0, 9.0 * z), 0.4, 0.3))
	for d in decors:
		if d.kind != Decor.Kind.POOL:
			spots.append(on_dry(d.position + Vector3(0, 0, -d.radius - 0.35), 0.4, 0.3))
	var best := spots[0]
	var best_room := -INF
	for s in spots:
		var room := s.distance_to(nest_pos) + randf_range(0.0, 0.8)
		for food in snacks:
			room = minf(room, s.distance_to(food.position))
		for d in decors:
			if s.distance_to(d.position) < d.radius:
				room -= 9.0
		if room > best_room:
			best_room = room
			best = s
	return best


# Whether a place is inside one of the shelters
func sheltered(at: Vector3) -> bool:
	for d in decors:
		if d.hollow and at.distance_to(d.position) < d.radius:
			return true
	return false


# How long since a finger last touched anything, in seconds
func left_alone() -> float:
	return clock - maxf(press_time, release_time)


# ---------------------------------------------------------------- the lamp

func set_lamp(mode: int) -> void:
	lamp_mode = mode
	light_dragging = false
	sfx.play("click", 0.8 if light_on else 0.6)
	for pet in pets():
		pet.caught()
		if light_on:
			var right := lamp_mode == pet.fav_lamp
			pet.look_over(pet.position, 1 if right else 0, "lamp" if right else "")
	_sync()
	save_game()


# A tap on the lamp: bright, low, heat, off, and round again
func tap_lamp() -> void:
	set_lamp((lamp_mode + 1) % LAMPS.size())


# Kept for the L key and the tests: out, or back to bright
func toggle_lamp() -> void:
	set_lamp(Lamp.BRIGHT if not light_on else Lamp.OFF)


# How fast the lamp warms an egg under it, next to the usual
func lamp_warmth() -> float:
	return LAMPS[lamp_mode]["warmth"]


func toggle_sound() -> void:
	sfx.muted = not sfx.muted
	_sync()
	save_game()


# ---------------------------------------------------------------- the scanner

# Points the scanner at one of them (or its egg) for a few seconds: its outline, its bones,
# and how full, rested, amused and fond it is. To the one it is given; or else the one last
# tapped; or else whichever is nearest the middle of the room.
func start_scan(r: Resident = null) -> void:
	end_fight(true)
	if r == null:
		r = chosen if chosen in residents else _nearest_resident(Vector3.ZERO)
	if r == null or r.leaving or r.body() == null or scanning:
		sfx.play("click", 0.7)
		return
	chosen = r
	scanned = r
	scanning = true
	scan_time = 0.0
	# Held on the left, unless that is where the one to be scanned is
	scan_side = 1.0 if screen_of(r.body().global_position).x < get_viewport().get_visible_rect().size.x * 0.42 else -1.0
	scanner.visible = true
	scan_ray.visible = true
	if r.pet != null:
		r.pet.xray(true)
		r.pet.hold_still()
	_aim_scanner()
	sfx.play("jingle", 0.6, -8.0)
	_sync()


func stop_scan() -> void:
	if not scanning:
		return
	scanning = false
	scanner.visible = false
	scan_ray.visible = false
	if scanned.pet != null:
		scanned.pet.xray(false)
	scanned = null
	scan_notes.queue_redraw()
	_sync()


# The egg or cryptlin nearest a place on the floor, or null if the room is empty
func _nearest_resident(to: Vector3) -> Resident:
	var best: Resident = null
	var best_way := INF
	for r in residents:
		if r.body() != null and not r.leaving and r.body().position.distance_to(to) < best_way:
			best_way = r.body().position.distance_to(to)
			best = r
	return best


# Holds the scanner in its lower corner of the view, just above the shelf and close to the eye,
# pointed at the one being scanned, with its light reaching to it
func _aim_scanner() -> void:
	var pet := scanned.pet
	var tall := 0.9 if pet == null else maxf(pet.tall(), 0.5)
	var middle := scanned.egg.centre() if pet == null else pet.global_position + Vector3(0, pet.tall() * 0.5, 0)
	var screen_size := get_viewport().get_visible_rect().size
	var short := minf(screen_size.x, screen_size.y)
	var corner := Vector2(screen_size.x * 0.5 + scan_side * (screen_size.x * 0.5 - short * SCANNER_IN.x), shelf.position.y - short * SCANNER_IN.y)
	var hand := camera.project_position(_in_view(corner), SCANNER_AWAY)
	# (it bobs a little, as a thing in a hand does)
	hand += camera.global_basis.y * sin(scan_time * 2.3) * 0.012
	# The same size on the screen whatever the shape of the screen
	var size := SCANNER_SIZE * Ps1.LINES * 2.0 * SCANNER_AWAY * tan(deg_to_rad(camera.fov * 0.5)) / view.size.y
	# Seen from the eye it lies along the line to the one it is pointed at, but turned further
	# side on than a straight aim from so close would be, so that it shows as what it is
	var sight := (hand - camera.global_position).normalized()
	var across := middle - hand
	across = (across - sight * across.dot(sight)).normalized()
	scanner.look_at_from_position(hand, hand + across * sin(SCANNER_SLANT) + sight * cos(SCANNER_SLANT), camera.global_basis.y)
	scanner.scale = Vector3.ONE * size
	scanner.global_position = hand - scanner.global_basis * Vector3(0, Items.BORE, 0)
	# The bar on its readout goes up and down, and a bright band on the body goes with it
	var sweep := sin(scan_time * 3.0)
	scan_bar.position.y = Items.READOUT.y + sweep * (Items.READOUT_SIZE.y * 0.5 - 0.015)
	if pet != null:
		pet.scan_skin.set_shader_parameter("band", pet.global_position.y + pet.tall() * (0.5 + 0.42 * sweep))
	# The light: a thin cone from the mouth of the gun, as wide as the one it falls on by the
	# time it gets there, that flickers. Its point is a little way back inside the barrel.
	var muzzle := scanner.to_global(Items.MUZZLE)
	var way := (middle - muzzle).normalized()
	var spread := tall * 0.55 / muzzle.distance_to(middle)
	var apex := muzzle - way * Items.MOUTH * 0.5 * size / spread
	var reach := apex.distance_to(middle) * 1.12
	scan_ray.look_at_from_position(muzzle, middle)
	scan_ray.scale = Vector3(reach * spread * 2.2, reach * spread * 2.2, reach - apex.distance_to(muzzle))
	ray_light.set_shader_parameter("apex", apex)
	ray_light.set_shader_parameter("axis", way)
	ray_light.set_shader_parameter("spread", spread)
	ray_light.set_shader_parameter("reach", reach)
	ray_light.set_shader_parameter("strength", 0.22 + 0.06 * sin(scan_time * 31.0) * sin(scan_time * 7.0))


func _word(value: float, words: Array[String]) -> String:
	return words[clampi(int(value / 100.0 * words.size()), 0, words.size() - 1)]


# The scanner's notes, drawn sharp over the picture with a line to what each is about
func _paint_notes() -> void:
	if not scanning:
		return
	var screen_size := get_viewport().get_visible_rect().size
	var pet := scanned.pet
	if pet == null:
		var egg := scanned.egg
		var warm: Array[String] = ["stone cold", "lukewarm", "warm", "about to hatch"]
		_note(screen_of(egg.centre()), Vector2(170, -90), "Egg", _word(egg.warmth, warm), egg.warmth, Color(1.0, 0.6, 0.25), screen_size)
		return
	var belly: Array[String] = ["empty", "peckish", "half full", "full", "stuffed"]
	var rest: Array[String] = ["worn out", "tired", "fresh", "wide awake"]
	var mind: Array[String] = ["bored stiff", "restless", "amused", "delighted"]
	var bond: Array[String] = ["wary of you", "getting used to you", "fond of you", "devoted"]
	var home: Array[String] = ["hates it here", "not at home", "settling in", "cosy", "loves it here"]
	_note(screen_of(pet.inside_at("brain")), Vector2(190, -110), "Mind", _word(pet.fun, mind), pet.fun, Color(1.0, 0.65, 0.85), screen_size)
	_note(screen_of(pet.inside_at("lungs")), Vector2(-200, -70), "Rest", _word(pet.energy, rest), pet.energy, Color(0.45, 0.85, 1.0), screen_size)
	_note(screen_of(pet.inside_at("heart")), Vector2(200, 10), "Heart", _word(pet.love, bond), pet.love, Color(1.0, 0.35, 0.45), screen_size)
	_note(screen_of(pet.inside_at("stomach")), Vector2(-200, 50), "Stomach", _word(pet.belly, belly), pet.belly, Color(1.0, 0.72, 0.2), screen_size)
	var feet := screen_of(pet.global_position)
	_note(feet, Vector2(0, 64), "Home", _word(pet.comfort, home), pet.comfort, Color(0.6, 0.9, 0.5), screen_size)
	var well: Array[String] = ["failing", "poorly", "off colour", "well", "in fine fettle"]
	# (far enough to the side that it is clear of the one under its feet, whose words are wider on a wide screen)
	_note(screen_of(pet.body_centre()), Vector2(240.0 if screen_size.x < 900.0 else 310.0, 130), "Health", _word(pet.health, well), pet.health, Color(0.93, 0.9, 0.8), screen_size)


func _note(from: Vector2, offset: Vector2, title: String, word: String, value: float, colour: Color, screen_size: Vector2) -> void:
	# In the scanner's own lettering (see Readout), bigger where there is the room for it
	var dot := 3.0 if screen_size.x >= 900.0 else 2.0
	var wide := maxf(Readout.width(word, dot), 120.0)
	var at := from + offset
	# Kept on the screen, and clear of the shelf
	at.x = clampf(at.x, wide * 0.5 + 12.0, screen_size.x - wide * 0.5 - 12.0)
	at.y = clampf(at.y, 40.0, shelf.position.y - 60.0)
	var left := floorf(at.x - wide * 0.5)
	at.y = floorf(at.y)
	scan_notes.draw_line(from, Vector2(clampf(from.x, left, left + wide), at.y + 8.0), Color(colour, 0.7), 2.0)
	scan_notes.draw_circle(from, 4.0, colour)
	Readout.paint(scan_notes, Vector2(left, at.y - 13.0), title, 2.0, colour)
	# How much, in five pips
	for i in 5:
		var pip := Rect2(left + i * 18.0, at.y + 7.0, 14.0, 7.0)
		scan_notes.draw_rect(pip.grow(1.5), Color(0, 0, 0, 0.7))
		scan_notes.draw_rect(pip, colour if value >= i * 20.0 + 10.0 else Color(colour, 0.22))
	Readout.paint(scan_notes, Vector2(left, at.y + 21.0), word, dot, Icons.BONE)


# ---------------------------------------------------------------- keeping the shelf and the pages up to date

func _sync() -> void:
	if shelf == null:
		return
	var have: Array[String] = []
	var marks := {}
	var counts := {}
	var out := {}
	# In the order of the row (see Items.ROW), whatever order the list of them is kept in
	for place: String in Items.ROW:
		for item in Items.LIST:
			var id: String = item["id"]
			if (id != place and item["group"] != place) or not owns(id) or in_room_now(id):
				continue
			have.append(id)
			if item["group"] in Items.SPENT and left_of(id) >= 0:
				counts[id] = left_of(id)
			elif item["group"] == "toy" and left_of(id) >= 0:
				# (those bought and not yet out, and those that have been out and were put away)
				counts[id] = left_of(id) + toybox.get(id, []).size()
	if have.has("marker"):
		counts["marker"] = markers_away.size() + (1 if stowing == "marker" else 0)
	# The marks are what is known of the one in question
	var pet := who().pet if who() != null else null
	if pet != null:
		var known := who().known
		if known.get("food", false):
			marks[Items.id_of("food", pet.fav_food)] = "heart"
		if known.get("yuck", false):
			marks[Items.id_of("food", pet.yuck_food)] = "cross"
		if known.get("toy", false):
			marks[Items.id_of("toy", pet.fav_toy)] = "heart"
		if known.get("ground", false):
			marks[Items.id_of("ground", pet.fav_ground)] = "heart"
		for id: String in Decor.IDS:
			if known.get("decor+" + id, false):
				marks[id] = "heart"
			elif known.get("decor-" + id, false):
				marks[id] = "cross"
		if known.get("water", false) and pet.needs_water():
			marks["pool"] = "heart"
	if scanning:
		out["scanner"] = true
	shelf.marks = marks
	shelf.counts = counts
	shelf.out = out
	shelf.stock(have)
	# An empty room inside a host page, and an egg to lay in it: the wheel turns to the egg, which
	# asks to be picked up (see Shelf.beckon) until it has been
	var waiting := embedded and residents.is_empty() and have.has("egg")
	if waiting and shelf.beckon == "":
		shelf.show_item("egg")
	shelf.beckon = "egg" if waiting else ""
	# (and is not to be tucked away meanwhile: the egg held out is the only way on)
	shelf.tab = not waiting
	if waiting:
		tuck(false)
	if who() != null:
		dev_label.text = "%d/%d\n%s" % [who().kind + 1, Cryptlin.KINDS.size(), Cryptlin.KINDS[who().kind]["title"]]
		dev_egg.text = "Hatch" if who().egg != null else "Egg"
	if notebook.visible:
		notebook.refresh()


# ---------------------------------------------------------------- the room

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.55)
	env.ambient_light_energy = 0.16
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# The room is drawn small into its own picture and blown up with hard pixels (the shelf's
	# marks and the words on top stay sharp, so they can be read on a phone)
	view = SubViewport.new()
	view.size = Vector2i(320, 240)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	camera = Camera3D.new()
	camera.environment = env
	view.add_child(camera)
	_aim_camera()
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	var post := ShaderMaterial.new()
	post.shader = load("res://shaders/ps1_screen.gdshader")
	screen = TextureRect.new()
	screen.texture = view.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.material = post
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	floor_mat = ShaderMaterial.new()
	floor_mat.shader = load("res://shaders/floor.gdshader")
	floor_mat.set_shader_parameter("style", floor_style)
	_build_shell()

	_build_nest()

	scanner = Items.scanner()
	scan_bar = Ps1.part(scanner, Ps1.box(), Ps1.mat(Color(0.4, 1.0, 0.55), 1.0), Items.READOUT, Vector3(Items.READOUT_SIZE.x, 0.03, 0.02))
	scanner.visible = false
	add_child(scanner)
	broom = Items.broom()
	broom.scale = Vector3.ONE * 1.25
	broom.visible = false
	add_child(broom)
	# Its light is the same haze as the lamp's. The shader gives it the shape of a cone; the
	# mesh only says where to draw, and is a closed tube a unit long and a unit across that
	# _aim_scanner stretches from the mouth of the gun to the one it is pointed at.
	ray_light = ShaderMaterial.new()
	ray_light.shader = load("res://shaders/beam.gdshader")
	ray_light.set_shader_parameter("tint", Color(0.35, 1.0, 0.75))
	var tube := CylinderMesh.new()
	tube.top_radius = 0.5
	tube.bottom_radius = 0.5
	tube.height = 1.0
	tube.radial_segments = 12
	scan_ray = Node3D.new()
	var ray := Ps1.part(scan_ray, tube, ray_light, Vector3(0, 0, -0.5), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scan_ray.visible = false
	add_child(scan_ray)

	# A ring that spreads where you tap to call it
	var ripple_mat := StandardMaterial3D.new()
	ripple_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ripple_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ripple_mat.albedo_color = Color(1, 0.95, 0.8, 0.0)
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.92
	hoop.outer_radius = 1.0
	ripple = _mesh(hoop, ripple_mat, Vector3(0, 0.02, 0))
	ripple.scale = Vector3(0.1, 0.02, 0.1)
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ripple.visible = false

	var crumb_mat := StandardMaterial3D.new()
	crumb_mat.vertex_color_use_as_albedo = true
	crumb_mat.roughness = 0.9
	var crumb := BoxMesh.new()
	crumb.size = Vector3.ONE * 0.035
	crumb.material = crumb_mat
	crumb_puff = CPUParticles3D.new()
	crumb_puff.mesh = crumb
	crumb_puff.one_shot = true
	crumb_puff.emitting = false
	crumb_puff.amount = 10
	crumb_puff.lifetime = 0.6
	crumb_puff.explosiveness = 1.0
	crumb_puff.direction = Vector3.UP
	crumb_puff.spread = 60.0
	crumb_puff.initial_velocity_min = 0.8
	crumb_puff.initial_velocity_max = 1.8
	crumb_puff.gravity = Vector3(0, -7, 0)
	add_child(crumb_puff)


# The room itself, to the size it is just now: floor, three brick walls, a vent and a pipe
func _build_shell() -> void:
	if shell != null:
		shell.queue_free()
	shell = Node3D.new()
	add_child(shell)
	# The floor runs on out under your feet; the cryptlin keeps to the far end of it
	var plane := PlaneMesh.new()
	plane.size = Vector2(half.x * 2.0 + 0.2, 8.0)
	var floor_mesh := Ps1.part(shell, plane, floor_mat, Vector3(0, 0, 4.0 - half.y - 0.1))
	# On its own layer, so the fill light can leave the floor outside the beam dark
	floor_mesh.layers = 2

	# Brick walls left, right and behind, the same brick as the station upstairs
	for wall: Array in [
		[Vector3(0, 6.0, -half.y - 0.1), Vector3(half.x * 2.0 + 0.4, 12.0, 0.2), Vector3.RIGHT],
		[Vector3(-half.x - 0.1, 6.0, 4.0 - half.y - 0.1), Vector3(0.2, 12.0, 8.0), Vector3.BACK],
		[Vector3(half.x + 0.1, 6.0, 4.0 - half.y - 0.1), Vector3(0.2, 12.0, 8.0), Vector3.BACK],
	]:
		var bricks := ShaderMaterial.new()
		bricks.shader = load("res://shaders/brick.gdshader")
		bricks.set_shader_parameter("across", wall[2])
		Ps1.part(shell, Ps1.box(), bricks, wall[0], wall[1])

	# A vent high on the back wall, and a pipe running along under the ceiling
	var iron := Ps1.mat(Color(0.2, 0.2, 0.22))
	var vent := Node3D.new()
	vent.position = Vector3(half.x - 1.0, lamp_at.y - 0.9, -half.y + 0.02)
	shell.add_child(vent)
	Ps1.part(vent, Ps1.box(), Ps1.flat(Color(0.015, 0.012, 0.012)), Vector3.ZERO, Vector3(0.82, 0.5, 0.02))
	for side: float in [-1.0, 1.0]:
		Ps1.part(vent, Ps1.box(), iron, Vector3(0.43 * side, 0, 0.02), Vector3(0.07, 0.62, 0.06))
		Ps1.part(vent, Ps1.box(), iron, Vector3(0, 0.28 * side, 0.02), Vector3(0.93, 0.07, 0.06))
	for i in 5:
		Ps1.part(vent, Ps1.box(), iron, Vector3(0, -0.18 + i * 0.09, 0.03), Vector3(0.8, 0.035, 0.07), Vector3(0.6, 0, 0))
	var pipe := Ps1.mat(Color(0.3, 0.2, 0.14))
	var pipe_y := lamp_at.y + 0.5
	Ps1.part(shell, Ps1.drum(6), pipe, Vector3(0, pipe_y, -half.y + 0.16), Vector3(0.07, half.x * 2.0, 0.07), Vector3(0, 0, PI * 0.5))
	Ps1.part(shell, Ps1.drum(6), pipe, Vector3(-half.x + 0.9, pipe_y + 3.0, -half.y + 0.16), Vector3(0.07, 6.0, 0.07))
	for x: float in [-half.x + 0.9, 0.3, half.x - 0.5]:
		Ps1.part(shell, Ps1.box(), iron, Vector3(x, pipe_y, -half.y + 0.1), Vector3(0.05, 0.2, 0.22))


# The room takes a new shape (the screen was turned, or is a different one from last time):
# the walls move, the lamp goes up or down with the ceiling, and everything in the room is
# brought back inside
func _reshape(room: Vector2, lamp: Vector3) -> void:
	half = room
	lamp_at = lamp
	if floor_mat == null:
		return
	_build_shell()
	if lamp_head != null:
		lamp_head.position = lamp_at
		cord.position = lamp_at + Vector3(0, 4.0, 0)
	move_nest(nest_pos)
	# The pool is built again to the new walls (over the back, if its side no longer fits)
	var pool := decor_of(Decor.Kind.POOL)
	if pool != null:
		_flood(pool, shore if shore in shores() else Shore.BACK)
	for d in decors:
		if d != pool:
			d.position = on_dry(d.position, d.radius * 0.6, d.radius)
	if ball != null:
		ball.position = in_room(ball.position, Ball.R)
	for m in messes:
		m.position = on_dry(m.position, 0.15, 0.15)
	for s in snacks:
		s.position = in_room(s.position, 0.2)
	for r in residents:
		if r.egg != null:
			r.egg.position = on_dry(r.egg.position, 0.4, 0.4)


func _mesh(mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi


# A bare bulb under a tin shade, on a cord from the ceiling. It swings to point where it is
# dragged, and a tap on it changes how it burns.
func _build_lamp() -> void:
	var tin := Ps1.mat(Color(0.24, 0.42, 0.34), 0.22)
	cord = Ps1.part(self, Ps1.box(), Ps1.mat(Color(0.05, 0.05, 0.05)), lamp_at + Vector3(0, 4.0, 0), Vector3(0.025, 8.0, 0.025))
	lamp_head = Node3D.new()
	lamp_head.position = lamp_at
	add_child(lamp_head)
	Ps1.part(lamp_head, Ps1.box(), Ps1.mat(Color(0.05, 0.05, 0.05)), Vector3(0, -0.15, 0), Vector3(0.025, 0.3, 0.025))
	var shade := CylinderMesh.new()
	shade.top_radius = 0.08
	shade.bottom_radius = 0.5
	shade.height = 0.3
	shade.radial_segments = 8
	shade.rings = 1
	shade.cap_bottom = false
	var hood := Ps1.part(lamp_head, shade, tin, Vector3(0, -0.42, 0))
	hood.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Ps1.part(lamp_head, Ps1.drum(6), tin, Vector3(0, -0.27, 0), Vector3(0.06, 0.08, 0.06))
	bulb = Ps1.part(lamp_head, Ps1.ball(), Ps1.mat(Color(1.0, 0.93, 0.78), 1.0), Vector3(0, -LAMP_DROP, 0), Vector3.ONE * 0.13)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	spot = SpotLight3D.new()
	spot.position = Vector3(0, -LAMP_DROP, 0)
	spot.rotation.x = -PI * 0.5
	spot.spot_range = 14.0
	spot.spot_angle = 48.0
	spot.spot_angle_attenuation = 0.6
	spot.spot_attenuation = 0.5
	spot.light_color = Color(1.0, 0.93, 0.78)
	spot.light_energy = 3.0
	spot.shadow_enabled = true
	spot.shadow_blur = 1.5
	spot.shadow_bias = 0.08
	spot.shadow_normal_bias = 2.0
	lamp_head.add_child(spot)

	var reach := 7.6
	beam = ShaderMaterial.new()
	beam.shader = load("res://shaders/beam.gdshader")
	beam.set_shader_parameter("reach", reach)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.1
	cone.bottom_radius = reach * tan(deg_to_rad(50.0))
	cone.height = reach
	cone.cap_top = false
	cone.cap_bottom = false
	cone.radial_segments = 32
	var haze := MeshInstance3D.new()
	haze.mesh = cone
	haze.material_override = beam
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	haze.rotation.x = PI * 0.5
	haze.position = Vector3(0, 0, -reach * 0.5)
	spot.add_child(haze)

	# Light thrown back off the floor, so what stands in the beam is not black underneath
	bounce = OmniLight3D.new()
	bounce.light_color = Color(1.0, 0.86, 0.66)
	bounce.omni_range = 7.5
	bounce.light_specular = 0.0
	bounce.light_cull_mask = 1
	add_child(bounce)

	# Dust drifting in the beam
	var mote_mat := StandardMaterial3D.new()
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote_mat.albedo_color = Color(1.0, 0.93, 0.78, 0.35)
	var speck := QuadMesh.new()
	speck.size = Vector2(0.016, 0.016)
	speck.material = mote_mat
	motes = CPUParticles3D.new()
	motes.mesh = speck
	motes.amount = 40
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.1
	motes.spread = 180.0
	motes.gravity = Vector3(0, -0.01, 0)
	motes.initial_velocity_min = 0.02
	motes.initial_velocity_max = 0.08
	motes.position = Vector3(0, 1.2, 0)
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)


func _aim_camera() -> void:
	camera.position = eye + Vector3(sin(clock * 0.21) * 0.1, sin(clock * 0.17) * 0.04, 0)
	camera.look_at(eye_on)
	camera.rotation.z = sin(clock * 0.45) * 0.07 * weird


# Phones held upright keep the whole room in view by fixing the width instead of the height
func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	view.size = Vector2i((size * Ps1.LINES / minf(size.x, size.y)).round())
	var tall := size.x < size.y
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var room := Vector2(2.9, 2.5)
	var lamp := Vector3(0, 3.4, 0.1)
	if tall:
		# Upright: a narrow, deep, tall room, as wide as the screen shows of its near end, with
		# the lamp up by the top of the screen and the floor running down to the shelf
		camera.fov = 62.0
		eye = Vector3(0, 4.7, 8.3)
		eye_on = Vector3(0, 1.66, 0)
		room = Vector2(clampf(4.0 * size.x / size.y, 1.7, 2.9), 3.1)
		lamp = Vector3(0, 6.3, 0.1)
	else:
		camera.fov = 44.0
		eye = Vector3(0, 4.0, 8.4)
		eye_on = Vector3(0, 1.0, 0)
	tall_room = tall
	if not room.is_equal_approx(half) or lamp != lamp_at or shell == null:
		_reshape(room, lamp)
	if shelf == null:
		return
	# Thumb-sized, and bigger still on an upright phone
	var deep := 190.0 if tall else 140.0
	# On an upright phone it rides up off the bottom edge, where the browser's own bar and the
	# bar for gestures are drawn over the page (the game cannot ask how much: it is given the
	# whole page), and the strip runs on down under it for its things to sink away through
	var lift := clampf(size.y * WHEEL_SPARE.x - WHEEL_SPARE.y, size.y * WHEEL_LIFT_LEAST, size.y * WHEEL_LIFT) if tall else 0.0
	shelf.position = Vector2(0, size.y - deep - lift)
	shelf.size = Vector2(size.x, deep + lift)
	shelf.drop = lift
	toast.position.y = 150.0 if tall else 40.0
	dev.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	notebook.fit(size)


# ---------------------------------------------------------------- what is drawn over the room

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	scan_notes = Control.new()
	scan_notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan_notes.draw.connect(_paint_notes)
	layer.add_child(scan_notes)
	scan_notes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	shelf = Shelf.new()
	layer.add_child(shelf)

	dev = VBoxContainer.new()
	dev.add_theme_constant_override("separation", 8)
	layer.add_child(dev)
	dev_label = Label.new()
	dev_label.add_theme_font_size_override("font_size", 18)
	dev_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	dev_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	dev_label.add_theme_constant_override("outline_size", 6)
	dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dev.add_child(dev_label)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 8)
	dev.add_child(steps)
	var dev_buttons: Array[Button] = [text_button(steps, "<", _dev_step.bind(-1)), text_button(steps, ">", _dev_step.bind(1))]
	dev_buttons.append(text_button(dev, "Look", _dev_look))
	dev_egg = text_button(dev, "Egg", _dev_egg)
	dev_buttons.append(dev_egg)
	dev_buttons.append(text_button(dev, "Age", _dev_age))
	dev_buttons.append(text_button(dev, "+1 day", _dev_day))
	for b in dev_buttons:
		b.custom_minimum_size = Vector2(64, 60)
		b.add_theme_font_size_override("font_size", 22)
	dev.custom_minimum_size.x = 136
	dev.grow_vertical = Control.GROW_DIRECTION_BOTH
	dev.visible = false

	toast = Label.new()
	toast.add_theme_font_size_override("font_size", 28)
	toast.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	toast.add_theme_constant_override("outline_size", 8)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0
	layer.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 40)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH

	card = StyleBoxFlat.new()
	card.bg_color = Color(Icons.MOSS, 0.96)
	card.border_color = Color(Icons.AMBER, 0.45)
	card.set_border_width_all(2)
	card.set_corner_radius_all(18)
	card.set_content_margin_all(26)

	# Asked before a cryptlin is sent away
	ask = PanelContainer.new()
	ask.add_theme_stylebox_override("panel", card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	ask.add_child(column)
	ask_text = _words(column, "", 28)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 16)
	column.add_child(answers)
	for b: Button in [icon_button(answers, "heart", _answer.bind(false), "Keep"), icon_button(answers, "moon", _answer.bind(true), "Let go")]:
		b.custom_minimum_size = Vector2(170, 130)
	layer.add_child(ask)
	_centre(ask)

	# Asked when it hatches (and from the notebook): what it is to be called
	namer = PanelContainer.new()
	namer.add_theme_stylebox_override("panel", card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 20)
	namer.add_child(rows)
	_words(rows, "What will you call it?", 28)
	name_edit = LineEdit.new()
	name_edit.max_length = 14
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(380, 70)
	name_edit.add_theme_font_size_override("font_size", 34)
	name_edit.add_theme_color_override("font_color", Icons.AMBER)
	name_edit.select_all_on_focus = true
	name_edit.text_submitted.connect(_name_done)
	rows.add_child(name_edit)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 16)
	rows.add_child(choices)
	for b: Button in [icon_button(choices, "dice", _name_roll, "Another"), icon_button(choices, "check", _name_done, "Done")]:
		b.custom_minimum_size = Vector2(170, 120)
	layer.add_child(namer)
	_centre(namer)

	notebook = Notebook.new(self)
	layer.add_child(notebook)
	notebook.visible = false


func _centre(panel: Control) -> void:
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false


func _words(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


# A button with a symbol on it (see Icons), and perhaps a word underneath
func icon_button(parent: Node, symbol: String, action: Callable, caption := "") -> IconButton:
	var b := IconButton.new()
	b.symbol = symbol
	b.caption = caption
	_dress(b, action)
	parent.add_child(b)
	return b


# A button with words on it, for the few places a symbol will not do
func text_button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", Icons.BONE)
	b.add_theme_color_override("font_disabled_color", Color(Icons.BONE, 0.25))
	_dress(b, action)
	parent.add_child(b)
	return b


# Dark as moss with a bone-pale edge, which turns to eyeshine amber under a finger
func _dress(b: Button, action: Callable) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 62)
	for style_name: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(Icons.MOSS, 0.78 if style_name == "normal" else 0.95)
		box.border_color = Color(Icons.BONE, 0.3)
		if style_name == "pressed":
			box.bg_color = Color(0.2, 0.17, 0.08, 0.95)
			box.border_color = Color(Icons.AMBER, 0.9)
		if style_name == "disabled":
			box.bg_color = Color(Icons.MOSS, 0.4)
			box.border_color = Color(Icons.BONE, 0.1)
		box.set_border_width_all(3 if style_name == "pressed" else 2)
		box.set_corner_radius_all(22)
		b.add_theme_stylebox_override(style_name, box)
	b.pressed.connect(action)


# Words across the top of the screen, for the test panel alone: nothing is ever written there in play
func _say(text: String) -> void:
	toast.text = text
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.6)
	tw.tween_interval(2.6)
	tw.tween_property(toast, "modulate:a", 0.0, 1.2)


# ---------------------------------------------------------------- things the cryptlin asks of the room

func hover_fresh() -> bool:
	return clock - hover_time < 2.0


# The nearest bit of food to a cryptlin that it has not already turned its nose up at, or null
func snack_for(who: Cryptlin) -> Snack:
	var best: Snack = null
	for s in snacks:
		if s.get_instance_id() in who.spurned:
			continue
		if best == null or s.position.distance_squared_to(who.position) < best.position.distance_squared_to(who.position):
			best = s
	return best


# Whether any of the others might yet eat a bit of food that this one will not
func wanted_by_another(snack: Snack, who: Cryptlin) -> bool:
	for pet in pets():
		if pet != who and pet.yuck_food != snack.kind and pet.belly < 97.0:
			return true
	return false


func remove_snack(snack: Snack) -> void:
	snacks.erase(snack)
	snack.queue_free()


func crumbs(at: Vector3, colour: Color) -> void:
	crumb_puff.position = at
	crumb_puff.color = colour
	crumb_puff.restart()


# A footprint left by one of the heavy kinds (see Track): where its foot came down, facing the
# way it was going, deeper and longer lasting on a soft floor. There are never more than
# MAX_TRACKS of them; the oldest goes to make room. Water takes no print.
func leave_print(shape: String, at: Vector3, facing: float, side: float, big: float) -> void:
	if wade(at) > 0.0:
		return
	while tracks.size() >= MAX_TRACKS:
		tracks.pop_front().queue_free()
	var print := Track.new(shape, side, big, floor_style in SOFT_GROUNDS)
	print.tree_exiting.connect(tracks.erase.bind(print))
	add_child(print)
	print.position = Vector3(at.x, 0, at.z)
	print.rotation.y = facing
	tracks.append(print)


# Something to eat that turns up for nothing (a fae leaves it): berries, set down at a place for
# whoever gets there first. It is not out of the stock of the keeper, and there is none if as
# much is lying about already as the room holds.
func gift(at: Vector3) -> void:
	if snacks.size() >= MAX_SNACKS:
		return
	var snack := Snack.new(Snack.Kind.BERRIES)
	add_child(snack)
	snack.drop(on_dry(at, 0.3, 0.1) + Vector3(0, 0.5, 0))
	snack.thud.connect(func(strength: float) -> void: sfx.play("thud", 1.3, clampf(strength * 2.0 - 16.0, -24.0, -4.0)))
	snacks.append(snack)



# Leaves a thing in the room (or the toy) shrivelled for so many seconds: sunk in on itself,
# and filling out again at the end of them
func shrivel(thing: Node3D, seconds: float) -> void:
	shrivelled[thing] = seconds


# What is shrivelled comes back to its shape as its time runs out
func _plump(delta: float) -> void:
	for thing: Variant in shrivelled.keys():
		if not is_instance_valid(thing):
			shrivelled.erase(thing)
			continue
		shrivelled[thing] = float(shrivelled[thing]) - delta
		var sunk := clampf(float(shrivelled[thing]) / 4.0, 0.0, 1.0)
		thing.scale = thing.scale.lerp(Vector3.ONE.lerp(Vector3(0.8, 0.45, 0.8), sunk), 1.0 - exp(-delta * 5.0))
		if float(shrivelled[thing]) <= 0.0:
			thing.scale = Vector3.ONE
			shrivelled.erase(thing)



# Water thrown up by something wading in the pool
func splash(at: Vector3) -> void:
	crumbs(Vector3(at.x, Decor.WATER + 0.08, at.z), Color(0.5, 0.75, 0.9))
	sfx.play("chomp", 0.9, -9.0)


# ---------------------------------------------------------------- every frame

func _process(delta: float) -> void:
	clock += delta
	# A finger resting on the floor takes hold of the lamp
	if grab == Grab.FLOOR and not light_dragging and light_on and clock - press_time > 0.3:
		light_dragging = true
		light_goal = press_floor
	if not light_dragging and clock - release_time > 2.5:
		light_goal = Vector3.ZERO
	light_point = light_point.lerp(light_goal, 1.0 - exp(-delta * (9.0 if light_dragging else 1.6)))
	# The lamp swings on its cord to point there, and eases to however it has been set to burn
	lamp_head.quaternion = Quaternion(Vector3.DOWN, (light_point - lamp_at).normalized())
	var mode: Dictionary = LAMPS[lamp_mode]
	var ease_in := 1.0 - exp(-delta * 6.0)
	light_level = move_toward(light_level, 1.0 if light_on else 0.0, delta * 5.0)
	if light_on:
		spot.light_color = spot.light_color.lerp(mode["colour"], ease_in)
		# Hung higher in a tall room, it burns harder and narrower to throw the same pool of light
		lamp_energy = lerpf(lamp_energy, float(mode["energy"]) * (2.6 if tall_room else 1.2), ease_in)
		lamp_angle = lerpf(lamp_angle, float(mode["angle"]) * (0.6 if tall_room else 1.0), ease_in)
	spot.light_energy = lamp_energy * light_level * (1.0 + sin(clock * 13.0) * sin(clock * 3.1) * 0.025)
	if flicker > 0.0:
		# Something is at the cord: it gutters
		flicker -= delta
		spot.light_energy *= 0.15 if sin(clock * 61.0) * sin(clock * 23.0) > 0.1 else 1.0
	_plump(delta)
	spot.spot_angle = lamp_angle
	spot.visible = light_level > 0.001
	# A dreamer in the room: the light goes the wrong colours, a little of it comes even from a
	# dark bulb, and the whole room tilts slowly one way and the other (see _aim_camera)
	weird = move_toward(weird, strange, delta * 0.5)
	strange = 0.0
	if weird > 0.0:
		spot.light_color = spot.light_color.lerp(Color.from_hsv(0.33 + 0.42 * (0.5 + 0.5 * sin(clock * 0.7)), 0.75, 1.0), weird * 0.75)
		spot.light_energy = maxf(spot.light_energy, weird * 0.7)
		spot.visible = true
	bulb.material_override.set_shader_parameter("tint", Color(0.2, 0.17, 0.15).lerp(spot.light_color, light_level))
	bulb.material_override.set_shader_parameter("glow", light_level)
	beam.set_shader_parameter("tint", spot.light_color)
	beam.set_shader_parameter("spread", tan(deg_to_rad(lamp_angle - 1.0)))
	beam.set_shader_parameter("strength", 0.07 * light_level * float(mode["energy"]))
	beam.set_shader_parameter("reach", lamp_at.y - LAMP_DROP + 1.3)
	beam.set_shader_parameter("apex", spot.global_position)
	beam.set_shader_parameter("axis", -spot.global_basis.z)
	bounce.light_color = spot.light_color
	bounce.light_energy = 0.2 * float(mode["energy"]) * light_level
	bounce.position = light_point + Vector3(0, 1.1, 1.8)
	motes.visible = light_level > 0.5
	motes.position = Vector3(light_point.x * 0.5, 1.2, light_point.z * 0.5)
	if decor_of(Decor.Kind.POOL) != null:
		decor_of(Decor.Kind.POOL).glint(light_point, spot.light_color, light_level * float(mode["energy"]) / 3.0)

	# A finger left on the cryptlin lifts it
	if grab == Grab.PET and is_instance_valid(held_pet):
		if not carrying and clock - press_time > 0.45 and moved < 14.0:
			carrying = true
			hold_point = _floor_at(last_at, 0.0, 0.4) + Vector3(0, 0.8, 0)
			held_pet.pick_up()
			Input.vibrate_handheld(30)
		if carrying:
			held_pet.carry(hold_point)
	# The scanner on its way up from the shelf, on the end of the finger
	if grab == Grab.SCANNER:
		scanner.scale = Vector3.ONE * 0.8
		scanner.position = scanner.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))
		scanner.rotation = Vector3(0, -0.9, 0)
		scan_bar.position.y = Items.READOUT.y

	_tick_broom(delta)
	_lay_due()
	if scuffle != null:
		_tick_fight(delta)

	if grab == Grab.BALL and ball != null:
		var before := ball.position
		ball.position = ball.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))
		if delta > 0.0:
			hold_vel = hold_vel.lerp((ball.position - before) / delta, 0.35)
	if grab == Grab.SNACK and held_snack != null:
		held_snack.position = held_snack.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))

	if scanning:
		scan_time += delta
		if not scanned in residents or scanned.body() == null or scan_time > SCAN_SECONDS:
			stop_scan()
		else:
			_aim_scanner()
			scan_notes.queue_redraw()

	if ripple.visible:
		var grown := ripple.scale.x + delta * 1.4
		ripple.scale = Vector3(grown, 0.02, grown)
		var mat := ripple.material_override as StandardMaterial3D
		mat.albedo_color.a = clampf(0.6 - grown, 0.0, 0.5)
		ripple.visible = grown < 0.6

	# Puddles dry up and heaps settle
	for m in messes.duplicate():
		if m.gone() >= 1.0:
			messes.erase(m)
			m.queue_free()

	_aim_camera()

	save_timer += delta
	if save_timer > 10.0:
		save_game()
		# (and a toy that broke may be to be had again by now)
		if not broken.is_empty():
			_sync()


# ---------------------------------------------------------------- touch

# A card or the notebook is up: nothing in the room or on the shelf answers to a finger
func _modal() -> bool:
	return ask.visible or namer.visible or notebook.visible


func _over_ui(p: Vector2) -> bool:
	return _modal() or (dev.visible and dev.get_global_rect().has_point(p))


# The room is drawn smaller than the screen, so touches are scaled down to it and back
func _in_view(at: Vector2) -> Vector2:
	return at * Vector2(view.size) / get_viewport().get_visible_rect().size


# Where a point in the room is on the screen
func screen_of(world: Vector3) -> Vector2:
	return camera.unproject_position(world) * get_viewport().get_visible_rect().size / Vector2(view.size)


# Where on the floor (or `height` above it) a point on the screen is, kept `margin` inside the
# walls; a margin below zero lets it run on past them
func _floor_at(at: Vector2, height := 0.0, margin := 0.2) -> Vector3:
	var from := camera.project_ray_origin(_in_view(at))
	var dir := camera.project_ray_normal(_in_view(at))
	var t := 60.0
	if dir.y < -0.001:
		t = minf((height - from.y) / dir.y, 60.0)
	var p := from + dir * t
	p.y = height
	return in_room(p, margin)


func _ray_hits(at: Vector2, centre: Vector3, radius: float) -> bool:
	return _ray_off(at, centre) < radius


# How far wide of a place in the room the line from a point on the screen passes
func _ray_off(at: Vector2, centre: Vector3) -> float:
	var from := camera.project_ray_origin(_in_view(at))
	var dir := camera.project_ray_normal(_in_view(at))
	var along := (centre - from).dot(dir)
	return (from + dir * along).distance_to(centre) if along > 0.0 else INF


# The egg or cryptlin under a finger (the nearest to it, if there are two), or null
func _resident_at(at: Vector2) -> Resident:
	var best: Resident = null
	var best_off := INF
	for r in residents:
		var off := INF
		if r.egg != null:
			off = _ray_off(at, r.egg.centre()) / 0.6
		elif r.pet != null and not r.leaving and r.pet.visible:
			off = _ray_off(at, r.pet.body_centre()) / (0.7 * maxf(r.pet.grow, 0.75))
		if off < 1.0 and off < best_off:
			best_off = off
			best = r
	return best


# A tap on the floor calls every one of them over: they gather round the place, not on it
func call_all(to: Vector3) -> void:
	var all := pets()
	for i in all.size():
		var a := TAU * i / all.size() + 0.6
		all[i].call_to(to + (Vector3(cos(a), 0, sin(a)) * 0.55 if all.size() > 1 else Vector3.ZERO))


# The thing standing in the room under a finger (the nest counts, and so does the pool,
# anywhere on its water), or null
func _thing_at(at: Vector2) -> Node3D:
	for d in decors:
		if d.kind != Decor.Kind.POOL and _ray_hits(at, d.position + Vector3(0, minf(d.radius, 0.4), 0), maxf(d.radius, 0.34)):
			return d
	if _ray_hits(at, nest_pos + Vector3(0, 0.1, 0), 0.55):
		return nest
	if wade(_floor_at(at, 0.0, 0.0)) > 0.0:
		return decor_of(Decor.Kind.POOL)
	return null


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event)
		elif event.index == finger:
			last_at = event.position
			_release()
	elif event is InputEventScreenDrag and event.index == finger:
		moved += event.relative.length()
		last_at = event.position
		match grab:
			Grab.BALL:
				hold_point = _floor_at(event.position, 0.75, 0.3)
				# Held down over the wheel the toy is on its way back there
				if ball != null:
					ball.visible = not _over_wheel(event.position)
					_offer("" if ball.visible else Items.id_of("toy", ball.kind))
			Grab.SNACK:
				hold_point = _held_at(event.position, 0.75)
				if _over_wheel(event.position):
					tuck(false)
			Grab.PET:
				if carrying:
					hold_point = _floor_at(event.position, 0.0, 0.4) + Vector3(0, 0.8, 0)
				elif moved > 14.0 and is_instance_valid(held_pet):
					held_pet.stroke()
			Grab.EGG:
				if moved > 14.0 and is_instance_valid(held_egg):
					held_egg.rub()
			Grab.SCANNER:
				hold_point = _floor_at(event.position, 0.0, 0.3)
			Grab.BROOM:
				hold_point = _floor_at(event.position, 0.0, 0.2)
			Grab.THING:
				if moved > 14.0 and is_instance_valid(held_thing):
					_drag_thing(event.position)
			Grab.SHELF:
				_drag_shelf(event)
			Grab.FLOOR:
				press_floor = _floor_at(event.position).limit_length(LIGHT_REACH)
				if light_on and (light_dragging or moved > 26.0):
					light_dragging = true
					light_goal = press_floor
	elif event is InputEventMouseMotion:
		hover_point = _floor_at(event.position)
		hover_time = clock
	elif event is InputEventMouseButton and event.pressed and shelf.has_point(event.position) and not _modal():
		# A mouse wheel over the wheel of things turns it
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			shelf.drag(90.0, 0.05)
		elif event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			shelf.drag(-90.0, 0.05)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and notebook.visible:
			notebook.close()
		elif _modal():
			return
		match event.keycode:
			KEY_F: use("bone")
			KEY_B: use("ball")
			KEY_L: toggle_lamp()
			KEY_M: toggle_sound()
			KEY_N: use("notebook")
			KEY_X: use("scanner")
			KEY_QUOTELEFT: dev_toggle()


func _press(e: InputEventScreenTouch) -> void:
	if _modal():
		return
	# Five quick taps in the top left corner open the test panel
	if Rect2(0, 0, 150, 150).has_point(e.position) and not dev.visible:
		dev_taps = dev_taps + 1 if clock - dev_tap_time < 0.6 else 1
		dev_tap_time = clock
		if dev_taps >= 5:
			dev_taps = 0
			dev_toggle()
			return
	if finger != -1 or _over_ui(e.position):
		return
	# A touch anywhere puts the scanner down
	if scanning and not shelf.has_point(e.position) and not shelf.on_tab(e.position):
		stop_scan()
		return
	finger = e.index
	press_time = clock
	press_at = e.position
	last_at = e.position
	moved = 0.0
	held_thing = null
	thing_new = false
	if shelf.on_tab(e.position):
		# The tab in the corner of the wheel: let go of, it tucks the wheel away or brings it back
		grab = Grab.TAB
	elif shelf.has_point(e.position):
		grab = Grab.SHELF
		shelf_item = shelf.item_at(e.position)
		sliding = false
		shelf.grab()
	elif scuffle != null and _ray_hits(e.position, scuffle.position + Vector3(0, 0.35, 0), 0.75):
		# A finger on the ball of dust breaks it up, and has hold of one of the two
		chosen = fighters[0].me
		held_pet = fighters[0]
		end_fight(true)
		grab = Grab.PET
		carrying = false
		_sync()
	elif _ray_hits(e.position, bulb.global_position + Vector3(0, 0.1, 0), 0.42):
		grab = Grab.LAMP
	elif ball != null and _ray_hits(e.position, ball.global_position, 0.5):
		_hold_ball(e.position)
	elif _snack_at(e.position) != null:
		held_snack = _snack_at(e.position)
		_hold_snack(e.position, true)
	elif _resident_at(e.position) != null:
		# One of them: it is the one in question from now on
		chosen = _resident_at(e.position)
		held_pet = chosen.pet
		held_egg = chosen.egg
		grab = Grab.EGG if held_egg != null else Grab.PET
		carrying = false
		_sync()
	else:
		held_thing = _thing_at(e.position)
		if held_thing != null:
			grab = Grab.THING
		else:
			grab = Grab.FLOOR
			press_floor = _floor_at(e.position).limit_length(LIGHT_REACH)


func _hold_ball(at: Vector2) -> void:
	grab = Grab.BALL
	ball.held = true
	ball.vel = Vector3.ZERO
	hold_vel = Vector3.ZERO
	hold_point = _floor_at(at, 0.75, 0.3)
	_notice_ball()


# A bit of food on the end of a finger: new off the row of things, or one that was lying in the
# room (which is nobody's to eat while it is held)
func _hold_snack(at: Vector2, lying: bool) -> void:
	grab = Grab.SNACK
	snack_lying = lying
	snacks.erase(held_snack)
	held_snack.hold()
	hold_point = _held_at(at, 0.75)
	if not lying:
		held_snack.position = hold_point


# Where a thing on the end of a finger hangs: under the finger, `height` off the floor where the
# room allows. Against a wall it rides up it, and in front of the room it follows the finger out
# over the row of things.
func _held_at(at: Vector2, height: float) -> Vector3:
	var from := camera.project_ray_origin(_in_view(at))
	var dir := camera.project_ray_normal(_in_view(at))
	var t := (height - from.y) / dir.y if dir.y < -0.001 else 60.0
	if dir.z < -0.001:
		t = minf(t, (-half.y + 0.3 - from.z) / dir.z)
	if absf(dir.x) > 0.001:
		t = minf(t, ((half.x - 0.3) * signf(dir.x) - from.x) / dir.x)
	return from + dir * t


# The bit of food lying in the room under a finger, or null
func _snack_at(at: Vector2) -> Snack:
	for s in snacks:
		if s.landed and _ray_hits(at, s.position + Vector3(0, 0.08, 0), 0.34):
			# (one of them standing behind it does not get in the way: the nearer is meant)
			var behind := _resident_at(at)
			if behind == null or camera.global_position.distance_to(s.position) < camera.global_position.distance_to(behind.body().position):
				return s
	return null


# A finger that came down on the wheel of things: sideways turns it, upwards pulls the thing off it
func _drag_shelf(e: InputEventScreenDrag) -> void:
	var gone := e.position - press_at
	# Up off the wheel, and not plainly a sideways swipe that strayed: the thing comes too
	if not shelf.has_point(e.position) and gone.y < -24.0 and shelf_item != "" and owns(shelf_item) and absf(gone.x) < maxf(absf(gone.y) * 2.5, 90.0):
		shelf.let_go()
		_pull(shelf_item, e.position)
	elif sliding:
		shelf.drag(e.relative.x, get_process_delta_time())
	elif absf(gone.x) > 16.0 and absf(gone.x) > absf(gone.y):
		sliding = true
	elif gone.y > 36.0 and gone.y > absf(gone.x) * 1.5:
		# A flick down on it tucks it away
		shelf_item = ""
		tuck(true)


# Something dragged up off the shelf: it comes into the room on the end of the finger
func _pull(id: String, at: Vector2) -> void:
	var item := Items.find(id)
	var n: int = item["n"]
	match item["group"]:
		"food":
			if pets().is_empty() or snacks.size() >= MAX_SNACKS:
				return
			held_snack = Snack.new(n)
			add_child(held_snack)
			_hold_snack(at, false)
		"toy":
			if pets().is_empty():
				return
			if ball != null and ball.kind != n:
				_clear_ball()
			if ball == null:
				_new_ball(n)
				ball.position = _floor_at(at, 0.75, 0.3)
			_hold_ball(at)
			_sync()
		"decor" when id == "marker":
			# One of those put away comes back out
			held_thing = _bring_marker(_floor_at(at, 0.0, 0.3))
			thing_new = false
			grab = Grab.THING
			moved = 15.0
			_sync()
		"decor":
			held_thing = decor_of(n)
			thing_new = held_thing == null
			if thing_new:
				held_thing = _stand(n, _floor_at(at, 0.0, 0.3), randf_range(-0.4, 0.4))
			grab = Grab.THING
			moved = 15.0
			_sync()
		"nest":
			set_nest(n)
			held_thing = nest
			grab = Grab.THING
			moved = 15.0
		"tool" when id == "scanner" and not scanning:
			# Carried up to whichever of them it is let go over
			grab = Grab.SCANNER
			hold_point = _floor_at(at, 0.0, 0.3)
			scanner.position = hold_point
			scanner.visible = true
		"tool" when id == "broom":
			# Carried about the floor, to sweep up whatever it is brought to
			grab = Grab.BROOM
			hold_point = _floor_at(at, 0.0, 0.2)
			if not broom.visible:
				broom.position = hold_point
				broom.visible = true
		_:
			# Grounds, eggs and the notebook have nothing to carry: dragging one up uses it
			shelf_item = ""
			use(id)


# A thing from the room following a finger across the floor. Nothing but the pool goes in the
# water; the pool itself goes to whichever part of the floor the finger is furthest into.
func _drag_thing(at: Vector2) -> void:
	if held_thing == nest:
		move_nest(_floor_at(at, 0.0, 0.6))
		return
	var d := held_thing as Decor
	# Held down over the wheel it is on its way back there: it is gone from the room, and the
	# wheel has it at its place
	d.visible = not _over_wheel(at)
	_offer("" if d.visible else Decor.IDS[d.kind])
	if d.kind == Decor.Kind.POOL:
		# (and the floor is whole again)
		floor_mat.set_shader_parameter("shore", shore if d.visible else Shore.NONE)
		# (and it is not moved by a finger on its way down there across the front of the room)
		var where := shore_near(_floor_at(at, 0.0, 0.0))
		if d.visible and where != shore and into(where, _floor_at(at, 0.0, 0.0)) > 0.3:
			_flood(d, where)
			splash(d.position)
	else:
		d.position = on_dry(_floor_at(at, 0.0, 0.0), d.radius * 0.6, d.radius)


func _release() -> void:
	var quick := clock - press_time < 0.3 and moved < 14.0
	# Let go of first: some of what follows opens things that let go of the finger themselves
	var was := grab
	grab = Grab.NONE
	finger = -1
	light_dragging_was = light_dragging
	light_dragging = false
	release_time = clock
	match was:
		Grab.TAB:
			tuck(not shelf.tucked)
		Grab.SHELF:
			shelf.let_go()
			if not sliding and moved < 14.0 and shelf_item != "":
				use(shelf_item)
		Grab.LAMP:
			if moved < 20.0:
				tap_lamp()
		Grab.BALL:
			stowing = ""
			shelf.bring("")
			if ball != null and _over_wheel(last_at):
				# Let go over the wheel, it is put away
				_clear_ball()
				sfx.play("click", 0.8)
				_sync()
				save_game()
			elif ball != null:
				ball.visible = true
				ball.held = false
				ball.vel = hold_vel.limit_length(7.5)
				_notice_ball()
				_sync()
		Grab.SCANNER:
			scanner.visible = false
			if not shelf.has_point(last_at):
				start_scan(_resident_at(last_at))
		Grab.SNACK:
			if held_snack != null:
				if shelf.has_point(last_at):
					# Put away again. One taken up off the floor untouched goes back into what is
					# left of its kind (the page the game is played in is not told).
					var id := Items.id_of("food", held_snack.kind)
					if snack_lying and held_snack.bites_left == Snack.BITES:
						_unspend(id)
					held_snack.queue_free()
				else:
					# Let go: it comes inside the walls (and far enough back not to lie under the row
					# of things, where a finger could not get at it again) and falls, and is anybody's
					var from := in_room(held_snack.position, 0.3)
					held_snack.drop(Vector3(from.x, maxf(from.y, 0.0), minf(from.z, half.y - 0.9)))
					if snack_lying:
						snacks.append(held_snack)
					else:
						_serve(held_snack)
				held_snack = null
		Grab.THING:
			if is_instance_valid(held_thing):
				if held_thing == nest:
					settle_nest()
				else:
					var d := held_thing as Decor
					d.visible = true
					stowing = ""
					shelf.bring("")
					if moved >= 14.0 and _over_wheel(last_at):
						remove_decor(d)
					elif thing_new:
						place_decor(d.kind, d.position)
					elif moved < 14.0 and quick:
						# (a tap on the pool calls them to that place in it, or on its edge)
						call_all(_floor_at(press_at, 0.0, 0.35) if d.kind == Decor.Kind.POOL else d.position + Vector3(0, 0, d.radius + 0.3))
					else:
						save_game()
			held_thing = null
		Grab.PET:
			var pet := held_pet
			held_pet = null
			if not is_instance_valid(pet):
				pass
			elif carrying:
				pet.put_down()
			elif quick:
				pet.boop()
				Input.vibrate_handheld(20)
			elif clock - press_time < 0.35 and moved > 80.0:
				# A flick: push it the way the finger went
				var way := _floor_at(last_at, 0.0, -7.0) - _floor_at(press_at, 0.0, -7.0)
				if way.length() > 0.05:
					pet.push(way)
					Input.vibrate_handheld(20)
			carrying = false
		Grab.EGG:
			if quick and is_instance_valid(held_egg):
				held_egg.tap()
				Input.vibrate_handheld(20)
			held_egg = null
		Grab.FLOOR:
			# A flick up from the bottom edge, where the wheel is tucked away, brings it back
			var up := press_at.y - last_at.y
			if shelf.tucked and press_at.y > shelf.global_position.y + (shelf.size.y - shelf.drop) * 0.5 and clock - press_time < 0.4 and up > 40.0 and up > absf(last_at.x - press_at.x) * 1.5:
				tuck(false)
			# (a tap on what they have left on the floor is a tap on the floor: it takes the broom
			# to clear it up)
			if quick and not light_dragging_was and not pets().is_empty():
				var there := _floor_at(press_at, 0.0, 0.35)
				call_all(there)
				ripple.position = Vector3(there.x, 0.02, there.z)
				ripple.scale = Vector3(0.08, 0.02, 0.08)
				ripple.visible = true


# ---------------------------------------------------------------- the site it may be played inside

# Inside another page (the station's basement): tell it when the room is on the screen, so it
# can lift whatever it was covering the load with, and take from it what has been bought.
#   out: {type: "CRYPTLINS_READY"}, {type: "CRYPTLINS_USED", item: <id>}
#        {type: "CRYPTLINS_SHOP"}: the keeper has asked for the ticket counter (the handbook's
#        Shop button); the game has saved, and expects to be hidden
#   in:  {type: "CRYPTLINS_STOCK", items: {<id>: <how many, or -1 for no end of them>}}
#        {type: "CRYPTLINS_SHOW"} and {type: "CRYPTLINS_HIDE"}: in front, or covered and left
# The page loads the game out of sight, so it rests (see rest) until it is first shown.
func _bridge() -> void:
	if not OS.has_feature("web"):
		return
	embedded = bool(JavaScriptBridge.eval("window.parent !== window", true))
	if not embedded:
		return
	_on_message = JavaScriptBridge.create_callback(_message)
	JavaScriptBridge.get_interface("window").addEventListener("message", _on_message)
	_sync()
	for i in 4:
		await get_tree().process_frame
	_post({"type": "CRYPTLINS_READY"})
	if not shown:
		rest(true)


func _inside_a_page() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("window.parent !== window", true))


# The Shop button in the handbook: the keeper wants the ticket counter. The game is saved, the
# handbook shut and the page told, which covers the game and takes them there.
func to_shop() -> void:
	if not embedded:
		return
	notebook.close()
	save_game()
	_post({"type": "CRYPTLINS_SHOP"})


func _post(message: Dictionary) -> void:
	if embedded:
		told.emit(message)
		JavaScriptBridge.eval("window.parent.postMessage(%s, '*')" % JSON.stringify(message), true)


func _message(args: Array) -> void:
	var data: Variant = JSON.parse_string(str(JavaScriptBridge.get_interface("JSON").stringify(args[0].data)))
	if not data is Dictionary:
		return
	match data.get("type"):
		"CRYPTLINS_STOCK":
			if data.get("items") is Dictionary:
				stock = data["items"]
				_sync()
		"CRYPTLINS_SHOW":
			shown = true
			rest(false)
		"CRYPTLINS_HIDE":
			rest(true)


# Out of sight (the page has covered the game, or not yet shown it): it saves, stops drawing
# and goes quiet, keeping its last picture. Back in front, each cryptlin lives through the time
# that went by, as it does when the game has been shut.
func rest(on: bool) -> void:
	if on == resting:
		return
	resting = on
	if on:
		if finger != -1:
			_release()
		save_game()
		rested_at = Time.get_unix_time_from_system()
	else:
		var gone := Time.get_unix_time_from_system() - rested_at
		if gone > 30.0:
			pass_time(gone)
	var draws := SubViewport.UPDATE_DISABLED if on else SubViewport.UPDATE_ALWAYS
	view.render_target_update_mode = draws
	shelf.view.render_target_update_mode = draws
	AudioServer.set_bus_mute(0, on or sfx.muted)
	get_tree().paused = on


# ---------------------------------------------------------------- the save

func save_game() -> void:
	save_timer = 0.0
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	var things: Array = []
	for d in decors:
		things.append({"k": d.kind, "x": d.position.x, "z": d.position.z, "r": d.rotation.y, "c": d.tint.to_html(false), "w": d.whose})
	var left: Array = []
	for m in messes:
		left.append({"k": m.kind, "x": m.position.x, "z": m.position.z, "t": m.made, "c": m.tint.to_html(false), "s": m.size})
	var living: Array = []
	for r in residents:
		living.append(r.to_save())
	file.store_string(JSON.stringify({
		"v": 3,
		"post": posted or embedded,
		"residents": living,
		"gone": departed.map(func(r: Resident) -> Dictionary: return r.to_save()),
		"markers": markers_away,
		"next_id": next_id,
		"floor": floor_style,
		"nest": nest_style,
		"nest_at": [nest_pos.x, nest_pos.z],
		"decor": things,
		"mess": left,
		"toy": {"k": ball.kind, "x": ball.position.x, "z": ball.position.z, "w": ball.wear, "b": ball.bought} if ball != null else {},
		"toybox": toybox,
		"scuffs": scuffs,
		"broken": broken,
		"used": used,
		"tucked": shelf.tucked if shelf != null else saved_tucked,
		"lamp": lamp_mode,
		"muted": sfx.muted if sfx != null else false,
		"time": Time.get_unix_time_from_system(),
	}))


# Reads the save and notes how long it has been. With no save the room is left empty, and
# _ready puts the first egg in it.
func _load_game() -> void:
	var data: Variant = null
	if FileAccess.file_exists(save_path):
		data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		return
	var d: Dictionary = data
	var now := Time.get_unix_time_from_system()
	# Inside the station nobody is given an egg for nothing any more: theirs comes in the post.
	# A save from when the room gave one loses who was in it, once; the room is left as it was.
	posted = bool(d.get("post", false))
	if _inside_a_page() and not posted:
		for key: String in ["residents", "gone", "markers"]:
			d.erase(key)
		d["v"] = 3
	if d.get("residents") is Array:
		for saved: Variant in d["residents"]:
			if saved is Dictionary and residents.size() < MAX_RESIDENTS:
				residents.append(Resident.from_save(saved))
	elif int(d.get("v", 1)) < 3:
		# Saves from when there was only ever one: a room with that one in it. (The oldest of
		# them, from before there were eggs, hold a hatched gremlin.)
		var only := Resident.from_save(d)
		only.name = str(d.get("name", "Grubnik"))
		if int(d.get("v", 1)) < 2 and only.needs.has("age"):
			# Saves from when a baby grew up in seven minutes: as far along now as it was then
			only.needs["age"] = clampf(float(only.needs["age"]) / 420.0, 0.0, 1.0) * Cryptlin.GROW_AGE
		only.born = float(d.get("born", now - float(only.needs.get("age", Cryptlin.GROW_AGE))))
		residents.append(only)
	if d.get("gone") is Array:
		for saved: Variant in d["gone"]:
			if saved is Dictionary:
				departed.append(Resident.from_save(saved))
	if d.get("markers") is Array:
		markers_away = d["markers"]
	# Each has a number of its own (those from older saves are given theirs now)
	next_id = int(d.get("next_id", 1))
	for r in residents + departed:
		if r.id <= 0:
			r.id = next_id
		next_id = maxi(next_id, r.id + 1)
	floor_style = clampi(int(d.get("floor", 0)), 0, GROUNDS.size() - 1)
	nest_style = clampi(int(d.get("nest", 0)), 0, Decor.NESTS.size() - 1)
	if d.get("nest_at") is Array and d["nest_at"].size() == 2:
		nest_pos = in_room(Vector3(float(d["nest_at"][0]), 0, float(d["nest_at"][1])), 0.6)
	if d.get("decor") is Array:
		saved_decor = d["decor"]
	if d.get("mess") is Array:
		saved_mess = d["mess"]
	# The toy on the floor and those put away, and how worn each is (a save from before toys wore
	# out has none of this: nothing was out, and whatever comes out is as good as new)
	if d.get("toy") is Dictionary:
		saved_toy = d["toy"]
	if d.get("toybox") is Dictionary:
		for id: String in d["toybox"]:
			if Items.find(id).get("group", "") == "toy" and d["toybox"][id] is Array:
				toybox[id] = d["toybox"][id]
	if d.get("scuffs") is Dictionary:
		for id: String in d["scuffs"]:
			scuffs[id] = clampf(float(d["scuffs"][id]), 0.0, Ball.WORN_OUT - 1.0)
	if d.get("broken") is Dictionary:
		for id: String in d["broken"]:
			broken[id] = float(d["broken"][id])
	if d.get("used") is Dictionary:
		for id: String in d["used"]:
			used[id] = int(d["used"][id])
	saved_tucked = bool(d.get("tucked", false))
	lamp_mode = clampi(int(d.get("lamp", Lamp.BRIGHT)), 0, LAMPS.size() - 1)
	away = maxf(now - float(d.get("time", now)), 0.0)
	_muted_at_start = bool(d.get("muted", false))


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and shelf != null:
		save_game()
