extends SceneTree
## Screenshots of the cryptlin at its various doings.
## godot --path . -s tests/shots.gd -- --shots=<dir> [--portrait] [--seed=N] [--kind=0..18] [--egg|--ui [--baby]|--faces|--many]
## With --egg: the egg of that kind, cracking and hatching, and then the new-egg question.
## With --ui: the room done up, the pool, the lamp, the scanner and the notebook. With --faces:
## each of the faces that go up over its head. With --many: three of different kinds sharing the room.

# The save this run uses: one for each kind and shape of screen, so that several can be run at once
var save := "user://shots_test.json"

var main: Den
var out := "user://shots"
var portrait := false
var look := 0
var kind := 0
var ui_only := false
var egg_only := false
var faces_only := false
var baby := false
var many := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out = arg.trim_prefix("--shots=")
		if arg.begins_with("--seed="):
			look = int(arg.trim_prefix("--seed="))
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
		if arg == "--egg":
			egg_only = true
		if arg == "--baby":
			baby = true
		if arg == "--faces":
			faces_only = true
		if arg == "--ui":
			ui_only = true
		if arg == "--many":
			many = true
		if arg == "--portrait":
			portrait = true
	DirAccess.make_dir_recursive_absolute(out)
	save = "user://shots_test_%d%s.json" % [kind, "_p" if portrait else ""]
	DisplayServer.window_set_size(Vector2i(540, 1170) if portrait else Vector2i(1280, 720))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	if many:
		# Three of different kinds, grown, as a save holds them
		var three: Array = []
		for i in 3:
			var k := (kind + i * 5) % Cryptlin.KINDS.size()
			three.append({"id": i + 1, "name": ["Mog", "Pim", "Zog"][i], "kind": Cryptlin.KINDS[k]["title"], "seed": maxi(look, 1) + i * 37, "hatched": true, "born": Time.get_unix_time_from_system() - 200000.0, "needs": {"belly": 70.0, "fun": 70.0, "energy": 90.0, "love": 50.0}})
		var f := FileAccess.open(save, FileAccess.WRITE)
		f.store_string(JSON.stringify({"v": 3, "residents": three, "next_id": 4, "time": Time.get_unix_time_from_system()}))
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
	if many:
		_run_many.call_deferred()
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
	for k in range(Decor.Kind.POOL + 1, Decor.IDS.size()):
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
	main.notebook.turn(main.notebook.pages() - 2)
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
	main.new_egg()
	await _wait(2.0)
	main.start_scan(all[1].me)
	await _wait(1.6)
	await _snap("m5_scan")
	main.stop_scan()
	main.chosen = all[0].me
	main.notebook.open()
	for i in main.residents.size():
		await _wait(0.3)
		await _snap("m6_page%d" % i)
		main.notebook.turn(1)
	await _wait(0.3)
	await _snap("m7_care")
	main.notebook.turn(main.notebook.pages() - main.residents.size() - 1)
	await _wait(0.3)
	await _snap("m8_odds")
	quit()


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
