class_name Notebook
extends PanelContainer
## The notebook, opened from the wheel of things: the one the ticket-master of Wayside Station kept
## on the things in his cellar, and has left for whoever looks after them now. Everything the game
## has to say in words is in here, and in his words: a chapter on each egg and cryptlin in the room
## and what has been found out about it (and one kept for each that has died), then how to look
## after them, the wheel of things, what a hand can do, and the odds and ends (the sound).
##
## It is drawn at the size of the screen, not of the room's small picture, in a typewriter face.
## It is sized to the screen with a margin all round (see fit), and a chapter that is too long
## for one leaf runs on over as many as it needs (see _lay_out): nothing is ever cut off.

const INK := Color(0.17, 0.14, 0.2)
const FAINT := Color(0.17, 0.14, 0.2, 0.55)
const PAPER := Color(0.87, 0.82, 0.68)
# Special Elite, a worn typewriter (Apache License 2.0: see fonts/SpecialElite-LICENSE.txt)
const FACE: FontFile = preload("res://fonts/SpecialElite-Regular.ttf")
const HEAD_SIZE := 31
const BODY_SIZE := 21
const LINE_GAP := 4
# How far in from every edge of the screen it keeps, how big it gets at most, and the least it
# will be made however small the screen
const EDGE := 20.0
const MOST := Vector2(640.0, 940.0)
const LEAST := Vector2(320.0, 380.0)
# What is on a leaf besides its words: the gap between the rows, and how tall the row at the
# foot is (the leaves either way, the means of renaming and letting go or the sound, and shut)
const GAP := 10
const FOOT_TALL := 68.0
# The chapters that come after the one for each of those in the room
const TITLES: Array[String] = ["Standing orders", "What is on the wheel", "What a hand can do", "Odds and ends"]
const CARE: Array[String] = [
	"You have the cellar now, so these are yours. I kept them going between trains. It is not hard work, only regular.",
	"They keep the station clock, whether you are down here or not. Miss a day and they have lived it without you.",
	"Feed each of them once or twice a day. A full belly lasts most of a day. Food goes to whoever gets to it first, so see the shy ones are not left out.",
	"Give them a toy when they mope. A hatchling is grown in a day or two.",
	"They sleep when they are worn out. Put the lamp out last thing and they take themselves off to the nest.",
	"They leave droppings. Sweep them up with the broom, or the place is spoiled for them. Puddles dry on their own in an hour.",
	"They do not all get on. Two that have fallen out will come to blows. A tap on the scuffle parts them and nobody is hurt.",
	"Two grown ones that are fond of each other, fed and settled, may pair off. Some hours later there is an egg in the nest, if there is room for one more. I never arranged it and neither can you.",
	"One left hungry for days sickens, and in the end it dies. There is a marker or two down there to show for it.",
	"Each kind has one trick that none of the others has. I have not written them out for you. Watch, and it goes in the book when you have seen it.",
	"The scanner shows what goes on inside one: how full it is, how rested, how amused, how fond of you, how well, and whether it likes its home. Drag it up onto the one you mean.",
]
const SHELF: Array[String] = [
	"Everything you have rides the wheel at the bottom, the scanner first and this book last. Turn it sideways to see the rest.",
	"Tap a thing to use it, or drag it up off the wheel and let go where you want it. What is out in the cellar is not on the wheel. Put it away and it is back in its place.",
	"An egg is one more mouth. The cellar holds four, eggs and all.",
	"Food gets eaten. When a thing runs out it is off the wheel until more comes down.",
	"Toys get thrown. Pick one up and throw it again, or carry it down to the wheel to put it away.",
	"Toys do not last. Play wears them and you will see it coming: scuffed first, then patched and sagging. Then one kick too many and you have the pieces to sweep up. The rough ones get through a toy quickest. One you paid for is gone for good. The station ball I can replace, though not the same day.",
	"The broom and pan are always there. Drag them up and over a mess and it is swept. Or tap the broom and it sees to one by itself. Tapping the mess does nothing. I tried.",
	"Rocks, logs and the like stay where you put them, and can be dragged about. They will sit on them, drink from them and hide in them.",
	"To put a thing away, pick it up off the floor and carry it down onto the wheel. The wheel turns to show its place. Let go there and it is put away. Let go anywhere else and you have only moved it. Whatever was sitting in it gets out, and lets you know what it thinks.",
	"The pool puts half the floor under water. A finger on the water has hold of it: drag it to another side, or down to the wheel. Those that live in water wade about in it and sleep at its edge. The rest keep to the dry, come down for a drink, and are cross if they are put in. Nothing else will stand in it. Food and toys float.",
	"A tray of ground changes the floor. A nest changes their bed.",
	"Each of them has its own idea of a good home, and one cellar cannot please them all. The marks on the wheel are what you know of the one you last touched.",
]
const HANDS: Array[String] = [
	"Tap the floor and they come.",
	"Hold and drag on the floor to swing the lamp. They chase the light.",
	"Tap the lamp to change it: bright, low, heat, off.",
	"Rub one to pet it. Tap it to poke it. Four pokes running is one too many.",
	"Hold a finger on one to pick it up. Flick it to send it sliding. Some take it better than others.",
	"Drag the nest to move it. It may well get dragged back.",
	"An egg wants warmth: the lamp, and the heat lamp most of all. Rub it to warm it faster. Tap it and it knocks back. I never got used to that.",
]
const ODDS: Array[String] = [
	"Each of them has a page at the front of this book. One that has hatched can be given a new name there, or let go. It walks off into the dark and that is the last of it. I do not ask where they go.",
	"One that dies keeps its page. It seemed wrong to tear them out.",
]
# The last of the odds and ends, by whether eggs come for nothing (the game played by itself) or
# are the keeper's own to bring (inside the station's page)
const EMPTY_FREE := "An empty cellar does not stay empty. An egg turns up. I have stopped wondering who sends them."
const EMPTY_POSTED := "An empty cellar stays empty until you bring an egg down yourself. It will be on the wheel when you have one."
const QUIET := "The noise they make can be shut off below. The trains you will have to put up with."
# A line on each kind: what anybody can see of it, and nothing that has to be found out
const KIND_NOTES: Array[String] = [
	"Ears, a tail and teeth. The plainest of them and the least trouble, which is not saying much.",
	"A young sasquatch. Slow, heavy and shy, and it eats like a platelayer.",
	"The snake is the animal. The rooster on the front of it is stuffed, and the snake is its tail. Do not let on that you know.",
	"All eyes and wings. Quick and squeaky, and worn out sooner than you would think.",
	"Thin as a rail and always hungry. It lurks.",
	"A frog that stands up. It jumps higher than is decent, and likes a dance.",
	"A hump, four flippers and a great deal of neck. Slow on land, shy, and seldom tired.",
	"A whale off the high slopes. It heaves itself about and is always starving.",
	"A deer's skull on something thin. It is never full and it keeps to the dark. I feed it first.",
	"A water horse's foal, all legs. Fast, and off like the down express when the mood takes it.",
	"A fish that walks. It stares, and it dances.",
	"A soft head with feelers where the mouth ought to be. Slow and deep in the voice. It watches.",
	"Stout, under a hat as tall as itself. Fond of a dance.",
	"A slip of a thing on four wings, with a light of its own. Never still, and soon tired.",
	"A toadstool that got up and walked. Slow and quiet, and it eats little. The easiest lodger I have had.",
	"A hare with antlers coming in. More spring than sense.",
	"A big head, long hands and two black eyes. It stares more than all the rest together.",
	"A great soft heap of white fur with a small face low down. Gentle, heavy and hungry.",
	"Three heads on one pup. The middle one leads. All three are hungry.",
	"One of the people from underneath. Slow and short in the sight, and it digs up everything.",
]
# And on each nature (Cryptlin.NATURES): each of them has two
const NATURE_NOTES: Array[String] = [
	"Greedy: first to the food and last to leave it.",
	"Playful: bores quickly, and is hard on its toys.",
	"Shy: hangs back, and watches from cover.",
	"Sleepy: tires early. Let it lie.",
	"Cuddly: likes a hand on it, and sulks if it is pushed.",
	"Bold: pushes in, and will stare you out.",
	"Grumpy: quick to take offence, and rough with its things.",
	"Restless: never in one place for long.",
]
# How it seems to be, by the face it last pulled (Cryptlin.FEELINGS)
const MOODS: Array[String] = [
	"Content enough, by the look of it.",
	"Happy just now.",
	"Excited about something.",
	"In a loving mood.",
	"Hungry. It will tell you so itself.",
	"Bored. Find it something to do.",
	"Sleepy.",
	"In a temper.",
	"Frightened of something.",
	"Low in itself.",
	"Disgusted, and letting it show.",
	"Poorly. Feed it and let it rest, and it should mend in a couple of days. Leave it and it will not.",
]

var world: Den
# The leaf it is open at, counted from the first, and which chapter that is and which leaf of it
var page := 0
var chapter := 0
var part := 0
# Every leaf there is just now, in order: its chapter, which leaf of that it is, and its words
var leaves: Array[Dictionary] = []
var heading: Label
var leaf: Control
var body: Label
var folio: Label
var rename: IconButton
var sound: IconButton
var let_go: IconButton


func _init(den: Den) -> void:
	world = den
	clip_contents = true
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = Color(0.34, 0.12, 0.1)
	paper.set_border_width_all(3)
	paper.border_width_left = 14
	paper.set_corner_radius_all(8)
	paper.set_content_margin_all(22)
	paper.content_margin_left = 34
	add_theme_stylebox_override("panel", paper)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", GAP)
	add_child(rows)
	heading = _line(rows, HEAD_SIZE, INK)
	heading.clip_text = true
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# The words sit in a frame of their own, so that however many there are it is the frame and
	# not the words that the notebook is sized by
	leaf = Control.new()
	leaf.clip_contents = true
	leaf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(leaf)
	body = _line(leaf, BODY_SIZE, INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", LINE_GAP)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	rows.add_child(foot)
	var back := world.icon_button(foot, "left", turn.bind(-1))
	rename = world.icon_button(foot, "pencil", func() -> void: world.open_namer(resident()), "Rename")
	let_go = world.icon_button(foot, "moon", func() -> void: world.ask_let_go(resident()), "Let go")
	sound = world.icon_button(foot, "sound_on", world.toggle_sound, "Sound")
	for b: Button in [rename, let_go, sound]:
		b.custom_minimum_size = Vector2(84, FOOT_TALL)
	folio = _line(foot, 19, FAINT)
	folio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b: Button in [back, world.icon_button(foot, "right", turn.bind(1)), world.icon_button(foot, "check", close)]:
		b.custom_minimum_size = Vector2(84, FOOT_TALL)


func _line(parent: Node, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FACE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


# Fills an upright phone and sits in the middle of a wide screen, clear of every edge
func fit(screen: Vector2) -> void:
	size = (screen - Vector2(EDGE, EDGE) * 2.0).clamp(LEAST, MOST)
	position = ((screen - size) * 0.5).round()
	if visible:
		refresh()


# Opens at the page of the one in question
func open() -> void:
	if world.finger != -1:
		world._release()
	world.stop_scan()
	open_at(maxi(everyone().find(world.who()), 0))
	world.sfx.play("click")


# Shows the first leaf of a chapter
func open_at(which: int) -> void:
	chapter = which
	part = 0
	visible = true
	refresh()


func close() -> void:
	visible = false
	world.sfx.play("click", 0.8)


# Those with a chapter of their own: all that live in the room, then those that have died
func everyone() -> Array[Resident]:
	return world.residents + world.departed


# How many chapters there are just now: one for each of them, and the rest
func chapters() -> int:
	return everyone().size() + TITLES.size()


# How many leaves there are just now, all the chapters together
func pages() -> int:
	return leaves.size()


func turn(by: int) -> void:
	_lay_out()
	page = posmod(page + by, pages())
	chapter = leaves[page]["chapter"]
	part = leaves[page]["part"]
	refresh()
	world.sfx.play("click", 1.1)


# Whose chapter it is open at, or null in the chapters that are about no one of them
func resident() -> Resident:
	return everyone()[chapter] if chapter < everyone().size() else null


# How wide the words can run, and how tall: what the frame of a leaf comes to at the size the
# notebook is
func _room() -> Vector2:
	var paper := get_theme_stylebox("panel")
	var wide := size.x - paper.get_margin(SIDE_LEFT) - paper.get_margin(SIDE_RIGHT)
	var tall := size.y - paper.get_margin(SIDE_TOP) - paper.get_margin(SIDE_BOTTOM) - heading.get_minimum_size().y - FOOT_TALL - GAP * 2
	return Vector2(maxf(wide, 40.0), maxf(tall, 40.0))


# How tall some words stand when they are wrapped to a width, as the page's label sets them
func _tall(text: String, wide: float) -> float:
	var set_out := TextParagraph.new()
	set_out.width = wide
	set_out.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	set_out.add_string(text, FACE, BODY_SIZE)
	return set_out.get_size().y + LINE_GAP * (set_out.get_line_count() - 1) + 2.0


# Sets every chapter out over as many leaves as it needs at the size the notebook is: paragraph
# by paragraph, a new leaf whenever the next will not fit, and a paragraph too long for a leaf by
# itself broken between two words.
func _lay_out() -> void:
	leaves.clear()
	for which in chapters():
		var held: Array[String] = []
		var count := 0
		for para in _words_of(which):
			var room := _room()
			if not held.is_empty() and _tall("\n\n".join(held + [para]), room.x) > room.y:
				leaves.append({"chapter": which, "part": count, "text": "\n\n".join(held)})
				held = []
				count += 1
			var rest: String = para
			while held.is_empty() and _tall(rest, room.x) > room.y:
				var words := rest.split(" ")
				var most := 1
				var low := 1
				var high := words.size() - 1
				while low <= high:
					var mid := (low + high) / 2
					if _tall(" ".join(words.slice(0, mid)), room.x) <= room.y:
						most = mid
						low = mid + 1
					else:
						high = mid - 1
				if words.size() < 2:
					break
				leaves.append({"chapter": which, "part": count, "text": " ".join(words.slice(0, most))})
				count += 1
				rest = " ".join(words.slice(most))
			held.append(rest)
		leaves.append({"chapter": which, "part": count, "text": "\n\n".join(held)})


func refresh() -> void:
	chapter = clampi(chapter, 0, chapters() - 1)
	_lay_out()
	# The leaf it was open at, or the last of its chapter if that has got shorter
	page = 0
	for i in leaves.size():
		if leaves[i]["chapter"] == chapter and leaves[i]["part"] <= part:
			page = i
	part = leaves[page]["part"]
	var r := resident()
	var pet := r.pet if r != null else null
	var rest := chapter - everyone().size()
	rename.visible = pet != null
	let_go.visible = pet != null
	let_go.disabled = r != null and r.leaving
	sound.visible = rest == TITLES.size() - 1
	sound.symbol = "sound_off" if world.sfx.muted else "sound_on"
	sound.caption = "Muted" if world.sfx.muted else "Sound"
	folio.text = "%d / %d" % [page + 1, pages()]
	body.text = leaves[page]["text"]
	if pet != null:
		heading.text = r.name
	elif r != null and r.egg != null:
		heading.text = "An egg"
	elif r != null:
		heading.text = "%s, gone" % r.name
	else:
		heading.text = TITLES[rest]


# Everything a chapter says, over however many leaves (the one it is open at, if none is given)
func said(which := -1) -> String:
	return "\n\n".join(_words_of(chapter if which < 0 else which))


# What a chapter says, a paragraph at a time
func _words_of(which: int) -> Array[String]:
	var all := everyone()
	if which >= all.size():
		match which - all.size():
			0:
				return CARE
			1:
				return SHELF
			2:
				return HANDS
		var odds := ODDS.duplicate()
		odds.append(EMPTY_POSTED if world._inside_a_page() else EMPTY_FREE)
		odds.append(QUIET)
		return odds
	var r := all[which]
	var paras: Array[String] = []
	if r.pet != null:
		paras.assign(_notes(r.pet).split("\n\n"))
	elif r.egg != null:
		paras.append("%s.%s" % [r.egg.title(), _parents(r, " Laid in the nest down here. Its parents are %s and %s.")])
		paras.append("I cannot tell you what is in it. Nobody can, until it is out.")
		paras.append("Keep it warm and it will hatch. The lamp does it slowly, the heat lamp quicker, and a hand rubbing it quickest of all.")
	else:
		paras.assign(_remembrance(r).split("\n\n"))
	return paras


# A line about the parents of one that was bred in the room, or nothing for one that was not
func _parents(r: Resident, line: String) -> String:
	return line % r.parent_names if r.parent_names.size() == 2 else ""


# The chapter kept for one that has died: what it was, how long it lived, and as much of its
# tastes as was ever found out
func _remembrance(r: Resident) -> String:
	var was := Cryptlin.profile(r.kind, r.look_seed)
	var both := Cryptlin.natures(r.kind, r.look_seed, r.nature)
	var known := r.known
	var likes: Array[String] = []
	for kind: int in was["decor"]:
		if known.get("decor+" + Decor.IDS[kind], false):
			likes.append("the " + Decor.PLAIN[kind])
	var hated: int = was["hates"]
	var water := "yes, a pool to wade in" if Cryptlin.KINDS[r.kind].get("water", false) else "no more than a drink"
	return "A %s, %s %s.%s

It lived %s, and is gone. Its marker stands where it lay. I have left what I knew of it.

Ate gladly: %s
Would not touch: %s
Best toy: %s
Floor it liked: %s
Lamp it liked: %s
Liked about the place: %s
Could not abide: %s
Wanted water: %s" % [
		Cryptlin.NATURES[both[0]]["title"], Cryptlin.NATURES[both[1]]["title"], Cryptlin.KINDS[r.kind]["title"], _parents(r, " Its parents were %s and %s."), _span(r.lived),
		Snack.PLURALS[was["food"]] if known.get("food", false) else "?",
		Snack.PLURALS[was["yuck"]] if known.get("yuck", false) else "?",
		"the " + Ball.PLAIN[was["toy"]] if known.get("toy", false) else "?",
		Den.GROUND_PLAIN[was["ground"]] if known.get("ground", false) else "?",
		Den.LAMPS[was["lamp"]]["title"] if known.get("lamp", false) else "?",
		", ".join(likes) if not likes.is_empty() else "?",
		"the " + Decor.PLAIN[hated] if known.get("decor-" + Decor.IDS[hated], false) else "?",
		water if known.get("water", false) else "?",
	]


# What is known of this cryptlin, in paragraphs. Its tastes are blank until it has shown them
# (the test panel gives them away).
func _notes(pet: Cryptlin) -> String:
	var open := world.dev.visible
	var known := pet.me.known
	var likes: Array[String] = []
	for kind in pet.like_decor:
		if open or known.get("decor+" + Decor.IDS[kind], false):
			likes.append("the " + Decor.PLAIN[kind])
	var hates: String = Decor.PLAIN[pet.hate_decor]
	var water := "yes, a pool to wade in" if pet.needs_water() else "no more than a drink"
	var grown := "Hatched %s ago, and full grown." % _span(Time.get_unix_time_from_system() - pet.me.born)
	if pet.is_baby():
		grown = "Hatched %s ago. Grown in about %s." % [_span(Time.get_unix_time_from_system() - pet.me.born), _span(pet.growing_left())]
	return "A %s %s%s.%s %s

%s
%s

%s %s

What they show you, write down. I did.

Eats gladly: %s
Will not touch: %s
Best toy: %s
Floor it likes: %s
Lamp it likes: %s
Likes about the place: %s
Cannot abide: %s
Wants water: %s
Its knack: %s" % [
		pet.nature_name(), "baby " if pet.is_baby() else "", pet.kind_name(), _parents(pet.me, " Hatched from an egg laid down here. Its parents are %s and %s."), KIND_NOTES[pet.kind],
		NATURE_NOTES[pet.nature], NATURE_NOTES[pet.nature2],
		grown, MOODS[pet.feeling],
		Snack.PLURALS[pet.fav_food] if open or known.get("food", false) else "?",
		Snack.PLURALS[pet.yuck_food] if open or known.get("yuck", false) else "?",
		"the " + Ball.PLAIN[pet.fav_toy] if open or known.get("toy", false) else "?",
		Den.GROUND_PLAIN[pet.fav_ground] if open or known.get("ground", false) else "?",
		Den.LAMPS[pet.fav_lamp]["title"] if open or known.get("lamp", false) else "?",
		", ".join(likes) if not likes.is_empty() else "?",
		"the " + hates if open or known.get("decor-" + Decor.IDS[pet.hate_decor], false) else "?",
		water if open or known.get("water", false) else "?",
		"it %s." % Knack.NOTES[pet.kind] if open or known.get("knack", false) else "?",
	]


# A length of time in the two biggest units that matter: "1 day 3 hours", "40 minutes"
func _span(seconds: float) -> String:
	var minutes := int(maxf(seconds, 0.0) / 60.0)
	if minutes < 1:
		return "a moment"
	if minutes < 60:
		return "%d minute%s" % [minutes, "" if minutes == 1 else "s"]
	var hours := minutes / 60
	if hours < 24:
		return "%d hour%s" % [hours, "" if hours == 1 else "s"]
	var days := hours / 24
	hours %= 24
	var text := "%d day%s" % [days, "" if days == 1 else "s"]
	return text if hours == 0 else "%s %d hour%s" % [text, hours, "" if hours == 1 else "s"]
