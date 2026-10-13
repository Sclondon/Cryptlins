class_name Notebook
extends PanelContainer
## The keeper's notebook, opened from the shelf. Everything the game has to say in words is in
## here: a page on each egg and cryptlin in the room and what has been found out about it, how
## to look after them, what a finger can do, and the few odds and ends (the sound).

const INK := Color(0.17, 0.14, 0.2)
const FAINT := Color(0.17, 0.14, 0.2, 0.55)
const PAPER := Color(0.87, 0.82, 0.68)
# The pages that come after the one for each of those in the room
const TITLES: Array[String] = ["Looking after them", "The shelf", "Hands", "Odds and ends"]
const CARE := "They live by the clock on the wall, whether you are here or not.

Feed each once or twice a day. A full belly lasts most of a day. Food is for whoever gets to it first.

Play with them when they are bored. One takes a day or two to grow up.

They sleep when they are worn out. Put the lamp out at night and they go to the nest.

They leave droppings. Tap one to clear it up: they spoil the place. Puddles dry by themselves.

They do not all get on. Two that have fallen out may fight: a tap on the scuffle breaks it up.

The scanner on the shelf shows what is going on inside one: how full its stomach is, how rested and how amused it is, how fond of you, and whether it likes its home. Drag it up onto the one you mean."
const SHELF := "Everything you have is on the shelf. Slide it sideways to see the rest.

Tap a thing to put it in, or drag it up off the shelf and let go where you want it.

An egg is one more for the room, which holds four.

Food gets eaten. Toys get thrown: pick one up and throw it again.

Rocks, logs and the like stay put. Drag them about, or back down to the shelf to put them away. They will sit on them, drink from them, wade in them and hide in them.

A tray of ground changes the floor. A nest changes their bed.

Every cryptlin has its own idea of a good home, and one room cannot please them all. The marks on the shelf are what you know of the one you last touched."
const HANDS := "Tap the floor to call them.

Hold and drag on the floor to swing the lamp. They chase the light.

Tap the lamp to change it: bright, low, heat, off.

Rub one to pet it. Tap it to poke it.

Hold a finger on one to pick it up. Flick it to push it.

Drag the nest to move it. It may well get dragged back.

An egg wants warmth: the lamp, and the heat lamp most of all. Rub it to warm it faster. Tap it and it knocks back."
const ODDS := "Each of them has a page at the front of this book. A cryptlin can be given a new name there, or let go: it walks off into the dark for good.

A room with nobody left in it is sent an egg."

var world: Den
var page := 0
var heading: Label
var body: Label
var tools: HBoxContainer
var folio: Label
var rename: IconButton
var sound: IconButton
var let_go: IconButton


func _init(den: Den) -> void:
	world = den
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = Color(0.34, 0.12, 0.1)
	paper.set_border_width_all(3)
	paper.border_width_left = 14
	paper.set_corner_radius_all(8)
	paper.set_content_margin_all(26)
	paper.content_margin_left = 36
	add_theme_stylebox_override("panel", paper)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	add_child(rows)
	heading = _line(rows, 32, INK)
	body = _line(rows, 21, INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("line_spacing", 3)
	tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 12)
	rows.add_child(tools)
	rename = world.icon_button(tools, "pencil", func() -> void: world.open_namer(resident()), "Rename")
	let_go = world.icon_button(tools, "moon", func() -> void: world.ask_let_go(resident()), "Let go")
	sound = world.icon_button(tools, "sound_on", world.toggle_sound, "Sound")
	for b: Button in [rename, let_go, sound]:
		b.custom_minimum_size = Vector2(124, 104)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	rows.add_child(foot)
	var back := world.icon_button(foot, "left", turn.bind(-1))
	folio = _line(foot, 20, FAINT)
	folio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b: Button in [back, world.icon_button(foot, "right", turn.bind(1)), world.icon_button(foot, "check", close)]:
		b.custom_minimum_size = Vector2(84, 72)


func _line(parent: Node, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


# Fills the screen on a phone, and sits in the middle of a wide one
func fit(screen: Vector2) -> void:
	var wide := minf(screen.x - 40.0, 620.0)
	var tall := minf(screen.y - 40.0, 900.0)
	size = Vector2(wide, tall)
	position = (screen - size) * 0.5


# Opens at the page of the one in question
func open() -> void:
	if world.finger != -1:
		world._release()
	world.stop_scan()
	page = maxi(world.residents.find(world.who()), 0)
	visible = true
	refresh()
	world.sfx.play("click")


func close() -> void:
	visible = false
	world.sfx.play("click", 0.8)


# How many pages there are just now: one for each in the room, and the rest
func pages() -> int:
	return world.residents.size() + TITLES.size()


func turn(by: int) -> void:
	page = posmod(page + by, pages())
	refresh()
	world.sfx.play("click", 1.1)


# Whose page it is open at, or null on the pages that are about no one of them
func resident() -> Resident:
	return world.residents[page] if page < world.residents.size() else null


func refresh() -> void:
	page = mini(page, pages() - 1)
	var r := resident()
	var pet := r.pet if r != null else null
	var rest := page - world.residents.size()
	rename.visible = pet != null
	let_go.visible = pet != null
	let_go.disabled = r != null and r.leaving
	sound.visible = rest == TITLES.size() - 1
	sound.symbol = "sound_off" if world.sfx.muted else "sound_on"
	sound.caption = "Muted" if world.sfx.muted else "Sound"
	tools.visible = rename.visible or sound.visible
	folio.text = "%d / %d" % [page + 1, pages()]
	if pet != null:
		heading.text = r.name
		body.text = _notes(pet)
	elif r != null:
		heading.text = "An egg"
		body.text = "%s.

Who knows what is inside? Keep it warm and it will hatch." % r.egg.title()
	else:
		heading.text = TITLES[rest]
		body.text = [CARE, SHELF, HANDS, ODDS][rest]


# What is known of this cryptlin. Its tastes are blank until it has shown them (the test panel
# gives them away).
func _notes(pet: Cryptlin) -> String:
	var open := world.dev.visible
	var known := pet.me.known
	var likes: Array[String] = []
	for kind in pet.like_decor:
		if open or known.get("decor+" + Decor.IDS[kind], false):
			likes.append("the " + Decor.PLAIN[kind])
	var hates: String = Decor.PLAIN[pet.hate_decor]
	var water := "yes, a pool to wade in" if pet.needs_water() else "no more than a drink"
	var grown := "Hatched %s ago, and all grown up." % _span(Time.get_unix_time_from_system() - pet.me.born)
	if pet.is_baby():
		grown = "Hatched %s ago. Grown in about %s." % [_span(Time.get_unix_time_from_system() - pet.me.born), _span(pet.growing_left())]
	return "A %s %s%s.
%s
Just now it is feeling %s.

Loves to eat: %s
Won't eat: %s
Favourite toy: %s
Happiest on: %s
Likes the lamp: %s
Likes having about: %s
Can't stand: %s
Needs water: %s

What it shows you gets written down here." % [
		pet.nature_name(), "baby " if pet.is_baby() else "", pet.kind_name(), grown, pet.feeling_name(),
		Snack.PLURALS[pet.fav_food] if open or known.get("food", false) else "?",
		Snack.PLURALS[pet.yuck_food] if open or known.get("yuck", false) else "?",
		"the " + Ball.PLAIN[pet.fav_toy] if open or known.get("toy", false) else "?",
		Den.GROUND_PLAIN[pet.fav_ground] if open or known.get("ground", false) else "?",
		Den.LAMPS[pet.fav_lamp]["title"] if open or known.get("lamp", false) else "?",
		", ".join(likes) if not likes.is_empty() else "?",
		"the " + hates if open or known.get("decor-" + Decor.IDS[pet.hate_decor], false) else "?",
		water if open or known.get("water", false) else "?",
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
