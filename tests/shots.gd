extends SceneTree
## Screenshots of the cryptlin at its various doings.
## godot --path . -s tests/shots.gd -- --shots=<dir> [--portrait] [--seed=N] [--kind=0..29] [--egg|--ui [--baby]|--scan|--faces|--many|--wheel|--variety [--with=K [--over]] [--per=1..4] [--side|--turn=DEGREES] [--baby] [--dark]|--poses [--baby]|--strides [--baby]]
## With --egg: the egg of that kind, cracking and hatching, and then the new-egg question.
## With --ui: the room done up, the pool, the lamp, the scanner and the notebook. With --scan: the
## scanner on the wheel, on the finger, and pointed at a grown one, a baby and an egg. With --faces:
## each of the faces that go up over its head. With --many: three of different kinds sharing the room.
## With --variety: one sheet of twelve of the kind, each of another seed, stood in rows facing
## the front under an even light (or side on, as babies, in the dark, or as the scanner shows
## them; fewer to a row with --per, for the wide ones; turned any way with --turn; with --with=K every
## other one is of kind K, to see two kinds side by side).
## With --wheel: the wheel of things at both of its stops and part of the way round.
## With --walk [--baby]: the kind walking across the room, four moments of it, and going away up it, three (with the squatchling's look back over its shoulder).
## With --knack [--step=N] [--at=SECONDS] [--then=SECONDS]: the kind taking a turn at the one thing only it does, with another beside it: two moments of it side by side (so long after it gets to part N of it, and so long after that).
## With --pool (and no other of those): four in a room with the pool in it, in each place it fits and under each lamp.

# The save this run uses: one for each kind and shape of screen, so that several can be run at once
var save := "user://shots_test.json"

var main: Den
var out := "user://shots"
var portrait := false
var look := 0
var kind := 0
# Something more to tell this run's save by (--tag=), for two checkouts of the game run at once
var tag := ""
var ui_only := false
var scan_only := false
var egg_only := false
var faces_only := false
var baby := false
var many := false
var variety := false
var beside := -1
var side_on := false
var dark := false
# With --with: the other kind stands behind the kind in question, and there is a thing of the room behind the last of them
var over := false
var bare := false
var per_row := 4
var turned := 0.0
var wheel := false
var walk := false
var pool := false
var knack := false
var tidy := false
var book := false
var from_step := 1
var first_wait := 0.8
var second_wait := 1.8
var poses := false
var strides := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out = arg.trim_prefix("--shots=")
		if arg.begins_with("--seed="):
			look = int(arg.trim_prefix("--seed="))
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
		if arg.begins_with("--tag="):
			tag = "_" + arg.trim_prefix("--tag=")
		if arg == "--egg":
			egg_only = true
		if arg == "--baby":
			baby = true
		if arg == "--faces":
			faces_only = true
		if arg == "--ui":
			ui_only = true
		if arg == "--scan":
			scan_only = true
		if arg == "--knack":
			knack = true
		if arg.begins_with("--step="):
			from_step = int(arg.trim_prefix("--step="))
		if arg.begins_with("--at="):
			first_wait = float(arg.trim_prefix("--at="))
		if arg.begins_with("--then="):
			second_wait = float(arg.trim_prefix("--then="))
		if arg == "--tidy":
			tidy = true
		if arg == "--book":
			book = true
		if arg == "--pool":
			pool = true
		if arg == "--many":
			many = true
		if arg == "--variety":
			variety = true
		if arg.begins_with("--with="):
			beside = int(arg.trim_prefix("--with="))
		if arg == "--side":
			side_on = true
		if arg.begins_with("--per="):
			per_row = clampi(int(arg.trim_prefix("--per=")), 1, 4)
		if arg.begins_with("--turn="):
			turned = deg_to_rad(float(arg.trim_prefix("--turn=")))
		if arg == "--xray":
			bare = true
		if arg == "--over":
			over = true
		if arg == "--dark":
			dark = true
		if arg == "--walk":
			walk = true
		if arg == "--wheel":
			wheel = true
		if arg == "--poses":
			poses = true
		if arg == "--strides":
			strides = true
		if arg == "--portrait":
			portrait = true
	DirAccess.make_dir_recursive_absolute(out)
	save = "user://shots_test_%d%s%s.json" % [kind, "_p" if portrait else "", tag]
	DisplayServer.window_set_size(Vector2i(540, 1170) if portrait else Vector2i(1280, 720))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	if variety:
		_run_variety.call_deferred()
		return
	if many or pool or knack or book:
		# Three of different kinds (or, for the pool, four), grown, as a save holds them
		var three: Array = []
		for i in (4 if pool or book else (2 if knack else 3)):
			var k := (kind + i * 5) % Cryptlin.KINDS.size()
			three.append({"id": i + 1, "name": ["Mog", "Pim", "Zog", "Nib"][i], "kind": Cryptlin.KINDS[k]["title"], "seed": maxi(look, 1) + i * 37, "hatched": true, "born": Time.get_unix_time_from_system() - 200000.0, "needs": {"belly": 70.0, "fun": 70.0, "energy": 90.0, "love": 50.0}})
		var f := FileAccess.open(save, FileAccess.WRITE)
		f.store_string(JSON.stringify({"v": 3, "residents": three, "next_id": three.size() + 1, "time": Time.get_unix_time_from_system()}))
		f.close()
	elif not egg_only:
		var f := FileAccess.open(save, FileAccess.WRITE)
		f.store_string(JSON.stringify({"name": "Seed %d" % look, "kind": Cryptlin.KINDS[kind]["title"], "seed": maxi(look, 1), "hatched": true, "needs": {}, "time": Time.get_unix_time_from_system()}))
		f.close()
	main = load("res://main.tscn").instantiate()
	main.save_path = save
	main.first_kind = kind
	main.ask_names = false
	root.add_child(main)
	if poses or strides:
		_run_close.call_deferred()
	elif tidy:
		_run_tidy.call_deferred()
	elif book:
		_run_book.call_deferred()
	elif knack:
		_run_knack.call_deferred()
	elif pool:
		_run_pool.call_deferred()
	elif many:
		_run_many.call_deferred()
	elif walk:
		_run_walk.call_deferred()
	elif wheel:
		_run_wheel.call_deferred()
	elif scan_only:
		_run_scan.call_deferred()
	elif ui_only:
		_run_ui.call_deferred()
	elif faces_only:
		_run_faces.call_deferred()
	elif egg_only:
		_run_egg.call_deferred()
	else:
		_run.call_deferred()


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/k%d_%s%s.png" % [out, kind, name, "_p" if portrait else ""])


# A piece of the picture round a place in the room, blown up, to see small things by
func _close_up(name: String, at: Vector3, size := Vector2i(340, 220), times := 3) -> void:
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	var scale := Vector2(shot.get_size()) / main.get_viewport().get_visible_rect().size
	var mid := Vector2i(main.screen_of(at) * scale)
	var cut := Rect2i(mid - size / 2, size).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
	var piece := shot.get_region(cut)
	piece.resize(cut.size.x * times, cut.size.y * times, Image.INTERPOLATE_NEAREST)
	piece.save_png("%s/k%d_%s%s.png" % [out, kind, name, "_p" if portrait else ""])


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _until(done: Callable, seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not done.call():
		await process_frame
		left -= 1.0 / 60.0


# The room done up, the shelf slid along, each lamp setting, the scanner, the notebook, the
# card that asks for a name, and the test panel
func _run_ui() -> void:
	await _wait(1.0)
	var pet := main.who().pet
	pet.set_needs({"belly": 35.0, "fun": 70.0, "energy": 80.0, "love": 55.0, "age": 0.0 if baby else Cryptlin.GROW_AGE})
	pet.position = Vector3(0.3, 0, 0.6)
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.2)
	await _snap("u1_bare")
	main.place_decor(Decor.Kind.CAVE, Vector3(-1.3, 0, -1.1))
	main.place_decor(Decor.Kind.ROCK, Vector3(1.5, 0, -0.9))
	main.place_decor(Decor.Kind.FERN, Vector3(1.7, 0, 0.6))
	main.place_decor(Decor.Kind.PUMPKIN, Vector3(-0.3, 0, -1.5))
	main.place_decor(Decor.Kind.DISH, Vector3(-1.5, 0, 0.9))
	main.move_nest(Vector3(0.9, 0, -1.4))
	main.who().known = {"food": true, "yuck": true, "toy": true}
	main._sync()
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.5)
	await _snap("u2_room")
	for style in [5, 2, 6]:
		main.set_ground(style)
		main.shelf.show_item(Items.id_of("ground", style))
		pet._enter(Cryptlin.State.STARE)
		await _wait(1.0)
		await _snap("u3_ground%d" % style)
	main.shelf.show_item("log")
	for mode in [Den.Lamp.LOW, Den.Lamp.HEAT, Den.Lamp.OFF, Den.Lamp.BRIGHT]:
		main.set_lamp(mode)
		pet._enter(Cryptlin.State.STARE)
		await _wait(1.2)
		await _snap("u4_lamp_%s" % Den.LAMPS[mode]["title"])
	pet._enter(Cryptlin.State.LURK)
	await _until(func() -> bool: return pet.step == 1, 9.0)
	await _wait(1.0)
	await _snap("u5_cave")
	# Each of the other shelters in turn, with the cryptlin inside
	for k in range(Decor.Kind.POOL + 1, Decor.Kind.POT + 1):
		var den := main.place_decor(k, Vector3(0.1, 0, 0.3))
		den.rotation.y = 0.0
		pet._enter(Cryptlin.State.LURK)
		pet.visiting = den
		pet.target = den.position
		await _until(func() -> bool: return pet.state == Cryptlin.State.LURK and pet.step == 1, 9.0)
		await _wait(1.2)
		await _snap("u5_%s" % Decor.IDS[k])
		main.remove_decor(den)
	pet.visiting = main.decor_of(Decor.Kind.ROCK)
	pet._enter(Cryptlin.State.VISIT)
	pet.visiting = main.decor_of(Decor.Kind.ROCK)
	await _until(func() -> bool: return pet.step == 1, 9.0)
	await _wait(1.5)
	await _snap("u6_rock")
	var pool := main.place_decor(Decor.Kind.POOL, Vector3(0.1, 0, 0.5))
	await _wait(0.5)
	pet._enter(Cryptlin.State.VISIT)
	pet.visiting = pool
	await _until(func() -> bool: return pet.step >= 1, 9.0)
	await _wait(2.2)
	await _snap("u6_pool")
	main.remove_decor(pool)
	pet._enter(Cryptlin.State.IDLE, 20.0)
	pet.position = Vector3(0.2, 0, 0.7)
	await _wait(0.6)
	main.shelf.show_item("notebook")
	main.start_scan()
	await _wait(1.6)
	await _snap("u7_scan")
	main.stop_scan()
	main.notebook.open()
	await _wait(0.3)
	await _snap("u8_notes")
	main.notebook.turn(1)
	await _wait(0.2)
	await _snap("u9_care")
	main.notebook.open_at(main.notebook.chapters() - 1)
	await _wait(0.2)
	await _snap("u10_odds")
	main.notebook.close()
	main.open_namer(main.who())
	await _wait(0.3)
	await _snap("u11_name")
	main._name_done()
	main.dev_toggle()
	await _wait(0.3)
	await _snap("u12_dev")
	quit()


# Keeping the place tidy: the wheel before and after a thing is stood in the room, the broom on
# the wheel and at work on a dropping, each toy new, scuffed and far gone, a ball breaking, and
# its bits on the floor with the ball gone from the wheel
func _run_tidy() -> void:
	await _wait(1.0)
	var pet := main.who().pet
	pet.set_needs({"belly": 80.0, "fun": 70.0, "energy": 90.0, "love": 55.0, "age": Cryptlin.GROW_AGE, "bowel": 0.0, "bladder": 0.0})
	pet.position = Vector3(-1.2, 0, 0.2)
	pet.ball_cooldown = 9999.0
	pet.beg_cooldown = 9999.0
	pet._enter(Cryptlin.State.STARE)
	main.shelf.show_item("skull")
	await _wait(1.0)
	await _snap("t1_wheel_before")
	main.place_decor(Decor.Kind.SKULL, Vector3(0.9, 0, 0.3))
	pet._enter(Cryptlin.State.STARE)
	await _wait(0.12)
	await _snap("t2_wheel_closing")
	await _wait(0.9)
	pet._enter(Cryptlin.State.STARE)
	await _snap("t3_wheel_after")
	# The same thing carried back down over the wheel, which turns to its place and makes room
	main.shelf.show_item("bone")
	main.held_thing = main.decor_of(Decor.Kind.SKULL)
	main.grab = Den.Grab.THING
	main._drag_thing(main.shelf.global_position + main.shelf.size * Vector2(0.3, 0.6))
	await _wait(0.9)
	await _snap("t3b_putting_away")
	main._drag_thing(main.screen_of(Vector3(0.9, 0, 0.3)))
	main.shelf.bring("")
	main.grab = Den.Grab.NONE
	main.held_thing = null
	await _wait(0.3)
	var dropping := main.leave_mess(Mess.Kind.DROPPING, Vector3(0.1, 0, 1.2), pet)
	main.leave_mess(Mess.Kind.PUDDLE, Vector3(-0.7, 0, 1.4), pet)
	main.shelf.show_item("broom")
	pet._enter(Cryptlin.State.STARE)
	await _wait(0.6)
	await _snap("t4_broom_wheel")
	main._pull("broom", main.screen_of(Vector3(0.9, 0, 1.3)))
	await _wait(0.4)
	await _snap("t5_broom_carried")
	main.hold_point = dropping.position
	await _until(func() -> bool: return main.sweeping != null and main.sweep_time > 0.2, 2.0)
	await _snap("t6_sweeping")
	await _close_up("t6_sweeping_close", dropping.position)
	await _wait(0.14)
	await _snap("t6_sweeping2")
	await _until(func() -> bool: return main.sweeping == null, 3.0)
	main.grab = Den.Grab.NONE
	for m in main.messes.duplicate():
		main.clear_mess(m)
	# Each toy three times over: new, scuffed and far gone
	var row: Array[Ball] = []
	for k in Ball.NAMES.size():
		for worn in 3:
			var toy := Ball.new(k)
			toy.held = true
			toy.wear = [0.0, Ball.SCUFFED, Ball.FAR_GONE][worn]
			toy.show_wear()
			toy.position = Vector3(-2.0 + k * 1.1 + worn * 0.36, Ball.R, 1.3)
			toy.rotation.y = 0.5
			main.add_child(toy)
			row.append(toy)
	pet.position = Vector3(-1.9, 0, -0.9)
	pet._enter(Cryptlin.State.STARE)
	await _wait(0.6)
	await _snap("t7_toys_new_scuffed_far_gone")
	await _close_up("t7_toys_close", Vector3(0, 0.1, 1.3), Vector2i(640, 110), 2)
	for toy in row:
		toy.queue_free()
	# A ball on its last legs, and the kick that ends it
	main.play_ball(Ball.Kind.BALL)
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(0.3, Ball.R, 1.0)
	main.ball.wear = Ball.WORN_OUT - 0.01
	main.ball.show_wear()
	pet.position = Vector3(-0.4, 0, 0.9)
	pet.yaw = 1.2
	pet._enter(Cryptlin.State.IDLE, 30.0)
	main.shelf.show_item("stone")
	await _wait(0.8)
	await _snap("t8_worn_ball")
	main.wear_toy(main.ball, pet)
	await _wait(0.16)
	await _snap("t9_breaking")
	await _close_up("t9_breaking_close", Vector3(0, 0.2, 1.0))
	await _wait(0.9)
	await _snap("t10_broken")
	await _close_up("t10_broken_close", Vector3(0, 0.2, 1.0))
	quit()


# The notebook, leaf by leaf, with four in the room and a good deal found out about them
func _run_book() -> void:
	await _wait(1.0)
	var all := main.pets()
	for i in all.size():
		var pet := all[i]
		pet.position = Vector3(-1.2 + i * 0.8, 0, 0.4 - 0.4 * (i % 2))
		pet._enter(Cryptlin.State.STARE)
		pet.me.known = {"food": true, "yuck": true, "toy": true, "ground": true, "lamp": true, "water": true, "knack": i != 1}
		for liked: int in pet.like_decor:
			pet.me.known["decor+" + Decor.IDS[liked]] = true
		if i != 2:
			pet.me.known["decor-" + Decor.IDS[pet.hate_decor]] = true
	all[1].me.name = "Bartholomew Mog"
	all[3].set_needs({"age": 3000.0})
	main.new_egg() if main.room_for_more() else null
	main.chosen = all[0].me
	main.notebook.open()
	for i in main.notebook.pages():
		await _wait(0.25)
		await _snap("b%02d" % i)
		main.notebook.turn(1)
	quit()


# The wheel of things: at its first stop, part of the way round, between two things with a
# finger on it, at its last stop, and as it is inside a page with a shop
func _run_wheel() -> void:
	await _wait(1.0)
	var pet := main.who().pet
	pet.set_needs({"belly": 60.0, "fun": 70.0, "energy": 80.0, "love": 55.0, "age": Cryptlin.GROW_AGE})
	pet.position = Vector3(0.3, 0, 0.2)
	pet._enter(Cryptlin.State.STARE)
	main.place_decor(Decor.Kind.ROCK, Vector3(1.2, 0, -0.9))
	main.who().known = {"food": true, "yuck": true, "toy": true}
	main._sync()
	main.shelf.show_item("scanner")
	await _wait(1.0)
	await _snap("w1_first")
	main.shelf.show_item("ball")
	await _wait(0.5)
	await _snap("w2_toys")
	main.shelf.show_item("log")
	main.shelf.grab()
	main.shelf.drag(-main.shelf._unit() * Shelf.PITCH * 0.5, 0.0)
	await _wait(0.5)
	await _snap("w3_between")
	main.shelf.let_go()
	main.shelf.show_item("notebook")
	await _wait(0.5)
	await _snap("w4_last")
	# Inside a page with a shop: only what comes free and what was bought, and how many are left
	main.embedded = true
	main.stock = {"fish": 3, "candy": 1, "egg": 2, "cave": 1}
	main._sync()
	main.shelf.show_item("fish")
	await _wait(0.5)
	await _snap("w5_shop")
	# An empty room there, with an egg in stock: the wheel holds the egg out
	main.stock = {"egg": 1}
	main.ask_let_go(main.who())
	main._answer(true)
	await _until(func() -> bool: return main.residents.is_empty(), 20.0)
	await _wait(0.6)
	await _snap("w6_gift")
	quit()


# The scanner: on the wheel, on the end of a finger, pointed at a grown one in the middle of the
# room, at the same one over on the left (when it is held on the right), at a baby and at an egg
func _run_scan() -> void:
	await _wait(1.0)
	var pet := main.who().pet
	pet.set_needs({"belly": 35.0, "fun": 70.0, "energy": 80.0, "love": 55.0, "age": Cryptlin.GROW_AGE})
	pet.position = Vector3(0.2, 0, 0.7)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	main.shelf.show_item("scanner")
	await _wait(1.0)
	await _snap("s1_row")
	main._pull("scanner", main.screen_of(Vector3(-0.9, 0, 0.9)))
	await _wait(0.5)
	await _snap("s2_finger")
	main.grab = Den.Grab.NONE
	main.start_scan()
	await _wait(1.6)
	await _snap("s3_scan")
	await _wait(0.5)
	await _snap("s3_scan2")
	main.stop_scan()
	pet.position = Vector3(-1.3, 0, 1.2)
	await _wait(0.3)
	main.start_scan()
	await _wait(1.6)
	await _snap("s4_left")
	main.stop_scan()
	pet.set_needs({"age": 0.0})
	pet.position = Vector3(0.2, 0, 0.7)
	await _wait(1.0)
	main.start_scan()
	await _wait(1.6)
	await _snap("s5_baby")
	main.stop_scan()
	pet.position = Vector3(-1.2, 0, -0.6)
	var egg := main.new_egg()
	await _until(func() -> bool: return egg.egg.landed, 4.0)
	main.start_scan(egg)
	await _wait(1.6)
	await _snap("s6_egg")
	main.stop_scan()
	main.set_lamp(Den.Lamp.OFF)
	main.start_scan(pet.me)
	await _wait(1.6)
	await _snap("s7_dark")
	quit()


# Three of different kinds in the one room: standing about, called over, eating, asleep in the
# nest, each one's page in the notebook, and the scanner on one of them
func _run_many() -> void:
	await _wait(1.0)
	var all := main.pets()
	for i in all.size():
		all[i].position = Vector3(-1.1 + i * 1.1, 0, 0.5 - 0.5 * (i % 2))
		all[i]._enter(Cryptlin.State.STARE)
	await _wait(1.5)
	await _snap("m1_three")
	main.call_all(Vector3(0.2, 0, 0.9))
	await _wait(2.5)
	await _snap("m2_called")
	for pet in all:
		pet.belly = 25.0
	main.feed(0, Vector3(-0.3, 4.0, 0.6))
	main.feed(0, Vector3(0.5, 4.0, 0.7))
	await _until(func() -> bool: return all.any(func(pet: Cryptlin) -> bool: return pet.state == Cryptlin.State.EAT), 8.0)
	await _wait(0.5)
	await _snap("m3_eating")
	await _until(func() -> bool: return main.snacks.is_empty(), 10.0)
	main.move_nest(Vector3(-0.4, 0, 0.3))
	for pet in all:
		pet.energy = 30.0
	main.set_lamp(Den.Lamp.LOW)
	for pet in all:
		pet.position = main.nest_pos + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
		pet._enter(Cryptlin.State.SLEEP)
	await _wait(2.5)
	await _snap("m4_asleep")
	main.set_lamp(Den.Lamp.BRIGHT)
	for i in all.size():
		all[i].energy = 90.0
		all[i].position = Vector3(-1.1 + i * 1.1, 0, 0.6)
		all[i]._enter(Cryptlin.State.IDLE, 30.0)
	# What they get up to together: a sniff, a chase, a fight and the loser afterwards
	for pet in all:
		pet.fight_cooldown = 0.0
	all[0].meet(Cryptlin.State.SNIFF, all[1])
	await _until(func() -> bool: return all[0].step == 1, 6.0)
	await _wait(0.6)
	await _snap("n1_sniff")
	all[2].meet(Cryptlin.State.TAG, all[0])
	await _wait(1.2)
	await _snap("n2_chase")
	await _until(func() -> bool: return all[2].state != Cryptlin.State.TAG and all[2].state != Cryptlin.State.FLEE, 12.0)
	all[0].position = Vector3(-0.2, 0, 0.7)
	all[1].position = Vector3(0.4, 0, 0.7)
	main.start_fight(all[0], all[1])
	await _wait(0.9)
	await _snap("n3_scuffle")
	await _wait(0.5)
	await _snap("n3_scuffle2")
	await _until(func() -> bool: return main.scuffle == null, 6.0)
	await _wait(1.6)
	await _snap("n4_after")
	await _wait(2.5)
	# Two that are fond of each other pairing off, caught at it, and the egg that turns up in the
	# nest (they are made a happy pair for the picture, and the hours are skipped)
	for pet: Cryptlin in [all[0], all[1]]:
		pet.set_needs({"belly": 90.0, "energy": 90.0, "health": 100.0})
		pet.comfort = 90.0
		pet.fav_ground = main.floor_style
		pet.fav_lamp = main.lamp_mode
		pet.fight_cooldown = 999.0
		pet._enter(Cryptlin.State.IDLE, 30.0)
	main.warm(all[0], all[1], 100.0)
	main.warm(all[1], all[0], 100.0)
	all[0].position = Vector3(-0.6, 0, 0.8)
	all[1].position = Vector3(0.5, 0, 0.8)
	all[2].position = Vector3(1.5, 0, -0.8)
	all[2]._enter(Cryptlin.State.STARE)
	all[0].meet(Cryptlin.State.PAIR, all[1])
	await _until(func() -> bool: return all[0].step == 1, 8.0)
	await _wait(1.0)
	await _snap("p1_pair")
	all[0].caught()
	await _wait(0.8)
	await _snap("p2_caught")
	await _until(func() -> bool: return all[0].state != Cryptlin.State.PAIR, 5.0)
	main.paired(all[0], all[1], Den.EGG_HOURS * 3600.0)
	await _wait(1.2)
	await _snap("p3_egg")
	# A poorly one, and the end of it: lying still, the ghost going up, and the marker it leaves
	all[2].set_needs({"health": 25.0, "belly": 30.0})
	all[2].flash_time = 0.0
	all[2].position = Vector3(-0.6, 0, 0.9)
	all[2].target = Vector3(0.9, 0, 0.9)
	all[2]._enter(Cryptlin.State.WANDER)
	await _wait(1.3)
	await _snap("o1_poorly")
	all[2].health = 0.0
	await _wait(1.6)
	await _snap("o2_still")
	await _wait(2.4)
	await _snap("o3_ghost")
	await _wait(1.4)
	await _snap("o4_ghost")
	await _wait(4.0)
	await _snap("o5_marker")
	main.new_egg()
	await _wait(2.0)
	main.start_scan(all[1].me)
	await _wait(1.6)
	await _snap("m5_scan")
	main.stop_scan()
	main.chosen = all[0].me
	main.notebook.open()
	for i in main.notebook.everyone().size():
		main.notebook.open_at(i)
		await _wait(0.3)
		await _snap("m6_page%d" % i)
	main.notebook.open_at(main.notebook.everyone().size())
	await _wait(0.3)
	await _snap("m7_care")
	main.notebook.open_at(main.notebook.chapters() - 1)
	await _wait(0.3)
	await _snap("m8_odds")
	quit()


# Twelve of the kind on one sheet, four to a row: six seeds from before there were more colours
# and six from since, counted on from --seed. The room holds four, so each row is the room
# opened afresh with four in it, and the strip they stand in is cut out of the picture.
func _run_variety() -> void:
	var strip := Rect2i(320, 370, 640, 220)
	var sheet := Image.create(strip.size.x, strip.size.y * 3, false, Image.FORMAT_RGB8)
	for row in 3:
		var four: Array = []
		for i in per_row:
			var n := row * per_row + i
			var k := beside if beside >= 0 and n % 2 == 1 else kind
			var s := look + n / 2 + 1 + (Cryptlin.OLD_SEEDS if n % 2 == 1 and beside < 0 else 0)
			four.append({"id": i + 1, "name": "Seed %d" % s, "kind": Cryptlin.KINDS[k]["title"], "seed": s, "hatched": true, "born": Time.get_unix_time_from_system() - 200000.0, "needs": {"belly": 80.0, "fun": 80.0, "energy": 90.0, "love": 50.0}})
		var f := FileAccess.open(save, FileAccess.WRITE)
		f.store_string(JSON.stringify({"v": 3, "residents": four, "next_id": 5, "time": Time.get_unix_time_from_system()}))
		f.close()
		main = load("res://main.tscn").instantiate()
		main.save_path = save
		main.ask_names = false
		root.add_child(main)
		await _wait(0.6)
		if dark:
			main.set_lamp(Den.Lamp.OFF)
		else:
			var sun := DirectionalLight3D.new()
			sun.light_energy = 0.45
			main.add_child(sun)
			sun.look_at_from_position(Vector3(0.5, 2.0, 4.0), Vector3(0, 0.4, 0))
		if over:
			main.place_decor(Decor.Kind.PUMPKIN, Vector3(2.0 / per_row + 0.1, 0, 1.45))
			main.place_decor(Decor.Kind.FERN, Vector3(-2.0 / per_row - 0.25, 0, 1.4))
		var all := main.pets()
		for frame in 80:
			for i in all.size():
				var pet := all[i]
				if baby:
					pet.age = 0.0
					pet.grow = pet.size_goal()
				pet.position = Vector3((i - (per_row - 1) * 0.5) * 4.0 / per_row, 0, 1.9)
				if over and i % 2 == 1:
					# (the other kind stood behind the one before it, to be seen through it or not)
					pet.position = Vector3((i - 1 - (per_row - 1) * 0.5) * 4.0 / per_row + 0.15, 0, 1.3)
				pet.yaw = PI * 0.5 if side_on else turned
				pet.velocity = Vector3.ZERO
				pet.fight_cooldown = 99.0
				pet.emote_again = 99.0
				pet.emote.visible = false
				pet.gaze = main.camera.global_position
				pet.xray(bare)
				if pet.state != Cryptlin.State.IDLE:
					pet._enter(Cryptlin.State.IDLE, 60.0)
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot, strip, Vector2i(0, strip.size.y * row))
		main.queue_free()
		await _wait(0.2)
	var tag := "%s%s%s%s%s%s%s" % ["_with%d" % beside if beside >= 0 else "", "_over" if over else "", "_side" if side_on else "", "_turn%d" % roundi(rad_to_deg(turned)) if turned != 0.0 else "", "_baby" if baby else "", "_dark" if dark else "", "_xray" if bare else ""]
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png("%s/k%d_variety%s.png" % [out, kind, tag])
	quit()


# One of the kind close to, on one sheet. With --poses: stood facing you and turned three ways,
# walking, eating, held up, and asleep from three sides. With --strides: so many moments one
# after another of it going across the room at a walk and then at a run, and of the jump it gives
# when it is startled. A baby with --baby.
func _run_close() -> void:
	await _wait(0.8)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.45
	main.add_child(sun)
	sun.look_at_from_position(Vector3(0.5, 2.0, 4.0), Vector3(0, 0.4, 0))
	var pet := main.who().pet
	pet.set_needs({"belly": 80.0, "fun": 80.0, "energy": 90.0, "love": 50.0})
	if baby:
		pet.age = 0.0
		pet.grow = pet.size_goal()
	var tiles: Array[Image] = []
	var spot := Vector3(0, 0, 1.7)
	if strides:
		for pace in 3:
			pet.position = Vector3(-1.5, 0, 1.7) if pace < 2 else spot
			pet.yaw = PI * 0.5
			pet._enter(Cryptlin.State.IDLE, 60.0)
			await _wait(0.5)
			match pace:
				0:
					pet.target = Vector3(1.7, 0, 1.7)
					pet._enter(Cryptlin.State.WANDER)
					await _wait(0.5)
				1:
					pet.call_to(Vector3(1.7, 0, 1.7))
					await _wait(0.35)
				2:
					pet.boop()
			for i in 8:
				tiles.append(await _tile(pet))
				await _wait(0.05 if pace < 2 else 0.09)
	else:
		for turn: float in [0.0, 70.0, 180.0, 250.0]:
			pet.position = spot
			pet._enter(Cryptlin.State.IDLE, 60.0)
			for frame in 40:
				pet.yaw = deg_to_rad(turn)
				await process_frame
			tiles.append(await _tile(pet))
		pet.position = Vector3(-1.2, 0, 1.7)
		pet.target = Vector3(1.7, 0, 1.7)
		pet._enter(Cryptlin.State.WANDER)
		await _wait(0.9)
		tiles.append(await _tile(pet))
		pet.belly = 30.0
		main.feed()
		await _until(func() -> bool: return pet.state == Cryptlin.State.EAT, 8.0)
		await _wait(0.6)
		tiles.append(await _tile(pet))
		await _until(func() -> bool: return main.snacks.is_empty(), 5.0)
		pet.position = spot
		pet.pick_up()
		pet.carry(spot + Vector3(0, 0.7, 0))
		await _wait(1.0)
		tiles.append(await _tile(pet))
		pet.put_down()
		await _until(func() -> bool: return pet.state != Cryptlin.State.HELD, 3.0)
		pet.position = spot
		pet._enter(Cryptlin.State.SLEEP)
		for turn: float in [0.0, 110.0, 200.0]:
			for frame in 130:
				pet.position = spot
				pet.yaw = deg_to_rad(turn)
				await process_frame
			tiles.append(await _tile(pet))
	var across := 4 if strides else 5
	var size := tiles[0].get_size()
	var sheet := Image.create(size.x * across, size.y * ceili(float(tiles.size()) / across), false, Image.FORMAT_RGB8)
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, size), Vector2i((i % across) * size.x, (i / across) * size.y))
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png("%s/k%d_%s%s.png" % [out, kind, "strides" if strides else "poses", "_baby" if baby else ""])
	quit()


# The piece of the picture that one of them is in
func _tile(pet: Cryptlin) -> Image:
	pet.emote.visible = false
	pet.emote_again = 99.0
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	var scale := Vector2(shot.get_size()) / main.get_viewport().get_visible_rect().size
	var size := Vector2i(260, 300)
	var mid := Vector2i(main.screen_of(Vector3(pet.position.x, 0.8 + pet.lift + pet.jump_y * 0.6, pet.position.z)) * scale)
	var piece := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	piece.blit_rect(shot, Rect2i(mid - size / 2, size).intersection(Rect2i(Vector2i.ZERO, shot.get_size())), Vector2i.ZERO)
	return piece


# The kind walking, under an even light: one picture of four moments of its stride as it goes
# across the room, and another of it going away up the room, which for one that looks back over
# its shoulder as it goes (the squatchling) is before the look and twice during it
func _run_walk() -> void:
	await _wait(0.6)
	var pet := main.who().pet
	pet.set_needs({"belly": 90.0, "fun": 90.0, "energy": 95.0, "love": 50.0, "age": 0.0 if baby else Cryptlin.GROW_AGE})
	pet.grow = pet.size_goal()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.45
	main.add_child(sun)
	sun.look_at_from_position(Vector3(0.5, 2.0, 4.0), Vector3(0, 0.4, 0))
	var size := Vector2i(230, 250)
	for away in 2:
		pet.position = Vector3(0.9, 0, 2.3) if away == 1 else Vector3(-1.7, 0, 1.7)
		pet.target = Vector3(-0.7, 0, -0.9) if away == 1 else Vector3(1.9, 0, 1.7)
		pet.yaw = atan2(pet.target.x - pet.position.x, pet.target.z - pet.position.z)
		pet.back_again = 99.0
		pet._enter(Cryptlin.State.WANDER)
		var waits: Array = [0.9, 0.5, 0.45] if away == 1 else [0.8, 0.32, 0.32, 0.32]
		var sheet := Image.create(size.x * waits.size(), size.y, false, Image.FORMAT_RGB8)
		for i in waits.size():
			await _wait(waits[i])
			pet.emote.visible = false
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			shot.convert(Image.FORMAT_RGB8)
			var scale := Vector2(shot.get_size()) / main.get_viewport().get_visible_rect().size
			var mid := Vector2i(main.screen_of(pet.global_position + Vector3(0, pet.tall() * 0.5, 0)) * scale)
			if away == 1 and i == 0:
				pet.glance_back(1.6)
			sheet.blit_rect(shot, Rect2i(mid - size / 2, size), Vector2i(size.x * i, 0))
		sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
		sheet.save_png("%s/k%d_%s%s.png" % [out, kind, "glance" if away == 1 else "walk", "_baby" if baby else ""])
	quit()


# Its knack: one of the kind with another beside it and what it needs to hand, taking its turn
# at it. One picture of two moments, the middle of the room cut out of each and set side by side.
func _run_knack() -> void:
	await _wait(1.0)
	var pet: Cryptlin = main.residents[0].pet
	var mate: Cryptlin = main.residents[1].pet
	if pet.kind in [Cryptlin.Kind.NESSIE, Cryptlin.Kind.KELPIE]:
		main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	main.place_decor(Decor.Kind.SKULL, Vector3(1.4, 0, 0.9))
	if pet.kind == Cryptlin.Kind.MERMAID:
		# (a rock to sit on, and water to be happy in)
		main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
		main.place_decor(Decor.Kind.ROCK, Vector3(-1.5, 0, 1.0))
	if pet.kind == Cryptlin.Kind.KONGAMATO and pool:
		# (the pool, for it to skim: without --pool it knocks the skull over instead)
		main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	if pet.kind == Cryptlin.Kind.NIGHTCRAWLER:
		# (something worth walking through)
		main.place_decor(Decor.Kind.ROCK, Vector3(-1.5, 0, 0.3))
	main.play_ball(Ball.Kind.BALL)
	main.ball.position = Vector3(-1.5, 0.2, 1.1)
	main.ball.vel = Vector3.ZERO
	for p: Cryptlin in [pet, mate]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 50.0})
		p.fight_cooldown = 999.0
		p.ball_cooldown = 999.0
		p.beg_cooldown = 999.0
		p.emote_again = 999.0
		p._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(-0.6, 0, 0.8)
	mate.position = Vector3(0.6, 0, 0.8)
	if pet.kind in [Cryptlin.Kind.FROGMAN, Cryptlin.Kind.BOLTER]:
		mate.belly = 100.0
		pet.belly = 100.0
		main.feed((pet.yuck_food + 1) % Snack.NAMES.size(), Vector3(1.1, 1.0, 1.6))
		await _wait(1.2)
		pet.belly = 60.0
	await _wait(0.6)
	pet.knack.again = 0.0
	pet._enter(Cryptlin.State.TRICK)
	var cut := Rect2i(250, 110, 780, 520)
	var sheet := Image.create(cut.size.x * 2, cut.size.y, false, Image.FORMAT_RGB8)
	for moment in 2:
		if moment == 0:
			await _until(func() -> bool: return pet.step >= from_step, 6.0)
			await _wait(first_wait)
		else:
			await _wait(second_wait)
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot, cut, Vector2i(cut.size.x * moment, 0))
	sheet.save_png("%s/k%d_knack.png" % [out, kind])
	quit()


# Four in a room with the pool: in each place it fits (those that live in water wading, the rest
# on the dry floor), under each lamp, one that does not live in water let go over the middle
# of it, food and a toy thrown in, one come down for a drink, and all of them asleep
func _run_pool() -> void:
	await _wait(1.0)
	var all := main.pets()
	main.move_nest(Vector3(1.3, 0, 1.2))
	for where in Den.shores():
		main.place_decor(Decor.Kind.POOL, Den.middle(where))
		await _spread(all)
		await _snap("q1_place%d" % where)
	for mode in [Den.Lamp.LOW, Den.Lamp.HEAT, Den.Lamp.OFF, Den.Lamp.BRIGHT]:
		main.set_lamp(mode)
		await _spread(all)
		await _snap("q2_lamp_%s" % Den.LAMPS[mode]["title"])
	var land := all.filter(func(pet: Cryptlin) -> bool: return not pet.needs_water())
	if not land.is_empty():
		land[0].position = Den.in_room(Den.shore_by(Vector3.ZERO, -1.7), 0.6)
		land[0]._enter(Cryptlin.State.IDLE, 5.0)
		await _wait(0.3)
		await _snap("q3_flounder")
		await _until(func() -> bool: return land[0].state != Cryptlin.State.FLOUNDER, 6.0)
		await _wait(0.4)
		await _snap("q3_out")
	for pet in all:
		pet.belly = 100.0
		pet._enter(Cryptlin.State.IDLE, 30.0)
	main.feed(Snack.Kind.FISH, Den.in_room(Den.shore_by(Vector3(0.5, 0, 0.5), -1.1), 0.6) + Vector3(0, 2.5, 0))
	main.play_ball(Ball.Kind.BALL)
	main.ball.position = Den.in_room(Den.shore_by(Vector3(-0.6, 0, -0.6), -1.2), 0.6) + Vector3(0, 1.5, 0)
	main.ball.vel = Vector3.ZERO
	for pet in all:
		pet.ball_cooldown = 30.0
	await _wait(1.3)
	await _snap("q4_afloat")
	await _wait(3.0)
	await _snap("q4_drifted")
	main._clear_toys()
	if not land.is_empty():
		land[0]._enter(Cryptlin.State.VISIT)
		land[0].visiting = main.decor_of(Decor.Kind.POOL)
		await _until(func() -> bool: return land[0].step >= 1, 8.0)
		await _wait(1.0)
		await _snap("q5_drink")
	main.set_lamp(Den.Lamp.LOW)
	for pet in all:
		pet.energy = 30.0
		pet.position = pet._bed() + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		pet._enter(Cryptlin.State.SLEEP)
	await _wait(2.5)
	await _snap("q6_asleep")
	quit()


# Those that live in water out wading in the pool, and the rest stood about on the dry floor
func _spread(all: Array[Cryptlin]) -> void:
	var dry := 0
	for pet in all:
		pet.energy = 100.0
		if pet.needs_water():
			pet._enter(Cryptlin.State.VISIT)
			pet.visiting = main.decor_of(Decor.Kind.POOL)
		else:
			pet.position = Den.on_dry(Den.shore_by(Vector3.ZERO, 0.9) + Den.place(-0.9 + dry * 1.3, 0.3 * (dry % 2)), 0.4, 0.4)
			pet._enter(Cryptlin.State.STARE)
			dry += 1
	await _until(func() -> bool: return all.all(func(pet: Cryptlin) -> bool: return not pet.needs_water() or pet.step >= 1), 9.0)
	await _wait(1.2)


# Every face that goes up over its head, under the lamp, and then two of them in the dark
func _run_faces() -> void:
	var pet := main.who().pet
	pet.set_needs({"belly": 60.0, "fun": 60.0, "energy": 90.0, "love": 40.0})
	pet.position = Vector3(0.2, 0, 0.6)
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.0)
	for how in range(1, Cryptlin.FEELINGS.size()):
		pet._enter(Cryptlin.State.STARE)
		pet.feel(how, 3.0)
		await _wait(0.9)
		await _snap("f%d_%s" % [how, Cryptlin.FEELINGS[how]["title"]])
	main.toggle_lamp()
	pet.energy = 100.0
	for how: int in [Cryptlin.Feeling.SCARED, Cryptlin.Feeling.LOVING]:
		pet._enter(Cryptlin.State.STARE)
		pet.feel(how, 3.0)
		await _wait(1.2)
		await _snap("f_dark_%s" % Cryptlin.FEELINGS[how]["title"])
	quit()


func _run_egg() -> void:
	await _wait(0.4)
	await _snap("e0_drop")
	await _until(func() -> bool: return main.who().egg.landed, 4.0)
	await _wait(1.0)
	await _snap("e1_egg")
	main.who().egg.warmth = 33.5
	await _wait(1.2)
	await _snap("e2_crack")
	main.who().egg.warmth = 67.5
	await _wait(1.2)
	await _snap("e3_peek")
	main.toggle_lamp()
	await _wait(1.0)
	await _snap("e4_dark")
	main.toggle_lamp()
	main.who().egg.warmth = 99.9
	await _until(func() -> bool: return main.who().pet != null, 6.0)
	await _wait(0.12)
	await _snap("e5_hatch")
	await _wait(1.6)
	await _snap("e6_hatched")
	main.ask_let_go(main.who())
	await _wait(0.3)
	await _snap("e7_ask")
	main._answer(true)
	await _wait(1.0)
	await _snap("e8_wave")
	quit()


func _run() -> void:
	var pet := main.who().pet
	pet.set_needs({"belly": 60.0, "fun": 60.0, "energy": 90.0, "love": 40.0})
	pet.position = Vector3(0.2, 0, 0.6)
	pet.yaw = 0.3
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.6)
	await _snap("1_stare")
	pet.feel(Cryptlin.Feeling.GRUMPY, 3.0)
	await _wait(1.0)
	await _snap("1_face")
	pet.flash_time = 0.0
	pet.position = Vector3(-0.9, 0, 0.2)
	pet.target = Vector3(1.3, 0, 0.9)
	pet._enter(Cryptlin.State.WANDER)
	await _wait(1.0)
	await _snap("2_walk")
	if pet.likes.has("print"):
		# The trail a heavy one leaves, on flagstones and then on sand
		for style: int in [0, 5]:
			main.set_ground(style)
			pet.position = Vector3(-1.2, 0, 0.3)
			pet.target = Vector3(1.4, 0, 1.3)
			pet._enter(Cryptlin.State.WANDER)
			await _until(func() -> bool: return pet.state != Cryptlin.State.WANDER, 6.0)
			await _snap("2_prints%d" % style)
		main.set_ground(0)
	pet.belly = 30.0
	main.feed()
	await _until(func() -> bool: return pet.state == Cryptlin.State.EAT, 8.0)
	await _wait(0.6)
	await _snap("3_eat")
	await _until(func() -> bool: return main.snacks.is_empty(), 4.0)
	main.play_ball()
	await _until(func() -> bool: return pet.kicks_total > 0, 10.0)
	await _wait(0.25)
	await _snap("4_ball")
	main.ball.vel = Vector3.ZERO
	pet.belly = 10.0
	pet.beg_cooldown = 0.0
	pet.ball_cooldown = 30.0
	pet._enter(Cryptlin.State.BEG)
	await _until(func() -> bool: return pet.step == 1, 6.0)
	await _wait(1.0)
	await _snap("5_beg")
	pet.belly = 80.0
	pet.stroke()
	for i in 50:
		pet.stroke()
		await process_frame
	await _snap("6_petted")
	pet.pick_up()
	pet.carry(pet.position + Vector3(0.2, 0.8, 0))
	await _wait(1.0)
	await _snap("6a_held")
	pet.put_down()
	await _until(func() -> bool: return pet.state != Cryptlin.State.HELD, 3.0)
	await _wait(0.8)
	pet._enter(Cryptlin.State.LURK)
	await _until(func() -> bool: return pet.step == 1, 9.0)
	await _wait(1.0)
	await _snap("7_lurk")
	pet.set_needs({"belly": 80.0, "fun": 80.0, "energy": 90.0, "bowel": 100.0})
	pet._enter(Cryptlin.State.IDLE, 0.1)
	await _until(func() -> bool: return pet.state == Cryptlin.State.TOILET and pet.step == 1, 9.0)
	await _wait(1.0)
	await _snap("7a_squat")
	await _until(func() -> bool: return pet.state != Cryptlin.State.TOILET, 5.0)
	await _wait(0.5)
	await _snap("7b_dropping")
	pet.position = Vector3(0.4, 0, 0.8)
	main.move_nest(Vector3(-0.3, 0, 0.5))
	pet._enter(Cryptlin.State.FOND)
	await _until(func() -> bool: return pet.step == 1, 9.0)
	await _wait(1.0)
	await _snap("7c_fond")
	pet.caught()
	await _wait(0.8)
	await _snap("7d_caught")
	await _until(func() -> bool: return pet.state != Cryptlin.State.FOND, 5.0)
	main.move_nest(Vector3(-1.6, 0, -1.2))
	pet.position = Vector3(0.3, 0, 0.7)
	for doing: int in [Cryptlin.State.SCRATCH, Cryptlin.State.DIG, Cryptlin.State.SPIN, Cryptlin.State.GAZE, Cryptlin.State.STRETCH]:
		pet._enter(doing)
		await _wait(1.1)
		await _snap("7e_%s" % Cryptlin.State.keys()[doing].to_lower())
	pet.position = main.nest_pos
	pet._enter(Cryptlin.State.SLEEP)
	await _wait(2.0)
	await _snap("8_sleep")
	main.toggle_lamp()
	pet.energy = 100.0
	pet.position = Vector3(0.6, 0, 1.2)
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.5)
	await _snap("9_dark")
	pet.feel(Cryptlin.Feeling.SCARED, 3.0)
	await _wait(1.0)
	await _snap("9_dark_face")
	quit()
