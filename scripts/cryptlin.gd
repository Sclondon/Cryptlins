class_name Cryptlin
extends Node3D
## One cryptlin: its body (built from primitives, shaped by its kind and a seed), its needs, its
## small brain, and its animation, which is all done here in code. It faces +Z.

signal left

enum State {
	IDLE, WANDER, STARE, LURK, COME, GO_FOOD, EAT, CHASE_BALL, CHASE_LIGHT,
	BEG, ZOOMIES, DANCE, PETTED, STARTLED, GO_SLEEP, SLEEP, LEAVE, HELD, SHOVED, INSPECT, SCANNED, VISIT, MOVE_NEST,
	TOILET, FOND, SCRATCH, STRETCH, DIG, SPIN, GAZE,
}
# The cryptids they are the young of
enum Kind {
	GREMLIN, SQUATCH, COCKATRICE, MOTHMAN, CHUPACABRA, FROGMAN, NESSIE, BOLTER, WENDIGO,
	KELPIE, MERFOLK, SPAWN, GNOME, FAE, FUNGUS, JACKALOPE, ALIEN, YETI, CERBERUS,
}

# What sets the kinds apart besides their looks: pace on the ground, appetite, how fast they tire,
# the spring in their hop, the pitch of their voice, and what they like to do with a free moment.
# The ones marked "water" live in it, and are not at home without a pool to wade in.
const KINDS: Array[Dictionary] = [
	{"title": "gremlin", "pace": 1.0, "hunger": 1.0, "tire": 1.0, "spring": 1.0, "voice": 1.0, "lurk": 1.0, "zoom": 1.0, "dance": 1.0, "stare": 1.0},
	{"title": "squatchling", "pace": 0.85, "hunger": 1.25, "tire": 1.1, "spring": 0.7, "voice": 0.55, "lurk": 2.2, "zoom": 0.5, "dance": 1.1, "stare": 1.4},
	{"title": "cockatrice", "pace": 1.1, "hunger": 1.0, "tire": 1.0, "spring": 1.2, "voice": 1.45, "lurk": 0.5, "zoom": 1.2, "dance": 1.5, "stare": 2.4},
	{"title": "mothman", "pace": 1.2, "hunger": 0.8, "tire": 1.2, "spring": 1.4, "voice": 1.6, "lurk": 1.2, "zoom": 2.2, "dance": 1.0, "stare": 1.5},
	{"title": "chupacabra", "pace": 1.25, "hunger": 1.6, "tire": 1.0, "spring": 1.2, "voice": 0.85, "lurk": 1.8, "zoom": 1.6, "dance": 0.6, "stare": 1.0},
	{"title": "Loveland frogman", "pace": 0.9, "hunger": 1.1, "tire": 0.9, "spring": 1.7, "voice": 0.75, "lurk": 0.6, "zoom": 1.0, "dance": 1.8, "stare": 1.2, "water": true},
	{"title": "Loch Ness monster", "pace": 0.75, "hunger": 1.2, "tire": 0.8, "spring": 0.6, "voice": 0.9, "lurk": 2.2, "zoom": 0.4, "dance": 1.0, "stare": 1.6, "water": true},
	{"title": "slide-rock bolter", "pace": 0.8, "hunger": 1.8, "tire": 1.2, "spring": 0.6, "voice": 0.5, "lurk": 0.6, "zoom": 3.0, "dance": 0.6, "stare": 0.9},
	{"title": "wendigo", "pace": 1.0, "hunger": 2.0, "tire": 0.7, "spring": 0.9, "voice": 0.6, "lurk": 2.6, "zoom": 0.5, "dance": 0.5, "stare": 1.8},
	{"title": "kelpie", "pace": 1.3, "hunger": 1.1, "tire": 0.9, "spring": 1.3, "voice": 0.8, "lurk": 1.0, "zoom": 2.0, "dance": 0.9, "stare": 1.2, "water": true},
	{"title": "merling", "pace": 0.9, "hunger": 1.1, "tire": 1.0, "spring": 1.0, "voice": 1.1, "lurk": 1.2, "zoom": 0.9, "dance": 1.4, "stare": 1.4, "water": true},
	{"title": "Cthulhu spawn", "pace": 0.8, "hunger": 1.5, "tire": 0.9, "spring": 0.7, "voice": 0.45, "lurk": 2.4, "zoom": 0.4, "dance": 0.6, "stare": 2.2, "water": true},
	{"title": "gnome", "pace": 0.95, "hunger": 1.2, "tire": 1.0, "spring": 0.9, "voice": 1.0, "lurk": 1.4, "zoom": 0.7, "dance": 1.5, "stare": 1.0},
	{"title": "fae", "pace": 1.3, "hunger": 0.7, "tire": 1.3, "spring": 1.5, "voice": 1.9, "lurk": 0.8, "zoom": 2.4, "dance": 2.0, "stare": 1.0},
	{"title": "living fungus", "pace": 0.7, "hunger": 0.8, "tire": 0.8, "spring": 0.8, "voice": 0.7, "lurk": 1.6, "zoom": 0.3, "dance": 0.8, "stare": 1.6},
	{"title": "jackalope", "pace": 1.35, "hunger": 1.0, "tire": 1.1, "spring": 1.8, "voice": 1.3, "lurk": 1.2, "zoom": 2.4, "dance": 1.0, "stare": 0.9},
	{"title": "alien", "pace": 0.95, "hunger": 0.9, "tire": 0.8, "spring": 1.1, "voice": 1.7, "lurk": 1.0, "zoom": 0.8, "dance": 0.8, "stare": 2.6},
	{"title": "yeti", "pace": 0.85, "hunger": 1.4, "tire": 1.0, "spring": 0.7, "voice": 0.5, "lurk": 1.6, "zoom": 0.6, "dance": 1.0, "stare": 1.2},
	{"title": "Cerberus", "pace": 1.15, "hunger": 1.7, "tire": 1.0, "spring": 1.1, "voice": 0.7, "lurk": 0.7, "zoom": 1.6, "dance": 0.9, "stare": 1.3},
]
# What the numbers in saves from before this list stood for (gremlin, bogle, spook, flit)
const OLD_KINDS: Array[int] = [Kind.GREMLIN, Kind.FROGMAN, Kind.WENDIGO, Kind.MOTHMAN]

# What it can beg for, with a picture of it in a thought bubble
enum Want { FOOD, BALL, WATER }

# How it is feeling just now, which shows in its eyes, its ears and how it holds its head
enum Feeling { CONTENT, HAPPY, EXCITED, LOVING, HUNGRY, BORED, SLEEPY, GRUMPY, SCARED, SAD, DISGUSTED }
# What goes up over its head when a feeling comes over it (nothing, for content): a round face
# sixteen dots across, drawn one dot of the picture to one dot of the face so it stays sharp. Each
# is its colour and the eight rows of its features: # dark, o white, r red, b blue.
const FACE := 16
const FACES: Array[Dictionary] = [
	{},
	{"tint": Color(1.0, 0.84, 0.22), "rows": ["", "..#....#", "..#....#", "", ".#......#", "..######", "", ""]},
	{"tint": Color(1.0, 0.7, 0.16), "rows": ["..#....#", ".#.#..#.#", "", ".########", ".#rrrrrr#", "..#rrrr#", "...####", ""]},
	{"tint": Color(1.0, 0.8, 0.84), "rows": [".r.r..r.r", ".rrr..rrr", "..r....r", "", ".#......#", "..######", "", ""]},
	{"tint": Color(1.0, 0.66, 0.36), "rows": ["", "..#....#", "..#....#", "", "..######", "..#rrrr#", "...####b", ".......b"]},
	{"tint": Color(0.74, 0.76, 0.82), "rows": ["", "", ".###..###", "..#....#", "", "", "..######", ""]},
	{"tint": Color(0.66, 0.76, 1.0), "rows": ["", "", ".#.#..#.#", "..#....#", "", "....##", "....##", ""]},
	{"tint": Color(1.0, 0.4, 0.3), "rows": [".#......#", "..#....#", "..##..##", "", "", "..######", ".#......#", ""]},
	{"tint": Color(0.74, 0.62, 1.0), "rows": [".ooo..ooo", ".o#o..o#o", ".ooo..ooo", "", "...####", "...#rr#", "...####", ""]},
	{"tint": Color(0.5, 0.68, 1.0), "rows": ["", "..#....#", "..#....#", ".b", ".b", "...####", "..#....#", ""]},
	{"tint": Color(0.62, 0.84, 0.36), "rows": [".#......#", "..#....#", ".#......#", "", "..######", "....rr", "....rr", ""]},
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
	[Snack.Kind.FISH, Snack.Kind.BERRIES], [Snack.Kind.FISH, Snack.Kind.BEETLE], [Snack.Kind.FISH, Snack.Kind.BONE],
	[Snack.Kind.TOADSTOOL, Snack.Kind.BERRIES], [Snack.Kind.BERRIES, Snack.Kind.CANDY], [Snack.Kind.BONE, Snack.Kind.BEETLE],
	[Snack.Kind.BERRIES, Snack.Kind.TOADSTOOL], [Snack.Kind.CANDY, Snack.Kind.BEETLE], [Snack.Kind.BONE, Snack.Kind.BERRIES],
	[Snack.Kind.BONE, Snack.Kind.FISH],
]
const TOY_LIKES: Array[Array] = [
	[Ball.Kind.BALL, Ball.Kind.BELL], [Ball.Kind.STONE, Ball.Kind.BALL], [Ball.Kind.BELL, Ball.Kind.STONE],
	[Ball.Kind.GLOW, Ball.Kind.BELL], [Ball.Kind.BALL, Ball.Kind.GLOW], [Ball.Kind.BALL, Ball.Kind.GLOW],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.STONE, Ball.Kind.BELL], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.GLOW, Ball.Kind.BALL], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BELL, Ball.Kind.STONE], [Ball.Kind.BELL, Ball.Kind.GLOW], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BALL, Ball.Kind.BELL], [Ball.Kind.GLOW, Ball.Kind.BELL], [Ball.Kind.STONE, Ball.Kind.BALL],
	[Ball.Kind.BALL, Ball.Kind.STONE],
]
# Natures that will not go together (shy and bold, sleepy and restless, cuddly and grumpy)
const OPPOSED: Array[Array] = [[2, 5], [3, 7], [4, 6]]
# What each kind leans towards in its room: two things to have about (Decor.Kind), two grounds
# (Den.GROUNDS) and a lamp setting (Den.Lamp), from the first nine things. The pool is no part of
# this: a kind needs it or does not.
const DECOR_LIKES: Array[Array] = [
	[Decor.Kind.SKULL, Decor.Kind.PUMPKIN], [Decor.Kind.LOG, Decor.Kind.FERN], [Decor.Kind.ROCK, Decor.Kind.GRAVESTONE],
	[Decor.Kind.CRYSTAL, Decor.Kind.PUMPKIN], [Decor.Kind.SKULL, Decor.Kind.ROCK], [Decor.Kind.DISH, Decor.Kind.FERN],
	[Decor.Kind.DISH, Decor.Kind.ROCK], [Decor.Kind.ROCK, Decor.Kind.CRYSTAL], [Decor.Kind.SKULL, Decor.Kind.GRAVESTONE],
	[Decor.Kind.FERN, Decor.Kind.ROCK], [Decor.Kind.DISH, Decor.Kind.CRYSTAL], [Decor.Kind.SKULL, Decor.Kind.CRYSTAL],
	[Decor.Kind.PUMPKIN, Decor.Kind.LOG], [Decor.Kind.FERN, Decor.Kind.CRYSTAL], [Decor.Kind.LOG, Decor.Kind.GRAVESTONE],
	[Decor.Kind.FERN, Decor.Kind.LOG], [Decor.Kind.CRYSTAL, Decor.Kind.SKULL], [Decor.Kind.ROCK, Decor.Kind.CAVE],
	[Decor.Kind.SKULL, Decor.Kind.GRAVESTONE],
]
const GROUND_LIKES: Array[Array] = [
	[1, 3], [2, 4], [4, 5], [1, 3], [5, 4], [2, 4], [6, 5], [6, 0], [2, 0],
	[6, 2], [5, 6], [5, 0], [2, 4], [2, 3], [2, 4], [4, 5], [3, 6], [6, 0], [0, 6],
]
const LAMP_LIKES: Array[int] = [1, 1, 2, 0, 2, 2, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 2]
# It lives in real time, like a pet: these are hours of the clock on the wall, and they pass
# whether or not anyone is looking. A full belly lasts most of a day, and a baby is grown in a
# day and a half.
const HOUR := 3600.0
const BELLY_HOURS := 14.0
const FUN_HOURS := 10.0
const AWAKE_HOURS := 15.0
const SLEEP_HOURS := 7.0
const GROW_AGE := 36.0 * HOUR
# How long a meal takes to come out the other end, and how long between puddles
const DIGEST_HOURS := 4.0
const PEE_HOURS := 3.0
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
	State.SCRATCH, State.DIG, State.SPIN, State.GAZE,
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
	[Color(0.16, 0.2, 0.22), Color(0.28, 0.36, 0.4), Color(0.2, 0.3, 0.26), Color(0.42, 0.46, 0.5), Color(0.52, 0.54, 0.52)],
	[Color(0.16, 0.42, 0.42), Color(0.2, 0.44, 0.3), Color(0.62, 0.36, 0.14), Color(0.3, 0.38, 0.52), Color(0.42, 0.46, 0.44)],
	[Color(0.24, 0.42, 0.3), Color(0.2, 0.36, 0.36), Color(0.36, 0.3, 0.44), Color(0.34, 0.4, 0.24), Color(0.4, 0.3, 0.34)],
	[Color(0.2, 0.3, 0.55), Color(0.22, 0.42, 0.22), Color(0.55, 0.42, 0.16), Color(0.45, 0.24, 0.2), Color(0.36, 0.3, 0.44)],
	[Color(0.85, 0.45, 0.6), Color(0.6, 0.5, 0.9), Color(0.45, 0.8, 0.6), Color(0.9, 0.75, 0.35), Color(0.45, 0.7, 0.9)],
	[Color(0.7, 0.14, 0.1), Color(0.5, 0.32, 0.16), Color(0.45, 0.25, 0.55), Color(0.75, 0.45, 0.1), Color(0.25, 0.45, 0.5)],
	[Color(0.5, 0.4, 0.28), Color(0.4, 0.32, 0.26), Color(0.46, 0.45, 0.44), Color(0.62, 0.58, 0.5), Color(0.3, 0.25, 0.22)],
	[Color(0.5, 0.52, 0.5), Color(0.4, 0.6, 0.36), Color(0.45, 0.55, 0.66), Color(0.56, 0.46, 0.62)],
	[Color(0.92, 0.94, 1.0), Color(0.82, 0.9, 1.0), Color(0.95, 0.92, 0.84), Color(0.76, 0.8, 0.88)],
	[Color(0.16, 0.15, 0.17), Color(0.3, 0.16, 0.12), Color(0.26, 0.25, 0.28), Color(0.34, 0.26, 0.18)],
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
	[Color(0.6, 1.0, 0.9), Color(1.0, 1.0, 0.85), Color(0.5, 0.9, 1.0)],
	[Color(1.0, 0.9, 0.3), Color(0.6, 1.0, 0.8), Color(1.0, 0.6, 0.3)],
	[Color(1.0, 0.85, 0.2), Color(1.0, 0.3, 0.2), Color(0.7, 1.0, 0.3)],
	[Color(0.5, 0.9, 1.0), Color(1.0, 0.85, 0.4), Color(0.7, 1.0, 0.5)],
	[Color(1.0, 1.0, 0.7), Color(0.7, 1.0, 1.0), Color(1.0, 0.7, 1.0)],
	[Color(1.0, 0.9, 0.4), Color(0.6, 1.0, 0.6), Color(0.5, 0.9, 1.0)],
	[Color(1.0, 0.6, 0.2), Color(1.0, 0.85, 0.3), Color(1.0, 0.35, 0.3)],
	[Color(0.6, 1.0, 0.6), Color(0.7, 0.9, 1.0), Color(1.0, 1.0, 1.0), Color(1.0, 0.5, 0.9)],
	[Color(0.5, 0.9, 1.0), Color(0.8, 1.0, 1.0), Color(1.0, 0.4, 0.3)],
	[Color(1.0, 0.3, 0.1), Color(1.0, 0.55, 0.1), Color(1.0, 0.85, 0.2)],
]

var world: Den
# What the room keeps of it: its name, and what has been found out about it
var me: Resident
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
# How far off the floor it floats (its body and all that hangs from it; it comes down to sleep)
var hover := 0.0
var neck_y := 0.64
# How far above the neck the middle of the head is
var head_y := 0.2
var centre_y := 0.55
var top_y := 1.15
var ear_splay := 1.0
var wings := false
# Wings of its own that beat by themselves, how fast and how far
var flaps: Array[Node3D] = []
var flap_rate := 0.0
var flap_reach := 0.0
# More heads than the one on its neck: they follow it round, a little behind
var heads: Array[Node3D] = []
# How big its insides are next to the usual (a slight body has less room), and how high its
# backbone runs when its head is not straight above it (0 for up to the neck)
var gut := 1.0
var back_y := 0.0
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
# What it has eaten and not yet passed, and how nearly it has to go (100: now), one way and the other
var digest := 0.0
var bowel := 0.0
var bladder := 0.0

# Who it is (see profile()), how old, how big, and how it feels
var nature := 0
var nature2 := 1
var fav_food := 0
var yuck_food := 0
var fav_toy := 0
# What it wants of its room: two or three things it likes having about and one it cannot stand
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
# The thing in the room it is making use of (hiding in, sitting on, drinking from, wading in), and how long
# before it next thinks of dragging its nest somewhere else
var visiting: Decor
var nest_cooldown := 240.0
# How long before it might next take a fancy to its nest (see _fancies)
var fond_cooldown := 120.0
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
# Food it has tasted and left for the others (instance ids), so as not to go back to it
var spurned: Array[int] = []
var kicks := 0
var kicks_total := 0
var kick_limit := 3
var ball_cooldown := 0.0
# How long after finishing a bit of food before it goes for the next (the others get a look in)
var food_cooldown := 0.0
var beg_cooldown := 6.0
var pounce_cooldown := 0.0
var last_stroke := -10.0
var beg_for: int = Want.FOOD
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
var bubble_water: Node3D
var hearts: CPUParticles3D
var zzz: Array[Label3D] = []
# The little face over its head, the picture for each feeling, how long it has been up, the
# feeling it was last put up for, and how long till a feeling that lasts shows again
var emote: MeshInstance3D
var faces: Array[ImageTexture] = []
var emote_time := 0.0
var emote_for := -1
var emote_again := 0.0


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
	# One of the two things its kind likes to have about, one more of its own, and one it hates,
	# all from the first nine things there were (so that a cryptlin keeps the tastes it has
	# always had, whatever is added since)
	var kin: Array = DECOR_LIKES[k]
	var liked: Array[int] = [kin[rng.randi() % kin.size()]]
	var rest: Array[int] = []
	for i in Decor.Kind.POOL:
		if i != liked[0]:
			rest.append(i)
	liked.append(rest.pop_at(rng.randi() % rest.size()))
	me["decor"] = liked
	me["hates"] = rest[rng.randi() % rest.size()]
	var grounds: Array = GROUND_LIKES[k]
	me["ground"] = grounds[rng.randi() % grounds.size()]
	me["lamp"] = LAMP_LIKES[k] if rng.randf() < 0.65 else rng.randi() % 3
	# The shelters that came after the first things get their chance last of all, so that nothing
	# drawn above changes: now and then, one of them to like as well
	if rng.randf() < 0.45:
		liked.append(rng.randi_range(Decor.Kind.POOL + 1, Decor.IDS.size() - 1))
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
		Kind.KELPIE:
			_build_kelpie(chub)
		Kind.MERFOLK:
			_build_merfolk(chub)
		Kind.SPAWN:
			_build_spawn(chub)
		Kind.GNOME:
			_build_gnome(chub, rng)
		Kind.FAE:
			_build_fae()
		Kind.FUNGUS:
			_build_fungus(chub, rng)
		Kind.JACKALOPE:
			_build_jackalope(chub, ear_len)
		Kind.ALIEN:
			_build_alien(chub)
		Kind.YETI:
			_build_yeti(chub, rng)
		Kind.CERBERUS:
			_build_cerberus(chub)
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
	_build_emote()


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


# A water horse's foal: all legs and neck, with waterweed for a mane and a tail, and never quite dry
func _build_kelpie(chub: float) -> void:
	neck_y = 0.54
	head_y = 0.4
	centre_y = 0.5
	top_y = 1.18
	ear_splay = 0.25
	gut = 0.75
	back_y = 0.62
	brain_at = Vector3(0, 0.42, 0.1)
	var weed := Ps1.mat(Color(0.1, 0.32, 0.2), 0.0, 0.35)
	var wrack := Ps1.mat(Color(0.22, 0.42, 0.16), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.12 * side, 0.38, -0.2))
		_part(leg, _capsule(0.04, 0.36), fur, Vector3(0, -0.16, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.345, 0.01), Vector3(0.055, 0.035, 0.065))
		_part(leg, _cone(), weed, Vector3(0, -0.29, -0.035), Vector3(0.04, 0.12, 0.03), Vector3(-2.72, 0, 0))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.5, -0.02), Vector3(0.19 * chub, 0.2, 0.32 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.45, 0), Vector3(0.16 * chub, 0.17, 0.28 * chub))
	# A tail of weed, hanging wet
	tail = _pivot(torso, Vector3(0, 0.56, -0.31 * chub))
	for i in 3:
		_part(tail, _cone(), wrack if i == 1 else weed, Vector3((i - 1) * 0.035, -0.14, -0.07), Vector3(0.045, 0.34 - absf(i - 1.0) * 0.08, 0.03), Vector3(-2.72, 0, (i - 1) * 0.2))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.12 * chub * side, 0.42, 0.2 * chub))
		_part(_foreleg(a, side, 0.42, 0.036), _cone(), weed, Vector3(0, -0.33, -0.035), Vector3(0.04, 0.12, 0.03), Vector3(-2.72, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.25 * chub))
	_part(neck, _capsule(0.07, 0.48), fur, Vector3(0, 0.17, 0.03), Vector3.ONE, Vector3(0.3, 0, 0))
	_part(neck, _sphere(), fur, Vector3(0, 0.41, 0.1), Vector3(0.135, 0.13, 0.17))
	_part(neck, _sphere(), fur, Vector3(0, 0.34, 0.27), Vector3(0.09, 0.08, 0.14), Vector3(0.5, 0, 0))
	_part(neck, _sphere(), pale, Vector3(0, 0.285, 0.35), Vector3(0.075, 0.062, 0.075))
	# The mane lies down the back of its neck in wet hanks, with a lock over the brow
	for i in 5:
		var up := 0.5 - i * 0.1
		var fall := 1.0 if i % 2 == 0 else -1.0
		_part(neck, _cone(), weed if i % 2 == 0 else wrack, Vector3(0.04 * fall, up - 0.06, (up - 0.17) * 0.31 - 0.1), Vector3(0.07, 0.24, 0.03), Vector3(-2.3, 0, 0.5 * fall))
	_part(neck, _cone(), wrack, Vector3(0, 0.5, 0.19), Vector3(0.06, 0.2, 0.03), Vector3(2.2, 0, 0))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.085 * side, 0.51, 0.04))
		_part(ear, _cone(), fur, Vector3(0, 0.07, 0), Vector3(0.035, 0.14, 0.02))
		ears.append(ear)
		_eye(Vector3(0.115 * side, 0.44, 0.19), 0.055)
		_part(neck, _sphere(), black, Vector3(0.035 * side, 0.3, 0.42), Vector3.ONE * 0.014)
	mouth_node = _pivot(neck, Vector3(0, 0.245, 0.36))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.045))


# A front leg for something that goes on four, hung from an arm's pivot `length` above the floor.
# The rig holds its arms a little out from its sides; this turns the leg back to stand straight,
# and gives back what it hangs from.
func _foreleg(a: Node3D, side: float, length: float, thick: float) -> Node3D:
	var fore := _pivot(a, Vector3.ZERO)
	fore.rotation.z = -REST_ARM.z * side
	_part(fore, _capsule(thick, length), fur, Vector3(0, 0.02 - length * 0.5, 0))
	_part(fore, _sphere(), dark, Vector3(0, 0.035 - length, 0.02), Vector3(thick * 1.4, 0.035, thick * 1.8))
	return fore


# A fish that walks: a crest, gill fins for ears, webbed hands, and a tail it has not lost yet
func _build_merfolk(chub: float) -> void:
	neck_y = 0.52
	centre_y = 0.42
	top_y = 1.1
	ear_splay = 1.2
	# Its fins are whatever colour its scales are not
	var scales: Color = fur.get_shader_parameter("tint")
	var fin := Ps1.mat(Color.from_hsv(fposmod(scales.h + 0.5, 1.0), 0.6, 0.6), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.11 * side, 0.2, 0))
		_part(leg, _capsule(0.05, 0.2), fur, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), fin, Vector3(0.02 * side, -0.18, 0.1), Vector3(0.1, 0.022, 0.17), Vector3(0, 0.35 * side, 0))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.4, 0), Vector3(0.24 * chub, 0.27, 0.21 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.37, 0.11 * chub), Vector3(0.18 * chub, 0.2, 0.12))
	_part(torso, _cone(), fin, Vector3(0, 0.5, -0.22 * chub), Vector3(0.02, 0.22, 0.1), Vector3(-0.6, 0, 0))
	tail = _pivot(torso, Vector3(0, 0.26, -0.18 * chub))
	_part(tail, _cone(), fur, Vector3(0, 0.02, -0.14), Vector3(0.08, 0.3, 0.07), Vector3(-1.4, 0, 0))
	_part(tail, _cone(), fin, Vector3(0, 0.085, -0.36), Vector3(0.012, 0.16, 0.07), Vector3(2.09, 0, 0))
	_part(tail, _cone(), fin, Vector3(0, 0.005, -0.36), Vector3(0.012, 0.16, 0.07), Vector3(1.05, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.23 * chub * side, 0.5, 0.03))
		_part(a, _capsule(0.04, 0.26), fur, Vector3(0, -0.1, 0))
		_part(a, _sphere(), fin, Vector3(0, -0.25, 0.01), Vector3(0.025, 0.07, 0.075))
		_part(a, _cone(), fin, Vector3(0, -0.1, -0.06), Vector3(0.012, 0.12, 0.05), Vector3(-0.5, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0.02), Vector3(0.3, 0.24, 0.27))
	_part(neck, _sphere(), pale, Vector3(0, 0.13, 0.07), Vector3(0.26, 0.15, 0.22))
	_part(neck, _sphere(), fin, Vector3(0, 0.1, 0.245), Vector3(0.15, 0.06, 0.06))
	for i in 3:
		_part(neck, _cone(), fin, Vector3(0, 0.47 - i * 0.05, 0.08 - i * 0.13), Vector3(0.018, 0.2 - i * 0.03, 0.09), Vector3(-0.3 - i * 0.35, 0, 0))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.26 * side, 0.2, -0.04))
		_part(ear, _cone(), fin, Vector3(0, 0.1, 0), Vector3(0.1, 0.2, 0.02))
		ears.append(ear)
		_eye(Vector3(0.16 * side, 0.27, 0.2), 0.095)
	mouth_node = _pivot(neck, Vector3(0, 0.1, 0.275))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.12, 0.05, 0.05))


# Something from under the sea that has not finished arriving: a great soft head, feelers where
# a mouth should be, and wings too small to matter yet
func _build_spawn(chub: float) -> void:
	neck_y = 0.5
	head_y = 0.24
	centre_y = 0.4
	top_y = 1.12
	gravity = 14.0
	flap_rate = 2.4
	flap_reach = 0.22
	var web := Ps1.mat(fur.get_shader_parameter("tint") * 0.6, 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.13 * side, 0.18, 0))
		_part(leg, _sphere(), fur, Vector3(0, -0.06, 0), Vector3(0.09, 0.12, 0.09))
		_part(leg, _sphere(), dark, Vector3(0, -0.15, 0.06), Vector3(0.1, 0.03, 0.13))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.36, 0), Vector3(0.27 * chub, 0.25, 0.24 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.33, 0.13 * chub), Vector3(0.19 * chub, 0.18, 0.12))
	tail = _pivot(torso, Vector3(0, 0.2, -0.2 * chub))
	_part(tail, _cone(), fur, Vector3(0, 0, -0.1), Vector3(0.05, 0.2, 0.05), Vector3(-PI * 0.5, 0, 0))

	for side: float in [-1.0, 1.0]:
		# A bat's wing in two points, on a finger of bone
		var wing := _pivot(torso, Vector3(0.14 * side, 0.54, -0.16 * chub))
		_part(wing, _cone(), web, Vector3(0.2 * side, 0.16, 0), Vector3(0.17, 0.4, 0.012), Vector3(0, 0, -0.9 * side))
		_part(wing, _cone(), web, Vector3(0.2 * side, -0.02, 0), Vector3(0.11, 0.3, 0.012), Vector3(0, 0, -1.9 * side))
		_part(wing, _capsule(0.015, 0.44), dark, Vector3(0.17 * side, 0.14, 0.01), Vector3.ONE, Vector3(0, 0, -0.9 * side))
		flaps.append(wing)
		var a := _pivot(torso, Vector3(0.25 * chub * side, 0.46, 0.05))
		_part(a, _capsule(0.045, 0.22), fur, Vector3(0, -0.08, 0))
		for claw: float in [-1.0, 1.0]:
			_part(a, _cone(), bone, Vector3(0.02 * claw, -0.22, 0.01), Vector3(0.012, 0.06, 0.012), Vector3(PI, 0, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.03))
	_part(neck, _sphere(), fur, Vector3(0, 0.26, -0.02), Vector3(0.31, 0.3, 0.32))
	_part(neck, _sphere(), fur, Vector3(0, 0.36, -0.16), Vector3(0.25, 0.24, 0.25))
	for wart: Vector3 in [Vector3(-0.15, 0.5, -0.04), Vector3(0.1, 0.55, -0.12), Vector3(0.2, 0.42, -0.2)]:
		_part(neck, _sphere(), pale, wart, Vector3.ONE * 0.045)
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.14 * side, 0.2, 0.25), 0.062)
		_part(neck, _sphere(), dark, Vector3(0.14 * side, 0.275, 0.26), Vector3(0.1, 0.03, 0.06), Vector3(0, 0, 0.35 * side))
	# Five feelers hang over its mouth, the middle one longest
	for i in 5:
		var across := i - 2.0
		var drop := 0.3 - absf(across) * 0.05
		_part(neck, _capsule(0.032, drop), fur if i % 2 == 0 else pale, Vector3(across * 0.062, 0.1 - drop * 0.5, 0.27 - absf(across) * 0.03), Vector3.ONE, Vector3(-0.15, 0, across * 0.12))
	mouth_node = _pivot(neck, Vector3(0, 0.06, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.08, 0.05, 0.04))


# Small, stout and sure of itself: a pointed hat as tall as it is, a nose like a berry, and the
# first wisp of a beard
func _build_gnome(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.5
	head_y = 0.17
	centre_y = 0.4
	top_y = 1.36
	ear_splay = 1.25
	# Red, as often as not
	var hats: Array[Color] = [Color(0.66, 0.1, 0.08), Color(0.66, 0.1, 0.08), Color(0.14, 0.26, 0.56), Color(0.5, 0.14, 0.4), Color(0.7, 0.5, 0.1)]
	var hat := Ps1.mat(hats[rng.randi() % hats.size()], 0.0, 0.35)
	var flesh := Ps1.mat(Color(0.74, 0.52, 0.4), 0.0, 0.35)
	var rosy := Ps1.mat(Color(0.78, 0.36, 0.3), 0.0, 0.35)
	var leather := Ps1.mat(Color(0.2, 0.13, 0.08), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.1 * side, 0.16, 0))
		_part(leg, _capsule(0.055, 0.16), dark, Vector3(0, -0.05, 0))
		_part(leg, _sphere(), leather, Vector3(0, -0.115, 0.05), Vector3(0.08, 0.045, 0.13))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.36, 0), Vector3(0.25 * chub, 0.24, 0.22 * chub))
	_part(torso, _sphere(), leather, Vector3(0, 0.3, 0), Vector3(0.252 * chub, 0.03, 0.224 * chub))
	_part(torso, BoxMesh.new(), bone, Vector3(0, 0.3, 0.215 * chub), Vector3(0.055, 0.05, 0.03))
	tail = _pivot(torso, Vector3(0, 0.3, -0.2))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.24 * chub * side, 0.47, 0.02))
		_part(a, _capsule(0.045, 0.22), fur, Vector3(0, -0.08, 0))
		_part(a, _sphere(), flesh, Vector3(0, -0.2, 0), Vector3.ONE * 0.055)
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	_part(neck, _sphere(), flesh, Vector3(0, 0.17, 0), Vector3(0.24, 0.2, 0.22))
	_part(neck, _sphere(), rosy, Vector3(0, 0.15, 0.22), Vector3.ONE * 0.062)
	_part(neck, _sphere(), bone, Vector3(0, 0.05, 0.13), Vector3(0.16, 0.11, 0.1))
	_part(neck, _cone(), bone, Vector3(0, -0.06, 0.16), Vector3(0.1, 0.18, 0.06), Vector3(PI, 0, 0))
	_part(neck, _cone(), hat, Vector3(0, 0.55, -0.02), Vector3(0.27, 0.6, 0.27), Vector3(-0.1, 0, 0.05))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.22 * side, 0.16, -0.02))
		_part(ear, _cone(), flesh, Vector3(0, 0.07, 0), Vector3(0.05, 0.14, 0.03))
		ears.append(ear)
		_eye(Vector3(0.09 * side, 0.2, 0.185), 0.048)
		_part(neck, _sphere(), rosy, Vector3(0.13 * side, 0.12, 0.16), Vector3(0.05, 0.04, 0.03))
	mouth_node = _pivot(neck, Vector3(0, 0.075, 0.235))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.02))


# Hardly there at all: a slip of a thing in a skirt of petals, held up on four wings and giving
# off a little light of its own
func _build_fae() -> void:
	neck_y = 0.42
	head_y = 0.18
	centre_y = 0.32
	top_y = 0.88
	hover = 0.26
	gravity = 6.0
	gut = 0.5
	flap_rate = 38.0
	flap_reach = 0.45
	fur.set_shader_parameter("glow", 0.1)
	pale.set_shader_parameter("glow", 0.16)
	var petals: Color = fur.get_shader_parameter("tint")
	var gauze := Ps1.mat(petals.lerp(Color.WHITE, 0.6), 0.45)
	torso = _pivot(self, Vector3.ZERO)
	# Its feet never touch the floor, so they hang from its body
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(torso, Vector3(0.045 * side, 0.2, 0))
		_part(leg, _capsule(0.022, 0.2), pale, Vector3(0, -0.09, 0))
		_part(leg, _cone(), fur, Vector3(0, -0.2, 0.02), Vector3(0.03, 0.07, 0.035), Vector3(PI - 0.5, 0, 0))
		legs.append(leg)
	_part(torso, _sphere(), pale, Vector3(0, 0.32, 0), Vector3(0.1, 0.13, 0.085))
	for i in 6:
		var lie := Basis(Vector3.UP, TAU * (i + 0.5) / 6.0) * Basis(Vector3.RIGHT, PI - 0.6)
		var petal := _part(torso, _cone(), fur, Vector3.ZERO)
		petal.basis = lie * Basis.from_scale(Vector3(0.07, 0.2, 0.02))
		petal.position = Vector3(0, 0.3, 0) + lie * Vector3(0, 0.1, 0)
	tail = _pivot(torso, Vector3(0, 0.26, -0.07))

	for side: float in [-1.0, 1.0]:
		var wing := _pivot(torso, Vector3(0.02 * side, 0.42, -0.07))
		_part(wing, _sphere(), gauze, Vector3(0.2 * side, 0.12, 0), Vector3(0.2, 0.1, 0.008), Vector3(0, 0, 0.55 * side))
		_part(wing, _sphere(), gauze, Vector3(0.14 * side, -0.1, 0), Vector3(0.13, 0.07, 0.008), Vector3(0, 0, -0.5 * side))
		flaps.append(wing)
		var a := _pivot(torso, Vector3(0.11 * side, 0.4, 0))
		_part(a, _capsule(0.02, 0.2), pale, Vector3(0, -0.08, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.01))
	_part(neck, _sphere(), pale, Vector3(0, 0.18, 0), Vector3(0.19, 0.18, 0.18))
	_part(neck, _sphere(), fur, Vector3(0, 0.24, -0.04), Vector3(0.2, 0.16, 0.19))
	_part(neck, _cone(), fur, Vector3(0.02, 0.42, 0.02), Vector3(0.06, 0.16, 0.05), Vector3(0.5, 0, -0.3))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.16 * side, 0.17, -0.02))
		_part(ear, _cone(), pale, Vector3(0, 0.1, 0), Vector3(0.04, 0.2, 0.02))
		ears.append(ear)
		_eye(Vector3(0.085 * side, 0.16, 0.135), 0.07)
	mouth_node = _pivot(neck, Vector3(0, 0.06, 0.165))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.035, 0.025, 0.02))


# A toadstool that got up and walked: a wide spotted cap on a pale stalk, and two eyes in the
# shade of the brim
func _build_fungus(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.4
	head_y = 0.16
	centre_y = 0.34
	top_y = 1.06
	gravity = 14.0
	var stalk := Ps1.mat(Color(0.8, 0.76, 0.64), 0.0, 0.35)
	var gills := Ps1.mat(Color(0.42, 0.36, 0.28), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.12 * side, 0.14, 0))
		_part(leg, _sphere(), stalk, Vector3(0, -0.07, 0.02), Vector3(0.09, 0.07, 0.11))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), stalk, Vector3(0, 0.3, 0), Vector3(0.23 * chub, 0.24, 0.21 * chub))
	_part(torso, _sphere(), gills, Vector3(0, 0.43, 0), Vector3(0.2 * chub, 0.03, 0.18 * chub))
	tail = _pivot(torso, Vector3(0, 0.2, -0.2))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.22 * chub * side, 0.36, 0.04))
		_part(a, _capsule(0.04, 0.2), stalk, Vector3(0, -0.07, 0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0))
	_part(neck, _sphere(), stalk, Vector3(0, 0.16, 0), Vector3(0.2, 0.2, 0.19))
	_part(neck, _sphere(), gills, Vector3(0, 0.34, 0), Vector3(0.4, 0.04, 0.4))
	var dome: Array[Vector2] = [
		Vector2(0.42, 0.33), Vector2(0.44, 0.37), Vector2(0.4, 0.46), Vector2(0.32, 0.54), Vector2(0.2, 0.61), Vector2(0.0, 0.64),
	]
	_part(neck, _lathe(dome, 10), fur, Vector3.ZERO)
	# Spots, lying on the cap
	var middle := Vector3(0, 0.34, 0)
	var radii := Vector3(0.44, 0.3, 0.44)
	for i in 7:
		var around := TAU * i / 7.0 + rng.randf_range(-0.3, 0.3)
		var up := rng.randf_range(0.3, 1.05)
		var at := middle + Vector3(sin(around) * cos(up), sin(up), cos(around) * cos(up)) * radii
		var spot := _part(neck, _sphere(), bone, at)
		var size := rng.randf_range(0.04, 0.075)
		spot.basis = Basis.looking_at(-((at - middle) / (radii * radii)).normalized()).scaled_local(Vector3(size, size, 0.012))
	_part(neck, _sphere(), bone, Vector3(0.02, 0.64, 0), Vector3(0.07, 0.012, 0.06))
	# And a small one of its own, coming up on the side
	_part(neck, _capsule(0.022, 0.14), stalk, Vector3(-0.3, 0.52, -0.08), Vector3.ONE, Vector3(0, 0, 0.6))
	_part(neck, _sphere(), fur, Vector3(-0.345, 0.585, -0.08), Vector3(0.065, 0.04, 0.065), Vector3(0, 0, 0.6))
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.085 * side, 0.15, 0.155), 0.06)
	mouth_node = _pivot(neck, Vector3(0, 0.05, 0.175))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.03))


# A hare with a buck's antlers coming in: long ears, long feet, a scut, and a great deal of spring
func _build_jackalope(chub: float, ear_len: float) -> void:
	neck_y = 0.46
	head_y = 0.18
	centre_y = 0.36
	top_y = 1.5
	ear_splay = 0.45
	gravity = 9.0
	var horn := Ps1.mat(Color(0.66, 0.56, 0.4), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.15 * side, 0.18, -0.06))
		_part(leg, _sphere(), fur, Vector3(0, 0, -0.02), Vector3(0.1, 0.13, 0.14))
		_part(leg, _sphere(), pale, Vector3(0, -0.145, 0.1), Vector3(0.065, 0.035, 0.2))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.34, -0.02), Vector3(0.23 * chub, 0.23, 0.27 * chub), Vector3(0.25, 0, 0))
	_part(torso, _sphere(), pale, Vector3(0, 0.34, 0.14 * chub), Vector3(0.15 * chub, 0.16, 0.11))
	tail = _pivot(torso, Vector3(0, 0.26, -0.27 * chub))
	_part(tail, _sphere(), bone, Vector3(0, 0.02, -0.03), Vector3.ONE * 0.08)

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.15 * chub * side, 0.36, 0.17))
		_part(a, _capsule(0.035, 0.22), fur, Vector3(0, -0.09, 0))
		_part(a, _sphere(), pale, Vector3(0, -0.2, 0.02), Vector3(0.045, 0.03, 0.06))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.1))
	_part(neck, _sphere(), fur, Vector3(0, 0.18, 0), Vector3(0.21, 0.19, 0.22))
	_part(neck, _sphere(), pale, Vector3(0, 0.12, 0.16), Vector3(0.11, 0.08, 0.1))
	_part(neck, _sphere(), maw, Vector3(0, 0.155, 0.255), Vector3(0.03, 0.02, 0.02))
	_part(neck, BoxMesh.new(), bone, Vector3(0, 0.055, 0.235), Vector3(0.045, 0.05, 0.015))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.09 * side, 0.33, -0.05))
		_part(ear, _cone(), fur, Vector3(0, ear_len * 0.6, 0), Vector3(0.06, ear_len * 1.2, 0.03))
		_part(ear, _cone(), pale, Vector3(0, ear_len * 0.55, 0.02), Vector3(0.035, ear_len * 0.9, 0.012))
		ears.append(ear)
		_eye(Vector3(0.13 * side, 0.22, 0.14), 0.07)
		_part(neck, _sphere(), pale, Vector3(0.15 * side, 0.1, 0.06), Vector3.ONE * 0.07)
		# Antlers, in front of the ears: a proper rack, a beam sweeping up and out with a brow
		# tine and three more standing off it
		var root := Vector3(0.08 * side, 0.34, 0.03)
		var fork := _spike(neck, horn, root, Vector3(0.45 * side, 1.0, -0.1), 0.34, 0.058, _drum(0.7, 1.0, 1.0))
		var tip := _spike(neck, horn, fork, Vector3(0.8 * side, 0.6, 0.15), 0.32, 0.044)
		_spike(neck, horn, root.lerp(fork, 0.35), Vector3(-0.05 * side, 0.8, 0.7), 0.2, 0.036)
		_spike(neck, horn, fork, Vector3(0.05 * side, 1.0, 0.0), 0.28, 0.04)
		_spike(neck, horn, fork.lerp(tip, 0.4), Vector3(0.25 * side, 1.0, -0.1), 0.23, 0.034)
		_spike(neck, horn, fork.lerp(tip, 0.75), Vector3(0.3 * side, 1.0, 0.1), 0.15, 0.03)
	mouth_node = _pivot(neck, Vector3(0, 0.075, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.03))


# From a long way off: a head too big for its body, long thin hands, and two black eyes with a
# light far down in each
func _build_alien(chub: float) -> void:
	neck_y = 0.52
	head_y = 0.26
	centre_y = 0.4
	top_y = 1.1
	gravity = 7.0
	gut = 0.6
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.07 * side, 0.24, 0))
		_part(leg, _capsule(0.03, 0.24), fur, Vector3(0, -0.1, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.215, 0.03), Vector3(0.045, 0.025, 0.08))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.4, 0), Vector3(0.13 * chub, 0.19, 0.11 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.34, 0.04), Vector3(0.12 * chub, 0.11, 0.1))
	tail = _pivot(torso, Vector3(0, 0.3, -0.1))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.14 * chub * side, 0.5, 0))
		_part(a, _capsule(0.022, 0.36), fur, Vector3(0, -0.16, 0))
		for finger: float in [-1.0, 0.0, 1.0]:
			_part(a, _cone(), dark, Vector3(0.02 * finger, -0.37, 0), Vector3(0.008, 0.09, 0.008), Vector3(PI, 0, 0.2 * finger))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.01))
	_part(neck, _capsule(0.035, 0.12), fur, Vector3(0, 0.03, 0))
	_part(neck, _sphere(), fur, Vector3(0, 0.3, -0.02), Vector3(0.3, 0.26, 0.3))
	_part(neck, _sphere(), fur, Vector3(0, 0.15, 0.05), Vector3(0.19, 0.17, 0.2))
	# Great slanted eyes, all dark but for the light in them
	for side: float in [-1.0, 1.0]:
		var eye := _pivot(neck, Vector3(0.115 * side, 0.2, 0.225))
		eye.rotation = Vector3(-0.1, 0.45 * side, 0.45 * side)
		_part(eye, _sphere(), black, Vector3.ZERO, Vector3(0.1, 0.062, 0.03))
		var pupil := _part(eye, _sphere(), eye_mat, Vector3(0, 0, 0.03), Vector3(0.026, 0.026, 0.02))
		eyes.append(eye)
		pupils.append(pupil)
	mouth_node = _pivot(neck, Vector3(0, 0.05, 0.215))
	_part(mouth_node, _sphere(), black, Vector3.ZERO, Vector3(0.04, 0.025, 0.02))


# A snow-ape's cub: white and shaggy, with a blue face, blue hands and feet, two nubs of horn,
# and arms it could trip over
func _build_yeti(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.6
	centre_y = 0.46
	top_y = 1.16
	gravity = 14.0
	var blue := Ps1.mat(Color(0.3, 0.46, 0.66), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.16 * side, 0.2, 0))
		_part(leg, _sphere(), fur, Vector3(0, -0.03, 0), Vector3(0.12, 0.15, 0.12))
		_part(leg, _sphere(), blue, Vector3(0, -0.155, 0.07), Vector3(0.11, 0.045, 0.17))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.42, 0), Vector3(0.34 * chub, 0.32, 0.3 * chub))
	# Shag hangs off it all round in two rows, light and lighter
	for i in 18:
		var around := TAU * (i + 0.5 * (i % 2)) / 18.0
		var high := 0.5 if i % 2 == 0 else 0.32
		var wide := 0.27 if i % 2 == 0 else 0.31
		var lie := Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, PI - 0.3)
		var hank := _part(torso, _cone(), pale if i % 3 == 0 else fur, Vector3.ZERO)
		var long := rng.randf_range(0.14, 0.22)
		hank.basis = lie * Basis.from_scale(Vector3(0.075, long, 0.04))
		hank.position = Vector3(sin(around) * wide * chub, high, cos(around) * wide * 0.88 * chub) + lie * Vector3(0, long * 0.5, 0)
	tail = _pivot(torso, Vector3(0, 0.3, -0.26 * chub))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.33 * chub * side, 0.62, 0.02))
		_part(a, _capsule(0.075, 0.42), fur, Vector3(0, -0.17, 0))
		_part(a, _cone(), pale, Vector3(0, -0.3, -0.03), Vector3(0.08, 0.16, 0.05), Vector3(PI, 0, 0))
		_part(a, _sphere(), blue, Vector3(0, -0.4, 0.01), Vector3(0.09, 0.08, 0.09))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.04))
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.28, 0.25, 0.26))
	_part(neck, _sphere(), blue, Vector3(0, 0.17, 0.12), Vector3(0.19, 0.16, 0.16))
	_part(neck, _sphere(), fur, Vector3(0, 0.3, 0.16), Vector3(0.2, 0.06, 0.1))
	_part(neck, _sphere(), dark, Vector3(0, 0.16, 0.285), Vector3(0.03, 0.022, 0.02))
	for i in 3:
		_part(neck, _cone(), pale, Vector3((i - 1) * 0.07, 0.47, 0.02), Vector3(0.05, 0.14, 0.04), Vector3(0.3, 0, (i - 1) * -0.4))
	for side: float in [-1.0, 1.0]:
		_part(neck, _cone(), blue, Vector3(0.21 * side, 0.4, 0), Vector3(0.045, 0.14, 0.045), Vector3(0, 0, -0.6 * side))
		_eye(Vector3(0.085 * side, 0.21, 0.245), 0.055)
		_part(neck, _cone(), bone, Vector3(0.05 * side, 0.1, 0.265), Vector3(0.018, 0.05, 0.018))
	mouth_node = _pivot(neck, Vector3(0, 0.07, 0.265))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.09, 0.045, 0.04))


# Three heads on one pup, each with a mind of its own and all of them hungry
func _build_cerberus(chub: float) -> void:
	neck_y = 0.5
	head_y = 0.19
	centre_y = 0.38
	top_y = 1.0
	ear_splay = 1.5
	gut = 0.8
	back_y = 0.5
	var collar := Ps1.mat(Color(0.62, 0.1, 0.08), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.14 * side, 0.24, -0.2))
		_part(leg, _capsule(0.055, 0.24), fur, Vector3(0, -0.1, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.205, 0.03), Vector3(0.07, 0.035, 0.1))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.38, -0.02), Vector3(0.25 * chub, 0.21, 0.33 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.36, 0.2 * chub), Vector3(0.2 * chub, 0.17, 0.14))
	# A whip of a tail with a barb on the end
	tail = _pivot(torso, Vector3(0, 0.46, -0.32 * chub))
	_part(tail, _capsule(0.022, 0.3), fur, Vector3(0, 0.09, -0.1), Vector3.ONE, Vector3(-0.85, 0, 0))
	_part(tail, _cone(), collar, Vector3(0, 0.23, -0.26), Vector3(0.05, 0.1, 0.02), Vector3(-0.85, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.15 * chub * side, 0.3, 0.2 * chub))
		_foreleg(a, side, 0.3, 0.05)
		arms.append(a)

	# The middle head is the one on the neck; the other two sit either side and follow it round
	neck = _pivot(torso, Vector3(0, neck_y, 0.27 * chub))
	ears = _hound_head(neck, collar)
	mouth_node = _pivot(neck, Vector3(0, 0.095, 0.215))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.06, 0.035, 0.05))
	for side: float in [-1.0, 1.0]:
		var head := _pivot(torso, Vector3(0.21 * chub * side, 0.46, 0.2 * chub))
		head.rotation.y = 0.6 * side
		var flops := _hound_head(head, collar)
		flops[0].rotation.z = 1.4
		flops[1].rotation.z = -1.4
		_part(head, _sphere(), maw, Vector3(0, 0.095, 0.215), Vector3(0.05, 0.012, 0.04))
		heads.append(head)


# One of a hound's heads, on a pivot: collar, skull, muzzle, nose, fangs and eyes. Gives back
# its two ears, for the rig to work or not.
func _hound_head(on: Node3D, collar: Material) -> Array[Node3D]:
	_part(on, _sphere(), fur, Vector3(0, 0.03, -0.03), Vector3.ONE * 0.115)
	_part(on, _sphere(), collar, Vector3(0, 0.05, -0.02), Vector3(0.125, 0.03, 0.125), Vector3(0.3, 0, 0))
	_part(on, _sphere(), fur, Vector3(0, 0.19, 0.03), Vector3(0.165, 0.15, 0.165))
	_part(on, _sphere(), pale, Vector3(0, 0.14, 0.17), Vector3(0.085, 0.07, 0.105))
	_part(on, _sphere(), black, Vector3(0, 0.165, 0.27), Vector3(0.03, 0.022, 0.02))
	var flops: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(on, Vector3(0.12 * side, 0.29, -0.02))
		_part(ear, _cone(), dark, Vector3(0, 0.07, 0), Vector3(0.055, 0.15, 0.03))
		flops.append(ear)
		_eye(Vector3(0.075 * side, 0.225, 0.155), 0.05, false, on)
		_part(on, _cone(), bone, Vector3(0.04 * side, 0.08, 0.235), Vector3(0.014, 0.05, 0.014), Vector3(PI, 0, 0))
	return flops


# An eye on the head (or on another one). Hollow ones are dark with the light in the pupil.
func _eye(at: Vector3, size: float, hollow := false, on: Node3D = null) -> void:
	var eye := _pivot(neck if on == null else on, at)
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
			# (wound clockwise seen from outside, which is the front of a face)
			for index: int in [a, b, a + 1, a + 1, b, b + 1]:
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


# A horn, tine or spine standing off `base` the way `dir` points; gives back where its tip is, so
# that the next can grow from there. A cone unless another mesh a unit tall is given.
func _spike(parent: Node3D, mat: Material, base: Vector3, dir: Vector3, length: float, thick: float, mesh: Mesh = null) -> Vector3:
	var up := dir.normalized()
	var across := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var mi := _part(parent, _cone() if mesh == null else mesh, mat, base + up * length * 0.5)
	mi.basis = Basis(across * thick, up * length, across.cross(up) * thick)
	return base + up * length


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
	bubble = _pivot(self, Vector3(0.35, top_y + hover + 0.35, 0))
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
	bubble_water = _pivot(bubble, Vector3(0, 0, 0.02))
	var wet := Ps1.flat(Color(0.2, 0.55, 0.95))
	_part(bubble_water, _sphere(), wet, Vector3(0, -0.04, 0), Vector3(0.085, 0.085, 0.01))
	_part(bubble_water, _cone(), wet, Vector3(0, 0.07, 0), Vector3(0.07, 0.14, 0.01))
	_part(bubble_water, _sphere(), Ps1.flat(Color(0.8, 0.92, 1.0)), Vector3(-0.03, -0.05, 0.004), Vector3(0.022, 0.035, 0.01))
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
	hearts.position = Vector3(0, top_y + hover - 0.1, 0)
	hearts.emitting = false
	hearts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hearts)


# The faces that go up over its head, a picture for each feeling, and the card they are shown on
func _build_emote() -> void:
	var inks := {"#": Color(0.1, 0.07, 0.12), "o": Color.WHITE, "r": Color(0.86, 0.12, 0.22), "b": Color(0.25, 0.55, 1.0)}
	for face in FACES:
		if face.is_empty():
			faces.append(null)
			continue
		var img := Image.create(FACE, FACE, false, Image.FORMAT_RGBA8)
		var tint: Color = face["tint"]
		for py in FACE:
			for px in FACE:
				var away := Vector2(px - 7.5, py - 7.5).length()
				if away < 7.9:
					img.set_pixel(px, py, tint if away < 6.9 else inks["#"])
		var rows: Array = face["rows"]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if inks.has(row[x]):
					img.set_pixel(x + 3, y + 4, inks[row[x]])
		faces.append(ImageTexture.create_from_image(img))
	# Lit by nothing and hidden by nothing: it shows as well in the dark as under the lamp
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.no_depth_test = true
	mat.render_priority = 4
	emote = _part(self, QuadMesh.new(), mat, Vector3.ZERO)
	emote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emote.visible = false


# ---------------------------------------------------------------- needs

# How it is doing all round: mostly its needs, and partly how well its room suits it
func mood() -> float:
	return (belly + fun + energy) / 3.0 * 0.75 + comfort * 0.25


func get_needs() -> Dictionary:
	return {"belly": belly, "fun": fun, "energy": energy, "love": love, "age": age, "digest": digest, "bowel": bowel, "bladder": bladder}


func set_needs(d: Dictionary) -> void:
	belly = clampf(float(d.get("belly", belly)), 0.0, 100.0)
	fun = clampf(float(d.get("fun", fun)), 0.0, 100.0)
	energy = clampf(float(d.get("energy", energy)), 0.0, 100.0)
	love = clampf(float(d.get("love", love)), 0.0, 100.0)
	# Saves from before there were babies hold a grown one
	age = float(d.get("age", GROW_AGE))
	digest = maxf(float(d.get("digest", digest)), 0.0)
	bowel = clampf(float(d.get("bowel", bowel)), 0.0, 100.0)
	bladder = clampf(float(d.get("bladder", bladder)), 0.0, 100.0)
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
	# What it has eaten works its way through in a few hours, and it has to pee every so often;
	# a baby is quicker about both
	var quick := 1.6 if is_baby() else 1.0
	var through := minf(digest, seconds * quick * 100.0 / (DIGEST_HOURS * HOUR))
	digest -= through
	bowel = minf(bowel + through, 100.0)
	bladder = minf(bladder + seconds * quick * (0.5 if asleep else 1.0) * 100.0 / (PEE_HOURS * HOUR), 100.0)
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
		# What it would have left on the floor in that time: droppings (a few; after that it is
		# all one heap as far as anyone can tell) and whatever puddles have not had time to dry
		if bowel >= 100.0:
			bowel = 0.0
			if world.droppings() < 4:
				world.leave_mess(Mess.Kind.DROPPING, world.toilet_spot(self), self, left)
		if bladder >= 100.0:
			bladder = 0.0
			if left < Mess.LASTS[Mess.Kind.PUDDLE]:
				world.leave_mess(Mess.Kind.PUDDLE, world.toilet_spot(self), self, left)
		if asleep:
			asleep = energy < 98.0
		else:
			asleep = energy < 12.0 or (dark and energy < 70.0)
	grow = size_goal()
	scale = Vector3.ONE * grow
	return asleep


# ---------------------------------------------------------------- what you can do to it

func body_centre() -> Vector3:
	return global_position + Vector3(0, (centre_y + hover * (1.0 - curl) - curl * 0.2) * grow, 0)


# How tall it stands (to the top of whatever is on its head), off the floor if it floats
func tall() -> float:
	return (top_y + hover * (1.0 - curl)) * grow


# How far above its feet the top of its head is just now: lower sat down or curled up, and
# higher on a baby, whose head is big for it
func top() -> float:
	return (neck_y + (top_y - neck_y) * neck.scale.y + hover * (1.0 - curl) - sit * 0.1 - curl * 0.3) * grow


# One of the kinds that live in water
func needs_water() -> bool:
	return KINDS[kind].get("water", false)


# A water kind with no pool in its room
func dry() -> bool:
	return needs_water() and world.decor_of(Decor.Kind.POOL) == null


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
# moment; a feeling that goes on (hungry, bored, sad, grumpy) comes up again every so often.
# Never while it sleeps (it has its z's), begs (it has its bubble) or is under the scanner.
func _show_emote(delta: float) -> void:
	emote_again -= delta
	var lasting := feeling in [Feeling.HUNGRY, Feeling.BORED, Feeling.SAD, Feeling.GRUMPY]
	if feeling != emote_for or (lasting and emote_again <= 0.0 and not emote.visible):
		# Settling back to plain happiness after something else is not news
		var news := feeling != Feeling.HAPPY or emote_again <= 0.0
		emote_for = feeling
		emote.visible = faces[feeling] != null and news
		if emote.visible:
			emote.material_override.albedo_texture = faces[feeling]
			emote_time = 0.0
			emote_again = randf_range(10.0, 16.0)
	if state == State.SLEEP or bubble.visible or xrayed or emote_time > 3.0:
		emote.visible = false
	if not emote.visible:
		return
	emote_time += delta
	# One dot of the face to one dot of the picture however far off it is, and set square on the
	# picture's dots, so that it is as sharp as it can be
	var cam := world.camera
	var above := global_position + Vector3(0, top(), 0)
	var deep := -(cam.global_transform.affine_inverse() * above).z
	var dot := 2.0 * deep * tan(deg_to_rad(cam.fov) * 0.5) / world.view.size.y
	var pop := 1.0 - exp(-emote_time * 9.0) * cos(emote_time * 16.0)
	var at := (cam.unproject_position(above) - Vector2(0, FACE * 0.5 + 1.0 + 4.0 * pop)).round()
	emote.global_transform = Transform3D(cam.global_basis * Basis.from_scale(Vector3.ONE * dot * FACE), cam.project_position(at, deep))
	emote.material_override.albedo_color.a = 1.0 - smoothstep(2.5, 3.0, emote_time)


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
	var seen := caught()
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
	_enter(State.HELD)
	var how: int = NATURES[nature]["carry"]
	feel(how, 60.0)
	_cry("squeak" if how in [Feeling.SCARED, Feeling.GRUMPY] else "chirp")
	if seen:
		feel(Feeling.SCARED, 6.0)


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
	if caught():
		return
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
	if caught():
		return
	if state in [State.SLEEP, State.GO_SLEEP, State.EAT, State.PETTED, State.STARTLED, State.LEAVE, State.HELD, State.SHOVED, State.SCANNED]:
		return
	target = Den.in_room(point, 0.35)
	_enter(State.COME)


# Something in its room has changed (a thing put in at `point`, new ground, the lamp):
# it goes over to see, and shows what it makes of it. `liking` is 1 if this is what it
# wants, -1 if it cannot stand it and 0 if it does not mind; `key` is what Den.learned() is told
# once it has looked (nothing, if there is nothing in that to learn).
func look_over(point: Vector3, liking: int, key: String) -> void:
	if caught() or not state in INTERRUPTIBLE:
		return
	inspect_liking = liking
	inspect_key = key
	target = Den.in_room(point, 0.35)
	_enter(State.INSPECT)


# The scanner is on it: it holds still and looks at you while it is
func hold_still() -> void:
	if caught():
		return
	if state in INTERRUPTIBLE or state in [State.STARTLED, State.INSPECT]:
		_enter(State.SCANNED)


# Whether one of its two natures is this one (an index into NATURES)
func _is(which: int) -> bool:
	return nature == which or nature2 == which


# Whether it might take a fancy to its nest just now, as a dog does to a cushion: only a grown
# one, content and not lately at it. A bold one does not care who sees; a shy one waits for the
# dark, or a nest tucked into a shelter; the rest wait until they have been left alone a while.
func _fancies() -> bool:
	if is_baby() or fond_cooldown > 0.0 or mood() < 60.0 or energy < 35.0:
		return false
	if _is(5):
		return true
	if _is(2):
		return not world.light_on or world.sheltered(world.nest_pos)
	return world.left_alone() > 20.0


# Come upon at it: it stops dead, and stares, and wishes the floor would open. True if it was.
func caught() -> bool:
	if state != State.FOND or step != 1:
		return false
	step = 2
	state_time = 0.0
	lift = 0.0
	wiggle = 0.0
	nod = 0.0
	arm_goal = REST_ARM
	feel(Feeling.SCARED, 3.5)
	_cry("squeak", 1.2)
	return true


# What it leaves behind takes after it a little
func dropping_colour() -> Color:
	var mine: Color = fur.get_shader_parameter("tint")
	return Color(0.3, 0.2, 0.1).lerp(mine, 0.35)


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
	food_cooldown -= delta
	beg_cooldown -= delta
	pounce_cooldown -= delta
	nest_cooldown -= delta
	fond_cooldown -= delta
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
	# (a baby has no such notions)
	if s == State.FOND and is_baby():
		s = State.IDLE
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
			visiting = world.shelter(self)
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
			# Food before anything; then water, if it is bored of nothing in particular
			beg_for = Want.BALL
			if belly < 25.0:
				beg_for = Want.FOOD
			elif dry() and (fun >= 22.0 or world.ball != null):
				beg_for = Want.WATER
			beg_cooldown = 90.0 if beg_for == Want.WATER else 30.0
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
		State.TOILET:
			target = world.toilet_spot(self)
		State.FOND:
			# Its nest, or its favourite toy if that is lying about
			fond_cooldown = randf_range(300.0, 900.0)
			kicks = 0
			target = world.nest_pos
			if world.ball != null and world.ball.kind == fav_toy and world.ball.speed() < 0.3 and randf() < 0.4:
				target = Vector3(world.ball.position.x, 0, world.ball.position.z)
		State.SCRATCH:
			state_len = randf_range(1.6, 2.6)
		State.DIG:
			state_len = randf_range(2.5, 4.0)
		State.SPIN:
			state_len = randf_range(1.8, 2.8)
			_cry("chirp", 1.3)
		State.GAZE:
			state_len = randf_range(3.0, 5.0)
			target = world.bulb.global_position if world.light_on and randf() < 0.7 else Vector3(Den.half.x - 1.0, Den.lamp_at.y - 0.9, -Den.half.y)
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
	elif bowel >= 100.0 or bladder >= 100.0:
		_enter(State.TOILET)
	elif belly < 97.0 and world.snack_for(self) != null and not _hangs_back():
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
	# Hungry, bored, or (now and then) a water kind with nowhere to get wet: it asks
	if beg_cooldown <= 0.0 and world.light_on and (belly < 25.0 or (fun < 22.0 and world.ball == null) or (dry() and randf() < 0.3)):
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
	# Odds and ends, by its kind and its natures
	options[State.SCRATCH] = 5.0 * (1.6 if _is(6) else 1.0)
	options[State.GAZE] = 4.0 * float(likes["stare"])
	if world.floor_style >= 4 and energy > 30.0:
		options[State.DIG] = 6.0 * (1.5 if _is(1) or _is(7) else 1.0) * (1.4 if world.floor_style == fav_ground else 1.0)
	if tail.get_child_count() > 0 and energy > 40.0:
		options[State.SPIN] = 3.0 * float(likes["zoom"])
	if _fancies():
		options[State.FOND] = 3.0
	var total := 0.0
	for w: float in options.values():
		total += w
	var roll := randf() * total
	for s: int in options:
		roll -= float(options[s])
		if roll <= 0.0:
			if s == State.WANDER:
				var a := randf() * TAU
				target = Den.in_room(Vector3(randf_range(-9.0, 9.0), 0, randf_range(-9.0, 9.0)).limit_length(Den.half.length()), 0.4)
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
						# Tucked into a shelter, looking out
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
				bubble_food.visible = beg_for == Want.FOOD
				bubble_ball.visible = beg_for == Want.BALL
				bubble_water.visible = beg_for == Want.WATER
				if beg_for == Want.FOOD:
					arm_goal = BELLY_ARM
					arm_wave = 0.25
				if state_time > state_len:
					_enter(State.IDLE)
		State.ZOOMIES:
			var a := state_len + step * 1.9
			var point := Den.in_room(Vector3(cos(a) * Den.half.x, 0, sin(a) * Den.half.y) * 0.75, 0.4)
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
					if inspect_key != "":
						world.learned(self, inspect_key)
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
			# A water kind does not stop at the edge of the pool
			var wading := visiting.kind == Decor.Kind.POOL and needs_water()
			if step == 0:
				var near := 0.2 if visiting.hollow else visiting.radius + 0.28 * grow
				if wading:
					near = visiting.radius * 0.45
				if _steer(at, WALK * 1.2, delta, near) or state_time > 7.0:
					step = 1
					state_time = 0.0
					state_len = randf_range(4.0, 7.5) + (4.0 if wading else 0.0)
					if visiting.kind == Decor.Kind.ROCK:
						hop(2.6)
					if wading:
						hop(2.2)
						world.splash(at)
						hearts.emitting = true
						feel(Feeling.LOVING, 4.0)
						world.learned(self, "water")
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
					_ when visiting.hollow:
						# Sits inside, looking out
						sit_goal = 1.0
						eye_goal = 1.2
						gaze = world.camera.global_position
						_face(gaze, delta)
					Decor.Kind.POOL when wading:
						# Wades in up to its middle and paddles about
						var down := 1.0 - exp(-delta * 5.0)
						position.x = lerpf(position.x, at.x, down)
						position.z = lerpf(position.z, at.z, down)
						if not airborne:
							lift = lerpf(lift, minf(Decor.WATER - centre_y * 0.75 * grow, 0.0), down)
						arm_wave = 0.2
						wag = 8.0
						wiggle = sin(anim_t * 3.0) * 0.06
						gaze = world.camera.global_position
						_face(gaze, delta)
						if int(state_time / 1.4) + 1 > step:
							step = int(state_time / 1.4) + 1
							world.splash(position)
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
					fun = minf(fun + (5.0 if wading else 1.5), 100.0)
					if visiting.kind in like_decor:
						love = minf(love + 0.3, 100.0)
					_enter(State.IDLE, 1.0)
					if wading:
						# Out over the stones
						hop(2.2)
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
		State.TOILET:
			if step == 0:
				gaze = target + Vector3(0, 0.2, 0)
				if _steer(target, WALK * 1.3, delta, 0.25) or state_time > 7.0:
					step = 1
					state_time = 0.0
			elif step == 1:
				# Squats, looking anywhere but at you
				_halt(delta)
				sit_goal = 1.0
				eye_goal = 0.5
				roll_goal = 0.2
				wiggle = sin(anim_t * 14.0) * 0.03
				gaze = position + Vector3(sin(yaw + 1.2), 0.3, cos(yaw + 1.2)) * 2.0
				if state_time > (1.8 if bowel >= 100.0 else 1.0):
					var behind := position - Vector3(sin(yaw), 0, cos(yaw)) * 0.25 * grow
					behind.y = 0.0
					if bowel >= 100.0:
						bowel = 0.0
						world.leave_mess(Mess.Kind.DROPPING, behind, self)
					else:
						bladder = 0.0
						world.leave_mess(Mess.Kind.PUDDLE, behind, self)
					step = 2
					state_time = 0.0
					sit_goal = 0.0
					roll_goal = 0.0
					eye_goal = 1.0
					hop(1.4)
					_cry("coo", 1.1, -6.0)
			else:
				_halt(delta)
				if state_time > 0.7:
					_enter(State.IDLE, 0.8)
		State.FOND:
			if step == 0:
				gaze = target + Vector3(0, 0.1, 0)
				if _steer(target, WALK * 1.2, delta, 0.15) or state_time > 8.0:
					step = 1
					state_time = 0.0
					state_len = randf_range(4.0, 6.0)
					feel(Feeling.LOVING, state_len)
			elif step == 1:
				# Up on it and giving it everything, eyes half shut
				_halt(delta)
				lift = lerpf(lift, 0.07, 1.0 - exp(-delta * 8.0))
				eye_goal = 0.35
				droop_goal = 0.6
				arm_goal = BELLY_ARM
				wag = 14.0
				wiggle = sin(anim_t * 19.0) * 0.13
				nod = 0.25 + sin(anim_t * 19.0) * 0.06
				if int(state_time / 0.33) > kicks:
					kicks = int(state_time / 0.33)
					squash_v = 2.2
				if state_time > state_len:
					fun = minf(fun + 6.0, 100.0)
					_cry("coo", 0.9)
					_enter(State.IDLE, 1.5)
					eye_goal = 0.5
			else:
				# Seen: stock still, staring at you, ears down
				_halt(delta)
				gaze = world.camera.global_position
				_face(gaze, delta)
				eye_goal = 1.25
				droop_goal = 1.0
				if state_time > 3.0:
					_enter(State.IDLE, 1.0)
		State.SCRATCH:
			# A good scratch behind the ear, head on one side
			_halt(delta)
			sit_goal = 1.0
			arm_goal = Vector3(-2.5, 0.0, 0.5)
			arm_wave = 0.5
			roll_goal = 0.35
			eye_goal = 0.4
			if state_time > state_len:
				_enter(State.IDLE, 0.8)
		State.STRETCH:
			# Up on its toes with its arms over its head, and a yawn to go with it
			_halt(delta)
			arm_goal = UP_ARM
			mouth_goal = 1.0 if state_time < 1.0 else 0.12
			eye_goal = 0.25
			nod = -0.35
			if step == 0:
				step = 1
				squash_v = -2.6
				_cry("yawn", 1.1)
			if state_time > 1.6:
				_enter(State.IDLE, 1.0)
		State.DIG:
			# Head down and both arms going: earth flies, and a heap is left behind
			_halt(delta)
			nod = 0.5 + sin(state_time * 9.0) * 0.1
			arm_goal = Vector3(-1.2, 0.0, 0.2)
			arm_wave = 0.6
			wag = 9.0
			gaze = position + Vector3(sin(yaw), 0.0, cos(yaw)) * 0.4
			var ahead := position + Vector3(sin(yaw), 0, cos(yaw)) * 0.3 * grow
			if int(state_time / 0.45) + 1 > step:
				step = int(state_time / 0.45) + 1
				world.crumbs(ahead + Vector3(0, 0.1, 0), Den.GROUND_TINTS[world.floor_style])
				_cry("chomp", 0.7, -14.0)
			if state_time > state_len:
				world.leave_mess(Mess.Kind.HEAP, Vector3(ahead.x, 0, ahead.z), self)
				fun = minf(fun + 5.0, 100.0)
				_enter(State.IDLE, 1.0)
		State.SPIN:
			# Round and round after its own tail, and then the room goes round by itself
			_halt(delta)
			if state_time < state_len:
				yaw += delta * 9.0
				wag = 14.0
				mouth_goal = 0.6
				gaze = position - Vector3(sin(yaw - 1.0), -0.2, cos(yaw - 1.0))
			else:
				wiggle = sin(anim_t * 4.0) * 0.22
				roll_goal = 0.3
				eye_goal = 0.6
				if state_time > state_len + 1.4:
					fun = minf(fun + 4.0, 100.0)
					_enter(State.IDLE, 1.0)
		State.GAZE:
			# Sits and stares up into the lamp, or at whatever lives in the vent
			_halt(delta)
			sit_goal = 1.0
			eye_goal = 1.2
			gaze = target
			_face(target, delta)
			if state_time > state_len:
				_enter(State.IDLE, 0.8)
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
			elif _steer(target, WALK * 0.85, delta, 0.5 if _bed_taken() else 0.12) or state_time > 12.0:
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
				_enter(State.STRETCH)
			# Sent to bed by the dark: remember, so that the lamp coming back on wakes it
			if not world.light_on:
				state_len = -1.0


# Whether another is asleep in the nest already (the next one in lies down beside it)
func _bed_taken() -> bool:
	for other in world.pets():
		if other != self and other.state == State.SLEEP and other.position.distance_to(world.nest_pos) < 0.6:
			return true
	return false


# Whether it leaves the food to the others for now: one that has just eaten gives them a moment
# (a greedy one does not), and a shy one lets them go first. Not if it is properly hungry.
func _hangs_back() -> bool:
	if belly < 20.0 or world.pets().size() < 2:
		return false
	if food_cooldown > 0.0 and not _is(0):
		return true
	if not _is(2) or belly < 30.0:
		return false
	for other in world.pets():
		if other != self and other.state in [State.GO_FOOD, State.EAT]:
			return true
	return false


func _go_food(delta: float) -> void:
	if not is_instance_valid(snack) or snack.held:
		snack = world.snack_for(self)
		if snack == null:
			_enter(State.IDLE, 0.6)
			return
	gaze = snack.global_position
	var away := Vector2(snack.position.x - position.x, snack.position.z - position.z).length()
	mouth_goal = 0.6 if away < 1.2 else 0.12
	# A greedy or a bold one pushes in ahead of the rest
	var haste := 1.25 if _is(0) or _is(5) else 1.0
	if _steer(snack.position, RUN * haste, delta, 0.42) and snack.landed:
		var s := snack
		_enter(State.EAT)
		snack = s
	elif state_time > 12.0:
		_enter(State.IDLE)


func _eat(delta: float) -> void:
	_halt(delta)
	if not is_instance_valid(snack) or snack.held:
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
			# One taste is enough, unless it is starving; it is left lying if one of the others
			# might have it
			if world.wanted_by_another(snack, self):
				spurned.append(snack.get_instance_id())
			else:
				world.remove_snack(snack)
			snack = null
			love = maxf(love - 1.0, 0.0)
			_cry("grumble", 1.3)
			_enter(State.STARTLED, 1.0)
			roll_goal = 0.35
			feel(Feeling.DISGUSTED, 5.0)
			world.learned(self, "yuck")
			return
		# Each bite is whoever's took it, so two at one bit of food share it as they come
		var loved := eaten == fav_food
		var share := 1.0 / Snack.BITES
		digest += 100.0 * share
		belly = minf(belly + Snack.VALUE * share * (1.3 if loved else (0.5 if eaten == yuck_food else 1.0)), 100.0)
		love = minf(love + (6.0 if loved else 2.0) * share, 100.0)
		if loved:
			fun = minf(fun + 8.0 * share, 100.0)
			feel(Feeling.LOVING, 5.0)
			world.learned(self, "food")
		if snack.bite():
			world.remove_snack(snack)
			snack = null
			food_cooldown = 4.0
			_cry("coo")
			hop(2.0)
			_enter(State.IDLE, 1.2)
			arm_goal = BELLY_ARM
			eye_goal = 0.5
			hearts.emitting = loved


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
		world.learned(self, "toy")
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


# Eased out of the way of something `room` across, not snapped: it slides round things
func _keep_off(centre: Vector3, room: float, delta: float) -> void:
	var off := Vector2(position.x - centre.x, position.z - centre.z)
	if off.length() < room:
		# (two on the very same spot part to either side, by the numbers they were given)
		off = (off.normalized() if off.length() > 0.001 else Vector2.from_angle(me.id * 2.4)) * room
		var clear := Vector2(position.x, position.z).move_toward(Vector2(centre.x, centre.z) + off, delta * 4.0)
		position.x = clear.x
		position.z = clear.y


# The others in the room, and any eggs, push it aside as softly as the things do, so that no
# two ever stand in one another. One that is asleep is not shifted by one that is up and about;
# sleepers in the one nest lie close.
func _keep_off_others(delta: float) -> void:
	for r in world.residents:
		if r.egg != null and r.egg.landed:
			_keep_off(r.egg.position, 0.3 + 0.2 * grow, delta)
	for other in world.pets():
		if other == self or other.lift > 0.05:
			continue
		if state == State.SLEEP and other.state != State.SLEEP:
			continue
		var room := 0.3 * (grow + other.grow)
		_keep_off(other.position, room * (0.7 if state == State.SLEEP else 1.0), delta)


func _move(delta: float) -> void:
	position.x += velocity.x * delta
	position.z += velocity.z * delta
	if state != State.LEAVE:
		# It walks round the things in its tank, and stays inside the walls
		if lift <= 0.05:
			for thing in world.decors:
				var room := thing.radius + 0.2 * grow
				# Not the shelter it is tucked into, nor the rock it is sat on
				if (thing.hollow and state in [State.SLEEP, State.GO_SLEEP, State.MOVE_NEST]) or (thing == visiting and state in [State.LURK, State.VISIT]):
					continue
				_keep_off(thing.position, room, delta)
			# And round what has been left on the floor, unless it is busy adding to it
			if state != State.TOILET:
				for m in world.messes:
					if m.kind != Mess.Kind.HEAP:
						_keep_off(m.position, 0.08 + 0.18 * grow, delta)
			_keep_off_others(delta)
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
	for i in eyes.size():
		eyes[i].scale = Vector3(1.0, maxf(eye_open, 0.07), 1.0)
		var socket: Node3D = eyes[i].get_parent()
		var d := (socket.global_transform.affine_inverse() * gaze - eyes[i].position).normalized()
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

	# Wings of its own beat by themselves, harder off the ground; spare heads follow the one on
	# the neck round, a little behind it
	for i in flaps.size():
		var side := -1.0 if i == 0 else 1.0
		flaps[i].rotation.y = side * (0.2 + sin(anim_t * flap_rate * (1.6 if airborne else 1.0)) * flap_reach)
	for i in heads.size():
		var side := -1.0 if i == 0 else 1.0
		var turn := Vector3(head_pitch * 0.8 + nod * 0.7 + hang, head_yaw * 0.6 + 0.6 * side, head_roll - 0.15 * side)
		heads[i].rotation = heads[i].rotation.lerp(turn, ease_slow * 0.5)
		heads[i].scale = neck.scale * 0.9

	if xrayed:
		_show_insides()
	if bubble.visible:
		bubble.global_basis = world.camera.global_basis
		bubble.position.y = top_y + hover + 0.35 + sin(anim_t * 2.0) * 0.03
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
	if node == bubble or node == emote or node in insides:
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
	var top: float = back_y if back_y > 0.0 else neck_y + brain_at.y * 0.5
	_part(chest, _capsule(0.014, maxf(top - centre_y + 0.22, 0.1)), white, Vector3(0, (top + centre_y - 0.22) * 0.5, -0.06))
	# The rest sits about the middle of its body, smaller in a slight one
	var organs := _pivot(chest, Vector3(0, centre_y, 0))
	organs.scale = Vector3.ONE * gut
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.82
	hoop.outer_radius = 1.0
	hoop.rings = 8
	hoop.ring_segments = 3
	for i in 3:
		_part(organs, hoop, white, Vector3(0, 0.14 - i * 0.07, 0), Vector3(0.14 - i * 0.012, 0.02, 0.11))
	for limb in legs + arms:
		insides.append(_part(limb, _capsule(0.012, 0.16), white, Vector3(0, -0.09, 0)))

	stomach = _pivot(organs, Vector3(0, -0.11, 0.03))
	_part(stomach, _sphere(), Ps1.organ(Color(0.32, 0.2, 0.1)), Vector3.ZERO, Vector3(0.125, 0.105, 0.1))
	stomach_fill = _part(stomach, _sphere(), Ps1.organ(Color(1.0, 0.72, 0.2)), Vector3.ZERO, Vector3(0.11, 0.09, 0.085))
	stomach_fill.material_override.render_priority = 3
	heart = _part(organs, _sphere(), Ps1.organ(Color(1.0, 0.25, 0.35)), Vector3(0.06, 0.08, 0.06), Vector3.ONE * 0.04)
	heart.material_override.render_priority = 3
	for side: float in [-1.0, 1.0]:
		lungs.append(_part(organs, _sphere(), Ps1.organ(Color(0.3, 0.6, 0.9)), Vector3(0.075 * side - 0.02, 0.1, -0.005), Vector3(0.045, 0.07, 0.04)))
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
