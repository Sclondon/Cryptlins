class_name Items
extends RefCounted
## Everything that sits on the shelf under the tank: the notebook and the scanner, eggs, food, toys,
## things to stand on the floor, nests and grounds. `n` is the item's number within its
## group (Snack.Kind, Ball.Kind, Decor.Kind, and so on).

const LIST: Array[Dictionary] = [
	{"id": "notebook", "group": "tool", "n": 0, "name": "Cryptlin Handbook"},
	{"id": "scanner", "group": "tool", "n": 1, "name": "Scanner"},
	{"id": "broom", "group": "tool", "n": 2, "name": "Broom"},
	{"id": "egg", "group": "egg", "n": 0, "name": "Egg"},
	{"id": "bone", "group": "food", "n": 0, "name": "Bone"},
	{"id": "toadstool", "group": "food", "n": 1, "name": "Toadstool"},
	{"id": "candy", "group": "food", "n": 2, "name": "Candy corn"},
	{"id": "fish", "group": "food", "n": 3, "name": "Fish"},
	{"id": "beetle", "group": "food", "n": 4, "name": "Beetle"},
	{"id": "berries", "group": "food", "n": 5, "name": "Berries"},
	{"id": "ball", "group": "toy", "n": 0, "name": "Ball"},
	{"id": "stone", "group": "toy", "n": 1, "name": "Stone"},
	{"id": "bell", "group": "toy", "n": 2, "name": "Bell"},
	{"id": "glow", "group": "toy", "n": 3, "name": "Glow orb"},
	{"id": "rock", "group": "decor", "n": 0, "name": "Rock"},
	{"id": "log", "group": "decor", "n": 1, "name": "Hollow log"},
	{"id": "fern", "group": "decor", "n": 2, "name": "Fern"},
	{"id": "skull", "group": "decor", "n": 3, "name": "Skull"},
	{"id": "crystal", "group": "decor", "n": 4, "name": "Crystal"},
	{"id": "pumpkin", "group": "decor", "n": 5, "name": "Pumpkin"},
	{"id": "gravestone", "group": "decor", "n": 6, "name": "Gravestone"},
	{"id": "dish", "group": "decor", "n": 7, "name": "Water dish"},
	{"id": "cave", "group": "decor", "n": 8, "name": "Cave"},
	{"id": "pool", "group": "decor", "n": 9, "name": "Pool"},
	{"id": "barrel", "group": "decor", "n": 10, "name": "Barrel"},
	{"id": "stump", "group": "decor", "n": 11, "name": "Hollow stump"},
	{"id": "tent", "group": "decor", "n": 12, "name": "Rag tent"},
	{"id": "crate", "group": "decor", "n": 13, "name": "Crate"},
	{"id": "pot", "group": "decor", "n": 14, "name": "Flowerpot"},
	{"id": "rags", "group": "nest", "n": 0, "name": "Rag nest"},
	{"id": "twigs", "group": "nest", "n": 1, "name": "Twig nest"},
	{"id": "cushion", "group": "nest", "n": 2, "name": "Cushion"},
	{"id": "box", "group": "nest", "n": 3, "name": "Cardboard box"},
	{"id": "flagstones", "group": "ground", "n": 0, "name": "Flagstones"},
	{"id": "floorboards", "group": "ground", "n": 1, "name": "Floorboards"},
	{"id": "moss", "group": "ground", "n": 2, "name": "Moss"},
	{"id": "checkers", "group": "ground", "n": 3, "name": "Checkered tiles"},
	{"id": "dirt", "group": "ground", "n": 4, "name": "Dirt"},
	{"id": "sand", "group": "ground", "n": 5, "name": "Sand"},
	{"id": "gravel", "group": "ground", "n": 6, "name": "Gravel"},
]
# What every keeper has without buying it. The rest come from the shop when the game is played
# inside a site that keeps one (see Den.stock), eggs among them: a room there is never given an
# egg for nothing. Played by itself, everything is on the shelf.
const FREE: Array[String] = ["notebook", "scanner", "broom", "rags", "dirt"]
# What every keeper there is given, once, and how many: used up or broken, they are gone, and more are bought
const GIVEN := {"bone": 3, "ball": 1}
# Used up when used: each one fed, or each egg laid, is one fewer on the shelf
const SPENT: Array[String] = ["food", "egg"]
# The order things ride in round the wheel, by id or by group: the scanner first and the notebook
# last, whatever order LIST is in (which saves and the shop go by, and is not to be renumbered)
const ROW: Array[String] = ["scanner", "broom", "food", "toy", "egg", "decor", "nest", "ground", "notebook"]
# Never bought or sold: on the shelf only while the keeper has one put away
const KEPT: Array[String] = ["gravestone"]
# On the scanner (see scanner()): how far up its barrel runs, the middle of the mouth of its cone
# and how wide that is (as a radius), and the middle and size of the readout on its back
const BORE := 0.56
const MUZZLE := Vector3(0, BORE, -0.54)
const MOUTH := 0.22
const READOUT := Vector3(0, BORE + 0.01, 0.35)
const READOUT_SIZE := Vector2(0.19, 0.14)
# How far the broom leans when nobody is sweeping with it (see broom())
const BROOM_LEAN := -0.3


static func find(id: String) -> Dictionary:
	for item in LIST:
		if item["id"] == id:
			return item
	return {}


static func id_of(group: String, n: int) -> String:
	for item in LIST:
		if item["group"] == group and item["n"] == n:
			return item["id"]
	return ""


# The item as it looks on the shelf, standing on the origin and about two thirds of a unit across
static func model(id: String) -> Node3D:
	var item := find(id)
	var n: int = item["n"]
	var holder := Node3D.new()
	match item["group"]:
		"food":
			var snack := Snack.new(n)
			snack.hold()
			snack.scale = Vector3.ONE * 2.0
			holder.add_child(snack)
		"toy":
			var toy := Ball.new(n)
			toy.held = true
			toy.position.y = Ball.R * 1.8
			toy.scale = Vector3.ONE * 1.8
			holder.add_child(toy)
		"decor":
			var thing := Decor.new(n)
			# (the big ones are shrunk to fit)
			thing.scale = Vector3.ONE * minf(0.95, 0.36 / Decor.RADII[n])
			holder.add_child(thing)
		"nest":
			var bed := Decor.nest(n)
			bed.scale = Vector3.ONE * 0.55
			holder.add_child(bed)
		"egg":
			# A plain pale egg: what is painted on the one that drops in is anybody's guess
			Ps1.part(holder, Ps1.ball(), Ps1.mat(Color(0.86, 0.82, 0.7)), Vector3(0, 0.36, 0), Vector3(Egg.WIDTH, Egg.HEIGHT, Egg.WIDTH) * 0.95)
			Ps1.part(holder, Ps1.ball(), Ps1.mat(Color(0.3, 0.24, 0.18)), Vector3(0, 0.02, 0), Vector3(0.3, 0.04, 0.3))
		"ground":
			# A tray of it
			var mat := ShaderMaterial.new()
			mat.shader = load("res://shaders/floor.gdshader")
			mat.set_shader_parameter("style", n)
			var top := PlaneMesh.new()
			top.size = Vector2(0.62, 0.62)
			Ps1.part(holder, top, mat, Vector3(0, 0.1, 0))
			Ps1.part(holder, Ps1.box(), Ps1.mat(Color(0.2, 0.15, 0.11)), Vector3(0, 0.045, 0), Vector3(0.68, 0.09, 0.68))
			holder.rotation.x = 0.5
			holder.position.y = 0.12
		_:
			if id == "notebook":
				holder.add_child(notebook())
			elif id == "broom":
				var b := broom()
				b.scale = Vector3.ONE * 0.86
				b.position = Vector3(0.02, 0.02, 0)
				holder.add_child(b)
			else:
				# Side on, its cone to the left and a little of its back showing
				var s := scanner()
				s.scale = Vector3.ONE * 0.8
				s.rotation.y = 0.7
				s.position = Vector3(0.07, 0.04, 0)
				holder.add_child(s)
	return holder


# The Cryptlin Handbook: a small ring-bound notebook, shut, with its name on a pasted label on
# the cover (two lines of it, at the size it is drawn) and a pencil tucked in it
static func notebook() -> Node3D:
	var book := Node3D.new()
	var leaf := Node3D.new()
	leaf.position = Vector3(0, 0.34, 0)
	leaf.rotation = Vector3(-0.35, 0, 0.12)
	book.add_child(leaf)
	Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.88, 0.84, 0.7)), Vector3(0.012, -0.012, -0.012), Vector3(0.43, 0.56, 0.03))
	Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.34, 0.12, 0.1)), Vector3(0, 0, 0.008), Vector3(0.44, 0.58, 0.02))
	Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.9, 0.86, 0.72)), Vector3(0, 0.08, 0.02), Vector3(0.32, 0.2, 0.006))
	var ink := Ps1.flat(Color(0.2, 0.18, 0.24))
	for i in 2:
		Ps1.part(leaf, Ps1.box(), ink, Vector3(0, 0.115 - i * 0.075, 0.025), Vector3(0.2 + 0.05 * i, 0.03, 0.002))
	for i in 5:
		Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.6, 0.6, 0.62)), Vector3(-0.16 + i * 0.08, 0.28, 0.0), Vector3(0.022, 0.07, 0.06))
	Ps1.part(leaf, Ps1.drum(5), Ps1.mat(Color(0.85, 0.65, 0.15)), Vector3(0.25, 0.0, 0.03), Vector3(0.018, 0.4, 0.018))
	Ps1.part(leaf, Ps1.drum(5, 0.0), Ps1.mat(Color(0.2, 0.18, 0.16)), Vector3(0.25, -0.225, 0.03), Vector3(0.018, 0.05, 0.018), Vector3(PI, 0, 0))
	return book


# A short hearth broom and a tin dustpan, for what gets left on the floor. The broom stands on
# its bristles, leaning, with the pan lying beside it; the two are children of their own ("brush"
# and "pan") so that the room can work the one against the other (see Den._tick_broom). Both give
# off a very little light, so that they can be found in the dark.
static func broom() -> Node3D:
	var set_of := Node3D.new()
	var brush := Node3D.new()
	brush.name = "brush"
	brush.position = Vector3(-0.1, 0, 0)
	brush.rotation.z = BROOM_LEAN
	set_of.add_child(brush)
	var wood := Ps1.mat(Color(0.5, 0.33, 0.17), 0.12)
	var straw := Ps1.mat(Color(0.8, 0.64, 0.28), 0.15)
	Ps1.part(brush, Ps1.drum(6), wood, Vector3(0, 0.5, 0), Vector3(0.022, 0.56, 0.022))
	Ps1.part(brush, Ps1.ball(), wood, Vector3(0, 0.79, 0), Vector3(0.032, 0.026, 0.032))
	Ps1.part(brush, Ps1.box(), Ps1.mat(Color(0.56, 0.14, 0.1), 0.12), Vector3(0, 0.2, 0), Vector3(0.24, 0.06, 0.075))
	Ps1.part(brush, Ps1.box(), straw, Vector3(0, 0.115, 0), Vector3(0.25, 0.13, 0.06))
	Ps1.part(brush, Ps1.box(), Ps1.mat(Color(0.25, 0.2, 0.14), 0.1), Vector3(0, 0.14, 0), Vector3(0.26, 0.018, 0.068))
	# (the ends of the bristles, splayed and uneven)
	for i in 5:
		Ps1.part(brush, Ps1.box(), Ps1.mat(Color(0.7, 0.54, 0.22).lerp(Color(0.86, 0.72, 0.36), (i % 2) * 0.8), 0.15), Vector3(-0.12 + i * 0.06, 0.03 + 0.008 * (i % 3), 0), Vector3(0.062, 0.06 + 0.016 * (i % 3), 0.07), Vector3(0, 0, (i - 2) * -0.09))
	var pan := Node3D.new()
	pan.name = "pan"
	pan.position = Vector3(0.17, 0, 0.02)
	pan.rotation.y = -0.5
	set_of.add_child(pan)
	var tin := Ps1.mat(Color(0.24, 0.42, 0.38), 0.12)
	var edge := Ps1.mat(Color(0.62, 0.64, 0.62), 0.12)
	Ps1.part(pan, Ps1.box(), tin, Vector3(0, 0.012, 0), Vector3(0.28, 0.014, 0.24), Vector3(0.06, 0, 0))
	Ps1.part(pan, Ps1.box(), tin, Vector3(0, 0.05, -0.12), Vector3(0.28, 0.085, 0.02))
	for side: float in [-1.0, 1.0]:
		Ps1.part(pan, Ps1.box(), tin, Vector3(0.14 * side, 0.04, -0.01), Vector3(0.016, 0.06, 0.22), Vector3(0.14, 0, 0))
	Ps1.part(pan, Ps1.box(), edge, Vector3(0, 0.008, 0.122), Vector3(0.28, 0.01, 0.014))
	Ps1.part(pan, Ps1.drum(5), Ps1.mat(Color(0.5, 0.33, 0.17), 0.12), Vector3(0, 0.085, -0.2), Vector3(0.022, 0.17, 0.022), Vector3(-1.25, 0, 0))
	return set_of


# The scanner: a radar gun of the kind the police point at cars. A pistol grip with a trigger, a
# boxy body, and a stubby barrel that flares to a round cone; on its back a small lit readout,
# and on top a light that is green when it works. It stands on the bottom of its grip, about a
# unit long, pointing along -Z, and gives off a little light of its own so that it shows in the dark.
static func scanner() -> Node3D:
	var s := Node3D.new()
	var shell := Ps1.mat(Color(0.42, 0.46, 0.55), 0.6)
	var dark := Ps1.mat(Color(0.2, 0.2, 0.25), 0.6)
	var steel := Ps1.mat(Color(0.66, 0.69, 0.74), 0.45)
	Ps1.part(s, Ps1.box(), dark, Vector3(0, 0.22, 0.17), Vector3(0.13, 0.44, 0.17), Vector3(-0.25, 0, 0))
	Ps1.part(s, Ps1.box(), dark, Vector3(0, 0.24, -0.03), Vector3(0.04, 0.03, 0.2))
	Ps1.part(s, Ps1.box(), dark, Vector3(0, 0.33, -0.12), Vector3(0.04, 0.2, 0.03))
	Ps1.part(s, Ps1.box(), Ps1.mat(Color(0.85, 0.2, 0.15), 0.4), Vector3(0, 0.35, 0.02), Vector3(0.05, 0.11, 0.04), Vector3(0.3, 0, 0))
	Ps1.part(s, Ps1.box(), shell, Vector3(0, BORE, 0.08), Vector3(0.26, 0.28, 0.5))
	Ps1.part(s, Ps1.box(), dark, Vector3(0, BORE + 0.15, -0.08), Vector3(0.05, 0.04, 0.12))
	Ps1.part(s, Ps1.drum(8), dark, Vector3(0, BORE, -0.24), Vector3(0.1, 0.14, 0.1), Vector3(PI * 0.5, 0, 0))
	Ps1.part(s, Ps1.drum(10, 0.5), steel, Vector3(0, BORE, -0.42), Vector3(MOUTH, 0.22, MOUTH), Vector3(PI * 0.5, 0, 0))
	Ps1.part(s, Ps1.drum(10), Ps1.mat(Color(0.8, 0.9, 0.95), 0.5), Vector3(0, BORE, MUZZLE.z), Vector3(MOUTH - 0.03, 0.02, MOUTH - 0.03), Vector3(PI * 0.5, 0, 0))
	Ps1.part(s, Ps1.box(), dark, Vector3(0, BORE, 0.335), Vector3(0.23, 0.22, 0.02))
	Ps1.part(s, Ps1.box(), Ps1.mat(Color(0.08, 0.3, 0.14), 1.0), READOUT, Vector3(READOUT_SIZE.x, READOUT_SIZE.y, 0.01))
	Ps1.part(s, Ps1.ball(), Ps1.mat(Color(0.3, 1.0, 0.5), 1.0), Vector3(0, BORE + 0.16, 0.24), Vector3.ONE * 0.045)
	return s
