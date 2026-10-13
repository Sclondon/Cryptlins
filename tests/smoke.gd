extends SceneTree
## Smoke test: the egg and hatching, naming, the shelf (food, toys, things for the room, ground),
## the pool and the kinds that need one,
## the lamp, petting, calling, sleep, time passing while away, the scanner, the notebook and
## sending it off for a new egg.
## godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..19]
## (touches are sent as window pixels, like a real finger)

# The save this run uses: one for each kind, so that several can be run at once
var save := "user://smoke_test.json"

var main: Den
var failures := 0
var kind := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
	save = "user://smoke_test_%d.json" % kind
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	main = _start()
	_run.call_deferred()


func _start() -> Den:
	var m: Den = load("res://main.tscn").instantiate()
	m.save_path = save
	m.first_kind = kind
	m.ask_names = false
	root.add_child(m)
	return m


func _restart() -> void:
	main.save_game()
	main.queue_free()
	await _frames(3)
	main = _start()
	await _frames(5)


# Shuts the game, lets this long go by on the clock, and opens it again
func _come_back_after(seconds: float) -> void:
	main.save_game()
	main.queue_free()
	await _frames(3)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save))
	data["time"] = float(data["time"]) - seconds
	var f := FileAccess.open(save, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	main = _start()
	await _frames(5)


# What is its own about how one looks: the same every time for the one seed, not the same from
# seed to seed, colours it has always had for a seed from before there were more, and a body
# whose proportions stay inside what its kind allows
func _looks(pet: Cryptlin) -> void:
	var k := pet.kind
	check(Cryptlin.looks(k, 7) == Cryptlin.looks(k, 7) and Cryptlin.colours(k, 7) == Cryptlin.colours(k, 7), "one seed always looks the same")
	var heads := {}
	var coats := {}
	var odd := {}
	var kept := true
	for s in 40:
		var drawn := Cryptlin.looks(k, s + 1)
		heads[snappedf(Cryptlin.span(k, "head", drawn["head"]), 0.05)] = true
		coats[drawn["marks"][0]] = true
		for extra: String in drawn["extras"]:
			odd[extra] = true
			kept = kept and extra in Cryptlin.EXTRAS[k]
		# The coat is one of those its kind has always had, give or take the drift
		var fur := Cryptlin.colours(k, s + 1)[0]
		var near := false
		for old: Color in Cryptlin.FURS[k]:
			near = near or (absf(fur.r - old.r) + absf(fur.g - old.g) + absf(fur.b - old.b) < 0.45)
		kept = kept and near
	check(heads.size() >= 5 and coats.size() >= 5 and not odd.is_empty(), "forty seeds give heads of %d sizes, %d sorts of coat and %d odd things" % [heads.size(), coats.size(), odd.size()])
	check(kept, "each in a colour its kind has always had, with only the odd things its kind can have")
	check(Cryptlin.new_seed() > Cryptlin.OLD_SEEDS, "a new one has a seed from since there were more colours")
	check(pet.eye_sizes.size() == pet.eyes.size() and pet.head_size > 0.8 and pet.head_size < 1.35, "its own is built to its proportions")
	var tex := Cryptlin.coat([Cryptlin.Mark.SPOTS, 5, Cryptlin.Mark.SOCKS], Color(0.4, 0.5, 0.3)).get_image()
	var shades := {}
	for y in Cryptlin.COAT:
		for x in Cryptlin.COAT:
			shades[tex.get_pixel(x, y).to_html(false)] = true
	check(shades.size() >= 2 and tex.get_pixel(3, 2) == tex.get_pixel(Cryptlin.COAT - 4, 2), "a marked coat is painted in more than one shade, the same on both sides")


# One from under the ground: it digs a great deal, whatever the floor, is at home in a dim room
# and not under the bright lamp, and does not see far
func _digger(pet: Cryptlin) -> void:
	var was := main.floor_style
	var digs := [0, 0]
	for hard in 2:
		main.set_ground(0 if hard == 1 else 4)
		for i in 200:
			pet.belly = 90.0
			pet.fun = 90.0
			pet.energy = 90.0
			pet.beg_cooldown = 99.0
			pet._enter(Cryptlin.State.IDLE, 1.0)
			pet._decide()
			if pet.state == Cryptlin.State.DIG:
				digs[hard] += 1
	pet._enter(Cryptlin.State.IDLE, 1.0)
	pet.beg_cooldown = 0.0
	main.set_ground(was)
	check(digs[0] > 40 and digs[1] > 15, "it digs a great deal on dirt and has a go at flagstones too (%d and %d times in 200)" % digs)
	var comfort := {}
	for mode: int in [Den.Lamp.BRIGHT, Den.Lamp.LOW, Den.Lamp.OFF]:
		main.lamp_mode = mode
		comfort[mode] = main.comfort_of(pet)
	main.lamp_mode = Den.Lamp.BRIGHT
	check(pet.fav_lamp == Den.Lamp.LOW and comfort[Den.Lamp.LOW] > comfort[Den.Lamp.BRIGHT] + 20.0 and comfort[Den.Lamp.OFF] > comfort[Den.Lamp.BRIGHT] + 20.0, "it wants the lamp low or off, and is not at ease under the bright one")
	check(pet._sees(pet.position + Vector3(0.5, 0, 0)) and not pet._sees(pet.position + Vector3(2.0, 0, 0)), "and it does not see far")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(done: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if done.call():
			return true
		await process_frame
	return done.call()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
	print("%s: %s" % ["ok  " if ok else "FAIL", what])


func _screen(world: Vector3) -> Vector2:
	return root.get_final_transform() * main.screen_of(world)


# Where an item stands on the shelf, as window pixels
func _on_shelf(id: String) -> Vector2:
	return root.get_final_transform() * main.shelf.point_of(id)


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag(pos: Vector2, by: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.position = pos
	e.relative = by
	Input.parse_input_event(e)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	await _frames(2)
	_touch(pos, false)
	await _frames(2)


# A finger down at one place, slid to another in a few steps (by way of a third, if one is
# given), and lifted
func _slide(from: Vector2, to: Vector2, steps := 8, via := Vector2.INF) -> void:
	_touch(from, true)
	await _frames(2)
	var start := from
	if via != Vector2.INF:
		for i in steps:
			_drag(from.lerp(via, float(i + 1) / steps), (via - from) / steps)
			await _frames(1)
		start = via
	for i in steps:
		_drag(start.lerp(to, float(i + 1) / steps), (to - start) / steps)
		await _frames(1)
	_touch(to, false)
	await _frames(2)


func _settled(pet: Cryptlin) -> bool:
	return pet.state in Cryptlin.INTERRUPTIBLE and not pet.airborne


# Two cryptlins made grown, fed, well, at home and fond of each other: a pair that would pair off
func _content(one: Cryptlin, mate: Cryptlin) -> void:
	for p: Cryptlin in [one, mate]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 70.0, "health": 100.0, "age": Cryptlin.GROW_AGE, "bowel": 0.0, "bladder": 0.0})
		p.grow = p.adult_size
		p.fav_ground = main.floor_style
		p.fav_lamp = main.lamp_mode
		# (one from underground is made easy about the lamp, like the rest)
		p.likes.erase("dim")
		p.hate_decor = Decor.Kind.DISH
		p.comfort = main.comfort_of(p)
		p.fight_cooldown = 9999.0
		p.fond_cooldown = 9999.0
		p.me.paired = 0.0
		p.me.expecting = {}
		p._enter(Cryptlin.State.IDLE, 30.0)
	one.position = Vector3(-0.7, 0, 0.6)
	mate.position = Vector3(0.7, 0, 0.6)
	main.warm(one, mate, 90.0 - main.regard(one, mate))
	main.warm(mate, one, 90.0 - main.regard(mate, one))


func _run() -> void:
	# The egg
	await _frames(5)
	check(main.who().egg != null and main.who().pet == null, "a new game starts with an egg (%s)" % main.who().egg.title())
	check(main.shelf.ids.has("bone") and main.shelf.ids.has("notebook") and main.shelf.ids.size() == Items.LIST.size() - Items.KEPT.size() and main.shelf.ids.has("egg"), "everything is on the shelf (%d things)" % main.shelf.ids.size())
	main.use("bone")
	check(main.snacks.is_empty(), "but there is nothing to feed yet")
	check(await _until(func() -> bool: return main.who().egg.landed, 300), "the egg drops into the light")
	var warm := main.who().egg.warmth
	await _frames(90)
	var gained := main.who().egg.warmth - warm
	check(gained > 0.0, "the lamp warms it (%.1f)" % main.who().egg.warmth)
	main.set_lamp(Den.Lamp.HEAT)
	warm = main.who().egg.warmth
	await _frames(90)
	check(main.who().egg.warmth - warm > gained * 1.8, "the heat lamp warms it faster")
	main.set_lamp(Den.Lamp.OFF)
	await _frames(20)
	warm = main.who().egg.warmth
	await _frames(60)
	check(is_equal_approx(main.who().egg.warmth, warm), "and not at all when it is out")
	main.set_lamp(Den.Lamp.BRIGHT)
	warm = main.who().egg.warmth
	await _tap(_screen(main.who().egg.centre()))
	check(main.who().egg.warmth > warm + 2.0, "a tap warms it a little")
	main.who().egg.warmth = 40.0
	main.save_game()
	await _restart()
	check(main.who().egg != null and main.who().kind == kind and main.who().egg.warmth > 39.0, "a saved egg is still there, as warm")
	check(main.who().egg.stage == 1, "and as cracked")
	var at := _screen(main.who().egg.centre())
	_touch(at, true)
	var most := 0
	for i in 1500:
		if main.who().pet != null:
			break
		most = maxi(most, main.who().egg.stage)
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	_touch(at, false)
	check(most == 2, "rubbing it cracks it further")
	check(main.who().pet != null and main.who().egg == null, "and then it hatches")
	var pet := main.who().pet
	await _frames(30)
	check(pet.kind == kind, "what was in the egg is a %s" % pet.kind_name())
	check(pet.legs.size() == 2 and pet.eyes.size() >= 1, "a cryptlin is built")
	check(pet.nature != pet.nature2 and pet.nature_name().contains(", "), "with two natures (%s)" % pet.nature_name())
	_looks(pet)
	if pet.likes.has("dig"):
		_digger(pet)
	check(pet.is_baby() and pet.growing_left() > 24.0 * 3600.0, "a baby, with more than a day of growing to do")

	# Its name
	check(main.who().name != "", "it has a name made up for it (%s)" % main.who().name)
	main.open_namer(main.who())
	check(main.namer.visible, "and you are asked what to call it")
	main._name_roll()
	main.name_edit.text = "  Smoke  "
	main._name_done()
	check(not main.namer.visible and main.who().name == "Smoke", "what you type is its name")
	await _until(func() -> bool: return _settled(pet), 600)

	# Feeding, from the shelf
	pet.belly = 30.0
	pet.energy = 90.0
	var food := Items.id_of("food", (pet.yuck_food + 1) % Snack.NAMES.size())  # anything but the one it will not eat
	await _tap(_on_shelf(food))
	check(main.snacks.size() == 1, "a tap on food on the shelf drops it in")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "it finds it and eats it")
	check(pet.belly > 55.0, "eating fills its belly (%.0f)" % pet.belly)
	await _until(func() -> bool: return _settled(pet), 600)
	pet.belly = 30.0
	await _slide(_on_shelf(food), _screen(Vector3(-1.0, 0.9, 0.5)), 24, _on_shelf(food) - Vector2(0, 160))
	check(main.snacks.size() == 1 and main.snacks[0].position.x < -0.5, "dragged up off the shelf, it drops where you let go")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "and is eaten too")

	# Food on the end of a finger stays there, and food lying in the room can be picked up again
	await _until(func() -> bool: return _settled(pet), 600)
	pet.belly = 100.0
	pet.position = Vector3(-1.6, 0, -1.2)
	pet._enter(Cryptlin.State.IDLE, 30.0)
	var from_row := _on_shelf(food)
	var above := _screen(Vector3(0.5, 0.75, 1.0))
	_touch(from_row, true)
	await _frames(2)
	for i in 10:
		_drag(from_row.lerp(above, (i + 1) / 10.0), (above - from_row) / 10.0)
		await _frames(1)
	await _frames(20)
	check(main.held_snack != null and main.held_snack.held and main.snacks.is_empty(), "food dragged up off the row hangs on the finger")
	var hung := main.held_snack.position
	await _frames(60)
	check(main.held_snack.position.distance_to(hung) < 0.02, "held still for a second, it has not sunk")
	check(_screen(main.held_snack.position).distance_to(above) < 30.0, "and is under the finger")
	_touch(above, false)
	await _frames(2)
	check(main.snacks.size() == 1 and main.held_snack == null, "let go, it drops")
	await _until(func() -> bool: return main.snacks[0].landed, 300)
	var lying: Snack = main.snacks[0]
	var on_it := _screen(lying.position + Vector3(0, 0.08, 0))
	var over := _screen(Vector3(1.2, 0.75, 0.4))
	_touch(on_it, true)
	await _frames(2)
	check(main.held_snack == lying and main.snacks.is_empty(), "a finger on food lying in the room picks it up, and it is nobody's while it is held")
	for i in 10:
		_drag(on_it.lerp(over, (i + 1) / 10.0), (over - on_it) / 10.0)
		await _frames(1)
	await _frames(20)
	check(lying.position.x > 0.8 and lying.position.y > 0.4, "and carries it")
	_touch(over, false)
	await _frames(2)
	check(main.snacks.size() == 1 and main.snacks[0] == lying, "let go, it is anybody's again")
	pet.belly = 30.0
	pet._enter(Cryptlin.State.IDLE, 0.2)
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500) and pet.belly > 50.0, "and is eaten")

	# The ball
	pet.fun = 20.0
	await _until(func() -> bool: return _settled(pet), 600)
	await _tap(_on_shelf("ball"))
	check(main.ball != null, "a tap on the ball throws it in")
	check(await _until(func() -> bool: return pet.kicks_total > 0, 1500), "it chases the ball and kicks it")
	check(pet.fun > 25.0, "playing is fun (%.0f)" % pet.fun)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.CHASE_BALL, 2400), "it tires of the ball in the end")
	await _until(func() -> bool: return main.ball.speed() < 0.3 and main.ball.position.y < 0.2, 900)
	check(absf(main.ball.position.x) <= Den.half.x and absf(main.ball.position.z) <= Den.half.y, "the ball stays inside the walls")

	# Picking the ball up and throwing it
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(-0.8, Ball.R, 0.8)
	await _frames(2)
	at = _screen(main.ball.global_position)
	_touch(at, true)
	await _frames(2)
	check(main.ball.held, "a finger on the ball picks it up")
	for i in 10:
		at += Vector2(12, -4)
		_drag(at, Vector2(12, -4))
		await _frames(1)
	_touch(at, false)
	await _frames(2)
	check(not main.ball.held and main.ball.speed() > 0.5, "letting go throws it")

	# Petting and booping
	await _until(func() -> bool: return _settled(pet) and pet.ball_cooldown > 0.0, 2400)
	main._clear_toys()
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.3, 0, 0.4)
	await _frames(2)
	var love := pet.love
	at = _screen(pet.body_centre())
	_touch(at, true)
	for i in 40:
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	check(pet.state == Cryptlin.State.PETTED, "rubbing it pets it")
	check(pet.love > love, "petting builds the bond")
	_touch(at, false)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.PETTED, 200), "it stops purring when you stop")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	await _tap(_screen(pet.body_centre()))
	check(pet.state == Cryptlin.State.STARTLED, "a tap makes it jump")

	# Calling it over, and the lamp
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	var spot := Vector3(1.2, 0, 1.0) if pet.position.x < 0.0 else Vector3(-1.2, 0, 1.0)
	await _tap(_screen(spot))
	check(pet.state == Cryptlin.State.COME, "a tap on the floor calls it")
	check(await _until(func() -> bool: return pet.position.distance_to(spot) < 0.5, 600), "and it comes")
	var far := Vector3(-0.9, 0, 0.5) if pet.position.x > 0.0 else Vector3(0.9, 0, 0.5)
	# (near enough to see, for one that does not see far)
	if pet.likes.has("sight"):
		far = Vector3(spot.x * 0.15, 0, 0.6)
	_touch(_screen(far), true)
	await _frames(30)
	check(main.light_dragging, "a finger held on the floor takes the lamp")
	check(await _until(func() -> bool: return main.light_point.distance_to(far) < 0.4, 120), "the light follows it")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.CHASE_LIGHT, 60), "and the cryptlin chases the light")
	_touch(_screen(far), false)
	await _frames(5)
	check(not main.light_dragging, "letting go lets the lamp swing back")
	await _until(func() -> bool: return main.light_point.length() < 0.2, 300)
	var seen: Array[int] = []
	for i in 4:
		await _tap(_screen(main.bulb.global_position))
		seen.append(main.lamp_mode)
	check(seen == [Den.Lamp.LOW, Den.Lamp.HEAT, Den.Lamp.OFF, Den.Lamp.BRIGHT], "a tap on the lamp turns it low, to heat, off, and bright again")

	# Lamp off: bed
	await _until(func() -> bool: return _settled(pet), 900)
	pet.energy = 40.0
	main.set_lamp(Den.Lamp.OFF)
	check(not main.light_on, "the lamp goes out")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.SLEEP, 1800), "in the dark it goes to its nest and sleeps")
	check(pet.position.distance_to(main.nest_pos) < 0.5, "in its nest")
	var rested := pet.energy
	await _frames(120)
	check(pet.energy > rested, "sleep restores it")
	pet.energy = 70.0
	main.set_lamp(Den.Lamp.BRIGHT)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.SLEEP, 300), "the lamp coming on wakes it")

	# It lives by the clock: a minute changes next to nothing, and hours away are lived through
	pet.belly = 80.0
	pet.fun = 80.0
	pet.energy = 90.0
	await _frames(60 * 20)
	check(pet.belly > 79.5 and pet.fun > 79.0, "twenty seconds leaves it as full as it was (%.2f)" % pet.belly)
	pet.belly = 64.0
	var name := main.who().name
	var seed_was := main.who().look_seed
	await _restart()
	check(main.who().name == name and main.who().look_seed == seed_was and main.who().pet != null and main.who().pet.kind == kind, "the same cryptlin is there next time")
	check(absf(main.who().pet.belly - 64.0) < 1.0, "as full as it was left (%.0f)" % main.who().pet.belly)
	main.who().pet.belly = 100.0
	main.who().pet.energy = 90.0
	await _come_back_after(6.0 * 3600.0)
	pet = main.who().pet
	check(pet.belly < 75.0 and pet.belly > 30.0, "six hours away and it is hungrier, not starving (%.0f)" % pet.belly)
	check(pet.is_baby(), "and still a baby")
	pet.belly = 100.0
	await _come_back_after(40.0 * 3600.0)
	pet = main.who().pet
	check(pet.belly < 15.0, "left for a day and a half, it is starving (%.0f)" % pet.belly)
	check(not pet.is_baby() and is_equal_approx(pet.grow, pet.adult_size), "and has grown up, %.2f times the usual size" % pet.adult_size)
	# (what it left on the floor in that time is cleared away, so as not to be underfoot for what follows)
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# Tastes: its favourite food, the one it cannot stand, and its favourite toy
	pet.set_needs({"belly": 40.0, "fun": 50.0, "energy": 90.0, "love": 40.0})
	main.who().known = {}
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.position = Vector3(0.3, 0, 0.4)
	main.feed(pet.yuck_food)
	check(await _until(func() -> bool: return main.who().known.get("yuck", false), 1500), "it spits out %s" % Snack.PLURALS[pet.yuck_food])
	check(pet.feeling == Cryptlin.Feeling.DISGUSTED and main.snacks.is_empty(), "and is disgusted")
	check(main.toast.text.findn(Snack.PLURALS[pet.yuck_food]) < 0, "nothing is written on the screen about it")
	pet.belly = 40.0
	pet.flash_time = 0.0
	main.feed(pet.fav_food)
	check(await _until(func() -> bool: return main.who().known.get("food", false), 1500), "it loves %s" % Snack.PLURALS[pet.fav_food])
	check(pet.feeling == Cryptlin.Feeling.LOVING, "and shows it")
	check(main.shelf.marks.get(Items.id_of("food", pet.fav_food)) == "heart" and main.shelf.marks.get(Items.id_of("food", pet.yuck_food)) == "cross", "the shelf marks what it loves and what it hates")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.energy = 90.0
	pet.set_needs({"fun": 20.0, "bowel": 0.0, "bladder": 0.0})
	main.play_ball(pet.fav_toy)
	check(main.ball != null and main.ball.kind == pet.fav_toy, "the %s comes out" % Ball.PLAIN[pet.fav_toy])
	check(await _until(func() -> bool: return main.who().known.get("toy", false), 2400), "and turns out to be its favourite")
	main._clear_toys()

	# Doing up its room: things it likes, one it hates, and the ground
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0, 0, 0.6)
	var comfort := main.comfort_of(pet)
	var liked: int = pet.like_decor[0]
	await _tap(_on_shelf(Decor.IDS[liked]))
	check(main.decor_of(liked) != null, "a tap on the %s stands it in the room" % Decor.PLAIN[liked])
	check(pet.state == Cryptlin.State.INSPECT, "and the cryptlin goes to look it over")
	check(await _until(func() -> bool: return main.who().known.get("decor+" + Decor.IDS[liked], false), 900), "it likes having it about")
	check(main.comfort_of(pet) > comfort, "and is more at home for it (%.0f)" % main.comfort_of(pet))
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	comfort = main.comfort_of(pet)
	main.use(Decor.IDS[pet.hate_decor])
	check(await _until(func() -> bool: return main.who().known.get("decor-" + Decor.IDS[pet.hate_decor], false), 900), "it cannot stand the %s" % Decor.PLAIN[pet.hate_decor])
	check(main.comfort_of(pet) < comfort, "and is less at home for it")
	main.use(Decor.IDS[pet.hate_decor])
	check(main.decor_of(pet.hate_decor) == null, "a second tap puts it away again")
	# Dragging something about the floor, and back to the shelf
	var thing := main.decor_of(liked)
	thing.position = Vector3(-1.2, 0, 0.6)
	pet.position = Vector3(1.4, 0, -0.5)
	pet._enter(Cryptlin.State.IDLE, 6.0)
	await _frames(2)
	await _slide(_screen(thing.position + Vector3(0, 0.2, 0)), _screen(Vector3(0.9, 0, 1.0)))
	check(thing.position.x > 0.4, "a thing in the room can be dragged about")
	await _slide(_screen(thing.position + Vector3(0, 0.2, 0)), _on_shelf("notebook"))
	check(main.decor_of(liked) == null, "and dragged back down to the shelf to put it away")
	# Its nest goes where you drag it
	var nest_was := main.nest_pos
	await _slide(_screen(main.nest_pos + Vector3(0, 0.1, 0)), _screen(Vector3(1.2, 0, 0.9)))
	check(main.nest_pos.distance_to(nest_was) > 1.0 and main.nest.position == main.nest_pos, "the nest goes where you drag it")
	# And where the cryptlin drags it
	nest_was = main.nest_pos
	pet._enter(Cryptlin.State.MOVE_NEST)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.MOVE_NEST, 1500) and main.nest_pos.distance_to(nest_was) > 0.5, "or where the cryptlin drags it itself")
	# Shelters to hide in, and a rock to sit on
	pet.hate_decor = Decor.Kind.DISH
	for k in Decor.IDS.size():
		var probe := Decor.new(k)
		var is_shelter := probe.hollow
		probe.free()
		if not is_shelter:
			continue
		pet.set_needs({"belly": 80.0, "energy": 90.0, "bowel": 0.0, "bladder": 0.0})
		var hole := main.place_decor(k, Vector3(-1.1, 0, -0.8))
		await _until(func() -> bool: return _settled(pet), 900)
		pet.position = Vector3(1.2, 0, 0.9)
		pet._enter(Cryptlin.State.LURK)
		check(pet.visiting == hole and await _until(func() -> bool: return pet.state == Cryptlin.State.LURK and pet.step == 1, 900) and pet.position.distance_to(hole.position) < 0.4, "it hides in the %s" % Decor.PLAIN[k])
		main.remove_decor(hole)
	var rock := main.place_decor(Decor.Kind.ROCK, Vector3(0.8, 0, -0.6))
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.VISIT)
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.VISIT and pet.lift > 0.3, 900), "and climbs up to sit on the rock")
	main.remove_decor(rock)
	# A pool: a water kind is not at home without one and wades into it; the rest take it or leave it
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0, 0, 0.9)
	main.who().known.erase("water")
	var dry := main.comfort_of(pet)
	check(pet.dry() == pet.needs_water() and not main.notebook._notes(pet).contains("pool"), "nothing says yet whether it needs water")
	await _tap(_on_shelf("pool"))
	var pool := main.decor_of(Decor.Kind.POOL)
	check(pool != null and pool.radius > Decor.RADII[Decor.Kind.DISH] * 2.0, "a tap on the pool stands it in the room, a good deal bigger than the dish")
	check(not Decor.Kind.POOL in pet.like_decor and pet.hate_decor != Decor.Kind.POOL, "the pool is no part of its likes and dislikes")
	check(await _until(func() -> bool: return main.who().known.get("water", false), 900), "the cryptlin goes to look, and whether it needs water is found out")
	check(main.toast.text.findn("water") < 0 and main.toast.text.findn("pool") < 0, "nothing is written on the screen about it")
	if pet.needs_water():
		check(main.comfort_of(pet) > dry + 30.0, "a water kind is far more at home with a pool (%.0f, from %.0f)" % [main.comfort_of(pet), dry])
		check(main.shelf.marks.get("pool") == "heart" and main.notebook._notes(pet).contains("a pool to wade in"), "the shelf marks it and the notebook says so")
		await _until(func() -> bool: return _settled(pet), 900)
		pet._enter(Cryptlin.State.VISIT)
		check(pet.visiting == pool, "it goes to the pool of its own accord")
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.VISIT and pet.lift < 0.0 and pet.position.distance_to(Vector3(pool.position.x, pet.position.y, pool.position.z)) < 0.2, 900), "and wades in up to its middle")
		check(await _until(func() -> bool: return pet.state != Cryptlin.State.VISIT, 900) and pet.lift == 0.0, "and climbs out again")
		main.remove_decor(pool)
		check(pet.dry() and main.comfort_of(pet) < dry + 1.0, "without one it is back to making do")
		pet._enter(Cryptlin.State.BEG)
		check(pet.beg_for == Cryptlin.Want.WATER, "and asks for water")
	else:
		check(absf(main.comfort_of(pet) - dry) < 5.0 and not main.shelf.marks.has("pool"), "its kind takes a pool as it would anything else")
		check(main.notebook._notes(pet).contains("no more than a drink"), "and the notebook says so")
		main.remove_decor(pool)
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	await _tap(_on_shelf(Items.id_of("ground", pet.fav_ground)))
	check(main.floor_style == pet.fav_ground, "a tray of %s changes the floor" % Den.GROUND_PLAIN[pet.fav_ground])
	check(await _until(func() -> bool: return main.who().known.get("ground", false), 600), "which is the ground it is happiest on")

	# What goes in comes out: some hours after a meal it goes off and leaves a dropping
	await _until(func() -> bool: return _settled(pet), 900)
	for m in main.messes.duplicate():
		main.clear_mess(m)
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.set_needs({"belly": 40.0, "energy": 95.0, "fun": 80.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	var clean := main.comfort_of(pet)
	main.feed((pet.yuck_food + 1) % Snack.NAMES.size())
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500) and pet.digest > 50.0, "what it eats has to come out")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._wear(5.0 * 3600.0, false, 1.0, false)
	check(pet.bowel >= 100.0 and pet.bladder >= 100.0, "five hours on, it needs to go")
	pet.set_needs({"belly": 90.0, "energy": 95.0, "fun": 80.0, "bladder": 0.0})
	check(await _until(func() -> bool: return main.droppings() == 1, 1500), "and goes off and leaves a dropping")
	var dropping: Mess = main.messes.back()
	check(dropping.position.distance_to(main.nest_pos) > 0.8, "well away from its nest")
	check(main.comfort_of(pet) < clean - 5.0, "which spoils the place for it")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 6.0)
	pet.position = Den.in_room(dropping.position + Vector3(-1.6 if dropping.position.x > 0.0 else 1.6, 0, 0), 0.4)
	await _frames(2)
	await _tap(_screen(dropping.position + Vector3(0, 0.06, 0)))
	check(main.droppings() == 0 and main.comfort_of(pet) > clean - 0.1, "a tap clears it up, and it is at home again")
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.bladder = 100.0
	check(await _until(func() -> bool: return main.messes.size() == 1 and main.messes[0].kind == Mess.Kind.PUDDLE, 1500), "it pees too, and leaves a puddle")
	main.messes[0].made -= Mess.LASTS[Mess.Kind.PUDDLE]
	await _frames(3)
	check(main.messes.is_empty(), "which dries up by itself in an hour")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.set_needs({"belly": 100.0, "energy": 95.0, "digest": 100.0, "bowel": 0.0, "bladder": 0.0})
	await _come_back_after(6.0 * 3600.0)
	pet = main.who().pet
	check(main.droppings() == 1, "left alone for six hours after a meal, there is a dropping waiting")
	await _restart()
	pet = main.who().pet
	check(main.droppings() == 1, "and it is still there next time")
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# A grown one left to itself may take a fancy to its nest, and stops dead if it is seen at it
	await _until(func() -> bool: return _settled(pet), 900)
	pet.set_needs({"belly": 90.0, "energy": 95.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	main.nest_pos = Vector3(-0.8, 0, 0.6)
	main.move_nest(main.nest_pos)
	pet._enter(Cryptlin.State.FOND)
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.FOND and pet.step == 1, 900) and pet.position.distance_to(main.nest_pos) < 0.4, "a grown one gets over-fond of its nest")
	await _frames(20)
	await _tap(_screen(pet.body_centre()))
	check(pet.state == Cryptlin.State.FOND and pet.step == 2 and pet.feeling == Cryptlin.Feeling.SCARED, "a tap and it stops dead, mortified")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.age = 0.0
	pet.fond_cooldown = 0.0
	pet._enter(Cryptlin.State.FOND)
	check(pet.state != Cryptlin.State.FOND and not pet._fancies(), "a baby never does")
	pet.age = Cryptlin.GROW_AGE
	pet.grow = pet.adult_size

	# Odds and ends it gets up to
	for doing: int in [Cryptlin.State.SCRATCH, Cryptlin.State.STRETCH, Cryptlin.State.DIG, Cryptlin.State.SPIN, Cryptlin.State.GAZE]:
		pet._enter(doing)
		await _frames(40)
		check(pet.state == doing, "it can %s" % Cryptlin.State.keys()[doing].to_lower())
		check(await _until(func() -> bool: return pet.state != doing, 600), "  and stops again")
	check(main.messes.size() == 1 and main.messes[0].kind == Mess.Kind.HEAP and main.comfort_of(pet) > clean - 0.1, "digging leaves a heap of earth, which is no mess")
	main.messes[0].made -= Mess.LASTS[Mess.Kind.HEAP]
	await _frames(3)

	# The scanner
	await _until(func() -> bool: return _settled(pet), 900)
	await _tap(_on_shelf("scanner"))
	check(main.scanning and pet.xrayed and main.scanner.visible, "a tap on the scanner holds it up to the cryptlin")
	check(pet.state == Cryptlin.State.SCANNED, "which holds still for it")
	pet.belly = 10.0
	await _frames(5)
	var low: float = pet.stomach_fill.scale.y
	pet.belly = 90.0
	await _frames(5)
	check(pet.stomach_fill.scale.y > low * 3.0, "its stomach shows how full it is")
	await _tap(_screen(Vector3(-1.5, 0, 1.0)))
	check(not main.scanning and not pet.xrayed and pet.skin.is_empty(), "a tap anywhere puts the scanner down")

	# Handling: a finger left on it picks it up, a flick pushes it, too much poking annoys it
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.3, 0, 0.4)
	pet.velocity = Vector3.ZERO
	await _frames(2)
	var hold := _screen(pet.body_centre())
	_touch(hold, true)
	await _frames(45)
	check(pet.state == Cryptlin.State.HELD and pet.lift > 0.3, "a finger left on it picks it up")
	_drag(hold + Vector2(120, 0), Vector2(120, 0))
	await _frames(30)
	check(pet.position.x > 0.6, "and carries it about")
	_touch(hold + Vector2(120, 0), false)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.HELD and pet.lift == 0.0, 300), "and sets it down again")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.0, 0, 0.4)
	pet.velocity = Vector3.ZERO
	await _frames(2)
	hold = _screen(pet.body_centre())
	_touch(hold, true)
	for i in 6:
		_drag(hold + Vector2(25 * (i + 1), 0), Vector2(25, 0))
		await _frames(1)
	_touch(hold + Vector2(150, 0), false)
	await _frames(3)
	check(pet.state == Cryptlin.State.SHOVED and pet.velocity.x > 0.5, "a flick pushes it")
	await _until(func() -> bool: return _settled(pet), 600)
	for i in 4:
		pet.boop()
		await _frames(8)
	check(pet.feeling == Cryptlin.Feeling.GRUMPY, "poked four times, it is grumpy")

	# The notebook
	await _tap(_on_shelf("notebook"))
	check(main.notebook.visible and main.notebook.heading.text == "Smoke", "a tap on the notebook opens it at the cryptlin's page")
	check(main.notebook.body.text.contains(Snack.PLURALS[pet.fav_food]) and main.notebook.body.text.contains(pet.nature_name()), "which says what has been found out")
	main.use("bone")
	check(main.snacks.is_empty(), "nothing on the shelf answers while it is open")
	for i in main.notebook.pages() - 1:
		main.notebook.turn(1)
		check(main.notebook.body.text.length() > 60, "page %d: %s" % [i + 2, main.notebook.heading.text])
	main.notebook.close()

	# The room is kept
	main.place_decor(Decor.Kind.SKULL, Vector3(1.0, 0, -1.0))
	main.set_nest(1)
	main.set_lamp(Den.Lamp.LOW)
	var nest_at := main.nest_pos
	main.save_game()
	await _restart()
	check(main.floor_style == main.who().pet.fav_ground and main.nest_style == 1 and main.lamp_mode == Den.Lamp.LOW, "the floor, the nest and the lamp are kept")
	check(main.decor_of(Decor.Kind.SKULL) != null and main.nest_pos.distance_to(nest_at) < 0.01, "and where things stand")
	check(main.who().known.get("food", false) and main.who().known.get("ground", false) and main.who().name == "Smoke", "and what you know of it")

	# Played inside a site with a shop: only what comes free and what was bought
	main.embedded = true
	main.stock = {"fish": 2, "cave": -1}
	main._sync()
	check(main.shelf.ids.has("fish") and main.shelf.ids.has("cave") and main.shelf.ids.has("bone") and not main.shelf.ids.has("berries"), "with a shop, the shelf holds what is free and what was bought")
	main.who().pet._enter(Cryptlin.State.IDLE, 3.0)
	main.who().pet.belly = 30.0
	main.feed(Snack.Kind.FISH)
	check(main.left_of("fish") == 1 and main.shelf.counts.get("fish") == 1, "and food bought gets used up")
	main.feed(Snack.Kind.BERRIES)
	check(main.snacks.size() == 1, "and what was not bought cannot be used")
	main.dev.visible = true
	main._sync()
	check(main.shelf.ids.size() == Items.LIST.size() - Items.KEPT.size() and main.owns("berries") and main.left_of("fish") == -1, "with the test panel open everything is on the row without end, shop or no shop")
	main.feed(Snack.Kind.FISH)
	main.dev.visible = false
	main._sync()
	check(main.left_of("fish") == 1 and not main.owns("berries"), "and what is used meanwhile is not taken from what was bought")
	main.embedded = false
	main._clear_toys()
	main._sync()

	# A new egg
	main.set_lamp(Den.Lamp.BRIGHT)
	main.who().pet._enter(Cryptlin.State.IDLE, 3.0)
	main.ask_let_go(main.who())
	check(main.ask.visible, "asking for a new egg asks first")
	main._answer(false)
	await _frames(5)
	check(not main.ask.visible and main.who().pet != null and not main.who().leaving, "saying no keeps it")
	main.ask_let_go(main.who())
	main._answer(true)
	check(main.who().leaving and main.who().pet.state == Cryptlin.State.LEAVE, "saying yes sends it off")
	check(await _until(func() -> bool: return main.who().egg != null, 1200), "and a new egg comes")
	check(main.who().pet == null and main.ball == null and main.who().kind != kind, "holding a different kind (%s)" % main.who().egg.title())
	await _tap(_on_shelf("scanner"))
	check(main.scanning, "the scanner works on an egg too")
	main.stop_scan()

	# More than one: the egg on the shelf drops another in
	var first := main.who()
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == 2 and main.residents[1].egg != null, "a tap on the egg on the shelf drops another egg in (%s)" % main.residents[1].egg.title())
	check(main.residents[1].kind != first.kind and main.residents[1].id != first.id, "of a different kind, with a number of its own")
	await _until(func() -> bool: return main.residents[0].egg.landed and main.residents[1].egg.landed, 400)
	check(main.residents[0].egg.position.distance_to(main.residents[1].egg.position) > 0.5, "clear of the first")
	await _tap(_on_shelf("notebook"))
	check(main.notebook.pages() == Notebook.TITLES.size() + 2 and main.notebook.heading.text == "An egg", "the notebook has a page for each")
	main.notebook.close()
	for r in main.residents:
		r.egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 2, 400), "both hatch")
	var one: Cryptlin = main.residents[0].pet
	var two: Cryptlin = main.residents[1].pet
	check(one.me.name != "" and two.me.name != "" and one.me == main.residents[0] and two.me.born > 0.0, "each with a name and a birthday of its own")
	main.open_namer(two.me)
	main.name_edit.text = "Second"
	main._name_done()
	check(two.me.name == "Second" and one.me.name != "Second", "the card names the one it was opened for")
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)

	# Food is for whoever gets there, and neither stands in the other
	one.fight_cooldown = 9999.0
	two.fight_cooldown = 9999.0
	var both_eat := 0
	while both_eat == one.yuck_food or both_eat == two.yuck_food:
		both_eat += 1
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 25.0, "energy": 90.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	var fed := 0
	while fed < 6 and (one.belly <= 30.0 or two.belly <= 30.0):
		fed += 1
		main.feed(both_eat)
		main.feed(both_eat)
		await _until(func() -> bool: return main.snacks.is_empty(), 2400)
	check(one.belly > 30.0 and two.belly > 30.0, "food dropped in feeds them both in the end (%.0f, %.0f)" % [one.belly, two.belly])
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 6.0)
		p.position = Vector3(0.2, 0, 0.5)
	await _frames(120)
	check(one.position.distance_to(two.position) > 0.2, "put on the same spot, they push apart (%.2f)" % one.position.distance_to(two.position))

	# What is known is known of each, and the shelf shows it for the one last touched
	one.me.known = {}
	two.me.known = {}
	main.learned(one, "food")
	await _tap(_screen(two.body_centre()))
	check(main.who() == two.me and main.shelf.marks.is_empty() and not two.me.known.has("food"), "a tap on one makes it the one in question: nothing is known of it yet")
	await _until(func() -> bool: return _settled(two), 600)
	one.position = Vector3(-1.0, 0, 0.6)
	two.position = Vector3(1.0, 0, 0.6)
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 6.0)
	await _frames(3)
	await _slide(_on_shelf("scanner"), _screen(one.body_centre()), 16, _on_shelf("scanner") - Vector2(0, 160))
	check(main.scanning and main.scanned == one.me and one.xrayed and not two.xrayed, "the scanner dragged up onto one of them scans that one")
	check(main.shelf.marks.get(Items.id_of("food", one.fav_food)) == "heart", "and the shelf shows what is known of it")
	main.stop_scan()
	main.chosen = two.me
	main.start_scan()
	check(main.scanned == two.me, "tapped, it goes to the one last touched")
	main.stop_scan()
	main.chosen = null
	one.position = Vector3(0.1, 0, 0.2)
	two.position = Vector3(1.6, 0, 1.0)
	main.start_scan()
	check(main.scanned == one.me, "or else to the one nearest the middle")
	main.stop_scan()

	# One room, and each its own idea of it
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	for m in main.messes.duplicate():
		main.clear_mess(m)
	var thing_one: int = one.like_decor[0]
	for d in main.decors.duplicate():
		main.remove_decor(d)
	var home_one := main.comfort_of(one)
	var home_two := main.comfort_of(two)
	main.place_decor(thing_one, Vector3(-1.4, 0, -1.0))
	check(main.comfort_of(one) > home_one + 10.0 and (main.comfort_of(two) > home_two + 10.0) == (thing_one in two.like_decor), "what one likes having about is not for that reason to the other's liking")
	main.remove_decor(main.decor_of(thing_one))

	# Saved and restored, and time away is lived through by each
	for m in main.messes.duplicate():
		main.clear_mess(m)
	one.set_needs({"belly": 41.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	two.set_needs({"belly": 77.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	var names: Array[String] = [one.me.name, two.me.name]
	var seeds: Array[int] = [one.look_seed, two.look_seed]
	await _restart()
	check(main.residents.size() == 2 and main.pets().size() == 2, "both are there next time")
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(one.me.name == names[0] and two.me.name == names[1] and one.look_seed == seeds[0] and two.look_seed == seeds[1], "each who it was")
	check(absf(one.belly - 41.0) < 1.0 and absf(two.belly - 77.0) < 1.0 and one.me.known.get("food", false) and not two.me.known.has("food"), "as full as it was left, with what was known of it")
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 100.0, "energy": 90.0, "digest": 100.0, "bowel": 0.0, "bladder": 0.0})
	await _come_back_after(6.0 * 3600.0)
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(one.belly < 75.0 and two.belly < 75.0, "six hours away and both are hungrier (%.0f, %.0f)" % [one.belly, two.belly])
	check(main.droppings() == 2, "and each has left a dropping")
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# Getting on: what each thinks of the other, and what they get up to together
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "energy": 90.0, "fun": 50.0, "age": Cryptlin.GROW_AGE, "bowel": 0.0, "bladder": 0.0})
		p.grow = p.adult_size
		p.fight_cooldown = 0.0
		p.me.regard = {}
		p._enter(Cryptlin.State.IDLE, 30.0)
	one.position = Vector3(-0.9, 0, 0.5)
	two.position = Vector3(0.9, 0, 0.5)
	check(is_equal_approx(main.regard(one, two), 50.0 + one.suits(two)) and is_equal_approx(one.suits(two), two.suits(one)), "to begin with they think of each other as their natures suit (%.0f)" % main.regard(one, two))
	main.warm(one, two, 60.0 - main.regard(one, two))
	main.warm(two, one, 60.0 - main.regard(two, one))
	one.meet(Cryptlin.State.SNIFF, two)
	check(await _until(func() -> bool: return one.state == Cryptlin.State.SNIFF and one.step == 1, 600) and one.position.distance_to(two.position) < 1.3, "one goes over to the other and sniffs at it")
	check(await _until(func() -> bool: return one.state != Cryptlin.State.SNIFF, 300) and main.regard(one, two) > 60.0 and main.regard(two, one) > 60.0, "and they think the better of each other for it")
	two.position = Vector3(1.2, 0, 0.8)
	two.target = Vector3(-1.2, 0, -0.6)
	two._enter(Cryptlin.State.WANDER)
	one.meet(Cryptlin.State.FOLLOW, two)
	await _frames(150)
	check(one.state == Cryptlin.State.FOLLOW and one.position.distance_to(two.position) < 1.7, "one trails round after the other")
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 30.0)
		p.fun = 40.0
	var liking := main.standing(one, two)
	one.meet(Cryptlin.State.TAG, two)
	check(one.state == Cryptlin.State.TAG and two.state == Cryptlin.State.FLEE, "a game of chase: one runs and the other runs after it")
	check(await _until(func() -> bool: return not one.state in [Cryptlin.State.TAG, Cryptlin.State.FLEE] and not two.state in [Cryptlin.State.TAG, Cryptlin.State.FLEE], 2400), "which ends")
	check(one.fun > 40.0 and two.fun > 40.0 and main.standing(one, two) > liking, "with both the better amused and the better friends (%.0f)" % main.standing(one, two))
	# Asleep in the one nest: a heap if they get on, side by side if not
	main.move_nest(Vector3(0, 0, 0.2))
	main.warm(one, two, 80.0 - main.regard(one, two))
	main.warm(two, one, 80.0 - main.regard(two, one))
	for p: Cryptlin in [one, two]:
		p.energy = 30.0
		p.position = main.nest_pos + Vector3(0.05 if p == one else -0.05, 0, 0)
		p.velocity = Vector3.ZERO
		p._enter(Cryptlin.State.SLEEP)
	await _frames(120)
	var heaped := one.position.distance_to(two.position)
	main.warm(one, two, -60.0)
	main.warm(two, one, -60.0)
	await _frames(120)
	check(heaped > 0.05 and heaped < one.position.distance_to(two.position) - 0.1, "two that get on sleep in a heap, and two that do not lie apart (%.2f, %.2f)" % [heaped, one.position.distance_to(two.position)])
	main.warm(one, two, 30.0)
	main.warm(two, one, 30.0)
	liking = main.standing(one, two)
	main.set_lamp(Den.Lamp.OFF)
	main.pass_time(4.0 * 3600.0)
	check(one.state == Cryptlin.State.SLEEP and two.state == Cryptlin.State.SLEEP and main.standing(one, two) > liking + 1.0, "a night in the one nest brings them round to each other (%.0f, from %.0f)" % [main.standing(one, two), liking])
	main.set_lamp(Den.Lamp.BRIGHT)

	# Falling out. Two that are fed, at home and on good terms all but never fight
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 60.0, "health": 100.0, "bowel": 0.0, "bladder": 0.0})
		p.comfort = 70.0
		p._enter(Cryptlin.State.IDLE, 30.0)
		p.flash_time = 0.0
	one.position = Vector3(-0.3, 0, 0.5)
	two.position = Vector3(0.3, 0, 0.5)
	main.warm(one, two, 70.0 - main.regard(one, two))
	main.warm(two, one, 70.0 - main.regard(two, one))
	await _frames(3)
	check(one.temper(two) < 0.05 and not one.squabble(two, 0.5), "two that are fed, at home and on good terms have next to no fight in them (%.2f)" % one.temper(two))
	# An ill-matched hungry pair is another matter
	main.warm(one, two, -100.0)
	main.warm(two, one, -100.0)
	main.warm(one, two, 20.0)
	main.warm(two, one, 20.0)
	one.belly = 10.0
	two.belly = 10.0
	check(one.temper(two) > 0.9, "two that are hungry and cannot stand each other are spoiling for one (%.2f)" % one.temper(two))
	check(one.squabble(two, 1.0) and main.scuffle != null and one.state == Cryptlin.State.SCUFFLE and two.state == Cryptlin.State.SCUFFLE and not one.visible and not two.visible, "and come to blows: a ball of dust with the pair of them in it")
	check(await _until(func() -> bool: return main.scuffle == null, 400) and one.visible and two.visible, "which is soon over")
	var loser := one if one.health < two.health else two
	var winner := two if loser == one else one
	check(is_equal_approx(loser.health, 100.0 - Cryptlin.FIGHT_HURT) and winner.health == 100.0 and loser.state == Cryptlin.State.COWED, "the loser backs off a little the worse for it (%.0f)" % loser.health)
	check(is_equal_approx(main.regard(one, two), 20.0 - Den.FIGHT_SOURS) and is_equal_approx(main.regard(two, one), 20.0 - Den.FIGHT_SOURS), "and each thinks the less of the other")
	check(not one.squabble(two, 1.0), "they do not go straight back to it")
	for round in 3:
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.health = minf(p.health, Cryptlin.FIGHT_FLOOR + 3.0)
			p.fight_cooldown = 0.0
			p.belly = 10.0
		one.squabble(two, 1.0)
		await _until(func() -> bool: return main.scuffle == null, 400)
	check(is_equal_approx(minf(one.health, two.health), Cryptlin.FIGHT_FLOOR), "fight after fight never takes one below the floor (%.0f, %.0f)" % [one.health, two.health])
	# The keeper can break it up: a tap, food dropped on it, the lamp swung over it
	for way in 3:
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.health = 80.0
			p.fight_cooldown = 0.0
			p.belly = 10.0
			p.position = Vector3(-0.3 if p == one else 0.3, 0, 0.6)
		one.squabble(two, 1.0)
		await _frames(20)
		match way:
			0:
				await _tap(_screen(main.scuffle.position + Vector3(0, 0.35, 0)))
			1:
				main.feed(Snack.Kind.BONE, main.scuffle.position + Vector3(0, 1.5, 0))
				await _until(func() -> bool: return main.scuffle == null, 100)
			2:
				main.light_goal = main.scuffle.position
				main.light_point = main.scuffle.position
				main.light_dragging = true
				await _frames(3)
				main.light_dragging = false
		check(main.scuffle == null and main.scuffle_left > 0.5 and one.health == 80.0 and two.health == 80.0 and one.visible and two.visible, "%s breaks it up, and nobody is hurt" % ["a tap on the scuffle", "food dropped on it", "the lamp swung over it"][way])
		main._clear_toys()
	# A grown one never hurts a baby
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	two.age = 0.0
	for p: Cryptlin in [one, two]:
		p.fight_cooldown = 0.0
	one.squabble(two, 1.0)
	check(main.scuffle == null and two.state == Cryptlin.State.SHOVED and two.health == 80.0 and one.health == 80.0, "a grown one does not fight a baby: it cuffs it away, and the baby is not hurt")
	two.age = Cryptlin.GROW_AGE
	# Left to themselves, the hungry pair fall out of their own accord
	for round in 8:
		if main.scuffle != null:
			break
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.fight_cooldown = 0.0
			p.belly = 10.0
			p._enter(Cryptlin.State.IDLE, 4.0)
			p.position = Vector3(-0.3 if p == one else 0.3, 0, 0.6)
		if round % 2 == 1:
			main.feed(Snack.Kind.BONE, Vector3(0, 2.0, 0.6))
		await _until(func() -> bool: return main.scuffle != null, 400)
	check(main.scuffle != null, "left to themselves, a hungry pair that do not get on fall out: over being crowded, or over food")
	await _until(func() -> bool: return main.scuffle == null, 400)
	main._clear_toys()
	var worse := minf(one.health, two.health)
	var thinks := main.regard(one, two)
	await _restart()
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(is_equal_approx(minf(one.health, two.health), worse) and is_equal_approx(main.regard(one, two), thinks), "health and what they think of each other are kept")
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "health": 100.0})
		p.fight_cooldown = 9999.0

	# Health: days of an empty belly wear it away, and it mends fed and rested
	one.set_needs({"belly": 0.0, "health": 100.0, "energy": 90.0})
	one._wear(24.0 * 3600.0, false, 1.0, false)
	check(is_equal_approx(one.health, 100.0 - 2400.0 / Cryptlin.STARVE_HOURS) and one.health > 70.0, "a whole day of an empty belly costs it some of its health, and nothing like its life (%.0f)" % one.health)
	one.belly = 90.0
	one._wear(6.0 * 3600.0, true, 1.0, true)
	check(is_equal_approx(one.health, 100.0 - 2400.0 / Cryptlin.STARVE_HOURS + 600.0 / Cryptlin.MEND_HOURS), "fed and asleep, it mends (%.0f)" % one.health)
	one.set_needs({"belly": 60.0, "health": 30.0, "energy": 90.0})
	one.flash_time = 0.0
	one._enter(Cryptlin.State.IDLE, 5.0)
	await _frames(5)
	check(one.feeling == Cryptlin.Feeling.POORLY and one.faces[Cryptlin.Feeling.POORLY] != null, "a poorly one shows it")
	main.start_scan(one.me)
	await _frames(3)
	check(main.scanning and main._word(one.health, ["failing", "poorly", "off colour", "well", "in fine fettle"]) == "poorly", "and the scanner has a note of it")
	main.stop_scan()
	# The same wearing away whether the game is open or shut
	one.set_needs({"belly": 0.0, "health": 10.0, "energy": 90.0})
	two.set_needs({"belly": 0.0, "health": 10.0, "energy": 90.0})
	one._wear(9.5 * 3600.0, false, 1.0, false)
	two.pass_time(9.5 * 3600.0, false)
	check(one.health > 0.0 and absf(one.health - two.health) < 0.001, "an empty belly costs the same by the clock, with the game open or shut (%.3f, %.3f)" % [one.health, two.health])
	for m in main.messes.duplicate():
		main.clear_mess(m)
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "health": 100.0, "energy": 90.0, "bowel": 0.0, "bladder": 0.0})
		p._enter(Cryptlin.State.IDLE, 2.0)

	# The room holds four and no more
	await _tap(_on_shelf("egg"))
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == Den.MAX_RESIDENTS, "two more eggs make four")
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == Den.MAX_RESIDENTS, "and the room refuses a fifth")
	await _tap(_on_shelf("notebook"))
	check(main.notebook.pages() == Notebook.TITLES.size() + 4, "the notebook has a page for each of the four")
	main.notebook.close()

	# Letting one go, from its page in the notebook: no egg comes in its place
	main.chosen = two.me
	main.notebook.open()
	check(main.notebook.resident() == two.me and main.notebook.let_go.visible, "its page has the means of letting it go")
	main.notebook.let_go.pressed.emit()
	check(main.ask.visible and not main.notebook.visible, "which asks first")
	main._answer(true)
	check(await _until(func() -> bool: return main.residents.size() == 3, 1200) and not main.parting in main.residents, "saying yes sends that one off, and the rest stay")

	# Dying. One left with an empty belly for days dies: here, while the keeper was away
	for r in main.residents:
		if r.egg != null:
			r.egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 3, 400), "the two eggs hatch, which makes three")
	await _frames(30)
	var third: Cryptlin = main.residents[1].pet
	var fourth: Cryptlin = main.residents[2].pet
	var late := third.me.name
	one.set_needs({"belly": 100.0, "health": 100.0, "energy": 90.0})
	fourth.set_needs({"belly": 100.0, "health": 100.0, "energy": 90.0})
	third.set_needs({"belly": 0.0, "health": 2.0, "energy": 90.0})
	third._wear(1.0 * 3600.0, false, 1.0, false)
	check(third.health > 0.0, "with an hour less than it takes, it is still alive")
	await _come_back_after(3.0 * 3600.0)
	one = main.residents[0].pet
	third = main.residents[1].pet
	fourth = main.residents[2].pet
	check(third.health == 0.0 and third.state == Cryptlin.State.DYING and third.me.leaving and not third in main.pets(), "left hungry past the end of its health, it is found lying still")
	check(one.health > 90.0 and fourth.health > 90.0, "the others, fed, are none the worse")
	var lay := third.position
	check(await _until(func() -> bool: return main.departed.size() == 1, 400) and main.residents.size() == 2, "and then it is gone")
	var marker := main.decor_of(Decor.Kind.MARKER)
	check(marker != null and marker.position.distance_to(Vector3(lay.x, 0, lay.z)) < 0.3 and marker.whose == main.departed[0].id, "a marker of its own stands where it lay")
	check(is_instance_valid(third) and not third.skin.is_empty() and await _until(func() -> bool: return third.lift > 1.0, 600), "a pale ghost of it drifts up")
	var ghost := third.get_instance_id()
	check(await _until(func() -> bool: return not is_instance_id_valid(ghost), 1200), "and out through the ceiling")
	main.notebook.open()
	main.notebook.page = 2
	main.notebook.refresh()
	check(main.notebook.pages() == Notebook.TITLES.size() + 3 and main.notebook.heading.text == late + ", gone" and main.notebook.body.text.contains("It lived") and not main.notebook.let_go.visible, "its page stays in the notebook, marked as gone")
	main.notebook.close()
	check(main.toast.text.findn("gone") < 0 and main.toast.text.findn(late) < 0, "nothing is written on the screen about it")
	# And here in front of the keeper, by the same wearing away
	late = fourth.me.name
	fourth.set_needs({"belly": 0.0, "health": 2.0, "energy": 90.0})
	fourth._wear(1.9 * 3600.0, false, 1.0, false)
	await _frames(5)
	check(fourth.health > 0.0 and fourth.state != Cryptlin.State.DYING, "the last of its health lasts as long with the game open")
	fourth._wear(0.1 * 3600.0, false, 1.0, false)
	check(await _until(func() -> bool: return fourth.state == Cryptlin.State.DYING, 10), "and then it lies down and goes still")
	await _tap(_screen(fourth.position + Vector3(0, 0.2, 0)))
	check(fourth.state == Cryptlin.State.DYING, "past poking")
	check(await _until(func() -> bool: return main.departed.size() == 2, 400) and main.residents.size() == 1 and main.departed[1].name == late and main.departed[1].lived > 0.0, "and is gone, with how long it lived written down")
	ghost = fourth.get_instance_id()
	await _until(func() -> bool: return not is_instance_id_valid(ghost), 1200)
	# The marker is a thing like any other in the room, and never on sale
	marker = main.decor_of(Decor.Kind.MARKER)
	one.position = Vector3(1.6, 0, -1.4)
	one._enter(Cryptlin.State.IDLE, 30.0)
	marker.position = Vector3(-1.0, 0, 0.6)
	await _frames(2)
	await _slide(_screen(marker.position + Vector3(0, 0.15, 0)), _screen(Vector3(0.6, 0, 1.0)))
	check(marker.position.x > 0.2, "its marker can be dragged about")
	check(not main.shelf.ids.has("marker"), "there is none on the row of things while they all stand in the room")
	await _slide(_screen(marker.position + Vector3(0, 0.15, 0)), _on_shelf("bone"))
	check(main.markers_away.size() == 1 and main.shelf.ids.has("marker") and main.shelf.counts.get("marker") == 1, "or put away, when it is on the row")
	main.embedded = true
	main._sync()
	check(main.shelf.ids.has("marker") and main.left_of("marker") == 0, "inside a page with a shop too: it is kept, not bought")
	main.embedded = false
	main._sync()
	await _tap(_on_shelf("marker"))
	check(main.markers_away.is_empty() and main.decors.filter(func(d: Decor) -> bool: return d.kind == Decor.Kind.MARKER).size() == 2 and not main.shelf.ids.has("marker"), "and brought out again")
	await _restart()
	one = main.residents[0].pet
	check(main.departed.size() == 2 and main.departed[1].name == late and main.decors.filter(func(d: Decor) -> bool: return d.kind == Decor.Kind.MARKER and d.whose > 0).size() == 2, "the markers and the pages are kept")

	# Pairing off: two grown ones that think well of each other and want for nothing
	main.new_egg().egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 2, 400), "another hatches, to keep the one that is left company")
	await _frames(40)
	var mate: Cryptlin = main.residents[1].pet
	# (a room that suits them both: whatever each has is what it likes, and water for a water kind)
	if (one.needs_water() or mate.needs_water()) and main.decor_of(Decor.Kind.POOL) == null:
		main.place_decor(Decor.Kind.POOL, Vector3(1.6, 0, -1.4))
	for m in main.messes.duplicate():
		main.clear_mess(m)
	_content(one, mate)
	check(one.comfort >= 55.0 and mate.comfort >= 55.0 and main.would_pair(one, mate) and main.would_pair(mate, one), "a happy grown pair would pair off")
	# The hard limits. A baby is never any part of it, whichever of the two it is
	mate.age = 0.0
	check(not main.would_pair(one, mate) and not main.would_pair(mate, one), "never with a baby")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  not if the grown one goes to it")
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor if it goes to the grown one")
	mate.partner = one
	mate._enter(Cryptlin.State.PAIR)
	one.partner = mate
	one._enter(Cryptlin.State.PAIR)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor by being put straight into it")
	one.age = 0.0
	one.meet(Cryptlin.State.PAIR, mate)
	check(not main.would_pair(one, mate) and one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor two babies")
	main.pass_time(40.0 * 3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired == 0.0, "  nor while nobody is looking")
	# It takes both: one that is willing and one that is not do not pair
	_content(one, mate)
	main.warm(mate, one, -50.0)
	check(main.regard(one, mate) >= Den.PAIR_REGARD and not main.would_pair(one, mate) and not main.would_pair(mate, one), "never unless each thinks well of the other: one willing is not enough")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  the willing one cannot start it")
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  and the other does not")
	main.pass_time(3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "  nor while nobody is looking")
	# Never close kin: a parent and its young, or two with a parent in common
	_content(one, mate)
	mate.me.parents = [one.me.id, 9001]
	check(main.kin(one.me, mate.me) and not main.would_pair(one, mate) and not main.would_pair(mate, one), "never a parent with its own young")
	one.meet(Cryptlin.State.PAIR, mate)
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  whichever goes to which")
	mate.me.parents = [9001, 9002]
	one.me.parents = [9003, 9001]
	check(main.kin(one.me, mate.me) and not main.would_pair(one, mate), "nor two with a parent in common")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  who do not")
	main.pass_time(3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "  nor while nobody is looking")
	mate.me.parents = []
	one.me.parents = []
	# Nor one that is hungry or poorly
	_content(one, mate)
	mate.belly = 30.0
	check(not main.would_pair(one, mate), "nor when one of them is hungry")
	_content(one, mate)
	one.health = 50.0
	check(not main.would_pair(one, mate), "nor when one of them is poorly")
	# A pair that would: out in the open, and mortified to be caught at it
	_content(one, mate)
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state == Cryptlin.State.PAIR and mate.state == Cryptlin.State.PAIR and mate.waiting and not one.waiting, "a pair that would: one goes over to the other")
	check(await _until(func() -> bool: return one.step == 1 and mate.step == 1 and one.lift > 0.1, 900) and one.feeling == Cryptlin.Feeling.LOVING, "and clambers up on it, all hearts")
	await _tap(_screen(mate.body_centre()))
	check(one.state == Cryptlin.State.PAIR and one.step == 2 and mate.step == 2 and one.feeling == Cryptlin.Feeling.SCARED and mate.feeling == Cryptlin.Feeling.SCARED and one.lift == 0.0, "a tap and they both stop dead, mortified")
	check(await _until(func() -> bool: return one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, 400) and one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired == 0.0, "and nothing comes of it")
	for way in 3:
		_content(one, mate)
		await _frames(2)
		one.meet(Cryptlin.State.PAIR, mate)
		await _until(func() -> bool: return one.step == 1, 900)
		await _frames(20)
		match way:
			0: main.call_all(Vector3(0, 0, 1.2))
			1: main.set_lamp(Den.Lamp.LOW if main.lamp_mode != Den.Lamp.LOW else Den.Lamp.BRIGHT)
			2: main.start_scan(mate.me)
		check(one.step == 2 and mate.step == 2 and one.state == Cryptlin.State.PAIR, "%s stops them too" % ["calling them", "changing the lamp", "the scanner"][way])
		main.stop_scan()
		await _until(func() -> bool: return _settled(one) and _settled(mate), 900)
	# Left to it, an egg is on the way, and is laid in the nest some hours later
	_content(one, mate)
	await _frames(2)
	one.meet(Cryptlin.State.PAIR, mate)
	check(await _until(func() -> bool: return one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, 1500), "left to it, they are soon done")
	var layer := one if not one.me.expecting.is_empty() else mate
	check(one.me.expecting.is_empty() != mate.me.expecting.is_empty() and one.me.paired > 0.0 and mate.me.paired > 0.0, "and one of them has an egg on the way")
	check(is_equal_approx(float(layer.me.expecting["due"]) - layer.me.paired, Den.EGG_HOURS * 3600.0) and main.residents.size() == 2, "due in %d hours, and not before" % int(Den.EGG_HOURS))
	check(not main.would_pair(one, mate), "they do not pair again for days")
	await _restart()
	one = main.residents[0].pet
	mate = main.residents[1].pet
	layer = one if not one.me.expecting.is_empty() else mate
	check(not layer.me.expecting.is_empty() and main.residents.size() == 2, "the egg on the way is kept in the save")
	# (the clock is put back for the test by moving what the save holds: the egg is due by the
	# clock on the wall, so that is moved too)
	layer.me.expecting["due"] = float(layer.me.expecting["due"]) - Den.EGG_HOURS * 3600.0 - 60.0
	await _come_back_after(Den.EGG_HOURS * 3600.0 + 60.0)
	one = main.residents[0].pet
	mate = main.residents[1].pet
	check(main.residents.size() == 3 and main.residents[2].egg != null and one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "when the hours have gone by there is an egg")
	var young := main.residents[2]
	check(young.egg.position.distance_to(main.nest_pos) < 0.4, "in the nest")
	check(young.kind in [one.kind, mate.kind] and young.parents == [one.me.id, mate.me.id] and young.id != one.me.id and young.id != mate.me.id, "of the kind of one of its parents, with both of them written down")
	main.chosen = young
	main.notebook.open()
	check(main.notebook.body.text.contains(one.me.name) and main.notebook.body.text.contains(mate.me.name), "and named on its page in the notebook")
	main.notebook.close()
	# One asleep by an egg keeps it warm
	var brooded := young.egg.warmth
	main.set_lamp(Den.Lamp.OFF)
	one.position = main.nest_pos + Vector3(0.3, 0, 0)
	one._enter(Cryptlin.State.SLEEP)
	await _frames(120)
	check(young.egg.warmth > brooded + 1.0, "one asleep beside the egg broods it, lamp or no lamp")
	main.set_lamp(Den.Lamp.BRIGHT)
	young.egg.warmth = 100.0
	check(await _until(func() -> bool: return young.pet != null, 400), "it hatches")
	var child := young.pet
	check(child.kind in [one.kind, mate.kind] and child.is_baby(), "into a baby of a parent's kind (%s)" % child.kind_name())
	check(child.fur_colour.to_html(false) in [one.fur_colour.to_html(false), mate.fur_colour.to_html(false)], "in the coat of one of them")
	check(child.nature in [one.nature, mate.nature] and child.nature != child.nature2, "with a nature from one of them (%s)" % child.nature_name())
	var coated := one if child.fur_colour.to_html(false) == one.fur_colour.to_html(false) else mate
	var other := mate if coated == one else one
	check(child.marks == coated.marks, "the markings that go with that coat")
	check(is_equal_approx(float(child.shape["head"]), float(other.shape["head"])), "and the head of the other, for its kind")
	check(main.notebook._notes(child).contains("Its parents are %s and %s" % [one.me.name, mate.me.name]), "and its page records its parents")
	# Grown, it is still their young, and the room has its limit
	child.set_needs({"belly": 90.0, "energy": 90.0, "health": 100.0, "age": Cryptlin.GROW_AGE})
	child.fav_ground = main.floor_style
	child.fav_lamp = main.lamp_mode
	child.hate_decor = Decor.Kind.DISH
	child.comfort = 90.0
	_content(one, mate)
	main.warm(child, one, 95.0 - main.regard(child, one))
	main.warm(one, child, 95.0 - main.regard(one, child))
	check(not child.is_baby() and main.regard(one, child) >= Den.PAIR_REGARD and not main.would_pair(one, child) and not main.would_pair(child, mate), "grown up and fond of them, it is still their young: never")
	child.meet(Cryptlin.State.PAIR, one)
	check(child.state != Cryptlin.State.PAIR and one.state != Cryptlin.State.PAIR, "  whoever starts it")
	# With nobody looking, a happy pair gets round to it in a day or so; a full room has no egg
	main.new_egg()
	check(main.residents.size() == Den.MAX_RESIDENTS, "the room is full")
	one.me.paired = 0.0
	mate.me.paired = 0.0
	for day in 6:
		if one.me.paired > 0.0:
			break
		_content(one, mate)
		main.pass_time(24.0 * 3600.0)
	# (if the egg is still on the way, its time comes)
	for r in main.residents:
		if not r.expecting.is_empty():
			r.expecting["due"] = 0.0
	main._lay_due()
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired > 0.0 and main.residents.size() == Den.MAX_RESIDENTS, "with nobody looking a happy pair gets round to it, but a full room gets no egg")
	check(child.me.paired == 0.0 and child.me.expecting.is_empty(), "and their young had no part in it")
	await _restart()
	check(main.residents[2].parents.size() == 2 and main.residents[2].fur != "" and main.residents[2].nature >= 0 and main.residents[0].paired > 0.0, "parentage and what was inherited are kept in the save")

	# A save from when there was only ever one
	main.queue_free()
	await _frames(3)
	var old := FileAccess.open(save, FileAccess.WRITE)
	old.store_string(JSON.stringify({"v": 2, "name": "Old", "kind": Cryptlin.KINDS[kind]["title"], "seed": 7, "hatched": true, "born": Time.get_unix_time_from_system() - 5000.0, "needs": {"belly": 52.0, "fun": 50.0, "energy": 90.0, "love": 30.0, "age": 5000.0}, "known": {"toy": true}, "floor": 2, "time": Time.get_unix_time_from_system()}))
	old.close()
	main = _start()
	await _frames(5)
	check(main.residents.size() == 1 and main.who().name == "Old" and main.who().pet != null and main.who().pet.kind == kind and main.who().look_seed == 7, "a save from when there was only one loads as a room with that one in it")
	check(absf(main.who().pet.belly - 52.0) < 1.0 and main.who().known.get("toy", false) and main.who().pet.is_baby() and main.floor_style == 2, "as it was")
	await _restart()
	check(main.residents.size() == 1 and main.who().name == "Old" and main.who().id > 0, "and is saved again as one of a list")
	main.queue_free()
	await _frames(3)
	old = FileAccess.open(save, FileAccess.WRITE)
	old.store_string(JSON.stringify({"v": 2, "name": "", "kind": Cryptlin.KINDS[kind]["title"], "seed": 7, "hatched": false, "warmth": 40.0, "needs": {}, "known": {}, "time": Time.get_unix_time_from_system()}))
	old.close()
	main = _start()
	await _frames(5)
	check(main.residents.size() == 1 and main.who().egg != null and main.who().kind == kind and main.who().egg.warmth > 39.0, "an old save of an egg loads as that egg")

	# Inside a site with a shop, eggs are stock; but nobody is left without one
	main.dev_show(kind)
	await _frames(10)
	main.embedded = true
	main.stock = {}
	main._sync()
	check(not main.shelf.ids.has("egg"), "with a shop, there are no eggs on the shelf until one is bought")
	main.use("egg")
	check(main.residents.size() == 1, "and none to lay")
	main.ask_let_go(main.who())
	main._answer(true)
	check(await _until(func() -> bool: return main.who().egg != null, 1200) and main.residents.size() == 1, "but a room left empty is still sent an egg for nothing")
	main.stock = {"egg": 1}
	main._sync()
	check(main.shelf.ids.has("egg") and main.shelf.counts.get("egg") == 1, "an egg bought is on the shelf")
	main.use("egg")
	check(main.residents.size() == 2 and main.left_of("egg") == 0 and not main.shelf.ids.has("egg"), "and is used up when it is laid")
	main.use("egg")
	check(main.residents.size() == 2, "after which there are no more")
	main.embedded = false
	main._sync()

	# The test panel: five taps in the corner open it, and it can put any kind in the room
	var corner_tap := root.get_final_transform() * Vector2(40, 40)
	for i in 5:
		await _tap(corner_tap)
	check(main.dev.visible, "five taps in the corner open the test panel")
	for k in Cryptlin.KINDS.size():
		main.dev_show(k)
		await _frames(20)
		check(main.who().pet != null and main.who().pet.kind == k and main.who().egg == null and not main.who().pet.is_baby(), "the panel shows a %s" % main.who().pet.kind_name())
		main.start_scan()
		await _frames(3)
		check(main.who().pet.xrayed and main.who().pet.inside_at("brain").y > main.who().pet.inside_at("stomach").y, "  with its insides in the right order")
		main.stop_scan()
	main._dev_egg()
	await _frames(20)
	check(main.who().pet == null and main.who().egg != null, "and its egg")
	main._dev_egg()
	await _frames(170)
	check(main.who().pet != null and main.who().egg == null, "which hatches when told to")
	print("smoke: %d failure(s)" % failures)
	quit(failures)
