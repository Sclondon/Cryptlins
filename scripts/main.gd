class_name Den
extends Node
## Cryptlins: a bare bulb in a brick basement and the little monsters that live under it.
## This builds the room, the lamp and the shelf of things, reads the touches and keeps the save.
## Up to four live here at once (see Resident): each starts as an egg (scripts/egg.gd) and is a
## cryptlin once it hatches. `who()` is the one in question when a single one is meant.
## Nothing is written on the screen to say how any of it works: that is all in the notebook.

enum Grab { NONE, FLOOR, PET, BALL, EGG, SHELF, THING, SNACK, LAMP, SCANNER }
enum Lamp { BRIGHT, LOW, HEAT, OFF }

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
const NAME_HEADS: Array[String] = ["Grub", "Mog", "Snag", "Fizz", "Bork", "Nib", "Skrit", "Womp", "Gloom", "Pim", "Zog", "Murk"]
const NAME_TAILS: Array[String] = ["nik", "let", "wort", "bo", "gle", "kin", "zle", "by", "mort", "ix"]
const EGG_SPOT := Vector3(0, 0, 0.3)
const GROUNDS: Array[String] = ["Flagstones", "Floorboards", "Moss", "Checkers", "Dirt", "Sand", "Gravel"]
# As in "it is happiest on ..."
const GROUND_PLAIN: Array[String] = ["flagstones", "floorboards", "moss", "checkered tiles", "dirt", "sand", "gravel"]
const SCAN_SECONDS := 9.0
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
var ball: Ball
var snacks: Array[Snack] = []
var decors: Array[Decor] = []
# What the cryptlins have left on the floor (see Mess)
var messes: Array[Mess] = []
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
var stock := {}
var _on_message: JavaScriptObject
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
# The cryptlin or the egg a finger came down on
var held_pet: Cryptlin
var held_egg: Egg

# The scanner, and the one it is held up to
var scanned: Resident
var scanning := false
var scan_time := 0.0
var scanner: Node3D
var sweep: MeshInstance3D

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
	_load_game()
	_build_room()
	_build_lamp()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.muted = _muted_at_start
	_build_hud()
	for d: Variant in saved_decor:
		if d is Dictionary and int(d.get("k", -1)) >= 0 and int(d["k"]) < Decor.IDS.size():
			_stand(int(d["k"]), Vector3(float(d.get("x", 0.0)), 0, float(d.get("z", 0.0))), float(d.get("r", 0.0)))
	for m: Variant in saved_mess:
		if m is Dictionary and int(m.get("k", -1)) >= 0 and int(m["k"]) < Mess.LASTS.size():
			var laid := _lay_mess(int(m["k"]), Vector3(float(m.get("x", 0.0)), 0, float(m.get("z", 0.0))), float(m.get("t", 0.0)), Color.html(str(m.get("c", "4d331a"))), float(m.get("s", 1.0)))
			laid.visible = laid.gone() < 1.0
	get_viewport().size_changed.connect(_fit)
	_fit()
	if OS.has_feature("web") and str(JavaScriptBridge.eval("window.location.search", true)).contains("dev"):
		dev_toggle()
	for r in residents:
		if r.hatched:
			_spawn_pet(r, Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.6, 0.8)))
		else:
			_lay_egg(r, false)
	if residents.is_empty():
		# A new game, or a room with nobody left in it: one egg for nothing
		new_egg(first_kind)
		_say("An egg!")
	elif pets().is_empty():
		_say("Still an egg")
	# They have been living their lives while the game was shut (grown, asleep, hungry, glad to
	# see you: they show all that themselves)
	if away > 0.0:
		pass_time(away)
		away = 0.0
	_bridge()


# Keeps a point on the floor inside the walls, `margin` clear of them
static func in_room(p: Vector3, margin := 0.0) -> Vector3:
	return Vector3(clampf(p.x, -half.x + margin, half.x - margin), p.y, clampf(p.z, -half.y + margin, half.y - margin))


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
# in): each of them lives through it, and is found asleep in the nest if that is how it ended
func pass_time(seconds: float) -> void:
	for pet in pets():
		if pet.pass_time(seconds, not light_on):
			pet.position = nest_pos + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
			pet._enter(Cryptlin.State.SLEEP)
		elif pet.state == Cryptlin.State.SLEEP:
			pet._enter(Cryptlin.State.IDLE)
	_sync()


# ---------------------------------------------------------------- eggs and hatchlings

# Drops a new egg into the room: of a given kind, or of any that is not here already (nor
# `not_kind`, the kind of one that has just gone)
func new_egg(kind := -1, not_kind := -1) -> Resident:
	var r := Resident.new()
	r.id = next_id
	next_id += 1
	r.look_seed = randi() % 1000000 + 1
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
	egg.position = in_room(r.at if r.at != Vector3.INF else EGG_SPOT, 0.4)
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
	_say("It hatched!") # (what it is, is for the notebook)
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
	_say("This is %s" % naming.name)
	_sync()
	save_game()


# "Let go" on a cryptlin's page of the notebook: asks first, since it sends it away for good
func ask_let_go(r: Resident) -> void:
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
		_say("Goodbye, %s" % parting.name)
		_sync()


func _on_left(r: Resident) -> void:
	r.pet.queue_free()
	r.pet = null
	residents.erase(r)
	if pets().is_empty():
		_clear_toys()
	if residents.is_empty():
		# Nobody is left: an egg comes for nothing, and never the same kind twice running
		if not light_on:
			set_lamp(Lamp.BRIGHT)
		new_egg(-1, r.kind)
		_say("An egg!")
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
	if finger != -1:
		_release()
	stop_scan()
	ask.visible = false
	namer.visible = false
	var r := who()
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
		r.look_seed = randi() % 1000000 + 1
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


func _dev_step(by: int) -> void:
	dev_show(who().kind + by)


func _dev_look() -> void:
	dev_show(who().kind, who().egg != null, true)


# With a cryptlin: its egg instead. With an egg: hatch it now.
func _dev_egg() -> void:
	if who().egg != null:
		who().egg.warmth = 100.0
	else:
		dev_show(who().kind, true)


# Baby to adult and back
func _dev_age() -> void:
	var pet := who().pet
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
	var others := 0
	for d in decors:
		if d.kind in who.like_decor:
			c += 14.0
		elif d.kind == who.hate_decor:
			c -= 18.0
		else:
			others += 1
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
	return not embedded or id in Items.FREE or int(stock.get(id, 0)) != 0


# How many of a thing that gets used up are left, or -1 for no end of them
func left_of(id: String) -> int:
	if not embedded or id in Items.FREE:
		return -1
	return int(stock.get(id, 0))


func _spend(id: String) -> void:
	if left_of(id) > 0:
		stock[id] = left_of(id) - 1
		_post({"type": "CRYPTLINS_USED", "item": id})
		_sync()


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
		"decor":
			# In if it is out, out if it is in
			var there := decor_of(n)
			if there != null:
				remove_decor(there)
			else:
				place_decor(n, _free_spot(Decor.RADII[n]))
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
	snacks.append(snack)
	_spend(Items.id_of("food", snack.kind))


# Throws a toy in: a given one, or whichever is out already (the ball, if none is)
func play_ball(which := -1) -> void:
	if pets().is_empty():
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


func _new_ball(which: int) -> void:
	var toy := Ball.new(which)
	ball = toy
	add_child(ball)
	ball.bounced.connect(func(strength: float) -> void: sfx.play(toy.sound, toy.pitch, clampf(strength * 3.0 - 16.0, -24.0, -3.0)))


func _clear_ball() -> void:
	if ball != null:
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


func _stand(kind: int, at: Vector3, turn := 0.0) -> Decor:
	var d := Decor.new(kind)
	add_child(d)
	d.position = in_room(at, d.radius * 0.6)
	d.rotation.y = turn
	decors.append(d)
	return d


# Stands a thing in the room (or moves the one of its kind already there), and lets the
# cryptlins come and see what they think of it
func place_decor(kind: int, at: Vector3) -> Decor:
	var d := decor_of(kind)
	if d == null:
		d = _stand(kind, at, randf_range(-0.4, 0.4))
		crumbs(d.position + Vector3(0, 0.1, 0), Color(0.3, 0.25, 0.2))
		sfx.play("thud", 1.1, -6.0)
	else:
		d.position = in_room(at, d.radius * 0.6)
	_judge(d)
	_sync()
	save_game()
	return d


func remove_decor(d: Decor) -> void:
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
		var near := d.position + Vector3((i - (all.size() - 1) * 0.5) * 0.55, 0, d.radius + 0.35)
		if d.kind == Decor.Kind.POOL:
			# Whether it needs water shows the first time it sees some
			pet.look_over(near, 1 if pet.needs_water() else 0, "water")
		elif d.kind in pet.like_decor:
			pet.look_over(near, 1, "decor+" + id)
		elif d.kind == pet.hate_decor:
			pet.look_over(near, -1, "decor-" + id)
		else:
			pet.look_over(near, 0, "")


# How much bare floor there is round a place: how far to the nearest thing, nest, egg or cryptlin
func _clearance(p: Vector3) -> float:
	var room := p.distance_to(nest_pos) - 0.6
	for d in decors:
		room = minf(room, p.distance_to(d.position) - d.radius)
	for r in residents:
		if r.body() != null:
			room = minf(room, Vector2(p.x - r.body().position.x, p.z - r.body().position.z).length() - 0.4)
	return room


# Somewhere on the floor with nothing standing on it
func _free_spot(radius: float) -> Vector3:
	var best := Vector3.ZERO
	var best_room := -INF
	for i in 24:
		var p := Vector3(randf_range(-half.x + radius + 0.2, half.x - radius - 0.2), 0, randf_range(-half.y + radius + 0.1, half.y - radius - 0.7))
		if _clearance(p) > best_room:
			best_room = _clearance(p)
			best = p
	return best


# A place for an egg: the given one if it is clear, or else the clearest to be found within
# `reach` of it (near enough the middle for the lamp to warm it)
func _clear_spot(centre: Vector3, reach: float) -> Vector3:
	var best := in_room(centre, 0.4)
	var best_room := _clearance(best)
	for i in 24:
		if best_room > 0.25:
			break
		var a := randf() * TAU
		var p := in_room(centre + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, reach), 0.4)
		if _clearance(p) > best_room:
			best_room = _clearance(p)
			best = p
	return best


func set_ground(style: int) -> void:
	floor_style = clampi(style, 0, GROUNDS.size() - 1)
	floor_mat.set_shader_parameter("style", floor_style)
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
	nest_pos = in_room(Vector3(to.x, 0, to.z), 0.6)
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
		if in_room(s, 0.6).distance_to(nest_pos) > 0.8:
			far.append(in_room(s, 0.6))
	return far.pick_random() if not far.is_empty() else in_room(Vector3(randf_range(-1.5, 1.5), 0, -1.2), 0.6)


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
			return in_room(d.position + Vector3(0, 0, -d.radius - 0.4), 0.35)
	return in_room(Vector3(9.0 if randf() < 0.5 else -9.0, 0, -9.0), 0.5)


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
	m.position = in_room(Vector3(at.x, 0, at.z), 0.15)
	m.rotation.y = randf() * TAU
	messes.append(m)
	return m


# The keeper clears one up
func clear_mess(m: Mess) -> void:
	crumbs(m.position + Vector3(0, 0.08, 0), m.tint)
	sfx.play("click", 1.4, -4.0)
	messes.erase(m)
	m.queue_free()
	save_game()


func droppings() -> int:
	var n := 0
	for m in messes:
		if m.kind == Mess.Kind.DROPPING:
			n += 1
	return n


# The mess under a finger (not a heap of earth, which is nothing to clear), or null
func _mess_at(at: Vector2) -> Mess:
	for m in messes:
		if m.kind != Mess.Kind.HEAP and _ray_hits(at, m.position + Vector3(0, 0.06, 0), 0.24):
			return m
	return null


# Where a cryptlin goes to do its business: a grown one as far as it can get from its nest and
# anything to eat, in a corner or behind something; a baby more or less where it stands
func toilet_spot(who: Cryptlin) -> Vector3:
	if who.is_baby():
		var a := randf() * TAU
		return in_room(who.position + Vector3(cos(a), 0, sin(a)) * randf_range(0.2, 0.6), 0.3)
	var spots: Array[Vector3] = []
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 0.05]:
			spots.append(in_room(Vector3(9.0 * x, 0, 9.0 * z), 0.4))
	for d in decors:
		spots.append(in_room(d.position + Vector3(0, 0, -d.radius - 0.35), 0.4))
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

# Holds the scanner up to one of them (or its egg) for a few seconds: its outline, its bones,
# and how full, rested, amused and fond it is. To the one it is given; or else the one last
# tapped; or else whichever is nearest the middle of the room.
func start_scan(r: Resident = null) -> void:
	if r == null:
		r = chosen if chosen in residents else _nearest_resident(Vector3.ZERO)
	if r == null or r.leaving or r.body() == null or scanning:
		sfx.play("click", 0.7)
		return
	chosen = r
	scanned = r
	scanning = true
	scan_time = 0.0
	scanner.visible = true
	if r.pet != null:
		r.pet.xray(true)
		r.pet.hold_still()
	sfx.play("jingle", 0.6, -8.0)
	_sync()


func stop_scan() -> void:
	if not scanning:
		return
	scanning = false
	scanner.visible = false
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


func _aim_scanner() -> void:
	var pet := scanned.pet
	var middle := scanned.egg.centre() if pet == null else pet.global_position + Vector3(0, pet.tall() * 0.5, 0)
	var tall := 0.9 if pet == null else pet.tall()
	var size := maxf(tall, 0.5) / 0.6
	var toward := (camera.global_position - middle).normalized()
	scanner.scale = Vector3.ONE * size
	scanner.global_position = middle + toward * 0.75 - Vector3(0, 0.62 * size, 0)
	scanner.rotation = Vector3(0, atan2(toward.x, toward.z), 0)
	sweep.position.y = 0.62 + sin(scan_time * 3.0) * 0.3


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


func _note(from: Vector2, offset: Vector2, title: String, word: String, value: float, colour: Color, screen_size: Vector2) -> void:
	var font := scan_notes.get_theme_default_font()
	var wide := maxf(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, 120.0)
	var at := from + offset
	# Kept on the screen, and clear of the shelf
	at.x = clampf(at.x, wide * 0.5 + 12.0, screen_size.x - wide * 0.5 - 12.0)
	at.y = clampf(at.y, 40.0, shelf.position.y - 60.0)
	var left := at.x - wide * 0.5
	scan_notes.draw_line(from, Vector2(clampf(from.x, left, left + wide), at.y + 8.0), Color(colour, 0.7), 2.0)
	scan_notes.draw_circle(from, 4.0, colour)
	scan_notes.draw_string_outline(font, Vector2(left, at.y), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 6, Color(0, 0, 0, 0.85))
	scan_notes.draw_string(font, Vector2(left, at.y), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, colour)
	# How much, in five pips
	for i in 5:
		var pip := Rect2(left + i * 18.0, at.y + 7.0, 14.0, 7.0)
		scan_notes.draw_rect(pip.grow(1.5), Color(0, 0, 0, 0.7))
		scan_notes.draw_rect(pip, colour if value >= i * 20.0 + 10.0 else Color(colour, 0.22))
	scan_notes.draw_string_outline(font, Vector2(left, at.y + 36.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color(0, 0, 0, 0.85))
	scan_notes.draw_string(font, Vector2(left, at.y + 36.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Icons.BONE)


# ---------------------------------------------------------------- keeping the shelf and the pages up to date

func _sync() -> void:
	if shelf == null:
		return
	var have: Array[String] = []
	var marks := {}
	var counts := {}
	var out := {}
	for item in Items.LIST:
		var id: String = item["id"]
		if not owns(id):
			continue
		have.append(id)
		if item["group"] in Items.SPENT and left_of(id) >= 0:
			counts[id] = left_of(id)
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
	out[Items.id_of("ground", floor_style)] = true
	out[Items.id_of("nest", nest_style)] = true
	for d in decors:
		out[Decor.IDS[d.kind]] = true
	if ball != null:
		out[Items.id_of("toy", ball.kind)] = true
	if scanning:
		out["scanner"] = true
	shelf.marks = marks
	shelf.counts = counts
	shelf.out = out
	shelf.stock(have)
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
	sweep = Ps1.part(scanner, Ps1.box(), Ps1.mat(Color(0.3, 1.0, 0.5), 1.0), Vector3(0, 0.62, 0), Vector3(0.66, 0.015, 0.02))
	scanner.visible = false
	add_child(scanner)

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
	for d in decors:
		d.position = in_room(d.position, d.radius * 0.6)
	if ball != null:
		ball.position = in_room(ball.position, Ball.R)
	for m in messes:
		m.position = in_room(m.position, 0.15)
	for s in snacks:
		s.position = in_room(s.position, 0.2)
	for r in residents:
		if r.egg != null:
			r.egg.position = in_room(r.egg.position, 0.4)


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
	shelf.position = Vector2(0, size.y - deep)
	shelf.size = Vector2(size.x, deep)
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


# Water thrown up by something wading in the pool
func splash(at: Vector3) -> void:
	crumbs(Vector3(at.x, Decor.WATER + 0.05, at.z), Color(0.5, 0.75, 0.9))
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
	spot.spot_angle = lamp_angle
	spot.visible = light_level > 0.001
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
		scanner.scale = Vector3.ONE
		scanner.position = scanner.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))
		scanner.rotation = Vector3.ZERO

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
		elif r.pet != null and not r.leaving:
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


# The thing standing in the room under a finger (the nest counts), or null
func _thing_at(at: Vector2) -> Node3D:
	for d in decors:
		if _ray_hits(at, d.position + Vector3(0, minf(d.radius, 0.4), 0), maxf(d.radius, 0.34)):
			return d
	if _ray_hits(at, nest_pos + Vector3(0, 0.1, 0), 0.55):
		return nest
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
			Grab.SNACK:
				hold_point = _floor_at(event.position, 0.9, 0.3)
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
		# A mouse wheel over the shelf slides it along
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
	if scanning and not shelf.has_point(e.position):
		stop_scan()
		return
	finger = e.index
	press_time = clock
	press_at = e.position
	last_at = e.position
	moved = 0.0
	held_thing = null
	thing_new = false
	if shelf.has_point(e.position):
		grab = Grab.SHELF
		shelf_item = shelf.item_at(e.position)
		sliding = false
		shelf.grab()
	elif _ray_hits(e.position, bulb.global_position + Vector3(0, 0.1, 0), 0.42):
		grab = Grab.LAMP
	elif ball != null and _ray_hits(e.position, ball.global_position, 0.5):
		_hold_ball(e.position)
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


# A finger that came down on the shelf: sideways slides it, upwards pulls the thing off it
func _drag_shelf(e: InputEventScreenDrag) -> void:
	var gone := e.position - press_at
	# Up over the shelf's edge, and not plainly a sideways swipe that strayed: the thing comes too
	if e.position.y < shelf.global_position.y - 6.0 and shelf_item != "" and owns(shelf_item) and absf(gone.x) < maxf(absf(gone.y) * 2.5, 90.0):
		shelf.let_go()
		_pull(shelf_item, e.position)
	elif sliding:
		shelf.drag(e.relative.x, get_process_delta_time())
	elif absf(gone.x) > 16.0 and absf(gone.x) > absf(gone.y):
		sliding = true


# Something dragged up off the shelf: it comes into the room on the end of the finger
func _pull(id: String, at: Vector2) -> void:
	var item := Items.find(id)
	var n: int = item["n"]
	match item["group"]:
		"food":
			if pets().is_empty() or snacks.size() >= MAX_SNACKS:
				return
			held_snack = Snack.new(n)
			held_snack.set_process(false)
			add_child(held_snack)
			hold_point = _floor_at(at, 0.9, 0.3)
			held_snack.position = hold_point
			grab = Grab.SNACK
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
		_:
			# Grounds, eggs and the notebook have nothing to carry: dragging one up uses it
			shelf_item = ""
			use(id)


# A thing from the room following a finger across the floor
func _drag_thing(at: Vector2) -> void:
	if held_thing == nest:
		move_nest(_floor_at(at, 0.0, 0.6))
	else:
		var d := held_thing as Decor
		d.position = _floor_at(at, 0.0, d.radius * 0.6)
		# Held over the shelf it is on its way back there
		d.scale = Vector3.ONE * (0.6 if shelf.has_point(at) else 1.0)


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
		Grab.SHELF:
			shelf.let_go()
			if not sliding and moved < 14.0 and shelf_item != "":
				use(shelf_item)
		Grab.LAMP:
			if moved < 20.0:
				tap_lamp()
		Grab.BALL:
			if ball != null:
				ball.held = false
				ball.vel = hold_vel.limit_length(7.5)
			_notice_ball()
		Grab.SCANNER:
			scanner.visible = false
			if not shelf.has_point(last_at):
				start_scan(_resident_at(last_at))
		Grab.SNACK:
			if held_snack != null:
				if shelf.has_point(last_at):
					held_snack.queue_free()
				else:
					held_snack.set_process(true)
					held_snack.drop(held_snack.position)
					_serve(held_snack)
				held_snack = null
		Grab.THING:
			if is_instance_valid(held_thing):
				if held_thing == nest:
					settle_nest()
				else:
					var d := held_thing as Decor
					d.scale = Vector3.ONE
					if shelf.has_point(last_at):
						remove_decor(d)
					elif thing_new:
						place_decor(d.kind, d.position)
					elif moved < 14.0 and quick:
						call_all(d.position + Vector3(0, 0, d.radius + 0.3))
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
			var mess := _mess_at(press_at) if quick and not light_dragging_was else null
			if mess != null:
				clear_mess(mess)
			elif quick and not light_dragging_was and not pets().is_empty():
				var there := _floor_at(press_at, 0.0, 0.35)
				call_all(there)
				ripple.position = Vector3(there.x, 0.02, there.z)
				ripple.scale = Vector3(0.08, 0.02, 0.08)
				ripple.visible = true


# ---------------------------------------------------------------- the site it may be played inside

# Inside another page (the station's basement): tell it when the room is on the screen, so it
# can lift whatever it was covering the load with, and take from it what has been bought.
#   out: {type: "CRYPTLINS_READY"}, {type: "CRYPTLINS_USED", item: <id>}
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


func _post(message: Dictionary) -> void:
	if embedded:
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
		things.append({"k": d.kind, "x": d.position.x, "z": d.position.z, "r": d.rotation.y})
	var left: Array = []
	for m in messes:
		left.append({"k": m.kind, "x": m.position.x, "z": m.position.z, "t": m.made, "c": m.tint.to_html(false), "s": m.size})
	var living: Array = []
	for r in residents:
		living.append(r.to_save())
	file.store_string(JSON.stringify({
		"v": 3,
		"residents": living,
		"next_id": next_id,
		"floor": floor_style,
		"nest": nest_style,
		"nest_at": [nest_pos.x, nest_pos.z],
		"decor": things,
		"mess": left,
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
	# Each has a number of its own (those from older saves are given theirs now)
	next_id = int(d.get("next_id", 1))
	for r in residents:
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
	lamp_mode = clampi(int(d.get("lamp", Lamp.BRIGHT)), 0, LAMPS.size() - 1)
	away = maxf(now - float(d.get("time", now)), 0.0)
	_muted_at_start = bool(d.get("muted", false))


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and shelf != null:
		save_game()
