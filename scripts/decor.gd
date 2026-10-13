class_name Decor
extends Node3D
## Something stood in the tank to make it a home: a rock, a hollow log, a fern and so on. Each
## cryptlin likes having some of them about and cannot stand one. Also builds the nests.

enum Kind { ROCK, LOG, FERN, SKULL, CRYSTAL, PUMPKIN, GRAVESTONE, DISH, CAVE }

const IDS: Array[String] = ["rock", "log", "fern", "skull", "crystal", "pumpkin", "gravestone", "dish", "cave"]
const NAMES: Array[String] = ["Rock", "Hollow log", "Fern", "Skull", "Crystal", "Pumpkin", "Gravestone", "Water dish", "Cave"]
# As in "it likes having the ... about"
const PLAIN: Array[String] = ["rock", "hollow log", "fern", "skull", "crystal", "pumpkin", "gravestone", "water dish", "cave"]
# How much floor each takes up: the cryptlin walks round it
const RADII: Array[float] = [0.36, 0.34, 0.22, 0.24, 0.22, 0.28, 0.24, 0.32, 0.85]
const NESTS: Array[String] = ["Rags", "Twigs", "Cushion", "Box"]
const NEST_IDS: Array[String] = ["rags", "twigs", "cushion", "box"]

var kind: int = Kind.ROCK
var radius := 0.3
# A cave can be gone into: the cryptlin hides in it, looking out
var hollow := false


func _init(which: int = Kind.ROCK) -> void:
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
		Kind.GRAVESTONE:
			var stone := Ps1.mat(Color(0.4, 0.41, 0.43))
			var slab := Ps1.part(self, Ps1.box(), stone, Vector3(0, 0.22, 0), Vector3(0.36, 0.44, 0.1))
			slab.rotation.z = 0.06
			var arch := Ps1.part(self, Ps1.drum(10), stone, Vector3(-0.026, 0.43, 0), Vector3(0.18, 0.1, 0.18), Vector3(PI * 0.5, 0, 0.06))
			arch.scale = Vector3(0.18, 0.1, 0.18)
			var cut := Ps1.flat(Color(0.12, 0.12, 0.14))
			Ps1.part(self, Ps1.box(), cut, Vector3(-0.02, 0.38, 0.052), Vector3(0.03, 0.18, 0.004))
			Ps1.part(self, Ps1.box(), cut, Vector3(-0.02, 0.41, 0.052), Vector3(0.12, 0.03, 0.004))
			Ps1.part(self, Ps1.ball(), Ps1.mat(Color(0.2, 0.34, 0.14)), Vector3(0.1, 0.04, 0.05), Vector3(0.14, 0.06, 0.1))
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
