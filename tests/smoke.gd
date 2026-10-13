extends SceneTree
## Smoke test: the egg and hatching, naming, the shelf (food, toys, things for the room, ground),
## the pool and the kinds that need one,
## the lamp, petting, calling, sleep, time passing while away, the scanner, the notebook and
## sending it off for a new egg.
## godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..18]
## (touches are sent as window pixels, like a real finger)

const SAVE := "user://smoke_test.json"

var main: Den
var failures := 0
var kind := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	main = _start()
	_run.call_deferred()


func _start() -> Den:
	var m: Den = load("res://main.tscn").instantiate()
	m.save_path = SAVE
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
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	data["time"] = float(data["time"]) - seconds
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	main = _start()
	await _frames(5)


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


func _run() -> void:
	# The egg
	await _frames(5)
	check(main.egg != null and main.pet == null, "a new game starts with an egg (%s)" % main.egg.title())
	check(main.shelf.ids.has("bone") and main.shelf.ids.has("notebook") and main.shelf.ids.size() == Items.LIST.size(), "everything is on the shelf (%d things)" % main.shelf.ids.size())
	main.use("bone")
	check(main.snacks.is_empty(), "but there is nothing to feed yet")
	check(await _until(func() -> bool: return main.egg.landed, 300), "the egg drops into the light")
	var warm := main.egg.warmth
	await _frames(90)
	var gained := main.egg.warmth - warm
	check(gained > 0.0, "the lamp warms it (%.1f)" % main.egg.warmth)
	main.set_lamp(Den.Lamp.HEAT)
	warm = main.egg.warmth
	await _frames(90)
	check(main.egg.warmth - warm > gained * 1.8, "the heat lamp warms it faster")
	main.set_lamp(Den.Lamp.OFF)
	await _frames(20)
	warm = main.egg.warmth
	await _frames(60)
	check(is_equal_approx(main.egg.warmth, warm), "and not at all when it is out")
	main.set_lamp(Den.Lamp.BRIGHT)
	warm = main.egg.warmth
	await _tap(_screen(main.egg.centre()))
	check(main.egg.warmth > warm + 2.0, "a tap warms it a little")
	main.egg.warmth = 40.0
	main.save_game()
	await _restart()
	check(main.egg != null and main.pet_kind == kind and main.egg.warmth > 39.0, "a saved egg is still there, as warm")
	check(main.egg.stage == 1, "and as cracked")
	var at := _screen(main.egg.centre())
	_touch(at, true)
	var most := 0
	for i in 1500:
		if main.pet != null:
			break
		most = maxi(most, main.egg.stage)
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	_touch(at, false)
	check(most == 2, "rubbing it cracks it further")
	check(main.pet != null and main.egg == null, "and then it hatches")
	var pet := main.pet
	await _frames(30)
	check(pet.kind == kind, "what was in the egg is a %s" % pet.kind_name())
	check(pet.legs.size() == 2 and pet.eyes.size() >= 1, "a cryptlin is built")
	check(pet.nature != pet.nature2 and pet.nature_name().contains(", "), "with two natures (%s)" % pet.nature_name())
	check(pet.is_baby() and pet.growing_left() > 24.0 * 3600.0, "a baby, with more than a day of growing to do")

	# Its name
	check(main.pet_name != "", "it has a name made up for it (%s)" % main.pet_name)
	main.open_namer()
	check(main.namer.visible, "and you are asked what to call it")
	main._name_roll()
	main.name_edit.text = "  Smoke  "
	main._name_done()
	check(not main.namer.visible and main.pet_name == "Smoke", "what you type is its name")
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
	await _slide(_on_shelf(food), _screen(Vector3(-1.0, 0.9, 0.5)), 8, _on_shelf(food) - Vector2(0, 160))
	check(main.snacks.size() == 1 and main.snacks[0].position.x < -0.5, "dragged up off the shelf, it drops where you let go")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "and is eaten too")

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
	var name := main.pet_name
	var seed_was := main.pet_seed
	await _restart()
	check(main.pet_name == name and main.pet_seed == seed_was and main.pet != null and main.pet.kind == kind, "the same cryptlin is there next time")
	check(absf(main.pet.belly - 64.0) < 1.0, "as full as it was left (%.0f)" % main.pet.belly)
	main.pet.belly = 100.0
	main.pet.energy = 90.0
	await _come_back_after(6.0 * 3600.0)
	pet = main.pet
	check(pet.belly < 75.0 and pet.belly > 30.0, "six hours away and it is hungrier, not starving (%.0f)" % pet.belly)
	check(pet.is_baby(), "and still a baby")
	pet.belly = 100.0
	await _come_back_after(40.0 * 3600.0)
	pet = main.pet
	check(pet.belly < 15.0, "left for a day and a half, it is starving (%.0f)" % pet.belly)
	check(not pet.is_baby() and is_equal_approx(pet.grow, pet.adult_size), "and has grown up, %.2f times the usual size" % pet.adult_size)

	# Tastes: its favourite food, the one it cannot stand, and its favourite toy
	pet.set_needs({"belly": 40.0, "fun": 50.0, "energy": 90.0, "love": 40.0})
	main.known = {}
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.position = Vector3(0.3, 0, 0.4)
	main.feed(pet.yuck_food)
	check(await _until(func() -> bool: return main.known.get("yuck", false), 1500), "it spits out %s" % Snack.PLURALS[pet.yuck_food])
	check(pet.feeling == Cryptlin.Feeling.DISGUSTED and main.snacks.is_empty(), "and is disgusted")
	check(main.toast.text.findn(Snack.PLURALS[pet.yuck_food]) < 0, "nothing is written on the screen about it")
	pet.belly = 40.0
	pet.flash_time = 0.0
	main.feed(pet.fav_food)
	check(await _until(func() -> bool: return main.known.get("food", false), 1500), "it loves %s" % Snack.PLURALS[pet.fav_food])
	check(pet.feeling == Cryptlin.Feeling.LOVING, "and shows it")
	check(main.shelf.marks.get(Items.id_of("food", pet.fav_food)) == "heart" and main.shelf.marks.get(Items.id_of("food", pet.yuck_food)) == "cross", "the shelf marks what it loves and what it hates")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.energy = 90.0
	main.play_ball(pet.fav_toy)
	check(main.ball != null and main.ball.kind == pet.fav_toy, "the %s comes out" % Ball.PLAIN[pet.fav_toy])
	check(await _until(func() -> bool: return main.known.get("toy", false), 2400), "and turns out to be its favourite")
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
	check(await _until(func() -> bool: return main.known.get("decor+" + Decor.IDS[liked], false), 900), "it likes having it about")
	check(main.comfort_of(pet) > comfort, "and is more at home for it (%.0f)" % main.comfort_of(pet))
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	comfort = main.comfort_of(pet)
	main.use(Decor.IDS[pet.hate_decor])
	check(await _until(func() -> bool: return main.known.get("decor-" + Decor.IDS[pet.hate_decor], false), 900), "it cannot stand the %s" % Decor.PLAIN[pet.hate_decor])
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
	main.known.erase("water")
	var dry := main.comfort_of(pet)
	check(pet.dry() == pet.needs_water() and not main.notebook._notes(pet).contains("pool"), "nothing says yet whether it needs water")
	await _tap(_on_shelf("pool"))
	var pool := main.decor_of(Decor.Kind.POOL)
	check(pool != null and pool.radius > Decor.RADII[Decor.Kind.DISH] * 2.0, "a tap on the pool stands it in the room, a good deal bigger than the dish")
	check(not Decor.Kind.POOL in pet.like_decor and pet.hate_decor != Decor.Kind.POOL, "the pool is no part of its likes and dislikes")
	check(await _until(func() -> bool: return main.known.get("water", false), 900), "the cryptlin goes to look, and whether it needs water is found out")
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
	check(await _until(func() -> bool: return main.known.get("ground", false), 600), "which is the ground it is happiest on")

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
	for i in Notebook.TITLES.size() - 1:
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
	check(main.floor_style == main.pet.fav_ground and main.nest_style == 1 and main.lamp_mode == Den.Lamp.LOW, "the floor, the nest and the lamp are kept")
	check(main.decor_of(Decor.Kind.SKULL) != null and main.nest_pos.distance_to(nest_at) < 0.01, "and where things stand")
	check(main.known.get("food", false) and main.known.get("ground", false) and main.pet_name == "Smoke", "and what you know of it")

	# Played inside a site with a shop: only what comes free and what was bought
	main.embedded = true
	main.stock = {"fish": 2, "cave": -1}
	main._sync()
	check(main.shelf.ids.has("fish") and main.shelf.ids.has("cave") and main.shelf.ids.has("bone") and not main.shelf.ids.has("berries"), "with a shop, the shelf holds what is free and what was bought")
	main.pet._enter(Cryptlin.State.IDLE, 3.0)
	main.pet.belly = 30.0
	main.feed(Snack.Kind.FISH)
	check(main.left_of("fish") == 1 and main.shelf.counts.get("fish") == 1, "and food bought gets used up")
	main.feed(Snack.Kind.BERRIES)
	check(main.snacks.size() == 1, "and what was not bought cannot be used")
	main.embedded = false
	main._clear_toys()
	main._sync()

	# A new egg
	main.set_lamp(Den.Lamp.BRIGHT)
	main.pet._enter(Cryptlin.State.IDLE, 3.0)
	main.ask_new_egg()
	check(main.ask.visible, "asking for a new egg asks first")
	main._answer(false)
	await _frames(5)
	check(not main.ask.visible and main.pet != null and not main.leaving, "saying no keeps it")
	main.ask_new_egg()
	main._answer(true)
	check(main.leaving and main.pet.state == Cryptlin.State.LEAVE, "saying yes sends it off")
	check(await _until(func() -> bool: return main.egg != null, 1200), "and a new egg comes")
	check(main.pet == null and main.ball == null and main.pet_kind != kind, "holding a different kind (%s)" % main.egg.title())
	await _tap(_on_shelf("scanner"))
	check(main.scanning, "the scanner works on an egg too")
	main.stop_scan()

	# The test panel: five taps in the corner open it, and it can put any kind in the room
	var corner_tap := root.get_final_transform() * Vector2(40, 40)
	for i in 5:
		await _tap(corner_tap)
	check(main.dev.visible, "five taps in the corner open the test panel")
	for k in Cryptlin.KINDS.size():
		main.dev_show(k)
		await _frames(20)
		check(main.pet != null and main.pet.kind == k and main.egg == null and not main.pet.is_baby(), "the panel shows a %s" % main.pet.kind_name())
		main.start_scan()
		await _frames(3)
		check(main.pet.xrayed and main.pet.inside_at("brain").y > main.pet.inside_at("stomach").y, "  with its insides in the right order")
		main.stop_scan()
	main._dev_egg()
	await _frames(20)
	check(main.pet == null and main.egg != null, "and its egg")
	main._dev_egg()
	await _frames(170)
	check(main.pet != null and main.egg == null, "which hatches when told to")
	print("smoke: %d failure(s)" % failures)
	quit(failures)
