class_name Cryptlin
extends Node3D
## One cryptlin: its body (built from primitives, shaped by its kind and a seed), its needs, its
## small brain, and its animation, which is all done here in code. It faces +Z.

signal left

enum State {
	IDLE, WANDER, STARE, LURK, COME, GO_FOOD, EAT, CHASE_BALL, CHASE_LIGHT,
	BEG, ZOOMIES, DANCE, PETTED, STARTLED, GO_SLEEP, SLEEP, LEAVE, HELD, SHOVED, INSPECT, SCANNED, VISIT, MOVE_NEST,
	TOILET, FOND, SCRATCH, STRETCH, DIG, SPIN, GAZE,
	SNIFF, FOLLOW, TAG, FLEE, SCUFFLE, COWED, DYING, PAIR, FLOUNDER, TRICK, SPELL,
}
# The cryptids they are the young of
enum Kind {
	GREMLIN, SQUATCH, COCKATRICE, MOTHMAN, CHUPACABRA, FROGMAN, NESSIE, BOLTER, WENDIGO,
	KELPIE, MERFOLK, SPAWN, GNOME, FAE, FUNGUS, JACKALOPE, ALIEN, YETI, CERBERUS, MOLE,
}

# What sets the kinds apart besides their looks: pace on the ground, appetite, how fast they tire,
# the spring in their hop, the pitch of their voice, and what they like to do with a free moment.
# The ones marked "water" live in it, and are not at home without a pool to wade in. "dig" is how
# much more than the rest one digs (and it will dig any floor); "dim" is one from underground,
# as happy with the lamp off as low and unhappy under the bright one; "sight" is how far one that
# is short-sighted can see a toy or the moving light; "print" is the footprint a heavy one leaves
# (see Track).
const KINDS: Array[Dictionary] = [
	{"title": "gremlin", "pace": 1.0, "hunger": 1.0, "tire": 1.0, "spring": 1.0, "voice": 1.0, "lurk": 1.0, "zoom": 1.0, "dance": 1.0, "stare": 1.0},
	{"title": "squatchling", "pace": 0.85, "hunger": 1.25, "tire": 1.1, "spring": 0.7, "voice": 0.55, "lurk": 2.2, "zoom": 0.5, "dance": 1.1, "stare": 1.4, "print": "sasquatch"},
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
	{"title": "mole person", "pace": 0.72, "hunger": 1.2, "tire": 1.0, "spring": 0.6, "voice": 0.65, "lurk": 2.8, "zoom": 0.4, "dance": 0.7, "stare": 0.5, "dig": 5.0, "dim": true, "sight": 1.3},
]
# What the numbers in saves from before this list stood for (gremlin, bogle, spook, flit)
const OLD_KINDS: Array[int] = [Kind.GREMLIN, Kind.FROGMAN, Kind.WENDIGO, Kind.MOTHMAN]

# What it can beg for, with a picture of it in a thought bubble
enum Want { FOOD, BALL, WATER }

# How it is feeling just now, which shows in its eyes, its ears and how it holds its head
enum Feeling { CONTENT, HAPPY, EXCITED, LOVING, HUNGRY, BORED, SLEEPY, GRUMPY, SCARED, SAD, DISGUSTED, POORLY }
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
	{"tint": Color(0.74, 0.8, 0.68), "rows": ["", ".#.#..#.#", "..#....#", ".#.#..#.#", "", "..##..##", "....##", ""]},
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
	{"title": "poorly", "eye": 0.5, "droop": 0.9, "hang": 0.38, "shake": 0.015},
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
# How hard each nature is on a toy (the playful, the bold, the grumpy and the restless are rough
# with one, and pleased with themselves when it breaks; the rest are startled), and each kind:
# the heavy and the fierce wear one out fast, and the slight ones slowly
const NATURE_ROUGH: Array[float] = [1.0, 1.15, 0.8, 0.85, 0.8, 1.25, 1.3, 1.2]
const ROUGH: Array[float] = [1.0, 1.3, 1.0, 0.8, 1.4, 0.9, 1.1, 1.6, 1.4, 1.2, 0.9, 1.1, 0.8, 0.6, 0.7, 1.0, 0.8, 1.4, 1.6, 1.1]
# The two foods and two toys each kind leans towards (Snack.Kind, Ball.Kind); one of each is its favourite
const FOOD_LIKES: Array[Array] = [
	[Snack.Kind.CANDY, Snack.Kind.BONE], [Snack.Kind.BERRIES, Snack.Kind.TOADSTOOL], [Snack.Kind.BEETLE, Snack.Kind.BERRIES],
	[Snack.Kind.CANDY, Snack.Kind.BERRIES], [Snack.Kind.BONE, Snack.Kind.FISH], [Snack.Kind.BEETLE, Snack.Kind.FISH],
	[Snack.Kind.FISH, Snack.Kind.TOADSTOOL], [Snack.Kind.BONE, Snack.Kind.TOADSTOOL], [Snack.Kind.BONE, Snack.Kind.FISH],
	[Snack.Kind.FISH, Snack.Kind.BERRIES], [Snack.Kind.FISH, Snack.Kind.BEETLE], [Snack.Kind.FISH, Snack.Kind.BONE],
	[Snack.Kind.TOADSTOOL, Snack.Kind.BERRIES], [Snack.Kind.BERRIES, Snack.Kind.CANDY], [Snack.Kind.BONE, Snack.Kind.BEETLE],
	[Snack.Kind.BERRIES, Snack.Kind.TOADSTOOL], [Snack.Kind.CANDY, Snack.Kind.BEETLE], [Snack.Kind.BONE, Snack.Kind.BERRIES],
	[Snack.Kind.BONE, Snack.Kind.FISH], [Snack.Kind.BEETLE, Snack.Kind.TOADSTOOL],
]
const TOY_LIKES: Array[Array] = [
	[Ball.Kind.BALL, Ball.Kind.BELL], [Ball.Kind.STONE, Ball.Kind.BALL], [Ball.Kind.BELL, Ball.Kind.STONE],
	[Ball.Kind.GLOW, Ball.Kind.BELL], [Ball.Kind.BALL, Ball.Kind.GLOW], [Ball.Kind.BALL, Ball.Kind.GLOW],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.STONE, Ball.Kind.BELL], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.GLOW, Ball.Kind.BALL], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BELL, Ball.Kind.STONE], [Ball.Kind.BELL, Ball.Kind.GLOW], [Ball.Kind.GLOW, Ball.Kind.STONE],
	[Ball.Kind.BALL, Ball.Kind.BELL], [Ball.Kind.GLOW, Ball.Kind.BELL], [Ball.Kind.STONE, Ball.Kind.BALL],
	[Ball.Kind.BALL, Ball.Kind.STONE], [Ball.Kind.STONE, Ball.Kind.BELL],
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
	[Decor.Kind.SKULL, Decor.Kind.GRAVESTONE], [Decor.Kind.LOG, Decor.Kind.ROCK],
]
const GROUND_LIKES: Array[Array] = [
	[1, 3], [2, 4], [4, 5], [1, 3], [5, 4], [2, 4], [6, 5], [6, 0], [2, 0],
	[6, 2], [5, 6], [5, 0], [2, 4], [2, 3], [2, 4], [4, 5], [3, 6], [6, 0], [0, 6], [4, 4],
]
const LAMP_LIKES: Array[int] = [1, 1, 2, 0, 2, 2, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 2, 1]
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
# What losing a fight costs in health, and the health that fighting alone never takes it below
const FIGHT_HURT := 8.0
const FIGHT_FLOOR := 30.0
# Health goes in this many hours of an empty belly (four days: it takes real neglect), and all
# comes back in this many fed and rested. Below POORLY it shows.
const STARVE_HOURS := 96.0
const MEND_HOURS := 48.0
const POORLY := 40.0
# How much an hour asleep in the one nest raises what two of them think of each other
const SLEEP_WARMS := 0.6

const WALK := 1.0
const RUN := 2.6
const REST_ARM := Vector3(0.0, 0.0, 0.35)
const UP_ARM := Vector3(-0.3, 0.0, 2.5)
const BELLY_ARM := Vector3(-0.9, 0.0, -0.35)
# States that give way to food, a thrown ball, the moving light or tiredness
const INTERRUPTIBLE: Array[int] = [
	State.IDLE, State.WANDER, State.STARE, State.LURK, State.COME, State.BEG, State.ZOOMIES, State.DANCE,
	State.SCRATCH, State.DIG, State.SPIN, State.GAZE, State.SNIFF, State.FOLLOW,
]
# Fur and eye colours to draw from, by kind
const FURS: Array[Array] = [
	[Color(0.36, 0.5, 0.3), Color(0.44, 0.36, 0.56), Color(0.26, 0.47, 0.48), Color(0.46, 0.46, 0.5), Color(0.58, 0.36, 0.26), Color(0.52, 0.52, 0.3)],
	[Color(0.33, 0.27, 0.21), Color(0.26, 0.22, 0.18), Color(0.4, 0.34, 0.26), Color(0.29, 0.27, 0.25), Color(0.36, 0.26, 0.19)],
	[Color(0.5, 0.46, 0.38), Color(0.42, 0.26, 0.16), Color(0.3, 0.3, 0.34), Color(0.46, 0.38, 0.2)],
	[Color(0.24, 0.24, 0.29), Color(0.3, 0.26, 0.24), Color(0.34, 0.34, 0.37), Color(0.26, 0.21, 0.31)],
	[Color(0.34, 0.4, 0.48), Color(0.44, 0.47, 0.5), Color(0.27, 0.32, 0.4), Color(0.44, 0.46, 0.38)],
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
	[Color(0.2, 0.19, 0.23), Color(0.3, 0.26, 0.24), Color(0.36, 0.34, 0.37), Color(0.24, 0.22, 0.31), Color(0.4, 0.33, 0.27)],
]
const EYES: Array[Array] = [
	[Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.15), Color(0.6, 1.0, 0.3), Color(1.0, 0.45, 0.7), Color(0.4, 0.95, 1.0)],
	[Color(1.0, 0.8, 0.3), Color(0.7, 1.0, 0.5), Color(1.0, 0.45, 0.25), Color(0.6, 0.9, 1.0)],
	[Color(1.0, 0.3, 0.2), Color(1.0, 0.6, 0.15), Color(1.0, 0.9, 0.3), Color(0.6, 1.0, 0.4)],
	[Color(1.0, 0.15, 0.1), Color(1.0, 0.3, 0.1), Color(1.0, 0.1, 0.3)],
	[Color(1.0, 0.2, 0.15), Color(1.0, 0.5, 0.1), Color(1.0, 0.34, 0.05)],
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
	[Color(1.0, 0.95, 0.85), Color(0.85, 0.95, 1.0), Color(1.0, 0.85, 0.8)],
]
# A seed up to this is one from before there were more colours to draw from, and keeps to the
# lists above so that it stays the colour it has always been; a seed over it draws from these too
const OLD_SEEDS := 1000000
const FURS_MORE: Array[Array] = [
	[Color(0.3, 0.42, 0.56), Color(0.6, 0.5, 0.34)],
	[Color(0.44, 0.3, 0.2), Color(0.42, 0.4, 0.36)],
	[Color(0.56, 0.3, 0.2), Color(0.24, 0.3, 0.26)],
	[Color(0.36, 0.28, 0.22), Color(0.2, 0.26, 0.3)],
	[Color(0.4, 0.37, 0.44), Color(0.5, 0.5, 0.44)],
	[Color(0.3, 0.46, 0.4), Color(0.46, 0.4, 0.14)],
	[Color(0.18, 0.28, 0.3), Color(0.34, 0.4, 0.36)],
	[Color(0.44, 0.4, 0.42), Color(0.28, 0.3, 0.3)],
	[Color(0.22, 0.17, 0.15), Color(0.14, 0.16, 0.2)],
	[Color(0.3, 0.26, 0.24), Color(0.36, 0.42, 0.38)],
	[Color(0.5, 0.24, 0.3), Color(0.2, 0.3, 0.5)],
	[Color(0.3, 0.44, 0.4), Color(0.42, 0.36, 0.26)],
	[Color(0.5, 0.5, 0.2), Color(0.2, 0.4, 0.42)],
	[Color(0.9, 0.55, 0.4), Color(0.75, 0.85, 0.4)],
	[Color(0.8, 0.7, 0.5), Color(0.3, 0.5, 0.25)],
	[Color(0.56, 0.44, 0.36), Color(0.36, 0.34, 0.3)],
	[Color(0.6, 0.56, 0.44), Color(0.4, 0.5, 0.5)],
	[Color(0.88, 0.86, 0.8), Color(0.8, 0.86, 0.9)],
	[Color(0.22, 0.2, 0.24), Color(0.38, 0.2, 0.14)],
	[Color(0.5, 0.46, 0.43), Color(0.15, 0.14, 0.19)],
]
const EYES_MORE: Array[Array] = [
	[Color(0.8, 0.6, 1.0)], [Color(1.0, 0.95, 0.6)], [Color(1.0, 0.45, 0.6)], [Color(1.0, 0.4, 0.0)],
	[Color(1.0, 0.12, 0.22)], [Color(0.6, 1.0, 0.6)], [Color(0.8, 1.0, 0.6)], [Color(1.0, 0.7, 0.5)],
	[Color(0.9, 0.7, 1.0)], [Color(0.8, 1.0, 0.6)], [Color(1.0, 0.5, 0.7)], [Color(0.9, 0.6, 1.0)],
	[Color(1.0, 0.6, 0.4)], [Color(0.8, 1.0, 0.7)], [Color(1.0, 0.7, 0.5)], [Color(0.8, 1.0, 0.5)],
	[Color(1.0, 0.8, 0.4)], [Color(0.7, 1.0, 0.8)], [Color(1.0, 0.2, 0.3)], [Color(0.9, 1.0, 0.9)],
]
# How far one of a kind can be from the next in its proportions, each as the least and the most
# of what its body was drawn at: the size of its head, of its eyes and how far apart they sit,
# its build (slight to stout), the length of its limbs, of its ears, of whatever its kind wears
# on its head or back (horns, antlers, a comb, a crest, a hat, a long neck), and of its tail.
const SHAPE := {
	"head": [0.82, 1.3], "eye": [0.72, 1.42], "gap": [0.86, 1.18], "build": [0.84, 1.22],
	"limb": [0.78, 1.36], "ear": [0.6, 1.55], "crest": [0.55, 1.55], "tail": [0.55, 1.75],
}
# Where a kind's body will not take as much as that; "marks" is for a kind whose coat takes
# only some of the markings
const SHAPES: Array[Dictionary] = [
	{}, {"head": [0.88, 1.2], "limb": [0.8, 1.2], "marks": [Mark.SPOTS, Mark.PATCHES, Mark.STRIPES, Mark.SOCKS, Mark.FRECKLES, Mark.POINTS]}, {}, {}, {"limb": [0.85, 1.25], "crest": [0.7, 1.5]}, {"limb": [0.85, 1.3]},
	{"limb": [0.9, 1.15], "crest": [0.66, 1.4]}, {"head": [0.88, 1.16], "limb": [0.8, 1.6]},
	{"head": [0.85, 1.22], "limb": [0.84, 1.2]}, {"limb": [0.8, 1.22]}, {}, {"head": [0.85, 1.2]},
	{"crest": [0.6, 1.4]}, {"head": [0.85, 1.25]}, {"crest": [0.75, 1.3]}, {}, {"head": [0.86, 1.2], "crest": [0.85, 1.25]},
	{}, {"limb": [0.8, 1.25], "eye": [0.75, 1.2]},
	{"head": [0.88, 1.22], "eye": [0.75, 1.15], "limb": [0.85, 1.2], "crest": [0.75, 1.35], "tail": [0.6, 1.5]},
]
# What can be painted on a coat, and how likely each is for most kinds
enum Mark { PLAIN, SPOTS, PATCHES, STRIPES, BELLY, SOCKS, BLAZE, FRECKLES, POINTS }
const MARKS: Array[float] = [3.0, 2.0, 2.0, 2.0, 2.0, 1.5, 1.2, 1.5, 1.5]
# The coat is painted this many dots round and down, and drawn this much brighter than painted
const COAT := 32
const COAT_GAIN := 4.0
# The odd thing one may have that the next has not, with the chance of each: a tuft, whiskers, a
# snaggle tooth, a torn ear, one eye bigger than the other, eyes of two colours, and a horn or
# antler broken short. EXTRAS is which of them each kind can have.
const CHANCES := {"tuft": 0.3, "whiskers": 0.3, "tooth": 0.3, "torn": 0.22, "odd": 0.3, "split": 0.14, "broken": 0.22}
const EXTRAS: Array[Array] = [
	["tuft", "whiskers", "tooth", "torn", "split", "broken"], ["tuft", "tooth", "odd", "split"], ["odd", "split"],
	["tuft", "torn", "odd", "split"], ["tooth", "torn", "odd", "split"], ["tooth", "odd", "split"],
	["tooth", "odd", "split"], ["odd", "split"], ["torn", "split", "broken"], ["torn", "odd", "split"],
	["whiskers", "tooth", "torn", "odd", "split"], ["odd", "split"], ["whiskers", "tooth", "odd", "split"],
	["tuft", "torn", "odd", "split"], ["tooth", "odd", "split"],
	["whiskers", "tooth", "torn", "odd", "split", "broken"], ["odd", "split"],
	["whiskers", "tooth", "odd", "split", "broken"], ["tooth", "torn", "odd", "split"],
	["tuft", "whiskers", "tooth", "odd", "split"],
]

var world: Den
# What the room keeps of it: its name, and what has been found out about it
var me: Resident
var kind: int = Kind.GREMLIN
var look_seed := 1
# The colour of its coat (see colours(); one bred here has a parent's)
var fur_colour := Color.WHITE

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
# A dummy it wears in front of it (the cockatrice's stuffed rooster): the dummy, its two wings
# and its head, how far it is leaning and its wings trailing just now (see _flop); and of the
# snake that comes out of the back of it, each joint from the dummy to the head, and where each
# is when it is up and then when it is asleep
var decoy: Node3D
var decoy_parts: Array[Node3D] = []
var flop := Vector3.ZERO
var trail := 0.0
var serpent: Array[Node3D] = []
var serpent_at: Array[Vector3] = []
# How big its insides are next to the usual (a slight body has less room), and how high its
# backbone runs when its head is not straight above it (0 for up to the neck)
var gut := 1.0
var back_y := 0.0
# Where its insides are, if not on its middle line, and how they are drawn out along it
var gut_at := Vector3.ZERO
var gut_stretch := Vector3.ONE
# How far its head turns on its neck to look at something (and tips, in proportion), and how much
# one that drags itself along on its belly bunches up and stretches out as it goes
var head_turn := 1.25
var heave := 0.0
# One that hops where the rest walk, and in what manner ("rabbit"; nothing for one that walks:
# see _hop): how far through the hop it is on (0 between hops), how long that hop takes, how
# high it goes and how much of a run it is, which way a clumsy one tips over in it, how far off
# the floor it is just now, and how far what trails after it is lagging
var hops := ""
var hop_t := 0.0
var hop_len := 0.4
var hop_high := 0.0
var hop_run := 0.0
var hop_tip := 0.0
var hop_y := 0.0
var hop_lag := 0.0
# A body that is rounder on a baby (the yeti's, a ball of fluff that grows into its shape): the
# body and its size grown and newly hatched, what carries its arms and head, how far that is
# lower on a baby, and how long its arms are grown
var podge: MeshInstance3D
var podge_sizes: Array[Vector3] = []
var shoulders: Node3D
var baby_sink := 0.0
var reach := 1.0
# What is its own about its shape (see looks()): the size of its head, of each eye, and of what
# its kind wears on its head or back; how far longer legs raise its body, and whether it goes on
# four of them; where a tuft would grow on its head; what is painted on its coat (the marking,
# the seed it is drawn from, and a second marking over it), and the odd things it has (EXTRAS)
var shape := {}
var head_size := 1.0
var eye_sizes: Array[float] = []
var crest := 1.0
var stand := 0.0
var fours := false
var crown := Vector3.ZERO
var marks: Array[int] = [Mark.PLAIN, 0, Mark.PLAIN]
var extras: Array[String] = []
var fur: ShaderMaterial
var pale: ShaderMaterial
var dark: ShaderMaterial
var bone: ShaderMaterial
var black: ShaderMaterial
var maw: ShaderMaterial
var eye_mat: ShaderMaterial
# The one for each eye, left and right: the same, unless its eyes are of two colours
var eye_mats: Array[ShaderMaterial] = []

# Needs, 0 (bad) to 100 (good)
var belly := 70.0
var fun := 60.0
var energy := 80.0
var love := 20.0
# How well it is in itself, 0 to 100: a lost fight takes a little of it
var health := 100.0
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
# What it wears under the scanner: the scanner tells it how high its sweep has got
var scan_skin: ShaderMaterial
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
# How far under the floor (or the water) it has gone, for those whose knack takes them there
var dive := 0.0
# The one thing its kind does that no other does (see Knack)
var knack: Knack

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
# The other cryptlin it is busy with (sniffing at, following, chasing, running from, fighting),
# and how long before it can come to blows again
var partner: Cryptlin
var fight_cooldown := 20.0
# In a pairing, the one that was gone over to (it stands and waits for the other)
var waiting := false
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
# Which footfall it is on, counted from the swing of its legs
var footfall := 0
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
	# One from underground never wants more light than its kind does, whatever was drawn
	if KINDS[k].get("dim", false):
		me["lamp"] = LAMP_LIKES[k]
	# The shelters that came after the first things get their chance last of all, so that nothing
	# drawn above changes: now and then, one of them to like as well
	if rng.randf() < 0.45:
		liked.append(rng.randi_range(Decor.Kind.POOL + 1, Decor.IDS.size() - 1))
	return me


# The two natures of one of this kind and seed. One bred in the room has the first of them from
# a parent (`given`), and keeps the second it would have had unless the two will not go together.
static func natures(k: int, s: int, given := -1) -> Array[int]:
	var drawn := profile(k, s)
	var first: int = drawn["nature"] if given < 0 else given
	var second: int = drawn["nature2"]
	while second == first or [mini(second, first), maxi(second, first)] in OPPOSED:
		second = (second + 1) % NATURES.size()
	return [first, second]


# The fur and eye colour a kind and seed give (the egg shows the eye before it hatches)
static func colours(k: int, s: int) -> Array[Color]:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var furs: Array = FURS[k]
	var eye_set: Array = EYES[k]
	if s > OLD_SEEDS:
		furs = furs + FURS_MORE[k]
		eye_set = eye_set + EYES_MORE[k]
	var fur_colour: Color = furs[rng.randi() % furs.size()]
	var eye_colour: Color = eye_set[rng.randi() % eye_set.size()]
	# No two are quite the one colour: each drifts a little from what was picked, by a generator
	# of its own so that what is picked stays as it always was
	var drift := RandomNumberGenerator.new()
	drift.seed = s * 2749 + k * 31 + 5
	fur_colour = Color.from_hsv(
		fposmod(fur_colour.h + drift.randf_range(-0.035, 0.035), 1.0),
		clampf(fur_colour.s * drift.randf_range(0.78, 1.28), 0.0, 1.0),
		clampf(fur_colour.v * drift.randf_range(0.88, 1.14), 0.0, 1.0))
	eye_colour = Color.from_hsv(fposmod(eye_colour.h + drift.randf_range(-0.03, 0.03), 1.0), eye_colour.s, eye_colour.v)
	return [fur_colour, eye_colour]


# A seed for a new one: over OLD_SEEDS, so that it has the wider choice of colours
static func new_seed() -> int:
	return OLD_SEEDS + 1 + randi() % 1000000


# What a kind and seed make of its shape and markings, besides what colours() and _build() have
# always drawn: how far along each span of SHAPE it comes (0 to 1), what is painted on its coat,
# and which of the odd things in EXTRAS it has. Always drawn in the same order from a generator
# of its own, so that a saved cryptlin stays who it was; anything new is drawn last.
static func looks(k: int, s: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = s * 6151 + k * 389 + 71
	var me := {}
	for what: String in SHAPE:
		me[what] = rng.randf()
	var weight := 0.0
	for share in MARKS:
		weight += share
	var first := int(Mark.PLAIN)
	var pick := rng.randf() * weight
	for i in MARKS.size():
		pick -= MARKS[i]
		if pick < 0.0:
			first = i
			break
	var over := rng.randi_range(Mark.BELLY, Mark.POINTS) if rng.randf() < 0.35 else int(Mark.PLAIN)
	var takes: Array = SHAPES[k].get("marks", [])
	if not takes.is_empty():
		first = first if first in takes else int(Mark.PLAIN)
		over = over if over in takes else int(Mark.PLAIN)
	me["marks"] = [first, rng.randi() % 100000, over if over != first else int(Mark.PLAIN)]
	var odd: Array[String] = []
	for extra: String in CHANCES:
		if rng.randf() < float(CHANCES[extra]) and extra in EXTRAS[k]:
			odd.append(extra)
	me["extras"] = odd
	# Which side the odd thing is on, and how much smaller the smaller eye is
	me["side"] = rng.randi() % 2
	me["wink"] = rng.randf_range(0.66, 0.86)
	return me


# How far along a span of SHAPE one of this kind comes, as what its body is multiplied by
static func span(k: int, what: String, along: float) -> float:
	var limits: Array = SHAPES[k].get(what, SHAPE[what])
	return lerpf(limits[0], limits[1], along)


# The picture painted on a coat of colour `base`: `painted` is the marking, the seed it is drawn
# from and a second marking over it. It goes round a body from the front (both edges) by way of
# the back (the middle) and is the same on both sides, and from the top down; cones have only
# its top half, so the top is also the tips of ears. Kept at 1/COAT_GAIN of its strength so that
# a marking can be paler than the coat.
static func coat(painted: Array, base: Color) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(painted[1]) * 31 + 7
	var layers: Array[Dictionary] = []
	for type: int in [int(painted[0]), int(painted[2])]:
		if type != Mark.PLAIN:
			layers.append(_layer(type, base, rng))
	var img := Image.create(COAT, COAT, false, Image.FORMAT_RGB8)
	var under := base.srgb_to_linear()
	for y in COAT:
		for x in COAT:
			var c := base
			for layer in layers:
				if _marked(layer, x, y):
					c = layer["ink"]
			var lit := c.srgb_to_linear()
			var part := Color(lit.r / maxf(under.r, 0.004), lit.g / maxf(under.g, 0.004), lit.b / maxf(under.b, 0.004)) / COAT_GAIN
			img.set_pixel(x, y, Color(minf(part.r, 1.0), minf(part.g, 1.0), minf(part.b, 1.0)))
	return ImageTexture.create_from_image(img)


# One marking, ready to paint: its kind, its colour, and where its blots or bands fall
static func _layer(type: int, base: Color, rng: RandomNumberGenerator) -> Dictionary:
	var darker := base.darkened(rng.randf_range(0.32, 0.52))
	var paler := base.lerp(Color(0.96, 0.93, 0.84), rng.randf_range(0.26, 0.5))
	# Another colour near its own, for a coat that has any colour to it
	var other := Color.from_hsv(fposmod(base.h + rng.randf_range(0.07, 0.13) * (1.0 if rng.randf() < 0.5 else -1.0), 1.0), minf(base.s * 1.3 + 0.12, 1.0), base.v * 0.72)
	if base.s < 0.2:
		other = darker
	var roll := rng.randf()
	var layer := {"type": type, "ink": darker if roll < 0.5 else (paler if roll < 0.8 else other), "blots": [], "dots": {}}
	var blots: Array = layer["blots"]
	match type:
		Mark.SPOTS:
			# Round spots, few and big or many and small; each is how far round from the front,
			# how far down, and how big
			var big := rng.randf_range(0.07, 0.15)
			for i in int(lerpf(16.0, 6.0, (big - 0.07) / 0.08)):
				blots.append(Vector3(rng.randf(), rng.randf_range(0.08, 0.9), big * rng.randf_range(0.75, 1.2)))
		Mark.PATCHES:
			# A few big ragged patches, not the same on both sides
			for i in rng.randi_range(2, 4):
				blots.append(Vector3(rng.randf(), rng.randf_range(0.15, 0.8), rng.randf_range(0.2, 0.34)))
			layer["rag"] = rng.randi() % 1000
		Mark.STRIPES:
			# Bands round it or stripes down it, so many of them, with a kink
			layer["down"] = rng.randf() < 0.4
			layer["bands"] = rng.randi_range(3, 6)
			layer["kink"] = rng.randf_range(0.0, 0.12)
			layer["wide"] = rng.randf_range(0.0, 0.5)
		Mark.BELLY:
			layer["ink"] = paler if roll < 0.85 else darker
			layer["wide"] = rng.randf_range(0.18, 0.32)
		Mark.SOCKS:
			layer["ink"] = paler if roll < 0.7 else darker
			layer["wide"] = rng.randf_range(0.66, 0.8)
		Mark.BLAZE:
			layer["ink"] = paler
			layer["wide"] = rng.randf_range(0.07, 0.14)
		Mark.FRECKLES:
			layer["ink"] = darker if roll < 0.7 else other
			var dots: Dictionary = layer["dots"]
			for i in rng.randi_range(40, 90):
				dots[Vector2i(rng.randi() % (COAT / 2), rng.randi_range(3, COAT - 6))] = true
		Mark.POINTS:
			layer["ink"] = darker if roll < 0.75 else paler
			layer["wide"] = rng.randf_range(0.1, 0.17)
	return layer


# Whether a marking covers one dot of the coat
static func _marked(layer: Dictionary, x: int, y: int) -> bool:
	var u := (x + 0.5) / COAT
	var down := (y + 0.5) / COAT
	# How far round from the front, 0 to 1 at the middle of the back, either side alike
	var about := minf(u, 1.0 - u) * 2.0
	match int(layer["type"]):
		Mark.SPOTS:
			for blot: Vector3 in layer["blots"]:
				if Vector2(about - blot.x, down - blot.y).length() < blot.z:
					return true
		Mark.PATCHES:
			var rag := sin(x * 1.9 + int(layer["rag"])) * sin(y * 2.3 + int(layer["rag"]) * 0.7) * 0.05
			for blot: Vector3 in layer["blots"]:
				var across := absf(u - blot.x)
				if Vector2(minf(across, 1.0 - across) * 2.0, down - blot.y).length() < blot.z + rag:
					return true
		Mark.STRIPES:
			var along := about if layer["down"] else down
			var off := down if layer["down"] else about
			return sin((along + sin(off * 9.0) * float(layer["kink"])) * PI * 2.0 * int(layer["bands"])) > float(layer["wide"])
		Mark.BELLY:
			return (about < float(layer["wide"]) and down > 0.4) or down > 0.9
		Mark.SOCKS:
			return down > float(layer["wide"])
		Mark.BLAZE:
			return about < float(layer["wide"]) and down < 0.6
		Mark.FRECKLES:
			var dots: Dictionary = layer["dots"]
			return dots.has(Vector2i(mini(x, COAT - 1 - x), y))
		Mark.POINTS:
			return down < float(layer["wide"])
	return false


func _build() -> void:
	var traits: Dictionary = KINDS[kind]
	pace = traits["pace"]
	hunger = traits["hunger"]
	tire = traits["tire"]
	spring = traits["spring"]
	voice = traits["voice"]
	likes = traits.duplicate()
	var drawn := profile(kind, look_seed)
	nature = drawn["nature"]
	fav_food = drawn["food"]
	yuck_food = drawn["yuck"]
	fav_toy = drawn["toy"]
	adult_size = drawn["size"]
	var both := natures(kind, look_seed, me.nature if me != null else -1)
	nature = both[0]
	nature2 = both[1]
	like_decor.assign(drawn["decor"])
	hate_decor = drawn["hates"]
	fav_ground = drawn["ground"]
	fav_lamp = drawn["lamp"]
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
	fur_colour = picked[0]
	# One bred here wears the colour of one of its parents, and has a nature of one of them
	if me != null and me.fur != "":
		fur_colour = Color.html(me.fur)
	var eye_colour := picked[1]
	var ear_len := rng.randf_range(0.34, 0.52)
	var chub := rng.randf_range(0.94, 1.14)
	var horns := rng.randf() < 0.45
	var odd_eyes := rng.randf() < 0.35
	# The rest of its looks are its own too. One bred here has its markings from the parent whose
	# coat it wears, and its head from the other.
	shape = looks(kind, look_seed)
	if me != null and me.looks.get("marks") is Array and me.looks["marks"].size() == 3:
		shape["marks"] = me.looks["marks"]
	if me != null and me.looks.has("head"):
		shape["head"] = clampf(float(me.looks["head"]), 0.0, 1.0)
	for i in 3:
		marks[i] = int(shape["marks"][i])
	extras.assign(shape["extras"])
	if odd_eyes and kind == Kind.GREMLIN and not "odd" in extras:
		extras.append("odd")
	head_size = span(kind, "head", shape["head"])
	crest = span(kind, "crest", shape["crest"])
	chub *= span(kind, "build", shape["build"])
	fur = Ps1.mat(fur_colour * 0.76, 0.0, 0.35)
	if marks[0] != Mark.PLAIN or marks[2] != Mark.PLAIN:
		fur.set_shader_parameter("tex", coat(marks, fur_colour))
		fur.set_shader_parameter("gain", COAT_GAIN)
	pale = Ps1.mat(fur_colour.lightened(0.2) * 0.9, 0.0, 0.35)
	dark = Ps1.mat(fur_colour.darkened(0.5), 0.0, 0.35)
	bone = Ps1.mat(Color(0.92, 0.89, 0.78), 0.0, 0.35)
	black = Ps1.flat(Color(0.02, 0.01, 0.02))
	maw = Ps1.mat(Color(0.16, 0.03, 0.06))
	# The eyes give off their own light, so they are all you see of it in the dark
	eye_mat = Ps1.mat(eye_colour, 0.85)
	eye_mats = [eye_mat, eye_mat]
	if "split" in extras:
		eye_mats[int(shape["side"])] = Ps1.mat(Color.from_hsv(fposmod(eye_colour.h + 0.38, 1.0), eye_colour.s, eye_colour.v), 0.85)
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
		Kind.MOLE:
			_build_mole(chub)
		_:
			_build_gremlin(chub, ear_len, horns)

	if brain_at == Vector3.ZERO:
		brain_at = Vector3(0, head_y + 0.02, 0)
	_shape_up()
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
	knack = Knack.new(self)


func _build_gremlin(chub: float, ear_len: float, horns: bool) -> void:
	crown = Vector3(0, 0.47, 0.02)
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
		_eye(Vector3(0.135 * side, 0.25, 0.215), 0.1)
		_part(neck, _cone(), bone, Vector3(0.055 * side, 0.112, 0.283), Vector3(0.022, 0.05, 0.022))
		if horns:
			var long := 0.14 * crest * _snapped(side)
			_part(neck, _cone(), bone, Vector3((0.1 + long * 0.16) * side, 0.43 + long * 0.5, 0.03), Vector3(0.045, long, 0.045), Vector3(0, 0, -0.35 * side))
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
	crown = Vector3(0, 0.52, 0)
	fur = _shaggy(fur_colour * 0.76, 3, 0.15, {"hang": 0.9, "face": 0.2, "face_from": 0.42})
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.18 * side, 0.24, 0.02))
		_part(leg, _capsule(0.07, 0.24), dark, Vector3(0, -0.1, 0))
		# Big flat feet, toes out, and five fat toes on each, the big one on the inside
		var foot := _pivot(leg, Vector3(0, -0.185, 0))
		foot.rotation.y = 1.0 * side
		_part(foot, _sphere(), dark, Vector3(0, 0, 0.17), Vector3(0.19, 0.065, 0.3))
		for toe in 5:
			var across := (toe - 2.0) * 0.088 * side
			var size := 0.085 - toe * 0.009
			_part(foot, _sphere(), pale, Vector3(across, 0.01, 0.49 - toe * 0.03), Vector3(size * 0.8, size * 0.8, size * 1.3))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	tail = _pivot(torso, Vector3(0, 0.3, -0.2))
	for side: float in [-1.0, 1.0]:
		arms.append(_pivot(torso, Vector3(0.3 * side, 0.4, 0)))

	# The whole body turns to look, so it hangs from the neck
	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	var body := _pivot(neck, Vector3.ZERO)
	body.scale = Vector3(chub, 1.0, 0.8 * chub)
	# One smooth mound, wider than it is tall, flaring out to the hem, under its hair
	var shape: Array[Vector2] = [
		Vector2(0.48, 0.0), Vector2(0.55, 0.04), Vector2(0.54, 0.11), Vector2(0.47, 0.19), Vector2(0.4, 0.28),
		Vector2(0.35, 0.37), Vector2(0.28, 0.45), Vector2(0.17, 0.51), Vector2(0.0, 0.53),
	]
	_part(body, _lathe(shape, 14), fur, Vector3.ZERO)
	var shag := Ps1.mat(fur_colour * 0.76 * 0.62, 0.0, 0.35)
	# The hem is ragged: pointed tufts of every length hang off it and splay, light and dark,
	# and the odd one sticks straight out
	for i in 17:
		var around := TAU * (i + rng.randf_range(0.2, 0.8)) / 17.0
		var out := Vector3(sin(around), 0, cos(around))
		var long := rng.randf_range(0.13, 0.3)
		var splay := rng.randf_range(0.25, 0.75) if i % 6 != 3 else 1.25
		_spike(body, [pale, shag, fur][i % 3], out * 0.5 + Vector3(0, 0.1, 0), out * splay + Vector3.DOWN, long, 0.06)

	# Two tall dark eyes, wide at the bottom and drawn up to a point, with a light in each
	for side: float in [-1.0, 1.0]:
		var eye := _pivot(neck, Vector3(0.12 * chub * side, 0.2, 0.4 * chub))
		eye.rotation.x = -0.62
		_part(eye, _sphere(), black, Vector3.ZERO, Vector3(0.068, 0.078, 0.03))
		_part(eye, _cone(), black, Vector3(0, 0.16, 0), Vector3(0.06, 0.28, 0.026))
		var pupil := _part(eye, _sphere(), _eye_mat(), Vector3(0, 0, 0.03), Vector3(0.036, 0.046, 0.03))
		eyes.append(eye)
		pupils.append(pupil)
	# Its mouth is somewhere under the hair, and only shows when it opens
	mouth_node = _pivot(neck, Vector3(0, 0.07, 0.47 * chub))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.11, 0.06, 0.04))


# Its coat as long hair of this colour that hangs off it in locks (see Ps1.fur), with whatever is
# painted on it: `shells` layers of it, the longest `hair` off the skin in the measure of the
# mesh that wears it
func _shaggy(colour: Color, shells: int, hair: float, values := {}) -> ShaderMaterial:
	var coat := Ps1.fur(colour, shells, hair, values)
	Ps1.comb(coat, {"tex": fur.get_shader_parameter("tex"), "gain": fur.get_shader_parameter("gain")})
	return coat


# The cockatrice is the serpent, and the serpent is what its rooster has for a tail: it comes up
# out of the back end of a stuffed rooster, curving up and over with its head held high, and
# wears the rooster in front of it like a costume. The rig's neck, eyes and mouth are the snake's,
# and the rooster is a dummy (see `decoy`) with buttons for eyes, a beak that is sewn shut and limp
# wings, hung from the snake at the place where the two join, which flops along a beat behind
# whatever the snake does.
func _build_cockatrice(chub: float) -> void:
	neck_y = 0.85
	head_y = 0.13
	centre_y = 0.3
	top_y = 1.15
	gravity = 9.0
	# Its insides are up in the snake, behind the dummy, which it leans to one side of or the other
	var bend := 1.0 if int(shape["side"]) == 1 else -1.0
	gut = 0.56
	back_y = 0.5
	gut_at = Vector3(0.06 * bend, 0.31, -0.33)
	brain_at = Vector3(0, 0.14, 0.05)
	var yellow := Ps1.mat(Color(0.62, 0.46, 0.12), 0.0, 0.35)
	var red := Ps1.mat(Color(0.6, 0.1, 0.08), 0.0, 0.35)
	# The dummy is the colour its feathers were, gone dull, with a sacking breast
	var stuffed := Ps1.mat(fur_colour.lerp(Color(0.5, 0.44, 0.34), 0.5) * 0.7, 0.0, 0.2)
	var sacking := Ps1.mat(Color(0.52, 0.46, 0.34), 0.0, 0.2)
	var thread := Ps1.mat(Color(0.1, 0.08, 0.07))
	# Its legs are the dummy's: they dangle, and swing as it is walked along (see _flop, which
	# keeps them on the dummy)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.09 * side, 0.2, 0.14))
		_part(leg, _capsule(0.022, 0.2), yellow, Vector3(0, -0.08, 0))
		_part(leg, _sphere(), yellow, Vector3(0, -0.175, 0.04), Vector3(0.07, 0.02, 0.1))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	# The serpent, joint by joint from where it comes out of the dummy to its head: where each is
	# when it is up and about, and then where each is when it has laid itself round the dummy to
	# sleep. Paler down its front, with dark saddles down its back.
	serpent_at = [
		Vector3(0, 0.42, -0.04), Vector3(0.02 * bend, 0.46, -0.24), Vector3(0.06 * bend, 0.58, -0.37), Vector3(0.06 * bend, 0.71, -0.35), Vector3(0.02 * bend, 0.81, -0.25), Vector3(-0.02 * bend, 0.85, -0.12),
		Vector3(0, 0.42, -0.04), Vector3(-0.17, 0.5, -0.15), Vector3(-0.32, 0.46, 0.0), Vector3(-0.34, 0.42, 0.17), Vector3(-0.25, 0.4, 0.32), Vector3(-0.1, 0.34, 0.38),
	]
	var joints := serpent_at.size() / 2
	for i in joints:
		var thick := lerpf(0.085, 0.06, float(i) / (joints - 1)) * chub
		var link := _pivot(torso, serpent_at[i])
		if i < joints - 1:
			var taper := lerpf(0.085, 0.06, float(i + 1) / (joints - 1)) * chub / thick
			var length := _pivot(link, Vector3.ZERO)
			_part(length, _drum(taper, 1.0, 1.0), fur, Vector3(0, 0.5, 0), Vector3(thick, 1.0, thick))
			_part(length, _drum(taper, 1.0, 1.0), pale, Vector3(0, 0.5, thick * 0.4), Vector3(thick * 0.72, 1.0, thick * 0.72))
			if i > 0:
				_part(length, _sphere(), dark, Vector3(0, 0.5, -thick * 0.5), Vector3(thick * 0.8, 0.36, thick * 0.7))
		_part(link, _sphere(), fur, Vector3.ZERO, Vector3.ONE * thick)
		serpent.append(link)
	for side: float in [-1.0, 1.0]:
		arms.append(_pivot(serpent[2], Vector3(0.02 * side, 0.12, 0)))

	# Its head: flat and blunt, with a low red crest down the middle of it, fangs and a forked tongue
	neck = _pivot(torso, serpent_at[joints - 1])
	_part(neck, _sphere(), fur, Vector3(0, 0.12, 0.04), Vector3(0.12, 0.08, 0.15))
	_part(neck, _sphere(), fur, Vector3(0, 0.105, 0.16), Vector3(0.085, 0.055, 0.1))
	_part(neck, _sphere(), pale, Vector3(0, 0.075, 0.08), Vector3(0.095, 0.045, 0.13))
	var comb := neck.get_child_count()
	for i in 3:
		_part(neck, _cone(), red, Vector3(0, 0.215 - i * 0.012, 0.09 - i * 0.07), Vector3(0.022, 0.08 - i * 0.012, 0.045), Vector3(-0.3 - i * 0.2, 0, 0))
	_swell(neck, comb, Vector3(0, 0.19, 0.02), Vector3.ONE * crest)
	top_y += 0.06 * (crest - 1.0)
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.085 * side, 0.155, 0.1), 0.066)
		_part(neck, _sphere(), dark, Vector3(0.08 * side, 0.2, 0.09), Vector3(0.06, 0.018, 0.07), Vector3(0.2, 0, -0.5 * side))
		_part(neck, _cone(), bone, Vector3(0.04 * side, 0.058, 0.215), Vector3(0.014, 0.05, 0.014), Vector3(PI, 0, 0))
	_swell(neck, 0, Vector3.ZERO, Vector3.ONE * 1.22)
	mouth_node = _pivot(neck, Vector3(0, 0.09, 0.245))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.09, 0.06, 0.07))
	_part(mouth_node, Ps1.box(), red, Vector3(0, -0.02, 0.07), Vector3(0.016, 0.012, 0.1))
	for side: float in [-1.0, 1.0]:
		_part(mouth_node, Ps1.box(), red, Vector3(0.014 * side, -0.02, 0.135), Vector3(0.01, 0.01, 0.045), Vector3(0, 0.5 * side, 0))

	# The dummy, hung from the snake at the first joint of it, inside its own back end, so that
	# however it flops the two stay joined there
	decoy = _pivot(torso, serpent_at[0])
	_part(decoy, _sphere(), stuffed, Vector3(0, -0.08, 0.16), Vector3(0.2 * chub, 0.19, 0.23 * chub))
	_part(decoy, _sphere(), sacking, Vector3(0, -0.1, 0.18 + 0.1 * chub), Vector3(0.15 * chub, 0.15, 0.12))
	# (a seam down its front, and a patch)
	for i in 4:
		_part(decoy, Ps1.box(), thread, Vector3(0, -0.19 + i * 0.055, 0.18 + 0.2 * chub - absf(i - 1.5) * 0.012), Vector3(0.05, 0.01, 0.012))
	_part(decoy, Ps1.box(), red, Vector3(0.13 * chub, -0.06, 0.28), Vector3(0.01, 0.07, 0.07), Vector3(0, 0.5, 0.2))
	for side: float in [-1.0, 1.0]:
		var wing := _pivot(decoy, Vector3(0.18 * chub * side, 0.04, 0.16))
		_part(wing, _sphere(), stuffed, Vector3(0, -0.12, -0.02), Vector3(0.035, 0.15, 0.12))
		_part(wing, _cone(), sacking, Vector3(0, -0.27, -0.05), Vector3(0.028, 0.13, 0.08), Vector3(PI, 0, 0))
		decoy_parts.append(wing)
	var lolling := _pivot(decoy, Vector3(0, 0.08, 0.25))
	_part(lolling, _sphere(), stuffed, Vector3(0, 0.1, 0), Vector3(0.14, 0.14, 0.14))
	_part(lolling, _cone(), yellow, Vector3(0, 0.08, 0.17), Vector3(0.05, 0.13, 0.04), Vector3(PI * 0.5 + 0.25, 0, 0))
	for i in 3:
		_part(lolling, _cone(), red, Vector3(0, 0.26 - i * 0.02, 0.05 - i * 0.07), Vector3(0.03, 0.11 - i * 0.02, 0.05), Vector3(-0.2 - i * 0.25, 0, 0.25))
	_part(lolling, _sphere(), red, Vector3(0, -0.01, 0.12), Vector3(0.025, 0.055, 0.025))
	# Two buttons for eyes: flat, black, each in a ring of pale thread, and with nothing behind them
	for side: float in [-1.0, 1.0]:
		var button := _pivot(lolling, Vector3(0.1 * side, 0.13, 0.085))
		button.rotation = Vector3(0, 0.75 * side, 0)
		_part(button, _drum(1.0, 1.0, 1.0), bone, Vector3.ZERO, Vector3(0.042, 0.012, 0.042), Vector3(PI * 0.5, 0, 0))
		_part(button, _drum(1.0, 1.0, 1.0), thread, Vector3(0, 0, 0.006), Vector3(0.03, 0.012, 0.03), Vector3(PI * 0.5, 0, 0))
	decoy_parts.append(lolling)
	# What is left of the rooster's own tail: a few limp feathers round the place the snake comes
	# out of
	tail = _pivot(decoy, Vector3(0, 0.02, -0.03))
	for i in 3:
		_part(tail, _cone(), sacking if i == 1 else stuffed, Vector3((i - 1) * 0.07, -0.05 - absf(i - 1.0) * 0.03, -0.1), Vector3(0.04, 0.2, 0.014), Vector3(-PI * 0.5 - 0.5 - absf(i - 1.0) * 0.3, (1 - i) * 0.5, 0))


# What the cockatrice's dummy does, which is whatever the snake has just done, a beat late and
# with nothing holding it up: it leans and swings from where the snake comes out of it, its head
# lolls, its wings hang and trail, its legs dangle under it, and when the snake goes to sleep it
# tips over and the snake lays its length round it
func _flop(delta: float) -> void:
	var late := 1.0 - exp(-delta * 3.5)
	var speed := Vector2(velocity.x, velocity.z).length()
	var hung := airborne or lift > 0.05
	flop = flop.lerp(Vector3((0.5 if hung else 0.0) - minf(speed, 3.0) * 0.07 - squash * 1.6 + sit * 0.2, head_yaw * 0.25, sin(phase - 1.3) * 0.3 * gait - wiggle * 2.5 - head_roll * 0.6 + curl * 1.35), late)
	# The snake: each joint of it eases between where it is held up and where it lies asleep, it
	# sways as it goes, most at the head, and when it puts its head down to something it reaches
	# out round the side of the dummy to do it
	var joints := serpent.size()
	var at: Array[Vector3] = []
	var lean := Vector3(0.5 * signf(serpent_at[2].x), -0.6, 0.8) * nod
	for i in joints:
		var up := float(i) / (joints - 1)
		var sway := sin(anim_t * 1.7 - i * 0.9) * 0.012 + sin(phase - i * 0.8) * 0.03 * gait
		at.append(serpent_at[i].lerp(serpent_at[joints + i], curl) + Vector3(sway * up, 0, -minf(speed, 3.0) * 0.03 * up * up) * (1.0 - curl) + lean * up * up * (1.0 - curl))
	var belly := Vector3(0, -1.0, 0.6).lerp(Vector3(0.3, -1.0, 0.0), curl).normalized()
	for i in joints:
		serpent[i].position = at[i]
		if i < joints - 1:
			var along := at[i + 1] - at[i]
			var up := along.normalized()
			var across := up.cross(belly)
			if across.length() < 0.05:
				across = up.cross(Vector3.RIGHT)
			across = across.normalized()
			serpent[i].basis = Basis(across, up, across.cross(up))
			(serpent[i].get_child(0) as Node3D).scale.y = along.length()
	neck.position = at[joints - 1]
	# (and under the scanner its insides go with the part of it they are in)
	if not insides.is_empty():
		insides[0].position = (at[2] + at[3] - serpent_at[2] - serpent_at[3]) * 0.5
	decoy.position = at[0]
	decoy.rotation = flop
	var lolling := decoy_parts[2]
	lolling.rotation = Vector3(0.35 + flop.x * 1.6 + absf(sin(phase - 2.0)) * 0.25 * gait, flop.y, 0.3 + flop.z * 0.8)
	trail = lerpf(trail, 2.2 if hung else absf(sin(phase - 1.8)) * 0.4 * gait, late * 2.0)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		decoy_parts[i].rotation.z = side * (0.12 + trail)
		# Its legs hang from the dummy wherever that has got to, and off the floor they only dangle
		legs[i].position = torso.transform * (decoy.transform * Vector3(0.09 * side, -0.22, 0.18))
		legs[i].rotation.z = flop.z
		if lift > 0.05:
			legs[i].rotation.x = 0.3 + sin(anim_t * 2.5 + i * 1.7) * 0.15
	tail.rotation = Vector3(trail * 0.25, flop.y, flop.z * 0.3)


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
		_swell(a, 1, Vector3(0, -0.05, -0.03), Vector3(lerpf(1.0, crest, 0.7), lerpf(1.0, crest, 0.4), 1.0))
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.02))
	crown = Vector3(0, 0.41, -0.03)
	_part(neck, _sphere(), fur, Vector3(0, 0.2, 0), Vector3(0.24, 0.22, 0.22))
	for side: float in [-1.0, 1.0]:
		var ear := _pivot(neck, Vector3(0.08 * side, 0.38, 0.02))
		_part(ear, _cone(), dark, Vector3(0, ear_len * 0.5, 0), Vector3(0.02, ear_len, 0.02))
		_part(ear, _cone(), pale, Vector3(0, ear_len * 0.55, 0), Vector3(0.075, ear_len * 0.8, 0.012))
		ears.append(ear)
		_eye(Vector3(0.115 * side, 0.22, 0.155), 0.105)
	mouth_node = _pivot(neck, Vector3(0, 0.07, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.04, 0.04))


# The goat-sucker of the legend: gaunt, hairless and dog-like, down on all fours with its back
# humped and its ribs showing, a row of long spines from its skull to its tail, big haunches, a
# whip of a tail, and a long narrow muzzle with the fangs out in front
func _build_chupacabra(chub: float, ear_len: float) -> void:
	neck_y = 0.42
	head_y = 0.13
	centre_y = 0.4
	top_y = 0.9
	ear_splay = 1.75
	gut = 0.7
	back_y = 0.52
	fours = true
	brain_at = Vector3(0, 0.16, 0.0)
	chub *= 1.15
	var spine := Ps1.mat(Color(0.62, 0.24, 0.12), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		# Haunches made for springing: a big thigh, a thin shank and a long clawed foot
		var leg := _pivot(self, Vector3(0.13 * chub * side, 0.34, -0.22))
		_part(leg, _sphere(), fur, Vector3(0.01 * side, -0.03, 0.01), Vector3(0.07, 0.15, 0.125), Vector3(0.45, 0, 0))
		_part(leg, _capsule(0.028, 0.22), fur, Vector3(0, -0.21, -0.03), Vector3.ONE, Vector3(-0.3, 0, 0))
		_part(leg, _sphere(), dark, Vector3(0, -0.315, 0.04), Vector3(0.045, 0.028, 0.11))
		for claw: float in [-1.0, 1.0]:
			_part(leg, _cone(), bone, Vector3(0.022 * claw, -0.32, 0.15), Vector3(0.012, 0.05, 0.012), Vector3(PI * 0.5, 0, 0))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	# A deep chest, a waist drawn in under a humped back, and a pale hollow belly
	_part(torso, _sphere(), fur, Vector3(0, 0.38, 0.16), Vector3(0.135 * chub, 0.15, 0.17))
	_part(torso, _sphere(), fur, Vector3(0, 0.47, -0.02), Vector3(0.115 * chub, 0.13, 0.27), Vector3(-0.12, 0, 0))
	_part(torso, _sphere(), fur, Vector3(0, 0.4, -0.22), Vector3(0.12 * chub, 0.12, 0.14))
	_part(torso, _sphere(), pale, Vector3(0, 0.37, -0.04), Vector3(0.075 * chub, 0.075, 0.2))
	for side: float in [-1.0, 1.0]:
		for i in 4:
			_part(torso, _sphere(), pale, Vector3((0.128 - i * 0.008) * chub * side, 0.4 + i * 0.008, 0.14 - i * 0.065), Vector3(0.014, 0.085 - i * 0.008, 0.016), Vector3(0.35, 0, 0.12 * side))
	# The spines: longest over the hump, and the first thing anyone sees of it
	for i in 7:
		var along := i / 6.0
		var base := Vector3(0, 0.5 + sin(along * PI) * 0.09, 0.2 - along * 0.5)
		_spike(torso, spine, base, Vector3(0, 1.0, -0.25 - along * 0.6), (0.17 + sin(along * PI) * 0.12) * crest, 0.03)
	tail = _pivot(torso, Vector3(0, 0.44, -0.34))
	_part(tail, _capsule(0.016, 0.5), fur, Vector3(0, -0.105, -0.23), Vector3.ONE, Vector3(-2.0, 0, 0))
	_part(tail, _capsule(0.012, 0.2), fur, Vector3(0, -0.17, -0.55), Vector3.ONE, Vector3(-1.2, 0, 0))

	for side: float in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(0.11 * chub * side, 0.3, 0.2))
		var fore := _foreleg(a, side, 0.3, 0.028)
		_part(fore, _sphere(), fur, Vector3(0, -0.02, -0.01), Vector3(0.045, 0.07, 0.055))
		arms.append(a)

	# Its head is carried low and out in front
	neck = _pivot(torso, Vector3(0, neck_y, 0.3))
	_part(neck, _sphere(), fur, Vector3(0, 0.03, -0.07), Vector3(0.075, 0.08, 0.12), Vector3(-0.5, 0, 0))
	_part(neck, _sphere(), fur, Vector3(0, 0.1, 0.0), Vector3(0.115, 0.1, 0.125))
	_part(neck, _sphere(), fur, Vector3(0, 0.075, 0.17), Vector3(0.055, 0.05, 0.15))
	_part(neck, _sphere(), dark, Vector3(0, 0.09, 0.315), Vector3(0.025, 0.02, 0.02))
	for i in 3:
		_spike(neck, spine, Vector3(0, 0.18 - i * 0.03, 0.02 - i * 0.07), Vector3(0, 1.0, -0.3 - i * 0.45), (0.13 + i * 0.03) * crest, 0.026)
	for side: float in [-1.0, 1.0]:
		# Small ears, laid back along its skull
		var ear := _pivot(neck, Vector3(0.085 * side, 0.15, -0.06))
		_part(ear, _cone(), fur, Vector3(0, ear_len * 0.14, -0.03), Vector3(0.04, ear_len * 0.3, 0.02), Vector3(-0.9, 0, 0))
		ears.append(ear)
		_part(neck, _sphere(), fur, Vector3(0.07 * side, 0.16, 0.085), Vector3(0.05, 0.022, 0.05), Vector3(0.2, 0, 0.5 * side))
		_eye(Vector3(0.075 * side, 0.125, 0.09), 0.05)
		# Two long fangs past the end of its muzzle, and two short ones behind them
		_part(neck, _cone(), bone, Vector3(0.028 * side, 0.01, 0.29), Vector3(0.016, 0.11, 0.016), Vector3(PI, 0, 0))
		_part(neck, _cone(), bone, Vector3(0.036 * side, 0.03, 0.21), Vector3(0.012, 0.05, 0.012), Vector3(PI, 0, 0))
	mouth_node = _pivot(neck, Vector3(0, 0.04, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.04, 0.03, 0.11))
	# A big head for so thin a body
	_swell(neck, 0, Vector3.ZERO, Vector3.ONE * 1.3)


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
	# Some have a great deal more neck than others
	var up := 0.62 * crest
	neck_y = 0.38
	head_y = up
	centre_y = 0.4
	top_y = 0.5 + up
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
	_part(neck, _capsule(0.075, up + 0.04), fur, Vector3(0, up * 0.5 - 0.01, 0.02), Vector3.ONE, Vector3(0.08, 0, 0))
	_part(neck, _sphere(), fur, Vector3(0, up, 0.08), Vector3(0.14, 0.11, 0.19))
	for side: float in [-1.0, 1.0]:
		_part(neck, _sphere(), pale, Vector3(0.055 * side, up + 0.11, 0.02), Vector3.ONE * 0.028)
		_eye(Vector3(0.09 * side, up + 0.05, 0.13), 0.05)
	mouth_node = _pivot(neck, Vector3(0, up - 0.035, 0.23))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.08, 0.035, 0.05))


# A whale of the high slopes, and a whale to look at: a long body tapering back along the ground
# from a broad blunt head, a great wide mouth with the underjaw jutting and pegs for teeth, small
# eyes far back, a pale grooved throat, flat flippers it rows itself along on, a low ridge on its
# back, and flukes that curl over into hooks for hanging on to ridges. Grey as scree, blotched
# with lichen, with stones lying along its back. It is no water kind: it lives on the slopes.
func _build_bolter(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.25
	head_y = 0.04
	centre_y = 0.25
	top_y = 0.6
	gravity = 15.0
	brain_at = Vector3(0, 0.08, 0.12)
	# It has no neck to speak of, and turns the whole of itself to look at anything off to one side
	head_turn = 0.4
	heave = 0.07
	# Its insides are drawn out along it, and its backbone lies flat
	back_y = 0.34
	gut_at = Vector3(0, 0, -0.2)
	gut_stretch = Vector3(1.0, 0.85, 2.3)
	# (it has no legs: what the rig has for them is the pair of small bones a whale keeps)
	for side: float in [-1.0, 1.0]:
		legs.append(_pivot(self, Vector3(0.07 * side, 0.12, -0.32)))

	torso = _pivot(self, Vector3.ZERO)
	# The body, turned on a lathe from the tail forward and laid along the ground
	var hull: Array[Vector2] = [
		Vector2(0.045, 0.0), Vector2(0.075, 0.14), Vector2(0.14, 0.32), Vector2(0.22, 0.52), Vector2(0.28, 0.72),
		Vector2(0.3, 0.9), Vector2(0.27, 1.02),
	]
	_part(torso, _lathe(hull, 10), fur, Vector3(0, 0.25, -0.82), Vector3(chub, 1.0, 0.8), Vector3(PI * 0.5, 0, 0))
	_part(torso, _sphere(), pale, Vector3(0, 0.15, -0.12), Vector3(0.24 * chub, 0.14, 0.42))
	# Lichen on it in blotches, and a low ridge of a fin
	var lichens: Array[Material] = [Ps1.mat(Color(0.27, 0.31, 0.17), 0.0, 0.2), Ps1.mat(Color(0.34, 0.27, 0.13), 0.0, 0.2)]
	for i in 7:
		var along := rng.randf_range(-0.5, 0.1)
		var round := rng.randf_range(-1.2, 1.2)
		var wide := lerpf(0.13, 0.29, clampf((along + 0.8) / 0.9, 0.0, 1.0))
		_part(torso, _sphere(), lichens[i % 2], Vector3(sin(round) * wide * chub, 0.25 + cos(round) * wide * 0.8, along), Vector3(0.085, 0.03, 0.1) * rng.randf_range(0.6, 1.1), Vector3(0, 0, -round))
	_part(torso, _cone(), dark, Vector3(0, 0.5, -0.3), Vector3(0.025, 0.11, 0.13), Vector3(-0.5, 0, 0))
	var rock := BoxMesh.new()
	var scree := torso.get_child_count()
	for i in 4:
		var at := Vector3(rng.randf_range(-0.1, 0.1), 0.49 - i * 0.012, 0.02 - i * 0.14)
		_part(torso, rock, dark, at, Vector3(0.11, 0.07, 0.1) * rng.randf_range(0.7, 1.2), Vector3(rng.randf(), rng.randf(), rng.randf()))
	_swell(torso, scree, Vector3(0, 0.44, -0.2), Vector3.ONE * crest)
	tail = _pivot(torso, Vector3(0, 0.25, -0.82))
	_part(tail, _capsule(0.045, 0.2), fur, Vector3(0, 0.01, -0.05), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for side: float in [-1.0, 1.0]:
		# The flukes: flat, spread, and curled over at the tips into hooks
		_part(tail, _sphere(), fur, Vector3(0.1 * side, 0.02, -0.15), Vector3(0.12, 0.022, 0.07), Vector3(0, 0.5 * side, 0))
		_part(tail, _cone(), dark, Vector3(0.2 * side, 0.07, -0.19), Vector3(0.04, 0.14, 0.03), Vector3(0.4, 0, 0.9 * side))
		# The flippers reach out and down to the floor, and row
		var a := _pivot(torso, Vector3(0.24 * chub * side, 0.2, 0.06))
		_spike(a, dark, Vector3.ZERO, Vector3(0.8 * side, -0.55, -0.15), 0.3, 0.03, _drum(1.0, 1.0, 1.0))
		_part(a, _sphere(), dark, Vector3(0.2 * side, -0.15, -0.06), Vector3(0.15, 0.03, 0.1), Vector3(0, -0.3 * side, -0.6 * side))
		arms.append(a)

	# The head: a blunt brow over a mouth as wide as the whole of it, and the underjaw out in front
	neck = _pivot(torso, Vector3(0, neck_y, 0.14))
	_part(neck, _sphere(), fur, Vector3(0, 0.04, 0.14), Vector3(0.32 * chub, 0.23, 0.3))
	_part(neck, _sphere(), pale, Vector3(0, -0.12, 0.2), Vector3(0.33 * chub, 0.12, 0.34))
	_part(neck, _sphere(), dark, Vector3(0, 0.19, 0.3), Vector3(0.03, 0.012, 0.03))
	for i in 5:
		# Grooves down its throat
		var x := (i - 2.0) * 0.1 * chub
		_part(neck, Ps1.box(), dark, Vector3(x, -0.17 + absf(x) * 0.12, 0.36 - x * x * 1.3), Vector3(0.014, 0.012, 0.3), Vector3(0.32, x * 1.6, 0))
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.275 * chub * side, 0.1, 0.07), 0.042)
	mouth_node = _pivot(neck, Vector3(0, -0.03, 0.4))
	_part(mouth_node, _sphere(), maw, Vector3(0, 0, -0.06), Vector3(0.29 * chub, 0.12, 0.1))
	for i in 6:
		# Pegs standing up out of the underjaw
		var x := (i - 2.5) * 0.09 * chub
		_part(neck, _cone(), bone, Vector3(x, -0.03, 0.515 - x * x * 1.7), Vector3(0.026, 0.075, 0.024))


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
		var rack := neck.get_child_count()
		_part(neck, _cone(), skull, Vector3(0.15 * side, 0.52, -0.04), Vector3(0.03, 0.44, 0.03), Vector3(0, 0, -0.5 * side))
		_part(neck, _cone(), skull, Vector3(0.24 * side, 0.52, -0.04), Vector3(0.02, 0.2, 0.02), Vector3(0, 0, -1.15 * side))
		_part(neck, _cone(), skull, Vector3(0.13 * side, 0.5, 0.05), Vector3(0.02, 0.18, 0.02), Vector3(0.7, 0, -0.15 * side))
		_swell(neck, rack, Vector3(0.06 * side, 0.33, -0.04), Vector3.ONE * crest * _snapped(side))
	top_y = neck_y + 0.36 + 0.48 * crest
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
	fours = true
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
	var ridge := neck.get_child_count()
	for i in 3:
		_part(neck, _cone(), fin, Vector3(0, 0.47 - i * 0.05, 0.08 - i * 0.13), Vector3(0.018, 0.2 - i * 0.03, 0.09), Vector3(-0.3 - i * 0.35, 0, 0))
	_swell(neck, ridge, Vector3(0, 0.36, 0), Vector3.ONE * crest)
	top_y += 0.2 * (crest - 1.0)
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
		wing.scale = Vector3.ONE * lerpf(1.0, crest, 0.7)
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
		var drop := (0.3 - absf(across) * 0.05) * lerpf(1.0, crest, 0.8)
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
	# A beard and a hat as long as it has had time to grow them
	var beard := 0.18 * span(kind, "tail", shape["tail"])
	_part(neck, _cone(), bone, Vector3(0, 0.03 - beard * 0.5, 0.16), Vector3(0.1, beard, 0.06), Vector3(PI, 0, 0))
	_part(neck, _cone(), hat, Vector3(0, 0.25 + 0.3 * crest, -0.02), Vector3(0.27, 0.6 * crest, 0.27), Vector3(-0.1, 0, 0.05))
	top_y = neck_y + 0.26 + 0.6 * crest
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
		wing.scale = Vector3.ONE * lerpf(1.0, crest, 0.8)
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
	var cap := neck.get_child_count()
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
	# A wide flat cap or a tall narrow one
	_swell(neck, cap, Vector3(0, 0.34, 0), Vector3(crest, 2.0 - crest, crest))
	top_y = neck_y + 0.34 + 0.32 * (2.0 - crest)
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.085 * side, 0.15, 0.155), 0.06)
	mouth_node = _pivot(neck, Vector3(0, 0.05, 0.175))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.03))


# A hare with a buck's antlers coming in: long ears, long feet, a scut, and a great deal of spring
func _build_jackalope(chub: float, ear_len: float) -> void:
	hops = "rabbit"
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
		var rack := neck.get_child_count()
		var root := Vector3(0.08 * side, 0.34, 0.03)
		var fork := _spike(neck, horn, root, Vector3(0.45 * side, 1.0, -0.1), 0.34, 0.058, _drum(0.7, 1.0, 1.0))
		var tip := _spike(neck, horn, fork, Vector3(0.8 * side, 0.6, 0.15), 0.32, 0.044)
		_spike(neck, horn, root.lerp(fork, 0.35), Vector3(-0.05 * side, 0.8, 0.7), 0.2, 0.036)
		_spike(neck, horn, fork, Vector3(0.05 * side, 1.0, 0.0), 0.28, 0.04)
		_spike(neck, horn, fork.lerp(tip, 0.4), Vector3(0.25 * side, 1.0, -0.1), 0.23, 0.034)
		_spike(neck, horn, fork.lerp(tip, 0.75), Vector3(0.3 * side, 1.0, 0.1), 0.15, 0.03)
		_swell(neck, rack, root, Vector3.ONE * crest * _snapped(side))
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
	_swell(neck, 1, Vector3(0, 0.2, 0.05), Vector3.ONE * crest)
	top_y = neck_y + 0.2 + 0.38 * crest
	_part(neck, _sphere(), fur, Vector3(0, 0.15, 0.05), Vector3(0.19, 0.17, 0.2))
	# Great slanted eyes, all dark but for the light in them
	for side: float in [-1.0, 1.0]:
		var eye := _pivot(neck, Vector3(0.115 * side, 0.2, 0.225))
		eye.rotation = Vector3(-0.1, 0.45 * side, 0.45 * side)
		_part(eye, _sphere(), black, Vector3.ZERO, Vector3(0.1, 0.062, 0.03))
		var pupil := _part(eye, _sphere(), _eye_mat(), Vector3(0, 0, 0.03), Vector3(0.026, 0.026, 0.02))
		eyes.append(eye)
		pupils.append(pupil)
	mouth_node = _pivot(neck, Vector3(0, 0.05, 0.215))
	_part(mouth_node, _sphere(), black, Vector3.ZERO, Vector3(0.04, 0.025, 0.02))


# A yeti of the gentle sort: a huge soft pear of thick white fur with no neck and sloping
# shoulders, a small bare tan face set low on it (a broad flat nose, a wide thick-lipped mouth,
# small friendly eyes under a heavy brow), big hands on long heavy arms that hang to the ground,
# and short thick legs. A baby is a ball of fluff with the same little face (see `podge`).
func _build_yeti(chub: float, rng: RandomNumberGenerator) -> void:
	neck_y = 0.64
	head_y = 0.12
	centre_y = 0.48
	top_y = 1.06
	gravity = 14.0
	head_turn = 0.7
	brain_at = Vector3(0, 0.17, 0.02)
	crown = Vector3(0, 0.36, 0.0)
	# Off-white, and blue in the shadows of its coat, so that it is never one flat white under
	# the bright lamp. The coat on what is lathed or a capsule is measured as it stands; on a
	# ball, which is drawn a quarter of the size, the same hair is four times as long.
	var frost := {"shadow": Color(0.74, 0.84, 1.0), "tip_bleach": 0.05, "root_shade": 0.3, "streak": 0.3, "locks": 12.0, "rows": 3.0}
	fur = _shaggy(fur_colour * 0.8, 3, 0.1, frost)
	var fluff := _shaggy(fur_colour * 0.8, 3, 0.36, frost.merged({"face": 0.2, "face_from": 0.36, "face_hair": 0.1}))
	var tan := Ps1.mat(Color(0.56, 0.42, 0.3), 0.0, 0.3)
	var lip := Ps1.mat(Color(0.4, 0.27, 0.2), 0.0, 0.3)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.17 * side, 0.2, 0.02))
		_part(leg, _capsule(0.11, 0.26), fur, Vector3(0, -0.05, 0))
		_part(leg, _sphere(), tan, Vector3(0, -0.16, 0.08), Vector3(0.12, 0.045, 0.18))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	var pear: Array[Vector2] = [
		Vector2(0.28, 0.0), Vector2(0.4, 0.07), Vector2(0.45, 0.2), Vector2(0.43, 0.35), Vector2(0.36, 0.5),
		Vector2(0.28, 0.63), Vector2(0.2, 0.73), Vector2(0.1, 0.8), Vector2(0.0, 0.82),
	]
	podge = _part(torso, _lathe(pear, 12), fur, Vector3(0, 0.1, 0), Vector3(chub, 1.0, 0.9 * chub))
	podge_sizes = [podge.scale, Vector3(0.92 * chub, 0.7, 0.9 * chub)]
	tail = _pivot(torso, Vector3(0, 0.3, -0.36 * chub))
	# Its shoulders, which carry its arms and its head, and are a good deal lower on a baby
	shoulders = _pivot(torso, Vector3.ZERO)
	baby_sink = 0.2
	for side: float in [-1.0, 1.0]:
		var a := _pivot(shoulders, Vector3(0.37 * chub * side, 0.68, 0.07))
		_part(a, _capsule(0.085, 0.4), fur, Vector3(0.02 * side, -0.16, 0))
		_part(a, _capsule(0.1, 0.34), fur, Vector3(0.04 * side, -0.4, 0.01))
		_part(a, _sphere(), tan, Vector3(0.05 * side, -0.57, 0.03), Vector3(0.11, 0.085, 0.12))
		arms.append(a)

	neck = _pivot(shoulders, Vector3(0, neck_y, 0.05))
	_part(neck, _sphere(), fluff, Vector3(0, 0.13, 0), Vector3(0.27, 0.25, 0.26))
	# The face, low on the front of it
	_part(neck, _sphere(), tan, Vector3(0, 0.07, 0.15), Vector3(0.16, 0.13, 0.12))
	_part(neck, _sphere(), fluff, Vector3(0, 0.17, 0.2), Vector3(0.17, 0.05, 0.08))
	_part(neck, _sphere(), lip, Vector3(0, 0.075, 0.265), Vector3(0.062, 0.03, 0.035))
	_part(neck, _sphere(), lip, Vector3(0, 0.0, 0.235), Vector3(0.115, 0.04, 0.05))
	var knot := neck.get_child_count()
	for i in 3:
		_spike(neck, pale, Vector3((i - 1) * 0.06, 0.33, -0.02), Vector3((i - 1) * 0.5 + rng.randf_range(-0.2, 0.2), 1.0, -0.4), rng.randf_range(0.1, 0.16), 0.045)
	_swell(neck, knot, Vector3(0, 0.33, 0), Vector3.ONE * crest)
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.068 * side, 0.115, 0.255), 0.032)
	mouth_node = _pivot(neck, Vector3(0, 0.0, 0.275))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.09, 0.04, 0.03))


# Three heads on one pup, each with a mind of its own and all of them hungry
func _build_cerberus(chub: float) -> void:
	neck_y = 0.5
	head_y = 0.19
	centre_y = 0.38
	top_y = 1.0
	ear_splay = 1.5
	gut = 0.8
	back_y = 0.5
	fours = true
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


# One of the people from under the ground: stout and velvety, with spade hands far too big for
# it, a pink star for a nose, and eyes it has little use for
func _build_mole(chub: float) -> void:
	neck_y = 0.38
	head_y = 0.17
	centre_y = 0.3
	top_y = 0.8
	gravity = 15.0
	crown = Vector3(0, 0.36, -0.02)
	# Bare skin, pink enough to show a little in the dark
	var pink := Ps1.mat(Color(0.86, 0.48, 0.5), 0.3, 0.35)
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(self, Vector3(0.15 * side, 0.12, 0))
		_part(leg, _sphere(), fur, Vector3(0, -0.02, 0), Vector3(0.09, 0.08, 0.1))
		_part(leg, _sphere(), pink, Vector3(0, -0.08, 0.07), Vector3(0.08, 0.04, 0.13))
		legs.append(leg)

	torso = _pivot(self, Vector3.ZERO)
	_part(torso, _sphere(), fur, Vector3(0, 0.3, -0.02), Vector3(0.3 * chub, 0.27, 0.31 * chub))
	_part(torso, _sphere(), pale, Vector3(0, 0.25, 0.17 * chub), Vector3(0.2 * chub, 0.17, 0.14))
	tail = _pivot(torso, Vector3(0, 0.18, -0.3 * chub))
	_part(tail, _cone(), pink, Vector3(0, 0.02, -0.06), Vector3(0.028, 0.14, 0.028), Vector3(-1.3, 0, 0))

	for side: float in [-1.0, 1.0]:
		# A short thick arm, and a hand like a spade: a broad bare palm turned out to the front
		# and four long claws along the edge of it
		var a := _pivot(torso, Vector3(0.27 * chub * side, 0.38, 0.1))
		_part(a, _capsule(0.06, 0.18), fur, Vector3(0, -0.05, 0))
		_part(a, _sphere(), pink, Vector3(0.02 * side, -0.19, 0.05), Vector3(0.14, 0.13, 0.045), Vector3(0, -0.5 * side, 0))
		for claw in 4:
			var across := (claw - 1.5) * 0.068
			_part(a, _cone(), bone, Vector3(0.02 * side + across, -0.34 + absf(claw - 1.5) * 0.025, 0.05 + across * 0.5 * side), Vector3(0.026, 0.15, 0.02), Vector3(PI, 0, across * 2.0))
		_swell(a, 1, Vector3(0, -0.08, 0.02), Vector3.ONE * crest)
		arms.append(a)

	neck = _pivot(torso, Vector3(0, neck_y, 0.1))
	_part(neck, _sphere(), fur, Vector3(0, 0.17, 0), Vector3(0.23, 0.2, 0.23))
	_part(neck, _sphere(), pale, Vector3(0, 0.12, 0.17), Vector3(0.1, 0.085, 0.13))
	# The star: a ring of little feelers round the end of its snout
	var tip := Vector3(0, 0.12, 0.3)
	_part(neck, _sphere(), pink, tip, Vector3.ONE * 0.035)
	for i in 8:
		var around := TAU * i / 8.0
		_spike(neck, pink, tip, Vector3(cos(around), sin(around), 0.45), 0.085, 0.02)
	for side: float in [-1.0, 1.0]:
		_eye(Vector3(0.095 * side, 0.205, 0.195), 0.03)
	mouth_node = _pivot(neck, Vector3(0, 0.055, 0.2))
	_part(mouth_node, _sphere(), maw, Vector3.ZERO, Vector3(0.05, 0.03, 0.04))


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
	var lit := _eye_mat()
	_part(eye, _sphere(), black if hollow else lit, Vector3.ZERO, Vector3.ONE * size)
	var pupil := _part(eye, _sphere(), lit if hollow else black, Vector3(0, 0, size * 0.68), Vector3.ONE * size * 0.5)
	eyes.append(eye)
	pupils.append(pupil)


# How much is left of a horn or antler on this side (-1 left, 1 right) of one that has broken one
func _snapped(side: float) -> float:
	return 0.42 if "broken" in extras and (side > 0.0) == (int(shape["side"]) == 1) else 1.0


# The light for the next eye to be made: they are made left then right
func _eye_mat() -> ShaderMaterial:
	return eye_mats[eyes.size() % 2]


# Makes everything hung on `parent` from its child number `from` on bigger or smaller by `by`,
# about the point `anchor`: for whatever one of a kind has more or less of than the next
func _swell(parent: Node3D, from: int, anchor: Vector3, by: Vector3) -> void:
	for i in range(from, parent.get_child_count()):
		var part: Node3D = parent.get_child(i)
		part.transform = Transform3D(Basis.from_scale(by) * part.basis, anchor + (part.position - anchor) * by)


# Once its kind's body is built, what is its own about its proportions (see SHAPE): its head and
# eyes, its ears, tail and limbs, and then the odd things it has
func _shape_up() -> void:
	head_y *= head_size
	top_y = neck_y + (top_y - neck_y) * head_size
	var gap := span(kind, "gap", shape["gap"])
	var eye_size := span(kind, "eye", shape["eye"])
	for i in eyes.size():
		var eye := eyes[i]
		var ball: Node3D = eye.get_child(0)
		# Never so big, nor so close, that the two run into each other
		var room := absf(eye.position.x) * gap / maxf(ball.scale.x, 0.01)
		var size := minf(eye_size, room * 0.96)
		if "odd" in extras and i % 2 != int(shape["side"]):
			size *= float(shape["wink"])
		eye_sizes.append(size)
		# Set wider on a about head they sit further back on it
		eye.position.z -= eye.position.x * eye.position.x * (gap - 1.0) / maxf(absf(eye.position.z), 0.08)
		eye.position.x *= gap
	var ear_long := span(kind, "ear", shape["ear"])
	for i in ears.size():
		ears[i].scale = Vector3(lerpf(1.0, ear_long, 0.4), ear_long, 1.0)
		if "torn" in extras and i == int(shape["side"]):
			ears[i].scale = Vector3(1.0, ear_long * 0.5, 1.0)
	tail.scale = Vector3.ONE * span(kind, "tail", shape["tail"])
	# Longer legs raise the rest of it; one that goes on four has front legs to match, and the
	# rest have arms as long or short as their legs are
	var limb := span(kind, "limb", shape["limb"])
	if legs[0].get_parent() == self:
		stand = legs[0].position.y * (limb - 1.0)
		for leg in legs:
			leg.position.y *= limb
	for leg in legs:
		leg.scale.y = limb
	for a in arms:
		a.scale.y = (a.position.y + stand) / a.position.y if fours else lerpf(1.0, limb, 0.6)
	reach = arms[0].scale.y
	gut *= minf(span(kind, "build", shape["build"]) + 0.06, 1.0)

	var lip := mouth_node.position
	var side := 1.0 if int(shape["side"]) == 1 else -1.0
	if "tooth" in extras:
		_part(neck, _cone(), bone, lip + Vector3(0.035 * side, 0.03, 0.012), Vector3(0.024, 0.075, 0.024))
	if "whiskers" in extras:
		for flank: float in [-1.0, 1.0]:
			for tilt: float in [-0.25, 0.3]:
				_spike(neck, bone, lip + Vector3(0.04 * flank, 0.035, -0.02), Vector3(flank, tilt, 0.25), 0.2, 0.011)
	if "tuft" in extras and crown != Vector3.ZERO:
		for i in 3:
			_spike(neck, dark, crown + Vector3((i - 1) * 0.025, -0.02, 0), Vector3((i - 1) * 0.5 + 0.15 * side, 1.0, 0.3 - i * 0.3), 0.15 - absf(i - 1.0) * 0.03, 0.03)


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


# A shape turned on a lathe: points of (radius, height) from the bottom up, spun round. What is
# painted on it goes round from the front and down from the top, as on a ball.
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
			st.set_uv(Vector2(float(j) / sides, 1.0 - float(i) / (shape.size() - 1)))
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
	bubble = _pivot(self, Vector3(0.35, top_y + stand + hover + 0.35, 0))
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
	hearts.position = Vector3(0, top_y + stand + hover - 0.1, 0)
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
	return {"belly": belly, "fun": fun, "energy": energy, "love": love, "health": health, "age": age, "digest": digest, "bowel": bowel, "bladder": bladder}


func set_needs(d: Dictionary) -> void:
	belly = clampf(float(d.get("belly", belly)), 0.0, 100.0)
	fun = clampf(float(d.get("fun", fun)), 0.0, 100.0)
	energy = clampf(float(d.get("energy", energy)), 0.0, 100.0)
	love = clampf(float(d.get("love", love)), 0.0, 100.0)
	health = clampf(float(d.get("health", health)), 0.0, 100.0)
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
	if health <= 0.0:
		_enter(State.DYING)


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
	# Its health wears away over days of an empty belly, and mends over a couple of days fed and
	# rested
	if belly <= 0.0:
		health -= seconds * 100.0 / (STARVE_HOURS * HOUR)
	elif belly > 30.0 and (asleep or energy > 30.0):
		health += seconds * 100.0 / (MEND_HOURS * HOUR)
	health = clampf(health, 0.0, 100.0)


# The time nobody was looking, lived through in five-minute steps: it sleeps when it is worn out
# (or left in the dark) and wakes when it is rested. True if it is asleep at the end of it.
func pass_time(seconds: float, dark: bool) -> bool:
	var left := minf(seconds, LONGEST_AWAY)
	var asleep := false
	while left > 0.0 and health > 0.0:
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
	return global_position + Vector3(0, (centre_y + (stand + hover) * (1.0 - curl) - curl * 0.2) * grow, 0)


# How tall it stands (to the top of whatever is on its head), off the floor if it floats
func tall() -> float:
	return (top_y + (stand + hover) * (1.0 - curl)) * grow


# How far above its feet the top of its head is just now: lower sat down or curled up, and
# higher on a baby, whose head is big for it
func top() -> float:
	return (neck_y + (top_y - neck_y) * neck.scale.y / head_size + (stand + hover) * (1.0 - curl) - sit * 0.1 - curl * 0.3) * grow


# One of the kinds that live in water
func needs_water() -> bool:
	return KINDS[kind].get("water", false)


# A water kind with no pool in its room
func dry() -> bool:
	return needs_water() and world.decor_of(Decor.Kind.POOL) == null


# A place it can go to, as near a given one as may be: anywhere inside the walls for one that
# lives in water, and for the rest only the dry floor
func _footing(point: Vector3, margin: float) -> Vector3:
	return Den.in_room(point, margin) if needs_water() else Den.on_dry(point, margin, 0.3 * grow)


# Somewhere to wander off to: anywhere on the floor that it can go (one that does not live in
# water looks again sooner than end up at the edge of the pool every other time)
func _roam() -> Vector3:
	var spot := Vector3.ZERO
	for i in 6:
		spot = Vector3(randf_range(-9.0, 9.0), 0, randf_range(-9.0, 9.0)).limit_length(Den.half.length())
		if needs_water() or Den.wade(Den.in_room(spot, 0.4)) < -0.3 * grow:
			break
	return _footing(spot, 0.4)


# How far below the floor it stands where it is: down the shelving bed of the pool until the
# water is up to its middle, and afloat from there on out (and not at all while it is held up)
func _sunk() -> float:
	return minf(maxf(-Den.deep(position), Decor.WATER - centre_y * 0.75 * grow), 0.0) * clampf(1.0 - lift / 0.3, 0.0, 1.0)


# Whether it is in the pool with no business there: carried over it and let go, shoved in, or
# the water come to where it was standing
func _swamped() -> bool:
	return not needs_water() and lift <= 0.05 and Den.wade(position) > 0.15 and not state in [State.FLOUNDER, State.HELD, State.SHOVED, State.LEAVE, State.SCUFFLE, State.TRICK, State.SPELL]


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
	var lasting := feeling in [Feeling.HUNGRY, Feeling.BORED, Feeling.SAD, Feeling.GRUMPY, Feeling.POORLY]
	if feeling != emote_for or (lasting and emote_again <= 0.0 and not emote.visible):
		# Settling back to plain happiness after something else is not news
		var news := feeling != Feeling.HAPPY or emote_again <= 0.0
		emote_for = feeling
		emote.visible = faces[feeling] != null and news
		if emote.visible:
			emote.material_override.albedo_texture = faces[feeling]
			emote_time = 0.0
			emote_again = randf_range(10.0, 16.0)
	if state in [State.SLEEP, State.DYING] or bubble.visible or xrayed or emote_time > 3.0:
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
	elif health < POORLY:
		feeling = Feeling.POORLY
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
	target = _footing(point, 0.35)
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
	target = _footing(point, 0.35)
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


# Come upon at it (over-fond of its nest, or paired off with another, when the other is caught
# too): it stops dead, and stares, and wishes the floor would open. True if it was.
func caught() -> bool:
	if not state in [State.FOND, State.PAIR] or step == 0:
		return false
	# (caught already, and still wishing it)
	if step == 2:
		return true
	if state == State.PAIR and _has_partner() and partner.state == State.PAIR and partner.step == 1:
		partner._mortified()
	_mortified()
	return true


func _mortified() -> void:
	step = 2
	state_time = 0.0
	lift = 0.0
	wiggle = 0.0
	nod = 0.0
	arm_goal = REST_ARM
	hearts.emitting = false
	feel(Feeling.SCARED, 3.5)
	_cry("squeak", 1.2)


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
	if state == State.DYING:
		_dying(delta)
		_move(delta)
		_animate(delta)
		_show_emote(delta)
		return
	ball_cooldown -= delta
	food_cooldown -= delta
	fight_cooldown -= delta
	beg_cooldown -= delta
	pounce_cooldown -= delta
	nest_cooldown -= delta
	fond_cooldown -= delta
	knack.always(delta)
	glance_time -= delta
	_tick_needs(delta)
	_feel(delta)
	_bristle(delta)
	gaze = _default_gaze()
	_think(delta)
	_move(delta)
	_animate(delta)


# The end of it. It lies still for a moment; then a pale ghost of it gets up out of where it
# lay (the room puts a marker there) and drifts up and out through the ceiling.
func _dying(delta: float) -> void:
	velocity = Vector3.ZERO
	gaze = position + Vector3(sin(yaw), 0.2, cos(yaw))
	if step == 0:
		if state_time > 2.6:
			step = 1
			state_time = 0.0
			world.died(self)
			_ghost(self, Ps1.xray(Color(0.82, 0.9, 1.0)))
			curl_goal = 0.0
			eye_goal = 0.6
			arm_goal = UP_ARM * 0.4
			world.sfx.play("coo", 0.5 * voice, -8.0)
	else:
		lift += delta * (0.35 + state_time * 0.5)
		wiggle = sin(anim_t * 2.2) * 0.12
		yaw += delta * 0.5
		if lift > Den.lamp_at.y + 2.0:
			queue_free()


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
	# Nor is one ever any part of a pairing, which is for two grown ones that are both willing
	# and no kin (see Den.would_pair): there is no other way into it than this
	if s == State.PAIR and (not _has_partner() or not world.would_pair(self, partner)):
		s = State.IDLE
	# And there is no digging where it stands in water
	if s == State.DIG and Den.wade(position) > 0.0:
		s = State.IDLE
	# Whatever its knack, or a spell on it, had changed about it is put back
	if state in [State.TRICK, State.SPELL]:
		knack.over()
	waiting = false
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
			target = _footing(world.light_point + Vector3(randf_range(-0.6, 0.6), 0, 1.5), 0.4)
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
			target = _bed()
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
			kicks = 0
			wag = 5.0
		State.TRICK:
			knack.begin()
		State.FLOUNDER:
			# Out by the shortest way, and making the most of it
			target = Den.on_dry(position, 0.3, 0.45)
			eye_goal = 1.25
			arm_goal = UP_ARM
			arm_wave = 0.4
			world.splash(position)
			_cry("squeak", 1.1)
			feel(Feeling.GRUMPY, 9.0)
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
		State.SNIFF:
			wag = 6.0
		State.FOLLOW:
			state_len = randf_range(6.0, 10.0)
			wag = 6.0
		State.TAG, State.FLEE:
			kicks = 0
			wag = 9.0
		State.SCUFFLE:
			velocity = Vector3.ZERO
		State.DYING:
			# It lies down where it is and goes still
			world.dying(self)
			curl_goal = 1.0
			eye_goal = 0.0
			droop_goal = 1.0
			wag = 0.0
			velocity = Vector3.ZERO
			_cry("whimper", 0.7, -6.0)
		State.PAIR:
			fond_cooldown = randf_range(300.0, 900.0)
			kicks = 0
			wag = 8.0
		State.COWED:
			droop_goal = 0.9
			wag = 1.0
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
		# (one whose knack is a way of getting at its food may use that)
		_enter(State.TRICK if knack.fetches() else State.GO_FOOD)
	elif world.light_dragging and _sees(world.light_point):
		_enter(State.CHASE_LIGHT)
	elif world.ball != null and ball_cooldown <= 0.0 and (world.ball.held or world.ball.speed() > 1.5) and _sees(world.ball.position):
		_enter(State.CHASE_BALL)
	else:
		return false
	return true


# Whether something is near enough for it to see: anywhere in the room, for all but the
# short-sighted
func _sees(point: Vector3) -> bool:
	if not likes.has("sight"):
		return true
	return Vector2(point.x - position.x, point.z - position.z).length() < float(likes["sight"])


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
	# Most dig only where the floor is loose; a born digger has a go at anything
	var digger := float(likes.get("dig", 1.0))
	if (world.floor_style >= 4 or digger > 1.0) and energy > 30.0:
		options[State.DIG] = 6.0 * digger * (1.0 if world.floor_style >= 4 else 0.5) * (1.5 if _is(1) or _is(7) else 1.0) * (1.4 if world.floor_style == fav_ground else 1.0)
	if tail.get_child_count() > 0 and energy > 40.0:
		options[State.SPIN] = 3.0 * float(likes["zoom"])
	if knack.ready():
		options[State.TRICK] = knack.weight()
	if _fancies():
		options[State.FOND] = 3.0
	# The others: a sniff at one, trailing after one it likes (a baby after anybody), a chase
	var other := _someone()
	if other != null:
		options[State.SNIFF] = 9.0
		if world.regard(self, other) >= 45.0 or is_baby():
			options[State.FOLLOW] = 5.0 * (1.6 if _is(4) or is_baby() else 1.0)
		if world.regard(self, other) >= 45.0 and energy > 40.0 and other.energy > 30.0:
			options[State.TAG] = 5.0 * float(likes["zoom"]) * (1.5 if _is(1) else 1.0)
		# Now and then, two grown ones that are fond of each other and want for nothing
		if fond_cooldown <= 0.0 and world.would_pair(self, other):
			options[State.PAIR] = 4.0
	var total := 0.0
	for w: float in options.values():
		total += w
	var roll := randf() * total
	for s: int in options:
		roll -= float(options[s])
		if roll <= 0.0:
			if s == State.WANDER:
				target = _roam()
			if s in [State.SNIFF, State.FOLLOW, State.TAG, State.PAIR]:
				meet(s, other)
			else:
				_enter(s)
			return
	_enter(State.IDLE)


func _think(delta: float) -> void:
	if _swamped():
		_enter(State.FLOUNDER)
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
					target = _footing(Vector3(randf_range(-1.2, 1.2), 0, randf_range(-0.8, 1.2)), 0.4)
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
			var point := _footing(Vector3(cos(a) * Den.half.x, 0, sin(a) * Den.half.y) * 0.75, 0.4)
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
			if visiting.kind == Decor.Kind.POOL:
				_visit_pool(delta)
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
					_ when visiting.hollow:
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
		State.TRICK:
			knack.tick(delta)
		State.SPELL:
			knack.spelled(delta)
		State.FLOUNDER:
			# Thrashing for the bank, and none too pleased once it is on it
			gaze = target + Vector3(0, 0.2, 0)
			wiggle = sin(anim_t * 16.0) * 0.12
			if int(state_time / 0.4) + 1 > step and Den.wade(position) > 0.0:
				step = int(state_time / 0.4) + 1
				world.splash(position)
			if _steer(target, RUN * 0.7, delta, 0.15) or state_time > 8.0:
				love = maxf(love - 1.0, 0.0)
				_cry("grumble", 1.2)
				_enter(State.STARTLED, 1.4)
				roll_goal = 0.3
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
		State.SNIFF:
			_sniff(delta)
		State.FOLLOW:
			_follow(delta)
		State.TAG:
			_tag(delta)
		State.FLEE:
			_flee(delta)
		State.SCUFFLE:
			# Somewhere in the ball of dust (Den has the two of them until it is over)
			velocity = Vector3.ZERO
			if world.scuffle == null:
				_enter(State.IDLE, 1.0)
		State.PAIR:
			_pair(delta)
		State.COWED:
			_cowed(delta)
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
			elif _steer(target, WALK * 0.85, delta, _bed_reach() if target == world.nest_pos else 0.12) or state_time > 12.0:
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
			# A night in the one nest brings them round to each other
			for other in _bedfellows():
				world.warm(self, other, delta * SLEEP_WARMS / HOUR)
			if int(state_time / 3.4) > step:
				step = int(state_time / 3.4)
				_cry("snore", 1.0, -8.0)
			if energy >= 98.0 or (world.light_on and energy > 55.0 and state_len < 0.0):
				_cry("coo", 0.9)
				_enter(State.STRETCH)
			# Sent to bed by the dark: remember, so that the lamp coming back on wakes it
			if not world.light_on:
				state_len = -1.0


# At the pool. One that lives in water wades out and paddles about, in one place and then
# another, for a good long while; the rest come down to the edge of it for a drink.
func _visit_pool(delta: float) -> void:
	var wading := needs_water()
	if step == 0:
		if wading and Den.wade(target) < 0.4:
			target = world.wading_spot(position)
		var at := target if wading else Den.on_dry(Den.shore_by(position, 0.1 * grow + 0.04), 0.3)
		gaze = at + Vector3(0, 0.2, 0)
		if _steer(at, WALK * 1.2, delta, 0.25 if wading else 0.1) or state_time > 7.0:
			step = 1
			state_time = 0.0
			state_len = randf_range(4.0, 7.5) + (4.0 if wading else 0.0)
			if wading:
				world.splash(position)
				hearts.emitting = true
				feel(Feeling.LOVING, 4.0)
				world.learned(self, "water")
		return
	_halt(delta)
	if wading:
		arm_wave = 0.2
		wag = 8.0
		wiggle = sin(anim_t * 3.0) * 0.06
		gaze = world.camera.global_position
		_face(gaze, delta)
		if int(state_time / 1.4) + 1 > step:
			step = int(state_time / 1.4) + 1
			world.splash(position)
	else:
		# Drinks, facing out over the water
		_face(Den.shore_by(position, -1.0), delta)
		nod = 0.5 + sin(state_time * 7.0) * 0.12
		mouth_goal = 0.5
		if int(state_time / 0.8) + 1 > step:
			step = int(state_time / 0.8) + 1
			_cry("chomp", 1.7, -14.0)
	if state_time > state_len:
		if wading and kicks < 2:
			# (and off to another part of it)
			kicks += 1
			step = 0
			state_time = 0.0
			target = world.wading_spot(position)
			return
		fun = minf(fun + (5.0 if wading else 1.5), 100.0)
		_enter(State.IDLE, 1.0)


# Those asleep in the nest already
func _bedfellows() -> Array[Cryptlin]:
	var there: Array[Cryptlin] = []
	for other in world.pets():
		if other != self and other.state == State.SLEEP and other.position.distance_to(world.nest_pos) < 0.7:
			there.append(other)
	return there


# Where it goes to sleep: the nest, or the floor a little way off if one it does not get on
# with is in it already. One that lives in water sleeps at the edge of the pool, half in it.
func _bed() -> Vector3:
	if needs_water() and Den.shore != Den.Shore.NONE:
		return Den.in_room(Den.shore_by(position, -0.1), 0.4)
	for other in _bedfellows():
		if world.standing(self, other) < 35.0:
			var off := world.nest_pos.x * -1.0 if absf(world.nest_pos.x) > 0.1 else 1.0
			return Den.on_dry(world.nest_pos + Vector3(signf(off) * 1.0, 0, 0.3), 0.4, 0.2)
	return world.nest_pos


# How near its bed it has to get before it lies down: right in if the nest is empty, in a heap
# with those it gets on with, and beside the rest
func _bed_reach() -> float:
	var reach := 0.12
	for other in _bedfellows():
		reach = maxf(reach, 0.28 if world.standing(self, other) >= 60.0 else 0.5)
	return reach


# The one eating a bit of food already, or null
func _eater_of(food: Snack) -> Cryptlin:
	for other in world.pets():
		if other != self and other.state == State.EAT and other.snack == food:
			return other
	return null


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
		# Somebody is at it already: a shy one thinks better of it, and two that do not get on may
		# well fall out over it. Otherwise they share.
		var eater := _eater_of(snack)
		if eater != null:
			if _is(2) and belly >= 20.0:
				food_cooldown = 3.0
				_enter(State.IDLE, 1.0)
				return
			if squabble(eater, 0.8):
				return
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
		# Each bite is whoever's took it, so two at one bit of food share it as they come; and
		# eating side by side is a thing done together
		for other in world.pets():
			if other != self and other.state == State.EAT and position.distance_to(other.position) < 1.3:
				world.warm(self, other, 0.4)
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
	# Others after the same toy: a game shared, or (over a favourite, between two that do not
	# get on) something to fall out about
	for other in world.pets():
		if other != self and other.state == State.CHASE_BALL and position.distance_to(other.position) < 1.4:
			if (b.kind == fav_toy or b.kind == other.fav_toy) and squabble(other, 0.35):
				return
			world.warm(self, other, 0.4)
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
	# (every kick wears it a little, and the last one breaks it: see toy_broke)
	world.wear_toy(b, self)


# The thing it was sitting on, tucked into or wading in has been taken up from round it and put
# away: it is left standing where it was, wide awake and a little put out
func turned_out() -> void:
	if state in [State.LEAVE, State.HELD, State.DYING, State.SCUFFLE, State.SCANNED, State.SPELL, State.TRICK]:
		return
	visiting = null
	if state == State.SLEEP:
		energy = maxf(energy, 35.0)
	_cry("grumble")
	_enter(State.STARTLED, 1.2)
	feel(Feeling.GRUMPY, 5.0)


# How hard it is on a toy, next to an ordinary grown one: by its kind, its two natures, and less
# for a baby
func rough() -> float:
	return ROUGH[kind] * NATURE_ROUGH[nature] * NATURE_ROUGH[nature2] * (0.6 if is_baby() else 1.0)


# The toy has come apart, in front of it or under its own foot. A rough or lively one is delighted
# with itself; any other jumps out of its skin.
func toy_broke(at: Vector3) -> void:
	if state in [State.SLEEP, State.LEAVE, State.HELD, State.DYING, State.SCUFFLE, State.SCANNED, State.SPELL, State.TRICK]:
		return
	gaze = at
	ball_cooldown = 4.0
	if NATURE_ROUGH[nature] > 1.0:
		_enter(State.IDLE, 2.2)
		hop(3.2)
		arm_goal = UP_ARM
		wag = 14.0
		_cry("coo", 1.2)
		feel(Feeling.EXCITED, 4.0)
	else:
		_cry("squeak", 1.2)
		_enter(State.STARTLED, 1.6)
		feel(Feeling.SCARED, 4.0)


# ---------------------------------------------------------------- one another

# How well its natures go with another's, as a lean on what they make of each other to begin
# with: opposites grate (shy and bold, sleepy and restless, cuddly and grumpy), a grumpy one is
# hard going for anybody, and a nature in common or a cuddly one helps
func suits(other: Cryptlin) -> float:
	var lean := 0.0
	for pair: Array in OPPOSED:
		if (_is(pair[0]) and other._is(pair[1])) or (_is(pair[1]) and other._is(pair[0])):
			lean -= 14.0
	if _is(6) or other._is(6):
		lean -= 6.0
	if other._is(nature) or other._is(nature2):
		lean += 8.0
	if _is(4) or other._is(4):
		lean += 5.0
	return lean


# Whether the one it was busy with is still about
func _has_partner() -> bool:
	return is_instance_valid(partner) and partner in world.pets()


# Another cryptlin that is up and free to be bothered (and not out in the pool, where one that
# does not live in water could not get at it), or null
func _someone() -> Cryptlin:
	var free: Array[Cryptlin] = []
	for other in world.pets():
		if other != self and other.state in INTERRUPTIBLE and not other.knack.dread() and (needs_water() or Den.wade(other.position) <= 0.0):
			free.append(other)
	return free.pick_random() if not free.is_empty() else null


# Takes up with another: to sniff at it, to follow it about, to pair off with it (if they both
# will: see _enter), or to chase it (which sets the
# other running)
func meet(s: int, other: Cryptlin) -> void:
	partner = other
	_enter(s)
	if s == State.PAIR and state == State.PAIR:
		other.partner = self
		other._enter(State.PAIR)
		other.waiting = true
	if s == State.TAG:
		other.partner = self
		other._enter(State.FLEE)
		_cry("chirp", 1.2)


# How ready it is to come to blows with another, 0 to 1: mostly how little they think of each
# other, more when it is hungry, out of sorts or ill at ease, and next to nothing between two
# that are fed, at home and on good terms
func temper(other: Cryptlin) -> float:
	var standing := world.standing(self, other)
	var t := clampf((50.0 - standing) / 40.0, 0.0, 1.0)
	if belly < 25.0:
		t += 0.25
	if other.belly < 25.0:
		t += 0.1
	if comfort < 35.0:
		t += 0.1
	if _is(6) or feeling == Feeling.GRUMPY:
		t += 0.15
	if belly > 50.0 and other.belly > 50.0 and comfort > 50.0 and standing >= 45.0:
		t *= 0.1
	return clampf(t, 0.0, 1.0)


# Whether it is in a state to be fought with: up, on dry floor and not in anybody's hands
func _can_fight() -> bool:
	return fight_cooldown <= 0.0 and lift <= 0.05 and Den.wade(position) <= 0.0 and not state in [State.SLEEP, State.HELD, State.LEAVE, State.SCANNED, State.SCUFFLE, State.COWED, State.SHOVED, State.PETTED, State.FLOUNDER, State.TRICK, State.SPELL]


# Something to fall out over (food, the toy, being crowded): at these odds, and by how ready
# the two of them are for it, it comes to blows. True if it did.
func squabble(other: Cryptlin, odds: float) -> bool:
	if not _can_fight() or not other._can_fight() or randf() >= odds * temper(other):
		return false
	world.start_fight(self, other)
	return true


# One that is hungry or in a foul mood takes against whoever is standing too close
func _bristle(delta: float) -> void:
	if not state in INTERRUPTIBLE or (belly >= 20.0 and feeling != Feeling.GRUMPY):
		return
	for other in world.pets():
		if other != self and position.distance_to(other.position) < 0.75 and squabble(other, delta * 0.3):
			return


# How it is likely to do in a fight, this time: the bigger, the bolder and the fitter, with a
# good deal of luck in it
func might() -> float:
	var nerve := 1.0 + (0.3 if _is(5) else 0.0) + (0.2 if _is(6) else 0.0) - (0.2 if _is(2) else 0.0)
	return grow * nerve * (0.5 + health / 200.0) * randf_range(0.6, 1.4)


# Cuffed out of the way by a grown one: a baby is sent tumbling and squeaks, and is not hurt
func cuffed(by: Cryptlin) -> void:
	push(position - by.position)
	feel(Feeling.SCARED, 4.0)


# The fight is over and it lost: a little the worse for it (never a baby, and never below the
# floor: fighting alone does not kill), it backs off from the one that won
func beaten(by: Cryptlin) -> void:
	if not is_baby():
		health = maxf(health - FIGHT_HURT, minf(health, FIGHT_FLOOR))
	partner = by
	_enter(State.COWED)
	_cry("whimper", 1.1)
	feel(Feeling.SCARED, 6.0)


# Goes over to another and has a good sniff at it
func _sniff(delta: float) -> void:
	if not _has_partner():
		_enter(State.IDLE, 0.6)
		return
	gaze = partner.global_position + Vector3(0, partner.tall() * 0.5, 0)
	if step == 0:
		if _steer(partner.position, WALK * 1.2, delta, 0.36 * (grow + partner.grow) + 0.1) or state_time > 7.0:
			step = 1
			state_time = 0.0
			# (the other looks round to see what is at it)
			partner.glance_time = 1.6
			partner.glance_point = global_position + Vector3(0, tall() * 0.6, 0)
	else:
		_halt(delta)
		_face(partner.position, delta)
		nod = 0.3 + sin(state_time * 11.0) * 0.08
		if state_time > 1.6:
			var other := partner
			# Between two that do not get on, a sniff is a liberty
			if world.standing(self, other) < 35.0 and other.squabble(self, 0.6):
				return
			world.warm(self, other, 1.0)
			world.warm(other, self, 0.6)
			_cry("chirp", 0.9)
			_enter(State.IDLE, 1.0)


# Trails round after another for a while
func _follow(delta: float) -> void:
	if not _has_partner() or state_time > state_len:
		if _has_partner():
			world.warm(self, partner, 0.6)
		_enter(State.IDLE, 0.8)
		return
	gaze = partner.global_position + Vector3(0, partner.tall() * 0.5, 0)
	var behind := partner.position - Vector3(sin(partner.yaw), 0, cos(partner.yaw)) * (0.32 * (grow + partner.grow) + 0.1)
	_steer(behind, WALK * 1.3, delta, 0.2)


# A game of chase: it runs the other down, and a touch turns the game round
func _tag(delta: float) -> void:
	if not _has_partner() or partner.state != State.FLEE or partner.partner != self:
		_enter(State.IDLE, 0.8)
		return
	fun = minf(fun + delta * 0.5, 100.0)
	gaze = partner.global_position + Vector3(0, 0.3, 0)
	mouth_goal = 0.6
	var caught_up := _steer(partner.position, RUN * 1.12, delta, 0.33 * (grow + partner.grow) + 0.12)
	if caught_up or state_time > 9.0:
		var other := partner
		for both: Cryptlin in [self, other]:
			both.fun = minf(both.fun + 5.0, 100.0)
			both.hop(2.2)
		world.warm(self, other, 1.5)
		world.warm(other, self, 1.5)
		_cry("chirp", 1.2)
		kicks += 1
		if caught_up and kicks < 3 and other.energy > 25.0:
			# Tag: the other is it now
			var turns := kicks
			other.meet(State.TAG, self)
			other.kicks = turns
		else:
			_enter(State.IDLE, 1.2)
			other._enter(State.IDLE, 1.2)


# Running from the one that is it, round the room
func _flee(delta: float) -> void:
	if not _has_partner() or partner.state != State.TAG or partner.partner != self:
		_enter(State.IDLE, 0.8)
		return
	gaze = partner.global_position + Vector3(0, 0.3, 0)
	# A beat's start at the off, then away to wherever is furthest from it
	if state_time < 0.5:
		_halt(delta)
		return
	var from := position - partner.position
	from.y = 0.0
	if from.length() < 1.6 or position.distance_to(target) < 0.5:
		var side := from.normalized().rotated(Vector3.UP, 1.1 if me.id % 2 == 0 else -1.1)
		target = _footing(position + (from.normalized() + side) * 1.4, 0.5)
		if target.distance_to(position) < 0.8:
			# Cornered: break back past it
			target = _footing(-position * 0.8, 0.5)
	_steer(target, RUN * 1.05, delta, 0.3)


# Lost a fight: off to the far side of the room from the one that won, and small there a while
func _cowed(delta: float) -> void:
	if step == 0:
		if _has_partner():
			var from := position - partner.position
			from.y = 0.0
			target = _footing(position + from.normalized() * 2.2, 0.45)
		gaze = target + Vector3(0, 0.2, 0)
		if _steer(target, RUN, delta, 0.3) or state_time > 2.5:
			step = 1
			state_time = 0.0
	else:
		_halt(delta)
		sit_goal = 1.0
		droop_goal = 1.0
		eye_goal = 0.7
		if _has_partner():
			gaze = partner.global_position + Vector3(0, 0.3, 0)
			_face(partner.position, delta)
		if state_time > 3.0:
			_enter(State.IDLE, 1.5)


# Two grown ones that think well of each other pairing off, out in the open: the one that went
# over clambers up on the other and gives it the same foolish wiggle a nest gets (see FOND),
# hearts and all, and both are mortified if they are caught at it. That is all there is to see.
func _pair(delta: float) -> void:
	if not _has_partner() or partner.state != State.PAIR:
		_enter(State.IDLE, 1.0)
		return
	if step == 2:
		# Seen: stock still, staring at you, ears down
		_halt(delta)
		gaze = world.camera.global_position
		_face(gaze, delta)
		eye_goal = 1.25
		droop_goal = 1.0
		if state_time > 3.0:
			_enter(State.IDLE, 1.0)
		return
	gaze = partner.global_position + Vector3(0, partner.tall() * 0.6, 0)
	if step == 0:
		if waiting:
			# The one gone over to: it stays where it is and watches the other come
			_halt(delta)
			_face(partner.position, delta)
			wag = 10.0
		elif _steer(partner.position, WALK * 1.2, delta, 0.34 * (grow + partner.grow)) or state_time > 8.0:
			for both: Cryptlin in [self, partner]:
				both.step = 1
				both.state_time = 0.0
				both.state_len = randf_range(4.0, 6.0)
				both.feel(Feeling.LOVING, 6.0)
				both.hearts.emitting = true
		return
	_halt(delta)
	eye_goal = 0.35
	droop_goal = 0.6
	wag = 14.0
	if waiting:
		wiggle = sin(anim_t * 19.0 + 1.0) * 0.05
	else:
		# Up on the other and giving it everything, eyes half shut
		var near := 1.0 - exp(-delta * 8.0)
		var behind := partner.position - Vector3(sin(partner.yaw), 0, cos(partner.yaw)) * 0.12 * partner.grow
		position.x = lerpf(position.x, behind.x, near)
		position.z = lerpf(position.z, behind.z, near)
		yaw = rotate_toward(yaw, partner.yaw, delta * 6.0)
		lift = lerpf(lift, partner.centre_y * partner.grow * 0.55, near)
		arm_goal = BELLY_ARM
		wiggle = sin(anim_t * 19.0) * 0.13
		nod = 0.25 + sin(anim_t * 19.0) * 0.06
		if int(state_time / 0.33) > kicks:
			kicks = int(state_time / 0.33)
			squash_v = 2.2
			partner.squash_v = 1.2
		if state_time > state_len:
			var other := partner
			world.paired(self, other)
			for both: Cryptlin in [self, other]:
				both.fun = minf(both.fun + 6.0, 100.0)
				both._cry("coo", 0.9)
				both._enter(State.IDLE, 1.5)
				both.eye_goal = 0.5


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
	# (a poorly one drags itself about)
	var want := speed * pace * aligned * clampf(away / 0.5, 0.35, 1.0) * (0.6 if health < POORLY else 1.0)
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
		# (they step round one that is dying, too, which is past being pushed)
		if r.pet != null and r.pet != self and r.pet.state == State.DYING and r.pet.lift <= 0.05:
			_keep_off(r.pet.position, 0.3 * (grow + r.pet.grow), delta)
	for other in world.pets():
		if other == self or other.lift > 0.05 or other.state == State.SCUFFLE:
			continue
		if state == State.SLEEP and other.state != State.SLEEP:
			continue
		var room := 0.3 * (grow + other.grow)
		# (and a wide berth for one that is to be dreaded just now)
		if other.knack.dread():
			room += 0.6
		if state == State.SLEEP:
			room *= 0.45 if world.standing(self, other) >= 60.0 else 0.75
		_keep_off(other.position, room, delta)


func _move(delta: float) -> void:
	# (one that hops covers its ground in the hops, and none of it between them)
	var go := delta * (_hop_drive() if hops != "" else 1.0)
	position.x += velocity.x * go
	position.z += velocity.z * go
	if state != State.LEAVE and state != State.DYING:
		# It walks round the things in its tank, and stays inside the walls
		if lift <= 0.05:
			for thing in world.decors:
				var room := thing.radius + 0.2 * grow
				# Not the shelter it is tucked into, nor the rock it is sat on (and the pool is not
				# a thing to walk round: see below)
				if (thing.hollow and state in [State.SLEEP, State.GO_SLEEP, State.MOVE_NEST]) or (thing == visiting and state in [State.LURK, State.VISIT]) or thing.kind == Decor.Kind.POOL:
					continue
				_keep_off(thing.position, room, delta)
			# And round what has been left on the floor, unless it is busy adding to it
			if state != State.TOILET:
				for m in world.messes:
					if m.kind != Mess.Kind.HEAP:
						_keep_off(m.position, 0.08 + 0.18 * grow, delta)
			_keep_off_others(delta)
			# One that does not live in water goes no further than the edge of the pool, unless
			# it is sent in (when it has to get itself out again: see _swamped)
			if not needs_water() and Den.wade(position) <= 0.15 and not state in [State.SHOVED, State.FLOUNDER, State.HELD, State.SPELL]:
				var ashore := Den.on_dry(position, 0.0, 0.1 * grow)
				position.x = ashore.x
				position.z = ashore.z
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
	position.y = jump_y + lift + _sunk() - dive
	rotation.y = yaw


# ---------------------------------------------------------------- hopping

# Whether one that hops is going about on its own feet just now, and so in hops: not while it is
# held up, thrown into the air, skidding from a shove, in a fight or out of its depth
func _hops_now() -> bool:
	return hops != "" and lift <= 0.05 and not airborne and not state in [State.HELD, State.SHOVED, State.FLOUNDER, State.SCUFFLE, State.DYING] and _sunk() > -0.02


# Of a hop, the part of it that is gone when it leaves the ground, and the part it takes to
# settle once it is down again
const HOP_OFF := 0.14
const HOP_SETTLE := 0.14


# How far through a hop it comes down again: sooner in a lolloping hop, which has a pause after
# it, than in a bound at a run, which has next to none
func _hop_down() -> float:
	return lerpf(0.66, 0.84, hop_run)


# How much of its speed over the ground it has at this moment of a hop: none while it gathers
# itself and none in the pause after, and the more for it in between, so that over a whole hop
# it covers the same ground as one that walks at that speed
func _hop_drive() -> float:
	if not _hops_now():
		return 1.0
	var from := HOP_OFF * 0.4
	var to := _hop_down() + HOP_SETTLE * 0.5
	var u := inverse_lerp(from, to, hop_t)
	return 6.0 * u * (1.0 - u) / (to - from) if hop_t > 0.0 and u > 0.0 and u < 1.0 else 0.0


# The gait of one that hops where the rest walk (`hops`, set by its kind's build function). This
# keeps the time of it: the hop begins when it wants to be moving, is short and small at a walk
# and long and low at a run, shorter and clumsier for a baby, and ends with it down again and
# still for a moment; what is keyed to a step (a print, the squash of landing) is keyed to coming
# down. How it holds itself through the hop is its own manner's business: see _hop_rabbit.
func _hop(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var young := clampf(inverse_lerp(adult_size, BABY_SIZE, grow), 0.0, 1.0)
	var down := _hop_down()
	var before := hop_t
	if not _hops_now():
		hop_t = 0.0
	elif hop_t > 0.0:
		hop_t += delta / hop_len
		if before < down and hop_t >= down:
			squash_v += 1.4 + young
			if likes.has("print"):
				for side: float in [-1.0, 1.0]:
					world.leave_print(str(likes["print"]), global_transform * Vector3(absf(legs[0].position.x) * side, 0, 0.1), yaw + 0.2 * side, side, grow)
		if hop_t >= 1.0:
			hop_t = fmod(hop_t, 1.0) if speed > 0.08 else 0.0
			before = 0.0
	elif speed > 0.08:
		hop_t = 0.0001
	if hop_t > 0.0 and before <= 0.0:
		hop_run = clampf((speed - 1.5) / 1.6, 0.0, 1.0)
		hop_len = lerpf(0.44, 0.33, hop_run) * lerpf(1.0, 0.72, young)
		hop_high = lerpf(0.12, 0.16, hop_run) * clampf(speed, 0.3, 1.0) * lerpf(1.0, randf_range(0.8, 1.7), young)
		hop_tip = randf_range(-0.35, 0.35) * young
	var air := clampf(inverse_lerp(HOP_OFF, _hop_down(), hop_t), 0.0, 1.0) if hop_t > 0.0 else 0.0
	hop_y = sin(air * PI) * hop_high
	# What trails after it (ears, antlers, a tail) goes by how fast it is rising or falling, late
	var rising := jump_v if airborne else (cos(air * PI) * hop_high * PI / (hop_len * (_hop_down() - HOP_OFF)) if air > 0.0 and air < 1.0 else 0.0)
	hop_lag = lerpf(hop_lag, clampf(rising * 0.3, -0.45, 0.8), 1.0 - exp(-delta * 9.0))
	match hops:
		"rabbit":
			_hop_rabbit(air, young)


# A rabbit's hop, on all fours: it bunches up on its haunches, springs off the big hind legs with
# its nose up and its body stretched out and its forepaws reaching, tips over the top of the hop,
# comes down on its forepaws with its nose down, and its hindquarters swing in under it. Its
# ears and antlers lag behind all of this, and bob. Thrown straight up (startled, or jumping for
# something) its legs hang and its ears stream.
func _hop_rabbit(air: float, young: float) -> void:
	var down := _hop_down()
	var pitch := 0.0
	var kick := 0.0
	var paw := 0.0
	var stretch := 0.0
	if airborne:
		kick = 0.55
		paw = -0.5
		stretch = clampf(jump_v * 0.03, -0.08, 0.12)
	elif hop_t <= 0.0:
		pass
	elif hop_t < HOP_OFF:
		var u := hop_t / HOP_OFF
		pitch = -0.34 * u
		kick = -0.5 * sin(u * PI) + 1.1 * u * u
		paw = -0.6 * u
		stretch = -0.08 * sin(u * PI) + 0.06 * u
	elif hop_t < down:
		# (and it goes over the top of the hop laid out along its way, the more so at a run)
		pitch = -0.34 * cos(air * PI) + sin(air * PI) * lerpf(0.25, 0.45, hop_run)
		kick = lerpf(1.1, -0.9, smoothstep(0.2, 1.0, air))
		paw = -0.6 - 0.5 * sin(air * PI)
		stretch = 0.06 + sin(air * PI) * lerpf(0.14, 0.24, hop_run)
	else:
		var u := clampf((hop_t - down) / HOP_SETTLE, 0.0, 1.0)
		var rest := clampf(inverse_lerp(down + HOP_SETTLE, 1.0, hop_t), 0.0, 1.0)
		pitch = 0.34 * (1.0 - u)
		kick = lerpf(-0.9, -0.35, u) * (1.0 - rest)
		paw = -0.6 * (1.0 - u)
		stretch = 0.06 * (1.0 - u)
	torso.position.y += hop_y
	torso.rotation.x += pitch
	torso.rotation.z += hop_tip * sin(air * PI)
	torso.scale.z *= 1.0 + stretch
	torso.scale.y *= 1.0 - stretch * 0.5
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		legs[i].position.y = 0.18 * legs[i].scale.y + hop_y
		if lift <= 0.05:
			legs[i].rotation.x += kick + hop_tip * side * sin(air * PI)
		arms[i].rotation.x += paw
		ears[i].rotation.x = -hop_lag - 0.1 * minf(Vector2(velocity.x, velocity.z).length(), 3.0)
		ears[i].rotation.z -= side * hop_lag * 0.2 * young
	neck.rotation.x += -pitch * 0.75 + hop_lag * 0.2
	tail.rotation.x -= hop_lag * 0.6


# ---------------------------------------------------------------- animation

func _animate(delta: float) -> void:
	var ease_fast := 1.0 - exp(-delta * 12.0)
	var ease_slow := 1.0 - exp(-delta * 5.0)
	var speed := Vector2(velocity.x, velocity.z).length()
	gait = move_toward(gait, clampf(speed / 0.7, 0.0, 1.0), delta * 5.0)
	if hops != "":
		# (one that hops has no walk: see _hop, below)
		gait = 0.0
	phase += delta * (3.0 + speed * 5.5)
	var swing := sin(phase) * gait
	# One with a foot heavy enough to mark the floor leaves a print each time one comes down
	var landed := floori((phase - PI * 0.5) / PI)
	if landed != footfall:
		footfall = landed
		if likes.has("print") and gait > 0.35 and lift < 0.02 and not airborne and jump_y < 0.02:
			var side := 1.0 if landed % 2 == 0 else -1.0
			world.leave_print(str(likes["print"]), global_transform * Vector3(absf(legs[0].position.x) * side, 0, 0.16), yaw + 0.6 * side, side, grow)
	sit = lerpf(sit, sit_goal, ease_slow)
	curl = lerpf(curl, curl_goal, ease_slow)

	# Springy squash and stretch, kicked by take-offs and landings
	squash_v += (-squash * 140.0 - squash_v * 11.0) * delta
	squash = clampf(squash + squash_v * delta, -0.3, 0.4)
	var breath := sin(anim_t * (1.3 if curl > 0.5 else 2.6)) * (0.03 if curl > 0.5 else 0.012)
	torso.position.y = stand * (1.0 - sit * 0.3 - curl * 0.7) + absf(sin(phase)) * 0.05 * gait - sit * 0.1 - curl * 0.15 + hover * (1.0 - curl) * (1.0 + sin(anim_t * 2.2) * 0.22)
	torso.rotation.x = gait * minf(speed, 3.5) * 0.07 + curl * 0.12
	torso.rotation.z = wiggle + sin(anim_t * 42.0) * float(FEELINGS[feeling]["shake"])
	torso.scale = Vector3(1.0 + squash * 0.6 + breath, 1.0 - squash + breath, 1.0 + squash * 0.6 + breath)
	if heave > 0.0:
		# It hauls its front up and forward on its flippers, and the rest of it slides up behind
		torso.scale.z *= 1.0 + sin(phase * 2.0) * heave * gait
		torso.rotation.x -= maxf(sin(phase * 2.0), 0.0) * heave * 1.6 * gait

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
	var young := clampf(inverse_lerp(adult_size, BABY_SIZE, grow), 0.0, 1.0)
	neck.scale = Vector3.ONE * head_size * lerpf(1.0, 1.28, young)
	if podge != null:
		podge.scale = podge_sizes[0].lerp(podge_sizes[1], young)
		shoulders.position.y = -baby_sink * young
		for a in arms:
			a.scale.y = reach * lerpf(1.0, 0.72, young)

	arm = arm.lerp(arm_goal, ease_fast)
	var wave := sin(anim_t * 9.0) * arm_wave
	var tuck := curl * 0.8
	# Wings beat while it is off the ground
	var lift := (1.2 + sin(anim_t * 30.0) * 0.7) if wings and airborne else 0.0
	arms[1].rotation = Vector3(arm.x - swing * 0.7 * (1.0 - curl) + wave - tuck, arm.y, arm.z + lift)
	arms[0].rotation = Vector3(arm.x + swing * 0.7 * (1.0 - curl) - wave - tuck, -arm.y, -arm.z - lift)

	# Head turns to whatever it is looking at; the pupils go the rest of the way
	var seen := torso.global_transform.affine_inverse() * gaze - neck.position - Vector3(0, head_y, 0)
	var want_yaw := clampf(atan2(seen.x, seen.z), -head_turn, head_turn)
	var want_pitch := clampf(-atan2(seen.y, Vector2(seen.x, seen.z).length()), -0.56 * head_turn, 0.4 * head_turn)
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
		eyes[i].scale = Vector3(1.0, maxf(eye_open, 0.07), 1.0) * eye_sizes[i]
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
	if decoy != null:
		_flop(delta)
	if hops != "":
		_hop(delta)

	if xrayed:
		_show_insides()
	if bubble.visible:
		bubble.global_basis = world.camera.global_basis
		bubble.position.y = top_y + stand + hover + 0.35 + sin(anim_t * 2.0) * 0.03
	if zzz[0].visible:
		var cam_right := world.camera.global_basis.x
		for i in 3:
			var u := fmod(anim_t * 0.4 + i / 3.0, 1.0)
			zzz[i].global_position = global_position + Vector3(0, (top_y + stand - 0.4) * grow + u * 0.9, 0) + cam_right * (0.3 + sin(u * 5.0) * 0.12)
			zzz[i].modulate.a = sin(u * PI) * 0.9


# ---------------------------------------------------------------- under the scanner

# Turns it to a ghost of its outline with its insides showing, or back again
func xray(on: bool) -> void:
	if on == xrayed:
		return
	if on:
		knack.over()
	xrayed = on
	if insides.is_empty():
		_build_insides()
	for part in insides:
		part.visible = on
	if on:
		scan_skin = Ps1.xray(Color(0.35, 0.85, 1.0), true)
		_ghost(self, scan_skin)
	else:
		_unghost()


# What it wore before it was turned to one stuff all over (see _ghost) is put back on it
func _unghost() -> void:
	for mi: MeshInstance3D in skin:
		if is_instance_valid(mi):
			mi.material_override = skin[mi]
	skin.clear()


# Turns the whole of it to one stuff, remembering what each part of it wore
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
	var spine := _part(chest, _capsule(0.014, maxf(top - centre_y + 0.22, 0.1)), white, Vector3(0, (top + centre_y - 0.22) * 0.5, -0.06) + gut_at)
	if gut_stretch.z > 1.0:
		# One whose insides are drawn out along it has its backbone lying along its back
		spine.position = Vector3(0, top, 0) + gut_at
		spine.rotation.x = PI * 0.5
		spine.scale.y = gut_stretch.z * 1.4
	# The rest sits about the middle of its body, smaller in a slight one
	var organs := _pivot(chest, Vector3(0, centre_y, 0) + gut_at)
	organs.scale = gut_stretch * gut
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.82
	hoop.outer_radius = 1.0
	hoop.rings = 8
	hoop.ring_segments = 3
	for i in 3:
		_part(organs, hoop, white, Vector3(0, 0.14 - i * 0.07, 0), Vector3(0.14 - i * 0.012, 0.02, 0.11))
	# (a dummy's legs have no bones in them)
	for limb in (arms if decoy != null else legs + arms):
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
