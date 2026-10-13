class_name Notebook
extends PanelContainer
## The notebook, opened from the wheel of things: the one the ticket-master of Wayside Station kept
## on the things in his cellar, and has left for whoever looks after them now. Everything the game
## has to say in words is in here, and in his words, and there are few of them: a chapter on each
## egg and cryptlin in the room and what has been found out about it (and one kept for each that
## has died), and then one short leaf to start the keeper off, with the sound on it. How anything
## works is not written down: that is for the keeper to find out by trying.
##
## It is drawn at the size of the screen, not of the room's small picture, in a typewriter face.
## It is sized to the screen with a margin all round (see fit), and a chapter that is too long
## for one leaf runs on over as many as it needs (see _lay_out): nothing is ever cut off.

const INK := Color(0.17, 0.14, 0.2)
const FAINT := Color(0.17, 0.14, 0.2, 0.55)
const PAPER := Color(0.87, 0.82, 0.68)
# Special Elite, a worn typewriter (Apache License 2.0: see fonts/SpecialElite-LICENSE.txt)
const FACE: FontFile = preload("res://fonts/SpecialElite-Regular.ttf")
# What the notebook is called, on its cover and at the head of every leaf
const TITLE := "Cryptlin Handbook"
const TITLE_SIZE := 18
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
const FOOT_WIDE := 84.0
const FOOT_NARROW := 72.0
# The one chapter that comes after those for each of those in the room, and all it says: enough
# to start on and no more. The rest is for the keeper to find out.
const TITLES: Array[String] = ["To the keeper"]
const HELP: Array[String] = [
	"The cellar is yours now, and so are they.",
	"They want feeding, and they want company.",
	"The lamp answers to a tap.",
	"What rides the wheel can be dragged up into the room.",
	"The gun reads what the eye cannot.",
	"The rest they will show you, and it goes down in here.",
]
# What that leaf goes on to say inside the station, where there is a ticket counter to send the
# keeper to (the Shop button at its foot goes there) and a show every Friday
const COUNTER: Array[String] = [
	"Food, toys, things for the room and eggs are to be had for tickets at the counter upstairs.",
	"Fridays the station judges the best kept cryptlin: the week's keeping counts, not the morning's. The best three get tickets and a rosette to pin on, and the first a brass cup for the cellar.",
]
# What is said of one that wears a rosette, by its place (first, second, third)
const PLACES: Array[String] = ["First at the Friday show.", "Second at the Friday show.", "Third at the Friday show."]
# What is said of an egg, after what is painted on it
const EGG := "Nobody can say what is in it until it is out. It is cold to the touch."
# A line or two on each kind: what it looks like and how it struck him. What it needs is the
# keeper's to work out, and is hinted at here at most.
const KIND_NOTES: Array[String] = [
	"Ears, a tail and teeth. The least trouble of the lot, which is not saying much.",
	"A young sasquatch. It eats like a platelayer and does not care to be looked at.",
	"The snake is the animal. The rooster on the front of it is stuffed. Do not let on that you know.",
	"All eyes and wings, and worn out sooner than you would think.",
	"Thin as a rail and always hungry. It lurks.",
	"A frog that stands up. It came in off the river and has not forgotten it.",
	"A hump, four flippers and a great deal of neck. Not built for dry land.",
	"A whale off the high slopes. Always starving.",
	"A deer's skull on something thin. It is never full. I feed it first.",
	"A water horse's foal, all legs. Off like the down express when the mood takes it.",
	"A fish that walks. It walks better wet.",
	"A soft head with feelers where the mouth ought to be. It smells of low tide, and it watches.",
	"Stout, under a hat as tall as itself. Fond of a dance.",
	"A slip of a thing on four wings, with a light of its own. Never still.",
	"A toadstool that got up and walked. The easiest lodger I have had.",
	"A hare with antlers coming in. More spring than sense.",
	"A big head, long hands and two black eyes. It stares.",
	"A great soft heap of white fur with a small face low down. It was not made for a warm room.",
	"Three heads on one pup. All three are hungry.",
	"One of the people from underneath. The light is not kind to its eyes.",
	"A pair of white legs with a lump of a head on top. It would sooner stand than sit.",
	"Wings, and some come in a little jacket. Loud, and up on top of things.",
	"Stout and tusked, with wings a size too small for it. It roots.",
	"Tall, in a skirt like pleated tin. It does not walk, it glides.",
	"A horse's head, a bat's wings, a goat's legs and a fork to its tail. Loud.",
	"Fat and red, with teeth at one end and no eyes anywhere. It is a long way from the desert.",
	"A short wide heap of sandy hair with its knuckles on the floor. Hard on its things.",
	"The colour of ash, and you can see the wall through it.",
	"A small flying lizard with a beak full of teeth. Loud.",
	"A small person down to the waist and a fish from there on. Dry floor does not suit it.",
]
# How it seems to be, by the face it last pulled (Cryptlin.FEELINGS)
const MOODS: Array[String] = [
	"Content enough.",
	"Happy just now.",
	"Excited about something.",
	"In a loving mood.",
	"Hungry.",
	"Bored.",
	"Sleepy.",
	"In a temper.",
	"Frightened of something.",
	"Low in itself.",
	"Disgusted.",
	"Poorly.",
]
# What begins a row of the list of what has been found out: such a row is set close under the
# paragraph before it, with no gap between
const ROW := "\t"

var world: Den
# The leaf it is open at, counted from the first, and which chapter that is and which leaf of it
var page := 0
var chapter := 0
var part := 0
# Every leaf there is just now, in order: its chapter, which leaf of that it is, and its words
var leaves: Array[Dictionary] = []
var title: Label
var heading: Label
var leaf: Control
var body: Label
var folio: Label
var rename: IconButton
var sound: IconButton
var let_go: IconButton
var shop: IconButton
var foot_buttons: Array[Button] = []


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
	# Its name, as it is lettered on the cover, across the top of every leaf
	title = _line(rows, TITLE_SIZE, FAINT)
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	# (inside the station only: the way to the ticket counter upstairs)
	shop = world.icon_button(foot, "ticket", world.to_shop, "Shop")
	shop.visible = false
	for b: Button in [rename, let_go, sound, shop]:
		b.custom_minimum_size = Vector2(84, FOOT_TALL)
	folio = _line(foot, 19, FAINT)
	folio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b: Button in [back, world.icon_button(foot, "right", turn.bind(1)), world.icon_button(foot, "check", close)]:
		b.custom_minimum_size = Vector2(84, FOOT_TALL)
	for b in foot.get_children():
		if b is Button:
			foot_buttons.append(b)


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
	var tall := size.y - paper.get_margin(SIDE_TOP) - paper.get_margin(SIDE_BOTTOM) - title.get_minimum_size().y - heading.get_minimum_size().y - FOOT_TALL - GAP * 3
	return Vector2(maxf(wide, 40.0), maxf(tall, 40.0))


# How tall some words stand when they are wrapped to a width, as the page's label sets them
func _tall(text: String, wide: float) -> float:
	var set_out := TextParagraph.new()
	set_out.width = wide
	set_out.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	set_out.add_string(text, FACE, BODY_SIZE)
	return set_out.get_size().y + LINE_GAP * (set_out.get_line_count() - 1) + 2.0


# Sets every chapter out over as many leaves as it needs at the size the notebook is, which is
# one for nearly all of them: paragraph by paragraph and row by row of the list, a new leaf
# only when the next will not fit (so a leaf is full before the chapter runs on), and a
# paragraph too long for a leaf by itself broken between two words.
func _lay_out() -> void:
	leaves.clear()
	for which in chapters():
		var held: Array[String] = []
		var count := 0
		for para in _words_of(which):
			var room := _room()
			if not held.is_empty() and _tall(_set_out(held + [para]), room.x) > room.y:
				leaves.append({"chapter": which, "part": count, "text": _set_out(held)})
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
		leaves.append({"chapter": which, "part": count, "text": _set_out(held)})


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
	shop.visible = world.embedded
	# (with all of them on the one leaf, each gives up a little of its width)
	for b in foot_buttons:
		b.custom_minimum_size.x = FOOT_NARROW if shop.visible and rename.visible else FOOT_WIDE
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
	return _set_out(_words_of(chapter if which < 0 else which))


# Some paragraphs as they stand on a leaf: a gap between one and the next, and none between
# two rows of the list
func _set_out(paras: Array) -> String:
	var text := ""
	var row := false
	for para: String in paras:
		var next := para.begins_with(ROW)
		if text != "":
			text += "\n" if row and next else "\n\n"
		text += para.trim_prefix(ROW)
		row = next
	return text


# What a chapter says, a paragraph at a time
func _words_of(which: int) -> Array[String]:
	var all := everyone()
	if which >= all.size():
		return _help()
	var r := all[which]
	if r.pet != null:
		return _paras(r.pet)
	if r.egg != null:
		return ["%s.%s" % [r.egg.title(), _parents(r, " Its parents are %s and %s.")], EGG]
	return _remembrance(r)


# A line about the parents of one that was bred in the room, or nothing for one that was not
func _parents(r: Resident, line: String) -> String:
	return line % r.parent_names if r.parent_names.size() == 2 else ""


# The chapter kept for one that has died: what it was, how long it lived, and as much of its
# tastes as was ever found out
func _remembrance(r: Resident) -> Array[String]:
	var paras: Array[String] = [
		"%s.%s" % [_a(Cryptlin.KINDS[r.kind]["title"]), _parents(r, " Its parents were %s and %s.")],
		"It lived %s, and is gone.%s%s" % [_span(r.lived), _placed(r), _stone(r)],
	]
	var was := Cryptlin.profile(r.kind, r.look_seed, r.tastes)
	paras.append_array(_found(r.known, false, was["food"], was["yuck"], was["toy"], was["ground"], was["lamp"], was["decor"], was["hates"], Cryptlin.KINDS[r.kind].get("water", false), r.kind, [
		"Ate gladly", "Would not touch", "Best toy", "Floor it liked", "Lamp it liked", "Liked about the place", "Could not abide", "Wanted water", "Its knack",
	]))
	return paras


# The keeper's leaf. Inside the station it has the counter and the show to tell of as well, and
# is set closer to keep it to the one leaf.
func _help() -> Array[String]:
	if not world.embedded:
		return HELP
	var leaf: Array[String] = [" ".join(HELP.slice(0, 2)), " ".join(HELP.slice(2))]
	leaf.append_array(COUNTER)
	return leaf


# A few words on the rosette one of them wears, or nothing
func _placed(r: Resident) -> String:
	return " " + PLACES[r.rosette - 1] if r.rosette > 0 else ""


# A few words on the gravestone of one that died, if the keeper still has it: standing in the
# room, or put away
func _stone(r: Resident) -> String:
	for d in world.decors:
		if d.kind == Decor.Kind.GRAVESTONE and d.whose == r.id:
			return " Its stone stands in the cellar."
	for kept: Variant in world.markers_away:
		if kept is Dictionary and int(kept.get("w", 0)) == r.id:
			return " Its stone is put by."
	return ""


# What is known of this cryptlin, in paragraphs: what it is, how old and how it seems, and then
# only what it has shown of itself, a row for each thing as it is found out (the test panel
# gives them all away). A page begins nearly empty, and fills.
func _paras(pet: Cryptlin) -> Array[String]:
	var paras: Array[String] = [
		"%s. %s%s" % [_a("baby " + pet.kind_name() if pet.is_baby() else pet.kind_name()), KIND_NOTES[pet.kind], _parents(pet.me, " Its parents are %s and %s.")],
		"Hatched %s ago. %s%s" % [_span(Time.get_unix_time_from_system() - pet.me.born), MOODS[pet.feeling], _placed(pet.me)],
	]
	paras.append_array(_found(pet.me.known, world.dev.visible, pet.fav_food, pet.yuck_food, pet.fav_toy, pet.fav_ground, pet.fav_lamp, pet.like_decor, pet.hate_decor, pet.needs_water(), pet.kind, [
		"Eats gladly", "Will not touch", "Best toy", "Floor it likes", "Lamp it likes", "Likes about the place", "Cannot abide", "Wants water", "Its knack",
	]))
	return paras


# The same as one run of words, as it stands on its leaves
func _notes(pet: Cryptlin) -> String:
	return _set_out(_paras(pet))


# A thing with "a" or "an" before it, to begin a sentence
func _a(what: String) -> String:
	return ("An " if what.left(1).to_lower() in "aeiou" else "A ") + what


# The rows of the list: one for each thing that has been found out (or, with `open`, for every
# one), under the names in `heads`, and nothing at all for what has not
func _found(known: Dictionary, open: bool, food: int, yuck: int, toy: int, ground: int, lamp: int, liked: Array, hated: int, wet: bool, kind: int, heads: Array[String]) -> Array[String]:
	var likes: Array[String] = []
	for thing: int in liked:
		if open or known.get("decor+" + Decor.IDS[thing], false):
			likes.append("the " + Decor.PLAIN[thing])
	var rows: Array[String] = []
	var all := [
		[open or known.get("food", false), Snack.PLURALS[food]],
		[open or known.get("yuck", false), Snack.PLURALS[yuck]],
		[open or known.get("toy", false), "the " + Ball.PLAIN[toy]],
		[open or known.get("ground", false), Den.GROUND_PLAIN[ground]],
		[open or known.get("lamp", false), Den.LAMPS[lamp]["title"]],
		[not likes.is_empty(), ", ".join(likes)],
		[open or known.get("decor-" + Decor.IDS[hated], false), "the " + Decor.PLAIN[hated]],
		[open or known.get("water", false), "a pool to wade in" if wet else "no more than a drink"],
		[open or known.get("knack", false), "it %s." % Knack.NOTES[kind]],
	]
	for i in all.size():
		if all[i][0]:
			rows.append("%s%s: %s" % [ROW, heads[i], all[i][1]])
	return rows


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
