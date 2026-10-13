class_name Decor
extends Node3D
## Something stood in the tank to make it a home: a rock, a hollow log, a fern and so on. Each
## cryptlin likes having some of them about and cannot stand one. Some are shelters it can get
## inside, one is the gravestone left where a cryptlin died, and one is the pool, which is no small
## thing: half the floor under water (see fill). Also builds the nests.

enum Kind { ROCK, LOG, FERN, SKULL, CRYSTAL, PUMPKIN, GRAVESTONE, DISH, CAVE, POOL, BARREL, STUMP, TENT, CRATE, POT, MARKER, TROPHY }

const IDS: Array[String] = [
	"rock", "log", "fern", "skull", "crystal", "pumpkin", "gravestone", "dish", "cave", "pool",
	"barrel", "stump", "tent", "crate", "pot", "marker", "trophy",
]
const NAMES: Array[String] = [
	"Rock", "Hollow log", "Fern", "Skull", "Crystal", "Pumpkin", "Gravestone", "Water dish", "Cave", "Pool",
	"Barrel", "Hollow stump", "Rag tent", "Crate", "Flowerpot", "Gravestone", "Brass cup",
]
# As in "it likes having the ... about"
const PLAIN: Array[String] = [
	"rock", "hollow log", "fern", "skull", "crystal", "pumpkin", "gravestone", "water dish", "cave", "pool",
	"barrel", "hollow stump", "rag tent", "crate", "flowerpot", "gravestone", "brass cup",
]
# How much floor each takes up: the cryptlin walks round it
const RADII: Array[float] = [0.36, 0.34, 0.22, 0.24, 0.22, 0.28, 0.24, 0.32, 0.85, 0.72, 0.7, 0.74, 0.82, 0.78, 0.76, 0.2, 0.2]
const NESTS: Array[String] = ["Rags", "Twigs", "Cushion", "Box"]
const NEST_IDS: Array[String] = ["rags", "twigs", "cushion", "box"]
# Where the water in the pool stands (a little below the floor), how deep it gets, and how
# steeply the ground shelves down into it from the edge
const WATER := -0.06
const DEEP := 0.6
const SHELVE := 0.9

var kind: int = Kind.ROCK
# (the pool in the room has none: it is not walked round but kept out of, by Den.wade)
var radius := 0.3
# The pool's water, once it lies in the room
var water: ShaderMaterial
# A shelter (the cave, a barrel, a tent and so on) can be gone into: the cryptlin hides in it,
# looking out of the front, which faces +Z
var hollow := false
# A gravestone is one cryptlin's own: the colour it was, and its number
var tint := Color(0.5, 0.5, 0.52)
var whose := 0


func _init(which: int = Kind.ROCK, colour := Color(0.5, 0.5, 0.52)) -> void:
	tint = colour
	kind = which
	radius = RADII[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + kind
	match kind:
		Kind.ROCK:
			var grey := Ps1.mat(Color(0.36, 0.35, 0.37))
			var dim := Ps1.mat(Color(0.27, 0.27, 0.3))
			var lump := Ps1.ball()
			lump.radial_segments = 7
			lump.rings = 3
			Ps1.part(self, lump, grey, Vector3(0, 0.17, 0), Vector3(0.34, 0.24, 0.28), Vector3(0, 0.4, 0.1))
			Ps1.part(self, lump, dim, Vector3(0.2, 0.1, 0.12), Vector3(0.18, 0.13, 0.16), Vector3(0.2, 1.1, 0))
			Ps1.part(self, lump, dim, Vector3(-0.22, 0.08, -0.08), Vector3(0.14, 0.1, 0.13), Vector3(0, 2.0, 0.2))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.34, 0.14)), Vector3(-0.06, 0.37, 0.03), Vector3(0.14, 0.04, 0.12))
		Kind.LOG:
			var bark := Ps1.mat(Color(0.26, 0.18, 0.11))
			var across := Vector3(0, 0, PI * 0.5)
			Ps1.part(self, Ps1.drum(8), bark, Vector3(0, 0.2, 0), Vector3(0.2, 0.72, 0.2), across)
			# Hollow at both ends
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.drum(8), Ps1.mat(Color(0.42, 0.33, 0.2)), Vector3(0.358 * side, 0.2, 0), Vector3(0.19, 0.01, 0.19), across)
				Ps1.part(self, Ps1.drum(8), Ps1.flat(Color(0.03, 0.02, 0.02)), Vector3(0.362 * side, 0.2, 0), Vector3(0.14, 0.01, 0.14), across)
			Ps1.part(self, Ps1.drum(6), bark, Vector3(0.1, 0.38, 0.05), Vector3(0.045, 0.16, 0.045), Vector3(0.4, 0, -0.3))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.34, 0.14)), Vector3(-0.12, 0.38, 0), Vector3(0.16, 0.04, 0.13))
		Kind.FERN:
			for i in 8:
				var around := TAU * i / 8.0 + rng.randf_range(-0.2, 0.2)
				var lean := rng.randf_range(0.5, 1.05)
				var tall := rng.randf_range(0.36, 0.56)
				var frond := Ps1.part(self, Ps1.drum(4, 0.0), Ps1.mat(Color(0.14, 0.34, 0.14) if i % 2 == 0 else Color(0.2, 0.42, 0.16)), Vector3.ZERO)
				var lie := Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, lean)
				frond.basis = lie * Basis.from_scale(Vector3(0.07, tall, 0.02))
				frond.position = lie * Vector3(0, tall * 0.5, 0)
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.12, 0.08, 0.05)), Vector3(0, 0.02, 0), Vector3(0.12, 0.05, 0.12))
		Kind.SKULL:
			var bone := Ps1.mat(Color(0.8, 0.77, 0.66))
			var hole := Ps1.flat(Color(0.03, 0.02, 0.03))
			Ps1.part(self, Ps1.ball(), bone, Vector3(0, 0.24, -0.02), Vector3(0.2, 0.19, 0.22))
			Ps1.part(self, Ps1.box(), bone, Vector3(0, 0.09, 0.1), Vector3(0.2, 0.12, 0.16))
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.ball(), hole, Vector3(0.08 * side, 0.24, 0.17), Vector3(0.055, 0.06, 0.03))
				# A horn curling up from each side
				Ps1.part(self, Ps1.drum(5, 0.0), bone, Vector3(0.24 * side, 0.36, -0.03), Vector3(0.04, 0.26, 0.04), Vector3(0, 0, -0.9 * side))
			Ps1.part(self, Ps1.drum(3, 0.0), hole, Vector3(0, 0.15, 0.185), Vector3(0.025, 0.05, 0.01))
			for i in 4:
				Ps1.part(self, Ps1.box(), hole, Vector3(-0.06 + i * 0.04, 0.06, 0.181), Vector3(0.008, 0.06, 0.004))
		Kind.CRYSTAL:
			var tints: Array[Color] = [Color(0.55, 0.4, 0.95), Color(0.4, 0.75, 0.95), Color(0.7, 0.5, 1.0)]
			for i in 5:
				var around := TAU * i / 5.0
				var out := 0.0 if i == 0 else 0.11
				var tall := 0.62 if i == 0 else rng.randf_range(0.26, 0.42)
				var shard := Ps1.part(self, Ps1.drum(5, 0.0), Ps1.mat(tints[i % 3], 0.55), Vector3.ZERO)
				var lie := Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, 0.0 if i == 0 else 0.45)
				shard.basis = lie * Basis.from_scale(Vector3(0.075, tall, 0.075))
				shard.position = Vector3(sin(around), 0, cos(around)) * out + lie * Vector3(0, tall * 0.5, 0)
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.25, 0.24, 0.3)), Vector3(0, 0.03, 0), Vector3(0.2, 0.06, 0.2))
		Kind.PUMPKIN:
			var orange := Ps1.mat(Color(0.82, 0.4, 0.07))
			for i in 3:
				Ps1.part(self, Ps1.ball(), orange, Vector3(0, 0.2, 0), Vector3(0.27, 0.2, 0.17), Vector3(0, PI * i / 3.0, 0))
			Ps1.part(self, Ps1.drum(5), Ps1.mat(Color(0.2, 0.3, 0.1)), Vector3(0.01, 0.42, 0), Vector3(0.03, 0.1, 0.03), Vector3(0, 0, 0.3))
			# A face cut into it, lit from inside
			var fire := Ps1.mat(Color(1.0, 0.8, 0.25), 1.0)
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.drum(3, 0.0), fire, Vector3(0.09 * side, 0.26, 0.24), Vector3(0.04, 0.07, 0.01))
			Ps1.part(self, Ps1.ball(), fire, Vector3(0, 0.14, 0.26), Vector3(0.12, 0.035, 0.01))
		Kind.GRAVESTONE, Kind.MARKER:
			# Where one of them died (there is no other way to come by one): a leaning slab with an
			# arched top and a cross cut in it, a band of the colour the cryptlin was painted round
			# it, moss at its foot and the earth heaped in front. One from when they could be bought
			# is nobody's, and has no band. (MARKER is the number the stones of the dead once had.)
			kind = Kind.GRAVESTONE
			radius = RADII[kind]
			var stone := Ps1.mat(Color(0.4, 0.41, 0.43))
			var slab := Ps1.part(self, Ps1.box(), stone, Vector3(0, 0.22, 0), Vector3(0.36, 0.44, 0.1))
			slab.rotation.z = 0.06
			var arch := Ps1.part(self, Ps1.drum(10), stone, Vector3(-0.026, 0.43, 0), Vector3(0.18, 0.1, 0.18), Vector3(PI * 0.5, 0, 0.06))
			arch.scale = Vector3(0.18, 0.1, 0.18)
			var cut := Ps1.flat(Color(0.12, 0.12, 0.14))
			Ps1.part(self, Ps1.box(), cut, Vector3(-0.02, 0.38, 0.052), Vector3(0.03, 0.18, 0.004))
			Ps1.part(self, Ps1.box(), cut, Vector3(-0.02, 0.41, 0.052), Vector3(0.12, 0.03, 0.004))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.34, 0.14)), Vector3(0.1, 0.04, 0.05), Vector3(0.14, 0.06, 0.1))
			if tint.to_html(false) != "808085":
				var band := Ps1.part(self, Ps1.box(), Ps1.mat(tint), Vector3(-0.008, 0.16, 0), Vector3(0.375, 0.07, 0.115))
				band.rotation.z = 0.06
				Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.15, 0.1)), Vector3(-0.04, 0.02, 0.13), Vector3(0.26, 0.05, 0.16))
		Kind.TROPHY:
			# The cup from the station's Friday show: tarnished brass, two handles, on a wooden base
			# with a plate on the front of it
			var brass := Ps1.mat(Color(0.5, 0.4, 0.17), 0.06, 0.3)
			var dull := Ps1.mat(Color(0.4, 0.34, 0.16), 0.05)
			var wood := Ps1.mat(Color(0.26, 0.16, 0.09))
			Ps1.part(self, Ps1.box(), wood, Vector3(0, 0.05, 0), Vector3(0.24, 0.1, 0.24))
			Ps1.part(self, Ps1.box(), brass, Vector3(0, 0.05, 0.122), Vector3(0.12, 0.05, 0.006))
			Ps1.part(self, Ps1.drum(8, 0.5), dull, Vector3(0, 0.13, 0), Vector3(0.08, 0.06, 0.08))
			Ps1.part(self, Ps1.drum(6), dull, Vector3(0, 0.2, 0), Vector3(0.025, 0.1, 0.025))
			var bowl := Ps1.part(self, Ps1.drum(10, 0.5), brass, Vector3(0, 0.34, 0), Vector3(0.14, 0.2, 0.14))
			bowl.rotation.x = PI
			Ps1.part(self, Ps1.drum(10), Ps1.mat(Color(0.2, 0.16, 0.08)), Vector3(0, 0.441, 0), Vector3(0.12, 0.004, 0.12))
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.box(), dull, Vector3(0.17 * side, 0.4, 0), Vector3(0.07, 0.02, 0.025))
				Ps1.part(self, Ps1.box(), dull, Vector3(0.195 * side, 0.34, 0), Vector3(0.02, 0.12, 0.025))
				Ps1.part(self, Ps1.box(), dull, Vector3(0.15 * side, 0.29, 0), Vector3(0.09, 0.02, 0.025), Vector3(0, 0, 0.5 * side))
		Kind.DISH:
			Ps1.part(self, Ps1.drum(10, 0.82), Ps1.mat(Color(0.42, 0.24, 0.16)), Vector3(0, 0.05, 0), Vector3(0.3, 0.1, 0.3))
			Ps1.part(self, Ps1.drum(10), Ps1.mat(Color(0.16, 0.38, 0.5), 0.15), Vector3(0, 0.1, 0), Vector3(0.21, 0.012, 0.21))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.5, 0.75, 0.85), 0.3), Vector3(0.07, 0.108, -0.04), Vector3(0.05, 0.004, 0.03))
		Kind.CAVE:
			# Boulders leant together, open at the front, with room inside for one small monster
			hollow = true
			var grey := Ps1.mat(Color(0.33, 0.32, 0.35))
			var dim := Ps1.mat(Color(0.24, 0.24, 0.27))
			var lump := Ps1.ball()
			lump.radial_segments = 7
			lump.rings = 3
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, lump, grey if side < 0.0 else dim, Vector3(0.66 * side, 0.5, -0.05), Vector3(0.26, 0.62, 0.5), Vector3(0, 0.3 * side, -0.12 * side))
				Ps1.part(self, lump, dim if side < 0.0 else grey, Vector3(0.74 * side, 0.16, 0.34), Vector3(0.2, 0.2, 0.22), Vector3(0.3, side, 0))
			Ps1.part(self, lump, dim, Vector3(0, 0.55, -0.52), Vector3(0.7, 0.66, 0.2), Vector3(0.12, 0, 0))
			Ps1.part(self, lump, grey, Vector3(0.03, 1.2, -0.08), Vector3(0.86, 0.24, 0.58), Vector3(0.05, 0.2, 0.04))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.34, 0.14)), Vector3(-0.25, 1.4, 0.05), Vector3(0.34, 0.06, 0.26))
		Kind.POOL:
			# As it rides the wheel of things: a pond in a ring of stones with rushes at the back.
			# In the room it is a good deal more than that (see fill).
			var brim := 0.2
			var grey := Ps1.mat(Color(0.36, 0.35, 0.37))
			var dim := Ps1.mat(Color(0.27, 0.27, 0.3))
			var lump := Ps1.ball()
			lump.radial_segments = 7
			lump.rings = 3
			for i in 11:
				var around := TAU * i / 11.0
				var out := Vector3(sin(around), 0, cos(around))
				var tall := rng.randf_range(0.13, 0.19)
				Ps1.part(self, lump, grey if i % 2 == 0 else dim, out * 0.6 + Vector3(0, tall * 0.6, 0), Vector3(0.19, tall, 0.12), Vector3(rng.randf_range(-0.2, 0.2), around, 0))
			Ps1.part(self, Ps1.drum(12), Ps1.mat(Color(0.08, 0.26, 0.4), 0.2), Vector3(0, brim * 0.5, 0), Vector3(0.6, brim, 0.6))
			var shine := Ps1.mat(Color(0.5, 0.75, 0.85), 0.3)
			Ps1.part(self, Ps1.ball(), shine, Vector3(0.18, brim, 0.2), Vector3(0.12, 0.004, 0.035), Vector3(0, 0.4, 0))
			Ps1.part(self, Ps1.ball(), shine, Vector3(-0.22, brim, -0.05), Vector3(0.08, 0.004, 0.03), Vector3(0, -0.3, 0))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.16, 0.4, 0.16)), Vector3(-0.3, brim + 0.004, 0.3), Vector3(0.12, 0.006, 0.1))
			var rush := Ps1.mat(Color(0.2, 0.38, 0.14))
			for i in 3:
				var at := Vector3(-0.3 + i * 0.26, 0, -0.56 + absf(i - 1.0) * 0.1)
				var tall := 0.62 - absf(i - 1.0) * 0.14
				Ps1.part(self, Ps1.drum(4), rush, at + Vector3(0, tall * 0.5, 0), Vector3(0.012, tall, 0.012), Vector3(0, 0, (i - 1.0) * -0.12))
				Ps1.part(self, Ps1.drum(5), Ps1.mat(Color(0.3, 0.18, 0.1)), at + Vector3((i - 1.0) * 0.07, tall, 0), Vector3(0.03, 0.14, 0.03), Vector3(0, 0, (i - 1.0) * -0.12))
		Kind.BARREL:
			# A great cask on its side with the end knocked out, chocked so it cannot roll
			hollow = true
			var oak := Ps1.mat(Color(0.4, 0.26, 0.14))
			var old := Ps1.mat(Color(0.3, 0.2, 0.12))
			_staves(oak, old, 14, 0.66, Vector2(-0.56, 0.58), Vector2(0.0, 0.66), 0.05)
			_staves(old, oak, 14, 0.66, Vector2(0.0, 0.66), Vector2(0.56, 0.58), 0.05)
			Ps1.part(self, Ps1.drum(14), old, Vector3(0, 0.66, -0.53), Vector3(0.56, 0.04, 0.56), Vector3(PI * 0.5, 0, 0))
			var iron := Ps1.mat(Color(0.16, 0.16, 0.18))
			var hoop := TorusMesh.new()
			hoop.inner_radius = 0.9
			hoop.outer_radius = 1.0
			hoop.rings = 14
			hoop.ring_segments = 4
			for band: Vector2 in [Vector2(-0.44, 0.63), Vector2(0.0, 0.71), Vector2(0.46, 0.63)]:
				Ps1.part(self, hoop, iron, Vector3(0, 0.66, band.x), Vector3(band.y, 0.05, band.y), Vector3(PI * 0.5, 0, 0))
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.box(), old, Vector3(0.5 * side, 0.07, 0.1), Vector3(0.2, 0.14, 0.5), Vector3(0, 0, 0.5 * side))
			Ps1.part(self, Ps1.drum(6), Ps1.mat(Color(0.5, 0.4, 0.22)), Vector3(0.2, 1.32, -0.1), Vector3(0.05, 0.08, 0.05))
		Kind.STUMP:
			# What is left of a dead tree: rotted hollow, open to the sky and split down the front
			hollow = true
			var bark := Ps1.mat(Color(0.25, 0.18, 0.12))
			var punk := Ps1.mat(Color(0.36, 0.27, 0.17))
			var moss := Ps1.mat(Color(0.2, 0.34, 0.14))
			for i in 13:
				var around := TAU * i / 13.0
				if absf(wrapf(around, -PI, PI)) < 0.7:
					continue
				var tall := rng.randf_range(0.7, 1.15)
				var out := Vector3(sin(around), 0, cos(around))
				Ps1.part(self, Ps1.box(), bark if i % 2 == 0 else punk, out * 0.58 + Vector3(0, tall * 0.5, 0), Vector3(0.31, tall, 0.09), Vector3(-0.06, around, 0))
				Ps1.part(self, Ps1.drum(4, 0.0), bark if i % 2 == 0 else punk, out * 0.58 + Vector3(0, tall + 0.07, 0), Vector3(0.15, 0.16, 0.05), Vector3(0, around, 0))
				if i % 3 == 0:
					# A root running out along the floor
					var root := Ps1.part(self, Ps1.drum(5, 0.0), bark, out * 0.86 + Vector3(0, 0.07, 0))
					root.basis = Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, 1.45) * Basis.from_scale(Vector3(0.11, 0.56, 0.09))
			Ps1.part(self, Ps1.ball(), moss, Vector3(-0.5, 0.86, -0.3), Vector3(0.22, 0.06, 0.16))
			Ps1.part(self, Ps1.ball(), moss, Vector3(0.6, 0.08, 0.3), Vector3(0.2, 0.07, 0.18))
			# Bracket fungus up one side
			for i in 3:
				Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.72, 0.5, 0.2)), Vector3(0.63, 0.34 + i * 0.2, 0.2 - i * 0.14), Vector3(0.13, 0.03, 0.11))
		Kind.TENT:
			# Rags thrown over crossed sticks: open at the front, patched, and held down with stones
			hollow = true
			var rag := Ps1.mat(Color(0.4, 0.35, 0.29))
			var flap := Ps1.mat(Color(0.48, 0.42, 0.33))
			var stick := Ps1.mat(Color(0.3, 0.21, 0.12))
			var lean := atan2(0.74, 1.4)
			for side: float in [-1.0, 1.0]:
				Ps1.part(self, Ps1.box(), rag, Vector3(0.37 * side, 0.7, -0.05), Vector3(0.03, 1.6, 1.3), Vector3(0, 0, lean * side))
				# A flap hangs down each side of the way in
				Ps1.part(self, Ps1.box(), flap, Vector3(0.25 * side, 0.66, 0.6), Vector3(0.3, 1.46, 0.02), Vector3(0, 0, lean * side))
				for z: float in [-0.7, 0.62]:
					Ps1.part(self, Ps1.drum(5), stick, Vector3(0.33 * side, 0.78, z), Vector3(0.028, 1.86, 0.028), Vector3(0, 0, lean * side))
				Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.3, 0.3, 0.33)), Vector3(0.8 * side, 0.06, 0.3 * side), Vector3(0.12, 0.08, 0.1))
			Ps1.part(self, Ps1.box(), Ps1.mat(Color(0.27, 0.24, 0.21)), Vector3(0, 0.5, -0.69), Vector3(0.74, 1.0, 0.02))
			Ps1.part(self, Ps1.drum(5), stick, Vector3(0, 1.4, -0.04), Vector3(0.025, 1.5, 0.025), Vector3(PI * 0.5, 0, 0))
			# Patches
			Ps1.part(self, Ps1.box(), Ps1.mat(Color(0.5, 0.2, 0.16)), Vector3(0.36, 0.5, 0.612), Vector3(0.2, 0.24, 0.01), Vector3(0, 0, lean))
			Ps1.part(self, Ps1.box(), Ps1.mat(Color(0.22, 0.3, 0.4)), Vector3(-0.2, 0.84, 0.612), Vector3(0.18, 0.2, 0.01), Vector3(0, 0, -lean))
			Ps1.part(self, Ps1.box(), Ps1.mat(Color(0.5, 0.42, 0.2)), Vector3(-0.56, 0.36, 0.3), Vector3(0.034, 0.22, 0.2), Vector3(0, 0, -lean))
		Kind.CRATE:
			# A packing crate stood on end, one side prised off and a board left hanging
			hollow = true
			var pine := Ps1.mat(Color(0.5, 0.38, 0.22))
			var worn := Ps1.mat(Color(0.4, 0.3, 0.18))
			for side: float in [-1.0, 1.0]:
				for i in 4:
					Ps1.part(self, Ps1.box(), pine if i % 2 == 0 else worn, Vector3(0.6 * side, 0.14 + i * 0.27, 0), Vector3(0.04, 0.23, 1.1))
				for z: float in [-0.55, 0.55]:
					Ps1.part(self, Ps1.box(), worn, Vector3(0.6 * side, 0.56, z), Vector3(0.08, 1.12, 0.08))
			for i in 4:
				Ps1.part(self, Ps1.box(), worn if i % 2 == 0 else pine, Vector3(0, 0.14 + i * 0.27, -0.56), Vector3(1.2, 0.23, 0.04))
				Ps1.part(self, Ps1.box(), pine if i % 2 == 0 else worn, Vector3(-0.46 + i * 0.307, 1.13, 0), Vector3(0.28, 0.04, 1.2))
			Ps1.part(self, Ps1.box(), pine, Vector3(0, 1.02, 0.57), Vector3(1.24, 0.2, 0.04))
			Ps1.part(self, Ps1.box(), worn, Vector3(0.5, 0.42, 0.6), Vector3(0.2, 0.9, 0.04), Vector3(0, 0, 0.22))
			# A mark stencilled on its side, and the lid's nails
			var ink := Ps1.flat(Color(0.12, 0.1, 0.1))
			Ps1.part(self, Ps1.box(), ink, Vector3(0, 1.02, 0.592), Vector3(0.5, 0.03, 0.004))
			Ps1.part(self, Ps1.drum(3, 0.0), ink, Vector3(-0.4, 1.02, 0.592), Vector3(0.05, 0.1, 0.004))
		Kind.POT:
			# A flowerpot big enough for a tree, tipped over and cracked, its earth spilled out behind
			hollow = true
			var clay := Ps1.mat(Color(0.56, 0.28, 0.16))
			var baked := Ps1.mat(Color(0.46, 0.22, 0.13))
			_staves(clay, baked, 12, 0.72, Vector2(-0.56, 0.42), Vector2(0.44, 0.68), 0.05, [0, 1])
			_staves(baked, baked, 12, 0.72, Vector2(0.44, 0.74), Vector2(0.58, 0.74), 0.07, [0])
			Ps1.part(self, Ps1.drum(12), baked, Vector3(0, 0.72, -0.54), Vector3(0.42, 0.04, 0.42), Vector3(PI * 0.5, 0, 0))
			var earth := Ps1.mat(Color(0.14, 0.1, 0.07))
			Ps1.part(self, Ps1.ball(), earth, Vector3(0, 0.1, -0.5), Vector3(0.5, 0.24, 0.34))
			Ps1.part(self, Ps1.ball(), earth, Vector3(0.1, 0.03, 0.3), Vector3(0.42, 0.06, 0.34))
			# The shard that came out of it, and what was growing in it
			Ps1.part(self, Ps1.box(), clay, Vector3(0.74, 0.04, 0.5), Vector3(0.3, 0.05, 0.24), Vector3(0.1, 0.5, 0.15))
			Ps1.part(self, Ps1.drum(4), Ps1.mat(Color(0.3, 0.26, 0.14)), Vector3(-0.2, 0.36, -0.72), Vector3(0.015, 0.5, 0.015), Vector3(-0.7, 0, 0.3))


# The pool as it lies in the room: water over one part of the floor, from the walls to a
# wandering edge across the middle (Den.shore says which part, and Den.wade where the edge runs).
# The floor is cut away over it and the water is a sheet a little below; along the edge there
# are stones with gaps of bare mud between them, rushes in the shallows, and a few lily pads and
# rocks further out. Built to the room's size, and built again when that or its place changes.
func fill() -> void:
	for part in get_children():
		part.free()
	radius = 0.0
	rotation = Vector3.ZERO
	position = Den.middle(Den.shore)
	var back := Den.shore == Den.Shore.BACK
	var wide := Den.half.x if back else Den.half.y
	var mid := Den.SHORE_MIDS[Den.shore]
	var far := (Den.half.y if back else Den.half.x) + mid
	var rng := RandomNumberGenerator.new()
	rng.seed = 23 + Den.shore
	water = ShaderMaterial.new()
	water.shader = load("res://shaders/water.gdshader")
	water.set_shader_parameter("shore", Den.shore)
	# (the sheet runs on a little way under the floor and the walls, so that nothing shows past
	# its edge, and at the side of the room on out to the front with the floor)
	var from := Den.place(-wide - 0.5, mid - far - 0.5)
	var to := Den.place(wide + (0.5 if back else 6.0), mid + 0.5)
	var sheet := PlaneMesh.new()
	sheet.size = Vector2(absf(to.x - from.x), absf(to.z - from.z))
	var surface := Ps1.part(self, sheet, water, (from + to) * 0.5 - position + Vector3(0, WATER, 0))
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Lit as the floor is, by the lamp and not by what it throws back
	surface.layers = 2
	var grey := Ps1.mat(Color(0.36, 0.35, 0.37))
	var dim := Ps1.mat(Color(0.27, 0.27, 0.3))
	var moss := Ps1.mat(Color(0.2, 0.34, 0.14))
	var lump := Ps1.ball()
	lump.radial_segments = 7
	lump.rings = 3
	# Stones along the edge, half in and half out
	var along := -wide + 0.12
	while along < wide - 0.1:
		var big := rng.randf_range(0.07, 0.17)
		if rng.randf() < 0.7:
			var at := Den.at_shore(along, rng.randf_range(-0.12, 0.05)) - position
			Ps1.part(self, lump, grey if rng.randf() < 0.5 else dim, at + Vector3(0, big * 0.2, 0), Vector3(big * rng.randf_range(1.0, 1.5), big * 0.7, big), Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, 0))
			if rng.randf() < 0.2:
				Ps1.part(self, Ps1.ball(), moss, at + Vector3(0, big * 0.85, 0), Vector3(big * 0.7, 0.02, big * 0.6))
		along += big * 2.0 + rng.randf_range(0.04, 0.4)
	# Rushes in the shallows: a stand at each end of the edge and one somewhere between
	var rush := Ps1.mat(Color(0.2, 0.38, 0.14))
	var head := Ps1.mat(Color(0.3, 0.18, 0.1))
	for stand: float in [-wide + 0.45, rng.randf_range(-0.4, 0.4) * wide, wide - 0.45]:
		for i in 6:
			var at := Den.at_shore(stand + rng.randf_range(-0.3, 0.3), rng.randf_range(0.06, 0.32)) - position
			var tall := rng.randf_range(0.45, 0.85)
			var lean := Vector3(rng.randf_range(-0.14, 0.14), 0, rng.randf_range(-0.14, 0.14))
			Ps1.part(self, Ps1.drum(4), rush, at + Vector3(0, WATER + tall * 0.5, 0), Vector3(0.016, tall, 0.016), lean)
			if i % 2 == 0:
				Ps1.part(self, Ps1.drum(5), head, at + Vector3(-lean.z * tall, WATER + tall, lean.x * tall), Vector3(0.034, 0.16, 0.034), lean)
	# Lily pads (one of them in flower) and a rock or two, out where it is deep
	var pad := Ps1.mat(Color(0.16, 0.4, 0.16))
	for i in 5:
		var at := Den.at_shore(rng.randf_range(-0.85, 0.85) * wide, rng.randf_range(0.5, 0.9) * (far - 0.5)) - position + Vector3(0, WATER, 0)
		if i < 2:
			var big := rng.randf_range(0.16, 0.26)
			Ps1.part(self, lump, dim if i == 0 else grey, at, Vector3(big * 1.3, big * 0.55, big), Vector3(0, rng.randf() * TAU, 0.1))
		else:
			Ps1.part(self, Ps1.ball(), pad, at + Vector3(0, 0.004, 0), Vector3(0.13, 0.005, 0.11), Vector3(0, rng.randf() * TAU, 0))
			Ps1.part(self, Ps1.ball(), pad, at + Vector3(0.17, 0.004, 0.08), Vector3(0.08, 0.005, 0.07))
			if i == 2:
				Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.9, 0.82, 0.86), 0.2), at + Vector3(0.02, 0.03, 0.01), Vector3(0.04, 0.03, 0.04))


# Where the lamp is pointing, its colour and how hard it burns, for the glint it makes on the pool
func glint(at: Vector3, colour: Color, burning: float) -> void:
	if water != null:
		water.set_shader_parameter("lamp", at)
		water.set_shader_parameter("lamp_tint", colour)
		water.set_shader_parameter("lamp_glow", burning)


# A ring of boards about a line running front to back, `height` off the floor: a barrel, or a
# pot on its side. `back` and `front` are each (how far along, how wide the ring is there), so
# it can taper; the boards take the two colours turn about, and those in `gaps` are left out
# (the first is at the top).
func _staves(first: Material, second: Material, count: int, height: float, back: Vector2, front: Vector2, thick: float, gaps: Array[int] = []) -> void:
	var wide := 2.0 * maxf(back.y, front.y) * tan(PI / count) + 0.012
	for i in count:
		if i in gaps:
			continue
		var around := TAU * i / count
		var out := Vector3(sin(around), cos(around), 0)
		var from := out * back.y + Vector3(0, height, back.x)
		var to := out * front.y + Vector3(0, height, front.x)
		var along := (to - from).normalized()
		var across := out.cross(along).normalized()
		var board := Ps1.part(self, Ps1.box(), first if i % 2 == 0 else second, (from + to) * 0.5)
		board.basis = Basis(across, along.cross(across), along) * Basis.from_scale(Vector3(wide, thick, from.distance_to(to) + 0.01))


# Where the cryptlin sleeps, in one of four styles
static func nest(style: int) -> Node3D:
	var n := Node3D.new()
	match style:
		1:
			# A bird's nest of twigs, lined with straw
			var ring := TorusMesh.new()
			ring.inner_radius = 0.36
			ring.outer_radius = 0.6
			ring.rings = 10
			ring.ring_segments = 5
			Ps1.part(n, ring, Ps1.mat(Color(0.26, 0.18, 0.1)), Vector3(0, 0.08, 0), Vector3(1, 0.7, 1))
			var twig := BoxMesh.new()
			twig.size = Vector3(0.03, 0.03, 0.5)
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 16:
				var a := TAU * i / 16.0
				var at := Vector3(cos(a) * 0.5, rng.randf_range(0.06, 0.2), sin(a) * 0.5)
				Ps1.part(n, twig, Ps1.mat(Color(0.34, 0.24, 0.13) if i % 2 == 0 else Color(0.2, 0.14, 0.09)), at, Vector3.ONE, Vector3(rng.randf_range(-0.4, 0.4), -a + rng.randf_range(-0.5, 0.5), 0))
			Ps1.part(n, Ps1.drum(10), Ps1.mat(Color(0.5, 0.42, 0.2)), Vector3(0, 0.03, 0), Vector3(0.4, 0.05, 0.4))
		2:
			# A fat cushion with a button in the middle and a tassel at each corner
			var gold := Ps1.mat(Color(0.6, 0.48, 0.18))
			Ps1.part(n, Ps1.ball(), Ps1.mat(Color(0.38, 0.14, 0.3)), Vector3(0, 0.09, 0), Vector3(0.6, 0.13, 0.52))
			Ps1.part(n, Ps1.ball(), gold, Vector3(0, 0.2, 0), Vector3(0.05, 0.03, 0.05))
			for x: float in [-1.0, 1.0]:
				for z: float in [-1.0, 1.0]:
					Ps1.part(n, Ps1.ball(), gold, Vector3(0.44 * x, 0.06, 0.38 * z), Vector3.ONE * 0.055)
		3:
			# A cardboard box with its flaps open
			var card := Color(0.44, 0.33, 0.2)
			Ps1.part(n, Ps1.box(), Ps1.mat(card * 0.8), Vector3(0, 0.015, 0), Vector3(1.0, 0.03, 0.84))
			for z: float in [-1.0, 1.0]:
				Ps1.part(n, Ps1.box(), Ps1.mat(card), Vector3(0, 0.15, 0.42 * z), Vector3(1.0, 0.3, 0.03))
				Ps1.part(n, Ps1.box(), Ps1.mat(card * 0.9), Vector3(0, 0.33, 0.52 * z), Vector3(1.0, 0.03, 0.24), Vector3(-0.5 * z, 0, 0))
			for x: float in [-1.0, 1.0]:
				Ps1.part(n, Ps1.box(), Ps1.mat(card * 0.9), Vector3(0.5 * x, 0.15, 0), Vector3(0.03, 0.3, 0.84))
			Ps1.part(n, Ps1.ball(), Ps1.mat(Color(0.3, 0.32, 0.4)), Vector3(0, 0.05, 0), Vector3(0.44, 0.05, 0.36))
		_:
			# A ring of rags
			var ring := TorusMesh.new()
			ring.inner_radius = 0.34
			ring.outer_radius = 0.62
			ring.rings = 10
			ring.ring_segments = 6
			Ps1.part(n, ring, Ps1.mat(Color(0.2, 0.14, 0.12)), Vector3(0, 0.06, 0), Vector3(1, 0.5, 1))
			Ps1.part(n, Ps1.drum(10), Ps1.mat(Color(0.14, 0.1, 0.13)), Vector3(0, 0.02, 0), Vector3(0.4, 0.04, 0.4))
	return n
