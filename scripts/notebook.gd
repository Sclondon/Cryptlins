class_name Notebook
extends PanelContainer
## The notebook, opened from the wheel of things: the one the ticket-master of Wayside Station kept
## on the things in his cellar, and has left for whoever looks after them now. Everything the game
## has to say in words is in here, and in his words, and there are few of them: a chapter on each
## egg and cryptlin in the room and what has been found out about it (and one kept for each that
## has died), then one short leaf to start the keeper off, with the sound on it, and last of all
## his album: a sepia photograph of every kind there is (see Album), those the keeper has one of
## ringed and the rest faded. A tap on a photograph, or on the small one at the head of a
## cryptlin's own chapter, turns up what he wrote of the cryptid that kind comes of; the tick
## puts that away again. How anything works is not written down: that is for the keeper to find
## out by trying.
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
# How tall the row a leaf's heading is in, which is the size of the small photograph at its end
const STAMP := 52.0
# The album: the gap between two photographs, the least one is ever shown at (if they cannot all
# be that big on the one leaf, the album runs over more), and on a leaf of lore the most and the
# least the photograph is shown at and the least its words are set in
const CELL_GAP := 8.0
const CELL_LEAST := 64.0
const BIG := 300.0
const BIG_LEAST := 96.0
const LORE_LEAST := 14
# The chapters that come after those for each of those in the room: the keeper's leaf, and the
# album. All the first says is enough to start on and no more. The rest is for the keeper to
# find out.
const TITLES: Array[String] = ["To the keeper", "The album"]
const KEEPER := 0
const ALBUM := 1
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
# What he wrote of the cryptid each kind comes of: where and when it was told of, and what it is
# said to be
const LORE: Array[String] = [
	"Airmen of the Royal Air Force, out in Malta and the Middle East in the 1920s, blamed gremlins for whatever went wrong with an aeroplane that had no business going wrong. By the war of 1939 every squadron had them. A pilot named Dahl put them in a book in 1943, and they have been at large since.",
	"The sasquatch of the forests of the Pacific Northwest: tall, hairy, upright, and gone before anyone has a good look. The name was put into English in the 1920s by J. W. Burns, a schoolteacher in British Columbia, from the Halkomelem. It became Bigfoot in 1958, when a road gang at Bluff Creek in California found prints sixteen inches long round their bulldozer.",
	"English, from the fourteenth century, and never once described by anyone who saw it, the look of it being fatal. It hatches from an egg laid by a cock and sat on by a toad or a snake, and is a rooster in front and a serpent behind. Only the weasel is proof against it, and it is said to drop dead on hearing a cock crow.",
	"Point Pleasant, West Virginia, November 1966. Two young couples driving out by the old explosives works saw a grey thing the size of a man, with wings and red eyes that shone, and it kept up with the motor car at a hundred miles an hour. It was seen about the town for thirteen months, until the Silver Bridge fell into the Ohio in December 1967, and hardly at all after.",
	"Puerto Rico, 1995: goats and other stock found dead in the hills with holes in their necks and, it was said, no blood left in them. The name is Spanish for goat-sucker. The first to see it described spines down its back and great dark eyes; those shot since in Texas and Mexico have all turned out to be coyotes with the mange.",
	"Loveland, Ohio. In 1955 a man driving home at night reported three figures by the roadside, three or four feet tall, with the faces of frogs. In March 1972 two policemen, a fortnight apart, each saw something of the sort on the road by the Little Miami River. One of them said afterwards that it was a big lizard somebody had lost.",
	"Loch Ness, in the Highlands of Scotland: twenty-three miles long, very deep, and the colour of stewed tea. A road was built along the north shore in 1933 and the reports began that year: a hump, sometimes a long neck, and a wash with nothing to make it. The famous photograph of 1934 was owned up to sixty years on as a toy submarine with a head stuck on it.",
	"A tale of the lumber camps, set down by William Cox in 1910. It lives in the mountains of Colorado, where it hooks its tail over a ridge and waits, for days if need be, and then lets go and comes down the slope with its mouth open, taking in whatever is on the way. A forest ranger is said to have finished one with a dummy tourist packed with blasting powder.",
	"From the Algonquian peoples of the northern woods, the Ojibwe and the Cree among them: a spirit of winter and famine, gaunt to the bone, that eats and is never filled, and grows with every meal so that it is hungrier after than before. A man who ate human flesh to get through a hard winter was said to become one. The old accounts give it no antlers; those came later, with the pictures.",
	"The water horse of the Scottish rivers and lochs. It stands at the water's edge as a fine horse, saddled as often as not, and whoever gets up on it finds he cannot get down again, and is carried under. It is said that a man who gets hold of its bridle has the mastery of it.",
	"Sea people that come ashore are told of on every coast. The best attested is the wild man of Orford, in Suffolk, taken in the fishermen's nets in about 1167 and kept at the castle, as Ralph of Coggeshall has it. He ate his fish raw, would not or could not speak, and one day went back into the sea and was not seen again.",
	"Not folklore but a story: The Call of Cthulhu, by H. P. Lovecraft, printed in Weird Tales in February 1928. Cthulhu lies asleep in a drowned city under the South Pacific, vast and winged, with the head of an octopus, and his kind lie there with him. Sailors in the story find the city risen, and wish they had not.",
	"Paracelsus, a Swiss physician of the sixteenth century, gave the name to small people who live in the earth and pass through it as a fish does through water. The pointed hat came later, from the potteries of Thuringia. Sir Charles Isham brought the first of that sort to England for his rockery at Lamport Hall in 1847, and one of them is there yet.",
	"The fair folk of Britain and Ireland, who live under the hills and are spoken of politely, as the Good Neighbours, in case they are listening. They take offence easily and cannot abide iron. The small sort with wings is a notion of the last century or two; the photographs taken at Cottingley in 1917 were paper cut-outs on hatpins, as the two girls owned in 1983.",
	"No one creature, but toadstools have always had a name for it. A ring of them in the grass is where the fairies danced the night before in England, where the witches did in Germany, and in the Tyrol where a dragon rested its tail. Whoever steps inside one is in for it, by all accounts.",
	"Douglas, Wyoming. The Herrick brothers, who stuffed animals for a living, came in from hunting in 1932, threw a jackrabbit down beside a pair of antlers, and saw what they had. The town has issued licences to hunt them ever since, good for the thirty-first of June. It is said to sing back at cowboys in their own voices.",
	"The small grey sort, with the big head and the black eyes, comes from Betty and Barney Hill, who lost two hours on a road in New Hampshire one night in September 1961 and remembered afterwards what had filled them. Most who have been taken since describe the same. The wreck at Roswell in New Mexico in 1947 had bodies added to it thirty years later.",
	"The wild man of the high Himalaya, known to the Sherpas long before anyone came to climb. It became the Abominable Snowman in 1921 by a newspaperman's bad translation, after the Everest party of that year found tracks above twenty thousand feet. Eric Shipton photographed a footprint beside an ice axe in 1951, and the hairs and bones tested since have been bear.",
	"The hound of Hades, out of the Greek: it lies at the gate of the underworld, fawns on the dead as they come in, and eats any that try to go out again. Three heads is the usual count, though Hesiod gives it fifty. Heracles dragged it up into the daylight for the last of his labours, and Orpheus got past it with a tune.",
	"People under the ground are an old story, and the name is from a picture of 1956, The Mole People. In 1945 a magazine called Amazing Stories printed Richard Shaver's account of a spiteful race in caverns under our feet, which he gave as plain fact, and a good many readers wrote in to say they had met them. The name has been given since to those said to live in the old tunnels under New York.",
	"Fresno, California, 2007. A camera kept on a front lawn at night caught a pair of white legs walking across the grass, with a small head on top, no arms, and nothing else. Another camera took two more at Yosemite in 2011. Nobody has seen one except on a screen.",
	"Out of a book: The Wonderful Wizard of Oz, by L. Frank Baum, 1900. The Winged Monkeys are bound to do three things for whoever owns the Golden Cap, and they do them for the Wicked Witch of the West with no pleasure. The jackets are from the film of 1939.",
	"Aelian, a Roman, records that a sow with wings once laid waste the country round Clazomenae in Ionia, and the city put a winged boar on its coins, which can still be had. Since then the flying pig has mostly been a way of saying that a thing will not happen. The saying is four hundred years old in English at the least.",
	"Flatwoods, West Virginia, 12 September 1952. Some boys saw a light come down on a hilltop at dusk and went up with a neighbour, Mrs May, and a young National Guardsman. By torchlight they saw a thing ten feet tall, with a red face in a hood like the ace of spades and a dark pleated skirt, which hissed and came gliding at them. A meteor and a barn owl on a branch, the investigators say.",
	"The Pine Barrens of southern New Jersey. In 1735 a Mrs Leeds, brought to bed of her thirteenth child, wished it to the devil, and it grew a horse's head, a bat's wings and a forked tail, and went up the chimney. In one week of January 1909 it was reported in some thirty towns, and the schools and mills shut.",
	"The olgoi-khorkhoi of the southern Gobi, which is Mongolian for the large-intestine worm, that being what it looks like. Two feet or more of it lies under the sand and kills at a distance, by poison or by something like electricity, according to who is telling it. Roy Chapman Andrews had it from the Mongolian prime minister in the 1920s and wrote it down without believing it, and nobody has dug one up.",
	"The hairy man of the Australian bush, chiefly down the eastern ranges in New South Wales and Queensland. The first people of the country had names for it long before the settlers, who called it the yahoo and wrote to the newspapers about it all through the 1800s. Tall, upright, shy, and it smells.",
	"A kangaroo where there are none. In October 1974 two Chicago policemen cornered one in an alley on the north-west side, and it kicked them and went over a fence; it was seen across Illinois and Indiana for a month, and not caught. There are such reports from the American middle west back to 1899. None has ever been found, alive or otherwise.",
	"From the Jiundu swamps of what was then Northern Rhodesia, and written down by Frank Melland in 1923. The Kaonde people told him of a red thing with no feathers, wings of skin four to seven feet across and a beak full of teeth, that upsets canoes; the name means the overwhelmer of boats. Shown a book of animals, they picked the pterodactyl.",
	"Sailors have reported them on every sea. Columbus saw three off Hispaniola in January 1493 and noted that they were not so handsome as they are painted, which is fair, since they were very likely manatees. The one P. T. Barnum showed in New York in 1842 was half a monkey sewn to half a fish.",
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
# The kind whose lore is turned up over the leaf it is open at, or -1 when none is
var lore := -1
var album: Album
var title: Label
var heading: Label
# The small photograph at the end of the heading of a cryptlin's chapter, of its kind
var stamp: Album.Print
var leaf: Control
# The photographs of the album, one for each kind, and the frame they are stuck in; and the big
# one over a leaf of lore
var grid: Control
var cells: Array[Album.Print] = []
var big: Album.Print
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
	album = Album.new(world)
	add_child(album)
	var head := HBoxContainer.new()
	head.custom_minimum_size.y = STAMP
	rows.add_child(head)
	heading = _line(head, HEAD_SIZE, INK)
	heading.clip_text = true
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp = Album.Print.new(album)
	stamp.custom_minimum_size = Vector2(STAMP, STAMP)
	stamp.pressed.connect(func() -> void: read(resident().kind))
	head.add_child(stamp)
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
	grid = Control.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaf.add_child(grid)
	for kind in Cryptlin.KINDS.size():
		var cell := Album.Print.new(album)
		cell.pressed.connect(read.bind(kind))
		grid.add_child(cell)
		cells.append(cell)
	big = Album.Print.new(album)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leaf.add_child(big)
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
	for b: Button in [back, world.icon_button(foot, "right", turn.bind(1)), world.icon_button(foot, "check", done)]:
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
	lore = -1
	visible = true
	refresh()


# Turns up what is written of a kind, over whatever leaf it is open at
func read(kind: int) -> void:
	lore = kind
	refresh()
	world.sfx.play("click", 1.1)


# The tick at the foot of a leaf: it shuts the handbook; or, with a kind's lore turned up, puts
# that away and is back at the leaf under it
func done() -> void:
	if lore < 0:
		close()
		return
	lore = -1
	refresh()
	world.sfx.play("click", 0.9)


func close() -> void:
	lore = -1
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


# To the next leaf or the one before; or, with a kind's lore turned up, to the next kind's
func turn(by: int) -> void:
	if lore >= 0:
		lore = posmod(lore + by, LORE.size())
		refresh()
		world.sfx.play("click", 1.1)
		return
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
	var tall := size.y - paper.get_margin(SIDE_TOP) - paper.get_margin(SIDE_BOTTOM) - title.get_minimum_size().y - STAMP - FOOT_TALL - GAP * 3
	return Vector2(maxf(wide, 40.0), maxf(tall, 40.0))


# How tall some words stand when they are wrapped to a width, as the page's label sets them
func _tall(text: String, wide: float, letters := BODY_SIZE) -> float:
	var set_out := TextParagraph.new()
	set_out.width = wide
	set_out.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	set_out.add_string(text, FACE, letters)
	return set_out.get_size().y + LINE_GAP * (set_out.get_line_count() - 1) + 2.0


# Sets every chapter out over as many leaves as it needs at the size the notebook is, which is
# one for nearly all of them: paragraph by paragraph and row by row of the list, a new leaf
# only when the next will not fit (so a leaf is full before the chapter runs on), and a
# paragraph too long for a leaf by itself broken between two words.
func _lay_out() -> void:
	leaves.clear()
	for which in chapters():
		if which - everyone().size() == ALBUM:
			# (the album has no words: it is a leaf, or as many as its photographs need)
			var set_in := _album()
			for count in ceili(float(cells.size()) / (set_in.x * set_in.y)):
				leaves.append({"chapter": which, "part": count, "text": ""})
			continue
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
	var reading := lore >= 0
	rename.visible = pet != null and not reading
	let_go.visible = pet != null and not reading
	let_go.disabled = r != null and r.leaving
	sound.visible = rest == KEEPER and not reading
	shop.visible = world.embedded
	# The photographs: all of them are taken the first time the handbook is seen, those of the
	# kinds that have a chapter first
	var owned := kept()
	if visible:
		var first: Array[int] = []
		for one in everyone():
			if one.egg == null:
				first.append(one.kind)
		album.take(first)
	stamp.visible = r != null and r.egg == null and not reading
	if stamp.visible:
		stamp.show_kind(r.kind, owned.has(r.kind))
	grid.visible = rest == ALBUM and not reading
	if grid.visible:
		_stick_in(owned)
	big.visible = false
	body.offset_top = 0.0
	body.add_theme_font_size_override("font_size", BODY_SIZE)
	# (with all of them on the one leaf, each gives up a little of its width)
	for b in foot_buttons:
		b.custom_minimum_size.x = FOOT_NARROW if shop.visible and rename.visible else FOOT_WIDE
	sound.symbol = "sound_off" if world.sfx.muted else "sound_on"
	sound.caption = "Muted" if world.sfx.muted else "Sound"
	if reading:
		_turn_up(owned)
		return
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


# The kinds the keeper has one of, hatched and living in the room (as the keys of it)
func kept() -> Dictionary:
	var kinds := {}
	for r in world.residents:
		if r.hatched and r.egg == null:
			kinds[r.kind] = true
	return kinds


# How the album is set out at the size the notebook is: how many photographs across a leaf, how
# many down, and how big each is. All of them go on the one leaf if they can be made out at
# that; if not, a leaf holds as many as fit at the least they are shown at.
func _album() -> Vector3i:
	var room := _room()
	var best := Vector3i(1, 1, 0)
	for across in range(1, cells.size() + 1):
		var down := ceili(float(cells.size()) / across)
		var each := floori(minf((room.x + CELL_GAP) / across, (room.y + CELL_GAP) / down) - CELL_GAP)
		if each > best.z:
			best = Vector3i(across, down, each)
	if best.z >= CELL_LEAST:
		return best
	var step := CELL_LEAST + CELL_GAP
	return Vector3i(maxi(int((room.x + CELL_GAP) / step), 1), maxi(int((room.y + CELL_GAP) / step), 1), int(CELL_LEAST))


# Sets the photographs of the leaf of the album it is open at in their rows, in the middle of
# the leaf, those of the kinds in `owned` ringed
func _stick_in(owned: Dictionary) -> void:
	var room := _room()
	var set_in := _album()
	var held := set_in.x * set_in.y
	var step := set_in.z + CELL_GAP
	var from := Vector2((room.x - set_in.x * step + CELL_GAP) * 0.5, maxf((room.y - set_in.y * step + CELL_GAP) * 0.5, 0.0)).floor()
	for kind in cells.size():
		var cell := cells[kind]
		var place := kind - part * held
		cell.visible = place >= 0 and place < held
		cell.position = from + Vector2(place % set_in.x, place / set_in.x) * step
		cell.size = Vector2(set_in.z, set_in.z)
		cell.show_kind(kind, owned.has(kind))


# A leaf of lore: the name of the kind, its photograph as big as there is room for over the
# words, and what is written of the cryptid it comes of. The words are never cut off: on a small
# screen the photograph gives way first, and then the size they are set in.
func _turn_up(owned: Dictionary) -> void:
	var words := LORE[lore]
	var room := _room()
	var letters := BODY_SIZE
	while letters > LORE_LEAST and _tall(words, room.x, letters) > room.y:
		letters -= 1
	var across := floorf(minf(minf(room.y - _tall(words, room.x, letters) - GAP, BIG), room.x))
	big.visible = across >= BIG_LEAST
	if big.visible:
		big.position = Vector2(floorf((room.x - across) * 0.5), 0.0)
		big.size = Vector2(across, across)
		big.show_kind(lore, owned.has(lore), false)
		body.offset_top = across + GAP
	body.add_theme_font_size_override("font_size", letters)
	body.text = words
	heading.text = str(Cryptlin.KINDS[lore]["title"]).left(1).to_upper() + str(Cryptlin.KINDS[lore]["title"]).substr(1)
	folio.text = "%d / %d" % [lore + 1, LORE.size()]


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
	if which - all.size() == ALBUM:
		return []
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
