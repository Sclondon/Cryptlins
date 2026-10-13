class_name Items
extends RefCounted
## Everything that sits on the shelf under the tank: the notebook and the scanner, eggs, food, toys,
## things to stand on the floor, nests and grounds. `n` is the item's number within its
## group (Snack.Kind, Ball.Kind, Decor.Kind, and so on).

const LIST: Array[Dictionary] = [
	{"id": "notebook", "group": "tool", "n": 0, "name": "Notebook"},
	{"id": "scanner", "group": "tool", "n": 1, "name": "Scanner"},
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
	{"id": "marker", "group": "decor", "n": 15, "name": "Grave marker"},
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
# inside a site that keeps one (see Den.stock); played by itself, everything is on the shelf.
const FREE: Array[String] = ["notebook", "scanner", "bone", "ball", "rags", "dirt"]
# Used up when used: each one fed, or each egg laid, is one fewer on the shelf
const SPENT: Array[String] = ["food", "egg"]
# Never bought or sold: on the shelf only while the keeper has one put away
const KEPT: Array[String] = ["marker"]


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
			else:
				var s := scanner()
				s.scale = Vector3.ONE * 0.62
				s.rotation.z = 0.35
				s.position = Vector3(-0.05, 0.02, 0)
				holder.add_child(s)
	return holder


# A small ring-bound notebook with a pencil tucked in it
static func notebook() -> Node3D:
	var book := Node3D.new()
	var leaf := Node3D.new()
	leaf.position = Vector3(0, 0.34, 0)
	leaf.rotation = Vector3(-0.35, 0, 0.12)
	book.add_child(leaf)
	Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.34, 0.12, 0.1)), Vector3(0, 0, -0.012), Vector3(0.44, 0.58, 0.03))
	Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.88, 0.84, 0.7)), Vector3(0, -0.01, 0.01), Vector3(0.4, 0.52, 0.03))
	var ink := Ps1.flat(Color(0.3, 0.32, 0.45))
	for i in 4:
		Ps1.part(leaf, Ps1.box(), ink, Vector3(-0.02 * (i % 2), 0.12 - i * 0.09, 0.027), Vector3(0.28 - 0.04 * (i % 2), 0.014, 0.002))
	for i in 5:
		Ps1.part(leaf, Ps1.box(), Ps1.mat(Color(0.6, 0.6, 0.62)), Vector3(-0.16 + i * 0.08, 0.28, 0.0), Vector3(0.022, 0.07, 0.06))
	Ps1.part(leaf, Ps1.drum(5), Ps1.mat(Color(0.85, 0.65, 0.15)), Vector3(0.25, 0.0, 0.03), Vector3(0.018, 0.4, 0.018))
	Ps1.part(leaf, Ps1.drum(5, 0.0), Ps1.mat(Color(0.2, 0.18, 0.16)), Vector3(0.25, -0.225, 0.03), Vector3(0.018, 0.05, 0.018), Vector3(PI, 0, 0))
	return book


# The scanner: a frame to look through, on a handle, with a light that is green when it works.
# It stands upright facing +Z, about a unit tall, its window centred 0.62 up.
static func scanner() -> Node3D:
	var s := Node3D.new()
	var grey := Ps1.mat(Color(0.3, 0.32, 0.36))
	var dark := Ps1.mat(Color(0.13, 0.13, 0.16))
	for side: float in [-1.0, 1.0]:
		Ps1.part(s, Ps1.box(), grey, Vector3(0.36 * side, 0.62, 0), Vector3(0.07, 0.74, 0.07))
		Ps1.part(s, Ps1.box(), grey, Vector3(0, 0.62 + 0.36 * side, 0), Vector3(0.79, 0.07, 0.07))
	Ps1.part(s, Ps1.drum(6), dark, Vector3(0, 0.12, 0), Vector3(0.05, 0.26, 0.05))
	Ps1.part(s, Ps1.ball(), Ps1.mat(Color(0.3, 1.0, 0.5), 1.0), Vector3(0.36, 1.0, 0.04), Vector3.ONE * 0.04)
	return s
